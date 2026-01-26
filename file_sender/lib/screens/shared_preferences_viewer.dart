import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Viewer to inspect ALL SharedPreferences keys and values
class SharedPreferencesViewer extends StatefulWidget {
  const SharedPreferencesViewer({super.key});

  @override
  _SharedPreferencesViewerState createState() =>
      _SharedPreferencesViewerState();
}

class _SharedPreferencesViewerState extends State<SharedPreferencesViewer> {
  Map<String, dynamic>? _allPreferences;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final preferences = <String, dynamic>{};

      for (final key in allKeys) {
        final value = prefs.get(key);
        preferences[key] = value;
      }

      setState(() {
        _allPreferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading preferences: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SharedPreferences Inspector'),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllPreferences,
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
                  _buildSummary(),
                  SizedBox(height: 24),
                  _buildAllKeys(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final count = _allPreferences?.length ?? 0;
    final hasPerformanceMetrics =
        _allPreferences?.containsKey('performance_metrics') ?? false;

    return Card(
      elevation: 4,
      color: hasPerformanceMetrics ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPerformanceMetrics ? Icons.check_circle : Icons.warning,
                  color: hasPerformanceMetrics ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'SharedPreferences Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSummaryRow('Total Keys', '$count'),
            _buildSummaryRow(
              'performance_metrics Key',
              hasPerformanceMetrics ? '✅ Found' : '❌ Not Found',
            ),
            if (_allPreferences != null) ...[
              SizedBox(height: 8),
              Text(
                'All Keys:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _allPreferences!.keys.map((key) {
                  return Chip(
                    label: Text(key),
                    backgroundColor: key == 'performance_metrics'
                        ? Colors.green[100]
                        : Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllKeys() {
    if (_allPreferences == null || _allPreferences!.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No SharedPreferences data found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All SharedPreferences Keys & Values',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
        ),
        SizedBox(height: 16),
        ..._allPreferences!.entries.map((entry) {
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(
                _getIconForType(entry.value),
                color: _getColorForType(entry.value),
              ),
              title: Text(
                entry.key,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Type: ${_getTypeName(entry.value)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Value:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildValueDisplay(entry.key, entry.value),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildValueDisplay(String key, dynamic value) {
    if (value == null) {
      return Text('null', style: TextStyle(fontStyle: FontStyle.italic));
    }

    if (value is String) {
      // Check if it's JSON
      if (key == 'performance_metrics' || _isJsonString(value)) {
        try {
          final decoded = json.decode(value);
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JSON (decoded):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  json.encode(decoded),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Raw String:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return SelectableText(
            value,
            style: TextStyle(fontFamily: 'monospace'),
          );
        }
      }
      return SelectableText(
        value,
        style: TextStyle(fontFamily: 'monospace'),
      );
    } else if (value is List) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'List (${value.length} items)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (value.length <= 20)
              ...value.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '[$entry.key]: ${entry.value}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              })
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...value.take(10).toList().asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '[$entry.key]: ${entry.value}',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    );
                  }),
                  Text(
                    '... and ${value.length - 10} more items',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      );
    } else if (value is bool) {
      return Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (value is int || value is double) {
      return Text(
        value.toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        value.toString(),
        style: TextStyle(fontFamily: 'monospace'),
      );
    }
  }

  bool _isJsonString(String value) {
    try {
      json.decode(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  IconData _getIconForType(dynamic value) {
    if (value is String) return Icons.text_fields;
    if (value is int || value is double) return Icons.numbers;
    if (value is bool) return Icons.toggle_on;
    if (value is List) return Icons.list;
    return Icons.help_outline;
  }

  Color _getColorForType(dynamic value) {
    if (value is String) return Colors.blue;
    if (value is int || value is double) return Colors.green;
    if (value is bool) return Colors.orange;
    if (value is List) return Colors.purple;
    return Colors.grey;
  }

  String _getTypeName(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List (${value.length} items)';
    return value.runtimeType.toString();
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
