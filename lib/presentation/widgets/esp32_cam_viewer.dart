import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/localization/translations.dart';

class ESP32CamStreamService {
  final String url;
  final Duration timeout;
  
  HttpClient? _client;
  StreamController<Uint8List>? _controller;
  int _listenerCount = 0;
  Timer? _shutdownTimer;

  ESP32CamStreamService(this.url, {this.timeout = const Duration(seconds: 5)});

  Stream<Uint8List> get stream {
    _controller ??= StreamController<Uint8List>.broadcast(
      onListen: () {
        _listenerCount++;
        if (_shutdownTimer != null) {
          _shutdownTimer!.cancel();
          _shutdownTimer = null;
        }
        if (_client == null) {
          _startStreaming();
        }
      },
      onCancel: () {
        _listenerCount--;
        if (_listenerCount <= 0) {
          _listenerCount = 0;
          _shutdownTimer = Timer(const Duration(seconds: 3), () {
            _cleanup();
          });
        }
      },
    );
    return _controller!.stream;
  }

  void _startStreaming() async {
    _client = HttpClient();
    _client!.connectionTimeout = timeout;
    
    try {
      final request = await _client!.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }
      
      final BytesBuilder buffer = BytesBuilder(copy: false);
      
      await for (final chunk in response) {
        if (_controller == null || _controller!.isClosed) break;
        
        // Safety limit to prevent memory exhaustion
        if (buffer.length > 1024 * 1024) {
          buffer.clear();
        }
        
        buffer.add(chunk);
        
        while (true) {
          final bytes = buffer.toBytes();
          
          // Find Start of Image Marker: SOI (0xFF, 0xD8)
          int soiIndex = -1;
          for (int i = 0; i < bytes.length - 1; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
              soiIndex = i;
              break;
            }
          }
          
          if (soiIndex == -1) {
            // SOI not found. Keep only the last byte if it might be part of an SOI marker
            if (bytes.length > 2048) {
              final lastByte = bytes.last;
              buffer.clear();
              if (lastByte == 0xFF) {
                buffer.addByte(0xFF);
              }
            }
            break;
          }
          
          // Find End of Image Marker: EOI (0xFF, 0xD9)
          int eoiIndex = -1;
          for (int i = soiIndex + 2; i < bytes.length - 1; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
              eoiIndex = i + 1; // Inclusive of EOI marker (0xD9)
              break;
            }
          }
          
          if (eoiIndex == -1) {
            // EOI not found yet. Retain bytes from SOI onwards, discarding prior debris.
            if (soiIndex > 0) {
              final remaining = bytes.sublist(soiIndex);
              buffer.clear();
              buffer.add(remaining);
            }
            break;
          }
          
          // Extract the full JPEG frame
          final frame = bytes.sublist(soiIndex, eoiIndex + 1);
          if (_controller != null && !_controller!.isClosed) {
            _controller!.add(Uint8List.fromList(frame));
          }
          
          // Discard processed bytes
          final remaining = bytes.sublist(eoiIndex + 1);
          buffer.clear();
          buffer.add(remaining);
        }
      }
    } catch (e) {
      if (_controller != null && !_controller!.isClosed) {
        _controller!.addError(e);
      }
      _cleanup();
    }
  }

  void _cleanup() {
    _client?.close(force: true);
    _client = null;
    _controller?.close();
    _controller = null;
  }
}

class ESP32CamViewer extends ConsumerStatefulWidget {
  final String streamUrl;
  final BoxFit fit;

  // Static map of URL to shared stream service
  static final Map<String, ESP32CamStreamService> _sharedServices = {};

  const ESP32CamViewer({
    super.key,
    required this.streamUrl,
    this.fit = BoxFit.cover,
  });

  @override
  ConsumerState<ESP32CamViewer> createState() => _ESP32CamViewerState();
}

class _ESP32CamViewerState extends ConsumerState<ESP32CamViewer> {
  Stream<Uint8List>? _frameStream;
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    // Retrieve or create the shared stream service for this URL
    final service = ESP32CamViewer._sharedServices.putIfAbsent(
      widget.streamUrl,
      () => ESP32CamStreamService(widget.streamUrl),
    );
    _frameStream = service.stream;
  }

  void _retry() {
    setState(() {
      _retryKey++;
      
      // Clean up the failed service so a fresh connection is created
      final service = ESP32CamViewer._sharedServices.remove(widget.streamUrl);
      service?._cleanup();
      
      _initStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<Uint8List>(
      key: ValueKey('${widget.streamUrl}_$_retryKey'),
      stream: _frameStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.wifiOff, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  'Camera Feed Offline'.tr(ref),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Could not connect to:\n${widget.streamUrl}'.tr(ref),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text('Reconnect'.tr(ref)),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
          );
        }

        // Connecting/Loading State
        return Container(
          color: Colors.black87,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CONNECTING FEED...'.tr(ref),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.streamUrl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
