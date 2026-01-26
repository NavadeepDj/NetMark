#!/usr/bin/env python3
"""
Load Testing Script for NetMark Attendance System
Performs controlled stress testing with concurrent requests
"""

import requests
import time
import threading
import json
import statistics
from collections import defaultdict
from datetime import datetime
import argparse
import sys
import os
from io import StringIO

class LoadTester:
    def __init__(self, base_url, endpoint='/attendance_stats', log_file=None):
        self.base_url = base_url.rstrip('/')
        self.endpoint = endpoint
        self.results = defaultdict(list)
        self.errors = []
        self.lock = threading.Lock()
        self.log_file = log_file
        self.log_buffer = []
        self.start_time = None
        
    def make_request(self, request_id):
        """Make a single HTTP request and record timing."""
        url = f"{self.base_url}{self.endpoint}"
        start_time = time.perf_counter()
        try:
            response = requests.get(url, timeout=10)
            elapsed_time = time.perf_counter() - start_time
            
            with self.lock:
                self.results['response_times'].append(elapsed_time)
                self.results['status_codes'].append(response.status_code)
                if response.status_code >= 400:
                    self.errors.append({
                        'request_id': request_id,
                        'status_code': response.status_code,
                        'response_time': elapsed_time
                    })
            
            return {
                'request_id': request_id,
                'status_code': response.status_code,
                'response_time': elapsed_time,
                'success': response.status_code < 400
            }
        except Exception as e:
            elapsed_time = time.perf_counter() - start_time
            with self.lock:
                self.errors.append({
                    'request_id': request_id,
                    'error': str(e),
                    'response_time': elapsed_time
                })
            return {
                'request_id': request_id,
                'status_code': 0,
                'response_time': elapsed_time,
                'success': False,
                'error': str(e)
            }
    
    def run_test(self, concurrent_users=10, requests_per_user=10, delay_between_requests=0.1, use_server_tracking=False):
        """Run load test with specified parameters."""
        self.start_time = datetime.now()
        self.log(f"\n{'='*60}")
        self.log(f"LOAD TEST STARTED")
        self.log(f"{'='*60}")
        self.log(f"Base URL: {self.base_url}")
        self.log(f"Endpoint: {self.endpoint}")
        self.log(f"Concurrent Users: {concurrent_users}")
        self.log(f"Requests per User: {requests_per_user}")
        self.log(f"Total Requests: {concurrent_users * requests_per_user}")
        self.log(f"Start Time: {self.start_time.isoformat()}")
        self.log(f"{'='*60}\n")
        
        # Start server-side tracking if requested
        if use_server_tracking:
            try:
                start_response = requests.post(
                    f"{self.base_url}/stress_test/start",
                    json={'concurrentUsers': concurrent_users},
                    timeout=5
                )
                if start_response.status_code == 200:
                    self.log("✅ Server-side metrics tracking started")
            except Exception as e:
                self.log(f"⚠️  Could not start server tracking: {e}")
                use_server_tracking = False
        
        start_time = time.perf_counter()
        threads = []
        request_counter = [0]  # Use list to allow modification in nested function
        
        def user_simulation(user_id):
            """Simulate a single user making requests."""
            for i in range(requests_per_user):
                request_id = user_id * requests_per_user + i
                self.make_request(request_id)
                request_counter[0] += 1
                if delay_between_requests > 0:
                    time.sleep(delay_between_requests)
        
        # Start all user threads
        for user_id in range(concurrent_users):
            thread = threading.Thread(target=user_simulation, args=(user_id,))
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        total_time = time.perf_counter() - start_time
        
        # Stop server-side tracking if used
        if use_server_tracking:
            try:
                stop_response = requests.post(f"{self.base_url}/stress_test/stop", timeout=5)
                if stop_response.status_code == 200:
                    self.log("✅ Server-side metrics tracking stopped")
                    self.log(f"📊 View server metrics: {self.base_url}/scalability_metrics")
                    self.log(f"📄 Generate report: {self.base_url}/scalability_report")
            except Exception as e:
                self.log(f"⚠️  Could not stop server tracking: {e}")
        
        end_time = datetime.now()
        self.log(f"\nTest completed at: {end_time.isoformat()}")
        self.log(f"Total duration: {(end_time - self.start_time).total_seconds():.2f} seconds")
        
        # Calculate statistics
        response_times = self.results['response_times']
        total_requests = len(response_times)
        successful_requests = sum(1 for sc in self.results['status_codes'] if sc < 400)
        failed_requests = total_requests - successful_requests
        
        if response_times:
            stats = {
                'total_requests': total_requests,
                'successful_requests': successful_requests,
                'failed_requests': failed_requests,
                'success_rate': successful_requests / total_requests if total_requests > 0 else 0,
                'total_time_seconds': total_time,
                'throughput_rps': total_requests / total_time if total_time > 0 else 0,
                'mean_response_time_ms': statistics.mean(response_times) * 1000,
                'median_response_time_ms': statistics.median(response_times) * 1000,
                'min_response_time_ms': min(response_times) * 1000,
                'max_response_time_ms': max(response_times) * 1000,
                'std_dev_ms': statistics.stdev(response_times) * 1000 if len(response_times) > 1 else 0,
            }
            
            # Calculate percentiles
            sorted_times = sorted(response_times)
            n = len(sorted_times)
            stats['p95_response_time_ms'] = sorted_times[int(n * 0.95)] * 1000 if n > 1 else sorted_times[0] * 1000
            stats['p99_response_time_ms'] = sorted_times[int(n * 0.99)] * 1000 if n > 1 else sorted_times[0] * 1000
            
            return stats
        else:
            return None
    
    def log(self, message):
        """Log a message to both console and log file."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}"
        print(log_message)
        self.log_buffer.append(log_message)
    
    def save_logs(self):
        """Save all log messages to file."""
        if self.log_file:
            try:
                os.makedirs(os.path.dirname(self.log_file) if os.path.dirname(self.log_file) else '.', exist_ok=True)
                with open(self.log_file, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(self.log_buffer))
                    f.write('\n')
                self.log(f"✅ Test logs saved to {self.log_file}")
            except Exception as e:
                print(f"⚠️  Could not save logs to file: {e}")
    
    def print_report(self, stats):
        """Print formatted test report."""
        if not stats:
            self.log("No data collected!")
            return
        
        self.log(f"\n{'='*60}")
        self.log(f"LOAD TEST RESULTS")
        self.log(f"{'='*60}")
        self.log(f"Total Requests: {stats['total_requests']}")
        self.log(f"Successful: {stats['successful_requests']}")
        self.log(f"Failed: {stats['failed_requests']}")
        self.log(f"Success Rate: {stats['success_rate']*100:.2f}%")
        self.log(f"\nResponse Time Statistics:")
        self.log(f"  Mean: {stats['mean_response_time_ms']:.2f} ms")
        self.log(f"  Median: {stats['median_response_time_ms']:.2f} ms")
        self.log(f"  Min: {stats['min_response_time_ms']:.2f} ms")
        self.log(f"  Max: {stats['max_response_time_ms']:.2f} ms")
        self.log(f"  Std Dev: {stats['std_dev_ms']:.2f} ms")
        self.log(f"  P95: {stats['p95_response_time_ms']:.2f} ms")
        self.log(f"  P99: {stats['p99_response_time_ms']:.2f} ms")
        self.log(f"\nThroughput: {stats['throughput_rps']:.2f} requests/second")
        self.log(f"Total Time: {stats['total_time_seconds']:.2f} seconds")
        
        if self.errors:
            self.log(f"\nErrors ({len(self.errors)}):")
            for error in self.errors[:5]:  # Show first 5 errors
                self.log(f"  - {error}")
            if len(self.errors) > 5:
                self.log(f"  ... and {len(self.errors) - 5} more errors")
        
        self.log(f"{'='*60}\n")
    
    def save_report(self, stats, filename='load_test_results.json'):
        """Save test results to JSON file."""
        report = {
            'timestamp': datetime.now().isoformat(),
            'test_config': {
                'base_url': self.base_url,
                'endpoint': self.endpoint,
            },
            'results': stats,
            'errors': self.errors[:100]  # Limit to first 100 errors
        }
        
        try:
            os.makedirs(os.path.dirname(filename) if os.path.dirname(filename) else '.', exist_ok=True)
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2)
            self.log(f"✅ Results saved to {filename}")
        except Exception as e:
            self.log(f"⚠️  Could not save results to {filename}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Load test NetMark attendance system')
    parser.add_argument('--url', default='http://127.0.0.1:5000', help='Base URL of the server')
    parser.add_argument('--endpoint', default='/attendance_stats', help='Endpoint to test')
    parser.add_argument('--users', type=int, default=10, help='Number of concurrent users')
    parser.add_argument('--requests', type=int, default=10, help='Requests per user')
    parser.add_argument('--delay', type=float, default=0.1, help='Delay between requests (seconds)')
    parser.add_argument('--output', default='load_test_results.json', help='Output file for results')
    parser.add_argument('--log-file', default=None, help='Log file for console output (auto-generated if not specified)')
    parser.add_argument('--server-tracking', action='store_true', help='Use server-side metrics tracking')
    
    args = parser.parse_args()
    
    # Auto-generate log filename if not provided
    if not args.log_file:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_dir = "stress_test_logs"
        os.makedirs(log_dir, exist_ok=True)
        args.log_file = os.path.join(log_dir, f"load_test_{args.users}users_{timestamp}.log")
    
    tester = LoadTester(args.url, args.endpoint, log_file=args.log_file)
    stats = tester.run_test(
        concurrent_users=args.users,
        requests_per_user=args.requests,
        delay_between_requests=args.delay,
        use_server_tracking=args.server_tracking
    )
    
    if stats:
        tester.print_report(stats)
        tester.save_report(stats, args.output)
        tester.save_logs()
    else:
        tester.log("Test failed - no data collected")
        tester.save_logs()

if __name__ == '__main__':
    main()
