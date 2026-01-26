import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/performance_metrics_service.dart';

/// Debug screen to view raw metrics data and verify recording
class MetricsDebugScreen extends StatefulWidget {
  const MetricsDebugScreen({super.key});

  @override
  _MetricsDebugScreenState createState() => _MetricsDebugScreenState();
}

class _MetricsDebugScreenState extends State<MetricsDebugScreen> {
  final PerformanceMetricsService _metricsService = PerformanceMetricsService();
  Map<String, dynamic>? _rawMetrics;
  Map<String, dynamic>? _calculatedStats;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get raw metrics from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString('performance_metrics');

      if (metricsJson != null) {
        _rawMetrics = Map<String, dynamic>.from(json.decode(metricsJson));
      } else {
        _rawMetrics = {};
      }

      // Get calculated statistics
      _calculatedStats = await _metricsService.getAllStatistics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading metrics: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metrics Debug Viewer'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  _buildSection('📊 Raw Metrics Data (SharedPreferences)',
                      _buildRawMetrics()),
                  SizedBox(height: 24),
                  _buildSection(
                      '📈 Calculated Statistics', _buildCalculatedStats()),
                  SizedBox(height: 24),
                  _buildSection('🔍 Data Verification', _buildVerification()),
                  SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRawMetrics() {
    if (_rawMetrics == null || _rawMetrics!.isEmpty) {
      return Text(
        '❌ No raw metrics found in SharedPreferences',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKeyValue('Storage Key', 'performance_metrics'),
        Divider(),
        _buildKeyValue('Total Keys', '${_rawMetrics!.length}'),
        Divider(),
        ..._rawMetrics!.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                _buildValue(entry.value),
                Divider(),
              ],
            ),
          );
        }),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raw JSON:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                json.encode(_rawMetrics),
                style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatedStats() {
    if (_calculatedStats == null || _calculatedStats!.isEmpty) {
      return Text(
        '❌ No calculated statistics available',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_calculatedStats!.containsKey('auth_time_statistics'))
          _buildAuthTimeStats(_calculatedStats!['auth_time_statistics']),
        SizedBox(height: 16),
        if (_calculatedStats!.containsKey('accuracy_statistics'))
          _buildAccuracyStats(_calculatedStats!['accuracy_statistics']),
      ],
    );
  }

  Widget _buildAuthTimeStats(dynamic stats) {
    if (stats == null || stats['count'] == 0) {
      return Text('No authentication time data');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authentication Time Statistics:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        _buildKeyValue('Count', '${stats['count']}'),
        _buildKeyValue('Mean', '${(stats['mean'] as num).toStringAsFixed(3)}s'),
        _buildKeyValue(
            'Median', '${(stats['median'] as num).toStringAsFixed(3)}s'),
        _buildKeyValue(
            'Std Dev', '${(stats['std_dev'] as num).toStringAsFixed(3)}s'),
        _buildKeyValue('Min', '${(stats['min'] as num).toStringAsFixed(3)}s'),
        _buildKeyValue('Max', '${(stats['max'] as num).toStringAsFixed(3)}s'),
        if (stats.containsKey('confidence_interval_95'))
          _buildKeyValue(
            '95% CI',
            '[${(stats['confidence_interval_95']['lower'] as num).toStringAsFixed(3)}, ${(stats['confidence_interval_95']['upper'] as num).toStringAsFixed(3)}]',
          ),
      ],
    );
  }

  Widget _buildAccuracyStats(dynamic stats) {
    if (stats == null || stats['total_attempts'] == 0) {
      return Text('No accuracy data');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accuracy Statistics:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        _buildKeyValue('Total Attempts', '${stats['total_attempts']}'),
        _buildKeyValue('Successful', '${stats['successful']}'),
        _buildKeyValue('Failed', '${stats['failed']}'),
        _buildKeyValue('Fraud Attempts', '${stats['fraud_attempts']}'),
        _buildKeyValue(
          'Accuracy Rate',
          '${((stats['accuracy_rate'] as num) * 100).toStringAsFixed(2)}%',
        ),
        if (stats.containsKey('confidence_interval_95'))
          _buildKeyValue(
            '95% CI',
            '[${((stats['confidence_interval_95']['lower'] as num) * 100).toStringAsFixed(2)}%, ${((stats['confidence_interval_95']['upper'] as num) * 100).toStringAsFixed(2)}%]',
          ),
      ],
    );
  }

  Widget _buildVerification() {
    final hasData = _rawMetrics != null &&
        _rawMetrics!.isNotEmpty &&
        _rawMetrics!.containsKey('auth_times');

    final authTimes = _rawMetrics?['auth_times'] as List<dynamic>?;
    final count = authTimes?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasData ? Icons.check_circle : Icons.error,
              color: hasData ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              hasData ? '✅ Data is being recorded!' : '❌ No data recorded yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: hasData ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildKeyValue('Authentication Times Recorded', '$count'),
        if (authTimes != null && authTimes.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            'Recent Times (last 10):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          ...authTimes.reversed.take(10).map((time) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '  • ${(time as num).toStringAsFixed(3)}s',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            );
          }),
        ],
        SizedBox(height: 16),
        _buildKeyValue('Total Auth Attempts',
            '${_rawMetrics?['total_auth_attempts'] ?? 0}'),
        _buildKeyValue(
            'Successful Auths', '${_rawMetrics?['successful_auths'] ?? 0}'),
        _buildKeyValue('Failed Auths', '${_rawMetrics?['failed_auths'] ?? 0}'),
        _buildKeyValue(
            'Fraud Attempts', '${_rawMetrics?['fraud_attempts'] ?? 0}'),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Clear All Metrics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear Metrics?'),
                  content:
                      Text('This will delete all recorded metrics. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child:
                          Text('Clear', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _metricsService.clearMetrics();
                _loadMetrics();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Metrics cleared')),
                );
              }
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.download),
            label: Text('Export JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final json = await _metricsService.exportMetrics();
              // Show in dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Exported Metrics'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildValue(dynamic value) {
    if (value is List) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'List (${value.length} items)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (value.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                value.length <= 10
                    ? value.map((v) => v.toString()).join(', ')
                    : '${value.take(10).map((v) => v.toString()).join(', ')}... (${value.length} total)',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      );
    } else if (value is Map) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          json.encode(value),
          style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      );
    } else {
      return Text(
        value.toString(),
        style: TextStyle(fontFamily: 'monospace'),
      );
    }
  }
}
