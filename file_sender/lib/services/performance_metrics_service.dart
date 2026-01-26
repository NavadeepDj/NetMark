import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Service to collect and analyze performance metrics for statistical validation
class PerformanceMetricsService {
  static final PerformanceMetricsService _instance = PerformanceMetricsService._internal();
  factory PerformanceMetricsService() => _instance;
  PerformanceMetricsService._internal();

  final Logger _logger = Logger();
  static const String _metricsKey = 'performance_metrics';
  static const String _authAttemptsKey = 'auth_attempts';
  static const String _fraudAttemptsKey = 'fraud_attempts';

  /// Record face authentication time
  Future<void> recordAuthTime(double timeInSeconds, {bool success = true}) async {
    _logger.i('🔵 recordAuthTime CALLED: time=${timeInSeconds.toStringAsFixed(3)}s, success=$success');
    try {
      _logger.d('🔵 Getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();
      _logger.d('🔵 SharedPreferences instance obtained');
      
      _logger.d('🔵 Loading existing metrics...');
      final metrics = await _getMetrics(prefs);
      _logger.d('🔵 Existing metrics loaded: ${metrics.keys.length} keys');
      
      _logger.d('🔵 Initializing auth_times list...');
      metrics['auth_times'] ??= <double>[];
      _logger.d('🔵 Current auth_times count: ${metrics['auth_times']?.length ?? 0}');
      
      _logger.d('🔵 Adding new auth time: $timeInSeconds');
      metrics['auth_times']!.add(timeInSeconds);
      _logger.d('🔵 Auth time added. New count: ${metrics['auth_times']!.length}');
      
      metrics['total_auth_attempts'] = (metrics['total_auth_attempts'] ?? 0) + 1;
      if (success) {
        metrics['successful_auths'] = (metrics['successful_auths'] ?? 0) + 1;
      } else {
        metrics['failed_auths'] = (metrics['failed_auths'] ?? 0) + 1;
      }
      
      _logger.d('🔵 Metrics updated. Attempting to save...');
      _logger.d('🔵 Metrics to save: ${metrics.keys.toList()}');
      _logger.d('🔵 auth_times length: ${metrics['auth_times']?.length ?? 0}');
      
      await _saveMetrics(prefs, metrics);
      
      _logger.i('✅ Auth time recorded: ${timeInSeconds.toStringAsFixed(3)}s (success: $success)');
      _logger.i('✅ Total attempts: ${metrics['total_auth_attempts']}, Successful: ${metrics['successful_auths']}, Failed: ${metrics['failed_auths']}');
      _logger.i('✅ Total auth times stored: ${metrics['auth_times']?.length ?? 0}');
      
      // Verify it was saved
      _logger.d('🔵 Verifying save...');
      final verifyPrefs = await SharedPreferences.getInstance();
      final verifyJson = verifyPrefs.getString(_metricsKey);
      if (verifyJson != null) {
        _logger.i('✅ VERIFIED: Metrics saved successfully. JSON length: ${verifyJson.length}');
      } else {
        _logger.e('❌ VERIFICATION FAILED: Metrics not found after save!');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error recording auth time: $e');
      _logger.e('❌ Stack trace: $stackTrace');
    }
  }

  /// Record face embedding extraction time
  Future<void> recordEmbeddingTime(double timeInSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      metrics['embedding_times'] ??= <double>[];
      metrics['embedding_times']!.add(timeInSeconds);
      
      await _saveMetrics(prefs, metrics);
      _logger.d('📊 Embedding extraction time: ${timeInSeconds.toStringAsFixed(3)}s');
    } catch (e) {
      _logger.e('Error recording embedding time: $e');
    }
  }

  /// Record face verification time
  Future<void> recordVerificationTime(double timeInSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      metrics['verification_times'] ??= <double>[];
      metrics['verification_times']!.add(timeInSeconds);
      
      await _saveMetrics(prefs, metrics);
      _logger.d('📊 Verification time: ${timeInSeconds.toStringAsFixed(3)}s');
    } catch (e) {
      _logger.e('Error recording verification time: $e');
    }
  }

