#!/usr/bin/env python3
"""
Find Breaking Point Script
Tests progressively higher concurrent user loads to identify when the system fails
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

class BreakingPointTester:
    def __init__(self, base_url, endpoint='/attendance_stats'):
        self.base_url = base_url.rstrip('/')
        self.endpoint = endpoint
        self.results = defaultdict(list)
        self.errors = []
        self.lock = threading.Lock()
        self.timeout_errors = 0
        self.connection_errors = 0
        self.http_errors = 0
        
    def make_request(self, request_id):
        """Make a single HTTP request and record timing."""
        url = f"{self.base_url}{self.endpoint}"
        start_time = time.perf_counter()
        try:
            response = requests.get(url, timeout=30)  # Increased timeout for high load
            elapsed_time = time.perf_counter() - start_time
            
            with self.lock:
                self.results['response_times'].append(elapsed_time)
                self.results['status_codes'].append(response.status_code)
                if response.status_code >= 400:
                    self.http_errors += 1
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
        except requests.exceptions.Timeout:
            elapsed_time = time.perf_counter() - start_time
            with self.lock:
                self.timeout_errors += 1
                self.errors.append({
                    'request_id': request_id,
                    'error': 'Timeout',
                    'response_time': elapsed_time
                })
            return {'request_id': request_id, 'status_code': 0, 'success': False, 'error': 'Timeout'}
        except requests.exceptions.ConnectionError:
            elapsed_time = time.perf_counter() - start_time
            with self.lock:
                self.connection_errors += 1
                self.errors.append({
                    'request_id': request_id,
                    'error': 'ConnectionError',
                    'response_time': elapsed_time
                })
            return {'request_id': request_id, 'status_code': 0, 'success': False, 'error': 'ConnectionError'}
        except Exception as e:
            elapsed_time = time.perf_counter() - start_time
            with self.lock:
                self.errors.append({
                    'request_id': request_id,
                    'error': str(e),
                    'response_time': elapsed_time
                })
            return {'request_id': request_id, 'status_code': 0, 'success': False, 'error': str(e)}
    
    def test_load(self, concurrent_users, requests_per_user=5):
        """Test a specific load level."""
        print(f"\n{'='*70}")
        print(f"Testing: {concurrent_users} concurrent users, {requests_per_user} requests each")
        print(f"Total Requests: {concurrent_users * requests_per_user}")
        print(f"{'='*70}")
        
        # Reset counters
        self.results.clear()
        self.errors.clear()
        self.timeout_errors = 0
        self.connection_errors = 0
        self.http_errors = 0
        
        start_time = time.perf_counter()
        threads = []
        
        def user_simulation(user_id):
            """Simulate a single user making requests."""
            for i in range(requests_per_user):
                request_id = user_id * requests_per_user + i
                self.make_request(request_id)
        
        # Start all user threads
        for user_id in range(concurrent_users):
            thread = threading.Thread(target=user_simulation, args=(user_id,))
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete (with timeout)
        for thread in threads:
            thread.join(timeout=60)  # 60 second timeout per thread
        
        total_time = time.perf_counter() - start_time
        
        # Calculate statistics
        response_times = self.results['response_times']
        total_requests = len(response_times) + len(self.errors)
        successful_requests = len(response_times)
        failed_requests = len(self.errors)
        
        if response_times:
            stats = {
                'concurrent_users': concurrent_users,
                'total_requests': total_requests,
                'successful_requests': successful_requests,
                'failed_requests': failed_requests,
                'success_rate': successful_requests / total_requests if total_requests > 0 else 0,
                'total_time_seconds': total_time,
                'throughput_rps': successful_requests / total_time if total_time > 0 else 0,
                'mean_response_time_ms': statistics.mean(response_times) * 1000,
                'median_response_time_ms': statistics.median(response_times) * 1000,
                'min_response_time_ms': min(response_times) * 1000,
                'max_response_time_ms': max(response_times) * 1000,
                'std_dev_ms': statistics.stdev(response_times) * 1000 if len(response_times) > 1 else 0,
                'timeout_errors': self.timeout_errors,
                'connection_errors': self.connection_errors,
                'http_errors': self.http_errors,
            }
            
            # Calculate percentiles
            sorted_times = sorted(response_times)
            n = len(sorted_times)
            stats['p95_response_time_ms'] = sorted_times[int(n * 0.95)] * 1000 if n > 1 else sorted_times[0] * 1000
            stats['p99_response_time_ms'] = sorted_times[int(n * 0.99)] * 1000 if n > 1 else sorted_times[0] * 1000
            
            return stats
        else:
            return {
                'concurrent_users': concurrent_users,
                'total_requests': total_requests,
                'successful_requests': 0,
                'failed_requests': failed_requests,
                'success_rate': 0.0,
                'timeout_errors': self.timeout_errors,
                'connection_errors': self.connection_errors,
                'http_errors': self.http_errors,
            }
    
    def print_results(self, stats):
        """Print test results."""
        print(f"\nResults:")
        print(f"  Concurrent Users: {stats['concurrent_users']}")
        print(f"  Total Requests: {stats['total_requests']}")
        print(f"  Successful: {stats['successful_requests']}")
        print(f"  Failed: {stats['failed_requests']}")
        print(f"  Success Rate: {stats['success_rate']*100:.2f}%")
        
        if stats.get('mean_response_time_ms'):
            print(f"  Mean Response Time: {stats['mean_response_time_ms']:.2f} ms")
            print(f"  P95 Response Time: {stats['p95_response_time_ms']:.2f} ms")
            print(f"  Throughput: {stats['throughput_rps']:.2f} req/s")
        
        if stats.get('timeout_errors', 0) > 0:
            print(f"  [WARNING] Timeout Errors: {stats['timeout_errors']}")
        if stats.get('connection_errors', 0) > 0:
            print(f"  [WARNING] Connection Errors: {stats['connection_errors']}")
        if stats.get('http_errors', 0) > 0:
            print(f"  [WARNING] HTTP Errors: {stats['http_errors']}")
        
        # Determine if this is breaking point
        if stats['success_rate'] < 0.95:
            print(f"\n  [BREAKING POINT] Success rate < 95%")
            return True
        elif stats['success_rate'] < 0.99:
            print(f"\n  [DEGRADATION] Success rate < 99%")
            return False
        else:
            print(f"\n  [PASSED] System handles this load")
            return False

def main():
    parser = argparse.ArgumentParser(description='Find breaking point for NetMark server')
    parser.add_argument('--url', default='http://127.0.0.1:5000', help='Base URL of the server')
    parser.add_argument('--endpoint', default='/attendance_stats', help='Endpoint to test')
    parser.add_argument('--start', type=int, default=100, help='Starting number of concurrent users')
    parser.add_argument('--max', type=int, default=1000, help='Maximum number of concurrent users to test')
    parser.add_argument('--step', type=int, default=50, help='Increment step for concurrent users')
    parser.add_argument('--requests', type=int, default=5, help='Requests per user')
    parser.add_argument('--output', default='breaking_point_results.json', help='Output file')
    
    args = parser.parse_args()
    
    tester = BreakingPointTester(args.url, args.endpoint)
    
    print("="*70)
    print("BREAKING POINT TEST")
    print("="*70)
    print(f"Server: {args.url}")
    print(f"Endpoint: {args.endpoint}")
    print(f"Testing from {args.start} to {args.max} concurrent users (step: {args.step})")
    print("="*70)
    
    results = []
    breaking_point_found = False
    
    for users in range(args.start, args.max + 1, args.step):
        stats = tester.test_load(users, args.requests)
        results.append(stats)
        
        is_breaking = tester.print_results(stats)
        
        if is_breaking:
            breaking_point_found = True
            print(f"\n{'='*70}")
            print(f"[BREAKING POINT IDENTIFIED] {users} concurrent users")
            print(f"{'='*70}")
            break
        
        # Brief pause between tests
        time.sleep(2)
    
    # Save results
    report = {
        'timestamp': datetime.now().isoformat(),
        'test_config': {
            'base_url': args.url,
            'endpoint': args.endpoint,
            'start_users': args.start,
            'max_users': args.max,
            'step': args.step,
            'requests_per_user': args.requests
        },
        'results': results,
        'breaking_point_found': breaking_point_found,
        'breaking_point_users': users if breaking_point_found else None
    }
    
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    print(f"\n{'='*70}")
    print("TEST COMPLETE")
    print(f"{'='*70}")
    print(f"Results saved to: {args.output}")
    
    if breaking_point_found:
        print(f"\nBreaking point: {users} concurrent users")
    else:
        print(f"\nNo breaking point found up to {args.max} concurrent users")
        print("System handles all tested load levels")

if __name__ == '__main__':
    main()
