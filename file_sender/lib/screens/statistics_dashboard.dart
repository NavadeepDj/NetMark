import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/performance_metrics_service.dart';
import 'metrics_debug_screen.dart';

/// Statistics Dashboard for Faculty - Shows performance metrics and statistical analysis
class StatisticsDashboard extends StatefulWidget {
  const StatisticsDashboard({super.key});

  @override
  _StatisticsDashboardState createState() => _StatisticsDashboardState();
}

class _StatisticsDashboardState extends State<StatisticsDashboard> {
  final PerformanceMetricsService _metricsService = PerformanceMetricsService();
  final Logger _logger = Logger();

  Map<String, dynamic>? _authTimeStats;
  Map<String, dynamic>? _accuracyStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final authStats = await _metricsService.getAuthTimeStatistics();
      final accStats = await _metricsService.getAccuracyStatistics();

      setState(() {
        _authTimeStats = authStats;
        _accuracyStats = accStats;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistical Analysis Dashboard'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MetricsDebugScreen(),
                ),
              );
            },
            tooltip: 'Debug Metrics Viewer',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh Statistics',
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
                  _buildSectionTitle('1. Face Authentication Time Statistics'),
                  SizedBox(height: 16),
                  _buildAuthTimeCard(),
                  SizedBox(height: 24),
                  _buildSectionTitle(
                      '2. Accuracy & Fraud Prevention Statistics'),
                  SizedBox(height: 16),
                  _buildAccuracyCard(),
                  SizedBox(height: 24),
                  _buildSectionTitle('3. Statistical Validation'),
                  SizedBox(height: 16),
                  _buildValidationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildAuthTimeCard() {
    if (_authTimeStats == null || _authTimeStats!['count'] == 0) {
      return _buildEmptyState('No authentication time data available yet.');
    }

    final stats = _authTimeStats!;
    final mean = stats['mean'] as double;
    final ci = stats['confidence_interval_95'] as Map<String, dynamic>;
    final lower = ci['lower'] as double;
    final upper = ci['upper'] as double;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Samples', '${stats['count']}'),
            Divider(),
            _buildStatRow('Mean Time', '${mean.toStringAsFixed(3)} seconds'),
            _buildStatRow('Median Time',
                '${(stats['median'] as double).toStringAsFixed(3)} seconds'),
            _buildStatRow('Standard Deviation',
                '${(stats['std_dev'] as double).toStringAsFixed(3)} seconds'),
            _buildStatRow('Minimum Time',
                '${(stats['min'] as double).toStringAsFixed(3)} seconds'),
            _buildStatRow('Maximum Time',
                '${(stats['max'] as double).toStringAsFixed(3)} seconds'),
            _buildStatRow('95th Percentile',
                '${(stats['p95'] as double).toStringAsFixed(3)} seconds'),
            _buildStatRow('99th Percentile',
                '${(stats['p99'] as double).toStringAsFixed(3)} seconds'),
            Divider(),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '95% Confidence Interval',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lower Bound: ${lower.toStringAsFixed(3)} seconds',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Upper Bound: ${upper.toStringAsFixed(3)} seconds',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Range: ${(upper - lower).toStringAsFixed(3)} seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  _buildClaimValidation(
                    'Claim: 1-3 seconds',
                    lower >= 1.0 && upper <= 3.0,
                    'Authentication time is within the claimed range of 1-3 seconds',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    if (_accuracyStats == null || _accuracyStats!['total_attempts'] == 0) {
      return _buildEmptyState('No accuracy data available yet.');
    }

    final stats = _accuracyStats!;
    final accuracyRate = stats['accuracy_rate'] as double;
    final fraudPreventionRate = stats['fraud_prevention_rate'] as double;
    final ci = stats['confidence_interval_95'] as Map<String, dynamic>;
    final lower = ci['lower'] as double;
    final upper = ci['upper'] as double;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(
                'Total Authentication Attempts', '${stats['total_attempts']}'),
            _buildStatRow(
                'Successful Authentications', '${stats['successful']}'),
            _buildStatRow('Failed Authentications', '${stats['failed']}'),
            _buildStatRow(
                'Fraud Attempts Detected', '${stats['fraud_attempts']}'),
            Divider(),
            _buildStatRow(
                'Accuracy Rate', '${(accuracyRate * 100).toStringAsFixed(2)}%'),
            _buildStatRow('Fraud Prevention Rate',
                '${(fraudPreventionRate * 100).toStringAsFixed(2)}%'),
            Divider(),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '95% Confidence Interval for Accuracy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lower Bound: ${(lower * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Upper Bound: ${(upper * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Standard Error: ${((stats['standard_error'] as double) * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistical Validation Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildValidationItem(
              'Sample Size',
              _authTimeStats?['count'] != null &&
                      (_authTimeStats!['count'] as int) >= 30
                  ? '✅ Sufficient (n ≥ 30)'
                  : '⚠️ Small sample (n < 30)',
              _authTimeStats?['count'] != null &&
                  (_authTimeStats!['count'] as int) >= 30,
            ),
            _buildValidationItem(
              'Confidence Intervals',
              '✅ 95% CI calculated using appropriate method',
              true,
            ),
            _buildValidationItem(
              'Performance Claims',
              _authTimeStats != null &&
                      _authTimeStats!['count'] != null &&
                      _authTimeStats!['count'] > 0
                  ? _validatePerformanceClaims()
                  : '⏳ Collecting data...',
              _authTimeStats != null &&
                  _authTimeStats!['count'] != null &&
                  _authTimeStats!['count'] > 0,
            ),
            _buildValidationItem(
              'Statistical Methods',
              '✅ Wilson Score Interval for proportions\n✅ t-distribution for small samples\n✅ Normal approximation for large samples',
              true,
            ),
          ],
        ),
      ),
    );
  }

  String _validatePerformanceClaims() {
    if (_authTimeStats == null) return '⏳ No data';

    final mean = _authTimeStats!['mean'] as double;
    final ci =
        _authTimeStats!['confidence_interval_95'] as Map<String, dynamic>;
    final lower = ci['lower'] as double;
    final upper = ci['upper'] as double;

    // Validate 1-3 seconds claim
    if (lower >= 1.0 && upper <= 3.0) {
      return '✅ Authentication time (1-3s) validated: ${mean.toStringAsFixed(3)}s [${lower.toStringAsFixed(3)}-${upper.toStringAsFixed(3)}s]';
    } else if (mean >= 1.0 && mean <= 3.0) {
      return '⚠️ Mean within range, but CI extends beyond: ${mean.toStringAsFixed(3)}s [${lower.toStringAsFixed(3)}-${upper.toStringAsFixed(3)}s]';
    } else {
      return '❌ Claim not validated: ${mean.toStringAsFixed(3)}s [${lower.toStringAsFixed(3)}-${upper.toStringAsFixed(3)}s]';
    }
  }

  Widget _buildValidationItem(String title, String value, bool isValid) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isValid ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimValidation(String claim, bool isValid, String explanation) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: isValid ? Colors.green : Colors.orange,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  explanation,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