  /// Record fraud attempt (failed verification with wrong face)
  Future<void> recordFraudAttempt({String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      metrics['fraud_attempts'] = (metrics['fraud_attempts'] ?? 0) + 1;
      metrics['fraud_attempts_list'] ??= <Map<String, dynamic>>[];
      metrics['fraud_attempts_list']!.add({
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason ?? 'Face mismatch',
      });
      
      await _saveMetrics(prefs, metrics);
      _logger.w('🚨 Fraud attempt recorded: $reason');
    } catch (e) {
      _logger.e('Error recording fraud attempt: $e');
    }
  }

  /// Record successful authentication
  Future<void> recordSuccessfulAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      metrics['successful_auths'] = (metrics['successful_auths'] ?? 0) + 1;
      metrics['total_auth_attempts'] = (metrics['total_auth_attempts'] ?? 0) + 1;
      
      await _saveMetrics(prefs, metrics);
    } catch (e) {
      _logger.e('Error recording successful auth: $e');
    }
  }

  /// Get statistical analysis of authentication times
  Future<Map<String, dynamic>> getAuthTimeStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      final authTimes = (metrics['auth_times'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? [];
      
      if (authTimes.isEmpty) {
        return {
          'count': 0,
          'mean': 0.0,
          'median': 0.0,
          'std_dev': 0.0,
          'min': 0.0,
          'max': 0.0,
          'p95': 0.0,
          'p99': 0.0,
          'confidence_interval_95': {'lower': 0.0, 'upper': 0.0},
        };
      }
      
      return _calculateStatistics(authTimes);
    } catch (e) {
      _logger.e('Error getting auth time statistics: $e');
      return {};
    }
  }

  /// Get accuracy statistics with baseline comparisons and statistical tests
  Future<Map<String, dynamic>> getAccuracyStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metrics = await _getMetrics(prefs);
      
      final total = metrics['total_auth_attempts'] ?? 0;
      final successful = metrics['successful_auths'] ?? 0;
      final failed = metrics['failed_auths'] ?? 0;
      final fraudAttempts = metrics['fraud_attempts'] ?? 0;
      
      if (total == 0) {
        return {
          'total_attempts': 0,
          'successful': 0,
          'failed': 0,
          'fraud_attempts': 0,
          'accuracy_rate': 0.0,
          'fraud_prevention_rate': 0.0,
          'false_acceptance_rate': 0.0,
          'false_rejection_rate': 0.0,
          'confidence_interval_95': {'lower': 0.0, 'upper': 0.0},
          'baseline_comparison': {},
          'statistical_significance': {},
        };
      }
      
      // Calculate rates
      final accuracyRate = successful / total;
      final falseRejectionRate = failed / total; // Failed legitimate attempts
      // Fraud prevention rate: percentage of fraud attempts detected out of total fraud attempts
      // If we detected fraudAttempts, and total attempts = successful + failed + fraudAttempts
      // Then fraud prevention rate = fraudAttempts / (fraudAttempts + successful) 
      // But better: True Positive Rate for fraud detection
      final totalFraudAttempts = fraudAttempts; // All detected fraud attempts
      final fraudPreventionRate = totalFraudAttempts > 0 
          ? totalFraudAttempts / (totalFraudAttempts + successful) 
          : 0.0;
      // False Acceptance Rate (FAR): fraud attempts that were NOT detected / total fraud attempts
      // Since we only track detected fraud, we estimate FAR as: failed / (failed + successful)
      // This is conservative - assumes some failed attempts might be undetected fraud
      final falseAcceptanceRate = failed / total;
      
      // Calculate 95% confidence interval for accuracy using Wilson score interval
      final ci = _wilsonScoreInterval(successful, total, 0.95);
      
      // Baseline comparisons (industry standards)
      final baselineComparison = _compareToBaselines(accuracyRate, total);
      
      // Statistical significance testing
      final significanceTest = _testStatisticalSignificance(
        accuracyRate, 
        total, 
        baselineComparison['industry_baseline'] as double
      );
      
      return {
        'total_attempts': total,
        'successful': successful,
        'failed': failed,
        'fraud_attempts': fraudAttempts,
        'accuracy_rate': accuracyRate,
        'fraud_prevention_rate': fraudPreventionRate,
        'false_acceptance_rate': falseAcceptanceRate,
        'false_rejection_rate': falseRejectionRate,
        'confidence_interval_95': ci,
        'standard_error': sqrt(accuracyRate * (1 - accuracyRate) / total),
        'baseline_comparison': baselineComparison,
        'statistical_significance': significanceTest,
      };
    } catch (e) {
      _logger.e('Error getting accuracy statistics: $e');
      return {};
    }
  }

  /// Get all performance statistics
  Future<Map<String, dynamic>> getAllStatistics() async {
    final authTimeStats = await getAuthTimeStatistics();
    final accuracyStats = await getAccuracyStatistics();
    
    return {
      'auth_time_statistics': authTimeStats,
      'accuracy_statistics': accuracyStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Calculate statistical measures
  Map<String, dynamic> _calculateStatistics(List<double> values) {
    if (values.isEmpty) return {};
    
    values.sort();
    final n = values.length;
    
    // Mean
    final mean = values.reduce((a, b) => a + b) / n;
    
    // Standard deviation
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / n;
    final stdDev = sqrt(variance);
    
    // Median
    final median = n % 2 == 0
        ? (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2
        : values[n ~/ 2];
    
    // Percentiles
    final p95Index = (n * 0.95).floor().clamp(0, n - 1);
    final p99Index = (n * 0.99).floor().clamp(0, n - 1);
    
    // 95% Confidence interval (t-distribution for small samples, normal for large)
    final tValue = n < 30 ? 2.045 : 1.96; // Approximate t-value for 95% CI
    final marginOfError = tValue * (stdDev / sqrt(n));
    
    return {
      'count': n,
      'mean': mean,
      'median': median,
      'std_dev': stdDev,
      'min': values.first,
      'max': values.last,
      'p95': values[p95Index],
      'p99': values[p99Index],
      'confidence_interval_95': {
        'lower': (mean - marginOfError).clamp(0.0, double.infinity),
        'upper': mean + marginOfError,
        'margin_of_error': marginOfError,
      },
    };
  }

  /// Calculate Wilson score confidence interval for proportions
  Map<String, double> _wilsonScoreInterval(int successes, int total, double confidence) {
    if (total == 0) return {'lower': 0.0, 'upper': 0.0};
    
    final z = confidence == 0.95 ? 1.96 : 1.645; // z-score for confidence level
    final p = successes / total;
    final n = total.toDouble();
    
    final denominator = 1 + (z * z) / n;
    final center = (p + (z * z) / (2 * n)) / denominator;
    final margin = (z / denominator) * sqrt((p * (1 - p) / n) + (z * z) / (4 * n * n));
    
    return {
      'lower': (center - margin).clamp(0.0, 1.0),
      'upper': (center + margin).clamp(0.0, 1.0),
      'margin_of_error': margin,
    };
  }

  /// Compare accuracy to industry baselines
  /// Baselines from research: Face recognition systems typically achieve 85-95% accuracy
  Map<String, dynamic> _compareToBaselines(double accuracyRate, int sampleSize) {
    // Industry baselines (from academic research and commercial systems)
    const double industryBaseline = 0.90; // 90% typical for face recognition
    const double excellentBaseline = 0.95; // 95% excellent performance
    const double minimumBaseline = 0.85; // 85% minimum acceptable
    
    final difference = accuracyRate - industryBaseline;
    final percentDifference = (difference / industryBaseline) * 100;
    
    String performanceLevel;
    bool exceedsBaseline;
    
    if (accuracyRate >= excellentBaseline) {
      performanceLevel = 'Excellent';
      exceedsBaseline = true;
    } else if (accuracyRate >= industryBaseline) {
      performanceLevel = 'Above Average';
      exceedsBaseline = true;
    } else if (accuracyRate >= minimumBaseline) {
      performanceLevel = 'Average';
      exceedsBaseline = false;
    } else {
      performanceLevel = 'Below Average';
      exceedsBaseline = false;
    }
    
    return {
      'industry_baseline': industryBaseline,
      'excellent_baseline': excellentBaseline,
      'minimum_baseline': minimumBaseline,
      'difference': difference,
      'percent_difference': percentDifference,
      'performance_level': performanceLevel,
      'exceeds_baseline': exceedsBaseline,
      'sample_size': sampleSize,
      'baseline_source': 'Academic research and commercial face recognition systems',
    };
  }

  /// Test statistical significance against baseline
  /// Uses one-sample z-test for proportions
  Map<String, dynamic> _testStatisticalSignificance(
    double observedRate, 
    int sampleSize, 
    double baselineRate
  ) {
    if (sampleSize == 0) {
      return {
        'p_value': 1.0,
        'significant': false,
        'test_type': 'z-test',
        'z_score': 0.0,
      };
    }
    
    // One-sample z-test for proportions
    final p = observedRate;
    final p0 = baselineRate;
    final n = sampleSize.toDouble();
    
    // Standard error under null hypothesis
    final se = sqrt(p0 * (1 - p0) / n);
    
    if (se == 0) {
      return {
        'p_value': 1.0,
        'significant': false,
        'test_type': 'z-test',
        'z_score': 0.0,
        'error': 'Cannot compute: standard error is zero',
      };
    }
    
    // Z-score
    final zScore = (p - p0) / se;
    
    // Two-tailed p-value approximation using normal distribution
    // For large samples, z ~ N(0,1)
    final pValue = 2 * (1 - _normalCDF(zScore.abs()));
    
    // Significance at α = 0.05
    final significant = pValue < 0.05;
    
    return {
      'p_value': pValue,
      'significant': significant,
      'test_type': 'one-sample z-test for proportions',
      'z_score': zScore,
      'alpha': 0.05,
      'null_hypothesis': 'Accuracy rate equals baseline ($baselineRate)',
      'alternative_hypothesis': 'Accuracy rate differs from baseline',
      'interpretation': significant 
          ? 'Statistically significant difference from baseline'
          : 'No statistically significant difference from baseline',
    };
  }

  /// Approximate cumulative distribution function for standard normal distribution
  /// Using error function approximation
  double _normalCDF(double x) {
    // Approximation using error function: Φ(x) = 0.5 * (1 + erf(x/√2))
    return 0.5 * (1 + _erf(x / sqrt(2)));
  }

  /// Error function approximation using Taylor series
  double _erf(double x) {
    // Abramowitz and Stegun approximation
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;
    
    final sign = x < 0 ? -1 : 1;
    x = x.abs();
    
    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);
    
    return sign * y;
  }

  /// Get metrics from storage
  Future<Map<String, dynamic>> _getMetrics(SharedPreferences prefs) async {
    final metricsJson = prefs.getString(_metricsKey);
    if (metricsJson == null) {
      _logger.d('No metrics found in SharedPreferences');
      return {};
    }
    
    try {
      final decoded = json.decode(metricsJson);
      _logger.d('📊 Loaded metrics from storage: ${decoded.keys.length} keys');
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      _logger.e('Error parsing metrics: $e');
      _logger.e('Raw JSON: $metricsJson');
      return {};
    }
  }

  /// Save metrics to storage
  Future<void> _saveMetrics(SharedPreferences prefs, Map<String, dynamic> metrics) async {
    _logger.d('🔵 _saveMetrics CALLED with ${metrics.keys.length} keys');
    try {
      _logger.d('🔵 Encoding metrics to JSON...');
      final metricsJson = json.encode(metrics);
      _logger.d('🔵 JSON encoded. Length: ${metricsJson.length} characters');
      _logger.d('🔵 JSON preview: ${metricsJson.substring(0, metricsJson.length > 200 ? 200 : metricsJson.length)}...');
      
      _logger.d('🔵 Saving to SharedPreferences with key: $_metricsKey');
      final saved = await prefs.setString(_metricsKey, metricsJson);
      _logger.i('✅ Metrics saved to SharedPreferences: $saved');
      _logger.i('✅ Saved ${metrics.keys.length} keys, ${metrics['auth_times']?.length ?? 0} auth times');
      
      if (!saved) {
        _logger.e('❌ WARNING: setString returned false! Save may have failed!');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error saving metrics: $e');
      _logger.e('❌ Stack trace: $stackTrace');
      rethrow; // Re-throw to see the error
    }
  }

  /// Clear all metrics (for testing)
  Future<void> clearMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metricsKey);
      _logger.i('📊 All metrics cleared');
    } catch (e) {
      _logger.e('Error clearing metrics: $e');
    }
  }

  /// Export metrics as JSON (for analysis)
  Future<String> exportMetrics() async {
    final stats = await getAllStatistics();
    return json.encode(stats);
  }
}
