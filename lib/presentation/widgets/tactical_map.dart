import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TacticalMapPainter extends CustomPainter {
  final double latitude;
  final double longitude;
  final double heading;
  final List<List<double>> path;

  TacticalMapPainter({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.path,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerLat = path.isNotEmpty ? path.first[0] : latitude;
    final double centerLon = path.isNotEmpty ? path.first[1] : longitude;

    // Scale mapping: 0.0015 degree span = full map size
    final double scaleX = size.width / 0.0015;
    final double scaleY = size.height / 0.0015;

    Offset toPixel(double lat, double lon) {
      final double x = size.width / 2 + (lon - centerLon) * scaleX;
      final double y = size.height / 2 - (lat - centerLat) * scaleY; // Y is inverted on canvas
      return Offset(x, y);
    }

    final Paint gridPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.08)
      ..strokeWidth = 1.0;

    // 1. Draw grid coordinate lines
    const int gridDivisions = 10;
    for (int i = 0; i <= gridDivisions; i++) {
      final double x = size.width * i / gridDivisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      
      final double y = size.height * i / gridDivisions;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Sector dividing borders
    final Paint borderPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), borderPaint);

    // Draw Sector identifiers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    void drawSectorLabel(String name, Offset pos) {
      textPainter.text = TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.greenAccent.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos);
    }

    drawSectorLabel('SECTOR 1 - NORTH', const Offset(12, 12));
    drawSectorLabel('SECTOR 2 - EAST', Offset(size.width / 2 + 12, 12));
    drawSectorLabel('SECTOR 3 - WEST', Offset(12, size.height / 2 + 12));
    drawSectorLabel('SECTOR 4 - SOUTH (ACTIVE)', Offset(size.width / 2 + 12, size.height / 2 + 12));

    // 3. Draw Path Trace (Breadcrumbs Trail)
    if (path.length > 1) {
      final Paint pathPaint = Paint()
        ..color = Colors.greenAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Paint glowPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.3)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path tracePath = Path();
      final Offset firstPt = toPixel(path[0][0], path[0][1]);
      tracePath.moveTo(firstPt.dx, firstPt.dy);

      for (int i = 1; i < path.length; i++) {
        final Offset pt = toPixel(path[i][0], path[i][1]);
        tracePath.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(tracePath, glowPaint);
      canvas.drawPath(tracePath, pathPaint);
    }

    // 4. Draw Rover Vector Position
    final Offset roverPos = toPixel(latitude, longitude);

    // Draw radar target rings
    final Paint radarRing = Paint()
      ..color = Colors.greenAccent.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(roverPos, 20.0, radarRing);
    canvas.drawCircle(roverPos, 35.0, radarRing);

    // Draw crosshair axes
    canvas.drawLine(Offset(roverPos.dx - 45, roverPos.dy), Offset(roverPos.dx + 45, roverPos.dy), gridPaint);
    canvas.drawLine(Offset(roverPos.dx, roverPos.dy - 45), Offset(roverPos.dx, roverPos.dy + 45), gridPaint);

    // Draw Rover Arrow Symbol
    canvas.save();
    canvas.translate(roverPos.dx, roverPos.dy);
    
    // Rotate according to heading angle
    final double angleRad = heading * (pi / 180.0);
    canvas.rotate(angleRad);

    final Path roverPath = Path()
      ..moveTo(0, -9)   // Arrow nose tip
      ..lineTo(-6, 7)   // Bottom-left
      ..lineTo(0, 3)    // Tail indent
      ..lineTo(6, 7)    // Bottom-right
      ..close();

    final Paint roverPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    final Paint roverGlow = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(roverPath, roverGlow);
    canvas.drawPath(roverPath, roverPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TacticalMapPainter oldDelegate) {
    return oldDelegate.latitude != latitude ||
        oldDelegate.longitude != longitude ||
        oldDelegate.heading != heading ||
        oldDelegate.path.length != path.length;
  }
}

class TacticalMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double heading;
  final List<List<double>> path;

  const TacticalMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: TacticalMapPainter(
                  latitude: latitude,
                  longitude: longitude,
                  heading: heading,
                  path: path,
                ),
              ),
            ),
            
            // GPS HUD readout overlay
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.navigation, size: 10, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text(
                      'LAT: ${latitude.toStringAsFixed(6)}   LON: ${longitude.toStringAsFixed(6)}   HDG: ${heading.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tactical label
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Text(
                  'TACTICAL MAP FEED',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
