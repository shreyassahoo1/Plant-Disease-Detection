import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/localization/translations.dart';
import '../../../data/models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../widgets/glass_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'SCAN', 'ALERT', 'ROVER', 'SENSOR'
  bool _isCompareMode = false;
  final List<String> _selectedItemIds = [];

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    
    if (itemDate == today) {
      return 'Today, $timeStr';
    } else if (itemDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, $timeStr';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'SCAN':
        return LucideIcons.scan;
      case 'ALERT':
        return LucideIcons.bellRing;
      case 'ROVER':
        return LucideIcons.bot;
      case 'SENSOR':
        return LucideIcons.lineChart;
      default:
        return LucideIcons.helpCircle;
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'HIGH':
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.orangeAccent;
      case 'LOW':
        return Colors.greenAccent;
      case 'INFO':
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final theme = Theme.of(context);

    // Apply Filter
    final filteredHistory = history.where((item) {
      if (_selectedFilter == 'ALL') return true;
      return item.type == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('History Logs'.tr(ref)),
        actions: [
          if (history.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isCompareMode = !_isCompareMode;
                  _selectedItemIds.clear();
                });
              },
              icon: Icon(_isCompareMode ? LucideIcons.checkSquare : LucideIcons.listTodo, size: 18),
              label: Text(_isCompareMode ? 'Done'.tr(ref) : 'Compare'.tr(ref)),
              style: TextButton.styleFrom(
                foregroundColor: _isCompareMode ? theme.colorScheme.primary : Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              tooltip: 'Clear History'.tr(ref),
              onPressed: () => _confirmClearHistory(context),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Filter ChoiceChips
          _buildFilterBar(),
          
          // Selection Banner if Compare Mode Active
          if (_isCompareMode) _buildCompareBanner(),

          // Main List
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final isSelected = _selectedItemIds.contains(item.id);
                      final icon = _getIconForType(item.type);
                      final color = _getColorForSeverity(item.severity);

                      final cardWidget = Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          onTap: () {
                            if (_isCompareMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedItemIds.remove(item.id);
                                } else {
                                  if (_selectedItemIds.length >= 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('You can only compare 2 items at a time.'.tr(ref)),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    _selectedItemIds.add(item.id);
                                  }
                                }
                              });
                            } else {
                              _showItemDetails(context, item);
                            }
                          },
                          child: Row(
                            children: [
                              if (_isCompareMode) ...[
                                Checkbox(
                                  value: isSelected,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        if (_selectedItemIds.length >= 2) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('You can only compare 2 items at a time.'.tr(ref)),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        } else {
                                          _selectedItemIds.add(item.id);
                                        }
                                      } else {
                                        _selectedItemIds.remove(item.id);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.tr(ref),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description.tr(ref),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(item.timestamp),
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.severity,
                                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isCompareMode) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.grey.shade600),
                              ],
                            ],
                          ),
                        ),
                      );

                      if (_isCompareMode) {
                        return cardWidget;
                      }

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                        ),
                        onDismissed: (direction) {
                          ref.read(historyProvider.notifier).deleteHistoryItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Log deleted.'.tr(ref)),
                              action: SnackBarAction(
                                label: 'Undo'.tr(ref),
                                onPressed: () {
                                  ref.read(historyProvider.notifier).addHistoryItem(item);
                                },
                              ),
                            ),
                          );
                        },
                        child: cardWidget,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'SCAN', 'label': 'Scans'},
      {'key': 'ALERT', 'label': 'Alerts'},
      {'key': 'ROVER', 'label': 'Rover'},
      {'key': 'SENSOR', 'label': 'Sensors'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(f['label']!.tr(ref)),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundColor: Colors.transparent,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5) 
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFilter = f['key']!;
                    _selectedItemIds.clear(); // Reset comparisons if filter changes
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompareBanner() {
    final theme = Theme.of(context);
    final count = _selectedItemIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select 2 items to compare ($count/2)'.tr(ref),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ElevatedButton(
            onPressed: count == 2 
                ? () => _runComparison(context)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text('Compare Now'.tr(ref)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.clipboardList, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            'No history logs found.'.tr(ref),
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Clear History?'.tr(ref)),
          content: Text('Are you sure you want to permanently delete all history logs? This action cannot be undone.'.tr(ref)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr(ref)),
            ),
            TextButton(
              onPressed: () {
                ref.read(historyProvider.notifier).clearHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('History cleared successfully.'.tr(ref))),
                );
              },
              child: const Text('Delete All', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _runComparison(BuildContext context) {
    final history = ref.read(historyProvider);
    final itemsToCompare = history.where((item) => _selectedItemIds.contains(item.id)).toList();
    if (itemsToCompare.length != 2) return;
    
    // Pass items in chronological order: Item 1 (older) vs Item 2 (newer)
    final item1 = itemsToCompare[1].timestamp.isBefore(itemsToCompare[0].timestamp) ? itemsToCompare[1] : itemsToCompare[0];
    final item2 = item1 == itemsToCompare[0] ? itemsToCompare[1] : itemsToCompare[0];

    _showComparisonSheet(context, item1, item2);
  }

  void _showComparisonSheet(BuildContext context, HistoryItem item1, HistoryItem item2) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                children: [
                  // Pull handler
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Log Comparison'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Side-by-side titles
                        Row(
                          children: [
                            Expanded(
                              child: _buildComparisonHeaderCard(item1, 'Older Record'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildComparisonHeaderCard(item2, 'Newer Record'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Render type-specific comparison details
                        if (item1.type == 'SENSOR' && item2.type == 'SENSOR')
                          _buildSensorComparison(item1, item2)
                        else if (item1.type == 'SCAN' && item2.type == 'SCAN')
                          _buildScanComparison(item1, item2)
                        else
                          _buildMixedComparison(item1, item2),
                          
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComparisonHeaderCard(HistoryItem item, String label) {
    final color = _getColorForSeverity(item.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item.title.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(_formatDate(item.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(item.severity, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorComparison(HistoryItem item1, HistoryItem item2) {
    final s1 = item1.metadata;
    final s2 = item2.metadata;

    final double t1 = (s1['temperature'] as num?)?.toDouble() ?? 0.0;
    final double t2 = (s2['temperature'] as num?)?.toDouble() ?? 0.0;
    final double h1 = (s1['humidity'] as num?)?.toDouble() ?? 0.0;
    final double h2 = (s2['humidity'] as num?)?.toDouble() ?? 0.0;
    final double m1 = (s1['moisture'] as num?)?.toDouble() ?? 0.0;
    final double m2 = (s2['moisture'] as num?)?.toDouble() ?? 0.0;
    final double ph1 = (s1['ph'] as num?)?.toDouble() ?? 0.0;
    final double ph2 = (s2['ph'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Telemetry Metrics Analysis'),
        const SizedBox(height: 12),
        _buildMetricComparisonRow('Temperature', '${t1.toStringAsFixed(1)}°C', '${t2.toStringAsFixed(1)}°C', t2 - t1, '°C', lowerIsBetter: true),
        _buildMetricComparisonRow('Soil Moisture', '${m1.toStringAsFixed(1)}%', '${m2.toStringAsFixed(1)}%', m2 - m1, '%', lowerIsBetter: false),
        _buildMetricComparisonRow('Humidity', '${h1.toStringAsFixed(1)}%', '${h2.toStringAsFixed(1)}%', h2 - h1, '%', lowerIsBetter: null),
        _buildMetricComparisonRow('Soil pH', ph1.toStringAsFixed(1), ph2.toStringAsFixed(1), ph2 - ph1, '', lowerIsBetter: null),
        
        const SizedBox(height: 20),
        _buildSectionHeader('Agronomic Insights'),
        const SizedBox(height: 10),
        _generateSensorComparisonInsights(t1, t2, m1, m2, ph1, ph2),
      ],
    );
  }

  Widget _buildMetricComparisonRow(String name, String val1, String val2, double diff, String unit, {bool? lowerIsBetter}) {
    String diffText = '';
    Color diffColor = Colors.grey;
    if (diff > 0) {
      diffText = '+${diff.toStringAsFixed(1)}$unit';
      diffColor = lowerIsBetter == true ? Colors.redAccent : (lowerIsBetter == false ? Colors.greenAccent : Colors.blueAccent);
    } else if (diff < 0) {
      diffText = '${diff.toStringAsFixed(1)}$unit';
      diffColor = lowerIsBetter == true ? Colors.greenAccent : (lowerIsBetter == false ? Colors.redAccent : Colors.blueAccent);
    } else {
      diffText = 'No change';
      diffColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Text(name.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Expanded(
              flex: 2,
              child: Text(val1, style: const TextStyle(fontSize: 13), textAlign: TextAlign.right),
            ),
            const Expanded(
              flex: 1,
              child: Icon(Icons.arrow_right_alt, color: Colors.grey),
            ),
            Expanded(
              flex: 2,
              child: Text(val2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: diffColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(diffText, style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateSensorComparisonInsights(double t1, double t2, double m1, double m2, double ph1, double ph2) {
    List<String> insights = [];

    // Temperature analysis
    if (t2 > 35) {
      insights.add('⚠️ Critical heat stress registered in the latest log. Temperatures above 35°C are hazardous to most crops.');
    } else if (t2 < t1 && t1 > 32) {
      insights.add('✅ Environmental temperature has cooled down, decreasing heat stress levels.');
    }

    // Soil moisture analysis
    if (m2 < 30) {
      insights.add('⚠️ Soil moisture is extremely low (${m2.toStringAsFixed(1)}%). Crops risk wilting. Immediate irrigation is highly advised.');
    } else if (m2 > m1 + 10) {
      insights.add('🎉 Soil moisture improved significantly (+${(m2-m1).toStringAsFixed(1)}%), indicating successful watering or rain.');
    } else if (m2 < m1 - 5) {
      insights.add('📉 Soil moisture level is depleting. Keep a close eye to trigger irrigation if it goes below 35%.');
    }

    // pH analysis
    if (ph2 < 5.5) {
      insights.add('⚠️ Soil is highly acidic. Nutrient absorption (Nitrogen, Potassium) might be inhibited. Add agricultural lime.');
    } else if (ph2 > 7.8) {
      insights.add('⚠️ Soil is alkaline. Consider adding organic matter or sulfur to lower the pH.');
    }

    if (insights.isEmpty) {
      insights.add('📊 The ecosystem metrics are stable. Soil moisture and temperature values remain within standard operational bounds.');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeInsightBg(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                Expanded(child: Text(insight, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color themeInsightBg() {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.greenAccent.withOpacity(0.04) 
        : Colors.black.withOpacity(0.03);
  }

  Widget _buildScanComparison(HistoryItem item1, HistoryItem item2) {
    final String dis1 = item1.metadata['diseaseName'] ?? 'Unknown';
    final String dis2 = item2.metadata['diseaseName'] ?? 'Unknown';
    final double conf1 = (item1.metadata['confidence'] as num?)?.toDouble() ?? 0.0;
    final double conf2 = (item2.metadata['confidence'] as num?)?.toDouble() ?? 0.0;
    
    final int sevIndex1 = _getSeverityIndex(item1.severity);
    final int sevIndex2 = _getSeverityIndex(item2.severity);

    String cropStatusText = '';
    Color statusColor = Colors.grey;
    if (dis1 == dis2) {
      if (sevIndex2 < sevIndex1) {
        cropStatusText = 'Recovery Phase: Severity has decreased. Current measures are yielding positive results.';
        statusColor = Colors.greenAccent;
      } else if (sevIndex2 > sevIndex1) {
        cropStatusText = 'Deterioration: Severity of disease has escalated. Recommend immediate adjustment of treatments.';
        statusColor = Colors.redAccent;
      } else {
        cropStatusText = 'Persistent Status: Disease remains present at the same severity. Monitor treatment efficacy.';
        statusColor = Colors.orangeAccent;
      }
    } else {
      if (dis2.toLowerCase().contains('healthy')) {
        cropStatusText = 'Full Crop Recovery! The previously detected disease has cleared up completely.';
        statusColor = Colors.greenAccent;
      } else {
        cropStatusText = 'New Diagnostics: A different crop disease state has been scanned. Review symptoms.';
        statusColor = Colors.blueAccent;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('AI Diagnostics Summary'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompareInfoRow('Crop Status', dis1, dis2, isTitle: true),
              const Divider(height: 20),
              _buildCompareInfoRow('Confidence', '${conf1.toStringAsFixed(1)}%', '${conf2.toStringAsFixed(1)}%'),
              const Divider(height: 20),
              _buildCompareInfoRow('Severity Level', item1.severity, item2.severity, 
                  color1: _getColorForSeverity(item1.severity), 
                  color2: _getColorForSeverity(item2.severity)),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Pathological Analysis'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                statusColor == Colors.greenAccent ? LucideIcons.smile : LucideIcons.alertTriangle, 
                color: statusColor, 
                size: 20
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusColor == Colors.greenAccent ? 'Positive Progress' : 'Pathological Notice', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13)
                    ),
                    const SizedBox(height: 4),
                    Text(cropStatusText.tr(ref), style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getSeverityIndex(String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return 0;
      case 'MEDIUM':
        return 1;
      case 'HIGH':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildCompareInfoRow(String title, String val1, String val2, {bool isTitle = false, Color? color1, Color? color2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(title.tr(ref), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            val1.tr(ref), 
            style: TextStyle(
              fontSize: 13, 
              fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
              color: color1 ?? Colors.white
            )
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            val2.tr(ref), 
            style: TextStyle(
              fontSize: 13, 
              fontWeight: isTitle ? FontWeight.bold : FontWeight.w600,
              color: color2 ?? Colors.white
            )
          ),
        ),
      ],
    );
  }

  Widget _buildMixedComparison(HistoryItem item1, HistoryItem item2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Event Log Differences'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _buildCompareInfoRow('Log Type', item1.type, item2.type),
              const Divider(height: 20),
              _buildCompareInfoRow('Severity', item1.severity, item2.severity,
                  color1: _getColorForSeverity(item1.severity),
                  color2: _getColorForSeverity(item2.severity)),
              const Divider(height: 20),
              _buildCompareInfoRow('Summary', item1.description, item2.description),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Selecting items of the same category (e.g. two scans or two sensor snapshots) gives detailed agronomic delta analysis.'.tr(ref),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.tr(ref),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
    );
  }

  void _showItemDetails(BuildContext context, HistoryItem item) {
    final theme = Theme.of(context);
    final color = _getColorForSeverity(item.severity);
    final icon = _getIconForType(item.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title.tr(ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_formatDate(item.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.severity, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text('Log Message'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item.description.tr(ref), style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
                
                // Show dynamic content based on log type
                _buildTypeSpecificDetails(context, item),
                
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.cornerUpLeft),
                  label: Text('Back to Logs'.tr(ref)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(historyProvider.notifier).deleteHistoryItem(item.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Log deleted successfully.'.tr(ref))),
                    );
                  },
                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                  label: Text('Delete this log'.tr(ref), style: const TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSpecificDetails(BuildContext context, HistoryItem item) {
    final meta = item.metadata;
    if (item.type == 'SCAN') {
      final conf = (meta['confidence'] as num?)?.toDouble() ?? 0.0;
      final precautions = List<String>.from(meta['precautions'] ?? []);
      final fertilizers = List<String>.from(meta['indianFertilizers'] ?? []);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text('AI Confidence Score'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: conf / 100.0,
                  backgroundColor: Colors.white12,
                  color: _getColorForSeverity(item.severity),
                ),
              ),
              const SizedBox(width: 12),
              Text('${conf.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          
          if (precautions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Precautions & Treatment'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...precautions.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.shieldAlert, size: 14, color: _getColorForSeverity(item.severity)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 13, height: 1.3))),
                ],
              ),
            )),
          ],

          if (fertilizers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Recommended Bio-Inputs & Fertilizers'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...fertilizers.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.leaf, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13, height: 1.3))),
                ],
              ),
            )),
          ],
        ],
      );
    } else if (item.type == 'SENSOR') {
      final double t = (meta['temperature'] as num?)?.toDouble() ?? 0.0;
      final double h = (meta['humidity'] as num?)?.toDouble() ?? 0.0;
      final double m = (meta['moisture'] as num?)?.toDouble() ?? 0.0;
      final double ph = (meta['ph'] as num?)?.toDouble() ?? 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text('Telemetry Metrics'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildMiniMetricCard('Temp', '${t.toStringAsFixed(1)}°C', LucideIcons.thermometer, Colors.orangeAccent),
              _buildMiniMetricCard('Moisture', '${m.toStringAsFixed(1)}%', LucideIcons.waves, Colors.cyanAccent),
              _buildMiniMetricCard('Humidity', '${h.toStringAsFixed(1)}%', LucideIcons.droplet, Colors.blueAccent),
              _buildMiniMetricCard('Soil pH', ph.toStringAsFixed(1), LucideIcons.flaskConical, Colors.purpleAccent),
            ],
          ),
        ],
      );
    } else if (item.type == 'ROVER') {
      final battery = meta['battery'] ?? meta['batteryEnd'] ?? meta['batteryStart'] ?? 0.0;
      final lat = meta['latitude'] ?? 0.0;
      final lon = meta['longitude'] ?? 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text('Telemetry Data'.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailInfoRow('Battery Level', '${battery.toStringAsFixed(1)}%'),
          if (lat != 0.0 || lon != 0.0) ...[
            _buildDetailInfoRow('GPS Coordinates', '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'),
          ],
          if (meta.containsKey('pathPoints')) ...[
            _buildDetailInfoRow('Recorded Path Coordinates', '${meta['pathPoints']} points'),
          ],
          if (meta.containsKey('durationSeconds')) ...[
            _buildDetailInfoRow('Patrol Duration', '${meta['durationSeconds']} seconds'),
          ],
        ],
      );
    } else if (item.type == 'ALERT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailInfoRow('Alert Subtype', meta['alertType'] ?? 'WARNING'),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMiniMetricCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(label.tr(ref), style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.tr(ref), style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
