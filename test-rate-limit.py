#!/usr/bin/env python3
"""
Rate limiting test for POST /v1/auth/sign-in
Use only with authorized email addresses on domains you control.
"""

import requests
import time
import csv
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import argparse

def send_magic_link(email, request_num, delay=0):
    """Send a magic link request to the endpoint"""
    url = "https://compute.ornn.com/v1/auth/sign-in"
    
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Mozilla/5.0 (compatible; SecurityTest/1.0)"
    }
    
    data = {
        "email": email
    }
    
    # Try with optional resend parameter
    if request_num > 1:
        data["resend"] = "1"
    
    try:
        if delay:
            time.sleep(delay)
            
        start_time = time.time()
        response = requests.post(url, data=data, headers=headers, 
                                 allow_redirects=False, timeout=10)
        elapsed = time.time() - start_time
        
        return {
            "email": email,
            "request_num": request_num,
            "status_code": response.status_code,
            "location": response.headers.get("Location", ""),
            "elapsed_ms": round(elapsed * 1000, 2),
            "timestamp": datetime.now().isoformat(),
            "success": response.status_code in [200, 301, 302, 303, 307, 308]
        }
        
    except requests.exceptions.RequestException as e:
        return {
            "email": email,
            "request_num": request_num,
            "status_code": "ERROR",
            "location": "",
            "elapsed_ms": 0,
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": str(e)
        }

def run_rate_limit_test(emails, total_requests, concurrent, delay=0.5):
    """
    Run the rate limit test
    
    Args:
        emails: List of email addresses to test
        total_requests: Total number of requests to send (distributed across emails)
        concurrent: Number of concurrent requests
        delay: Delay between requests in seconds
    """
    results = []
    
    # Distribute requests across emails
    requests_per_email = total_requests // len(emails)
    remaining = total_requests % len(emails)
    
    all_requests = []
    for idx, email in enumerate(emails):
        count = requests_per_email + (1 if idx < remaining else 0)
        for i in range(count):
            all_requests.append((email, i + 1))
    
    print(f"📊 Sending {len(all_requests)} total requests across {len(emails)} email addresses")
    print(f"📧 Emails: {', '.join(emails)}")
    print(f"⚡ Concurrent: {concurrent}, Delay: {delay}s")
    print("=" * 60)
    
    # Execute requests with concurrency
    with ThreadPoolExecutor(max_workers=concurrent) as executor:
        futures = {
            executor.submit(send_magic_link, email, req_num, delay): (email, req_num) 
            for email, req_num in all_requests
        }
        
        completed = 0
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            completed += 1
            
            # Print progress
            status = f"✓ {result['status_code']}" if result['success'] else f"✗ {result.get('error', result['status_code'])}"
            print(f"[{completed}/{len(all_requests)}] {result['email']} → {status} ({result['elapsed_ms']}ms)")
    
    return results

def analyze_results(results):
    """Analyze and display results"""
    print("\n" + "=" * 60)
    print("📈 RESULTS ANALYSIS")
    print("=" * 60)
    
    # Status code distribution
    status_codes = {}
    for r in results:
        code = str(r['status_code'])
        status_codes[code] = status_codes.get(code, 0) + 1
    
    print("\n📊 Status Code Distribution:")
    for code, count in sorted(status_codes.items()):
        print(f"  {code}: {count} requests ({count/len(results)*100:.1f}%)")
    
    # Check for rate limiting indicators
    rate_limit_indicators = [
        r for r in results 
        if r.get('status_code') in [429, 503, 403] or 
           (isinstance(r.get('status_code'), int) and r['status_code'] >= 400)
    ]
    
    if rate_limit_indicators:
        print(f"\n⚠️  Rate limiting detected: {len(rate_limit_indicators)} requests failed with HTTP errors")
        print("   This suggests rate limiting IS active")
    else:
        print("\n✅ No rate limiting detected in this test")
        print("   All requests succeeded (consider testing with higher volume)")
    
    # Timing analysis
    avg_time = sum(r['elapsed_ms'] for r in results if r['elapsed_ms'] > 0) / len([r for r in results if r['elapsed_ms'] > 0])
    print(f"\n⏱️  Average response time: {avg_time:.2f}ms")
    
    # Email-specific stats
    print("\n📧 Per-email breakdown:")
    email_stats = {}
    for r in results:
        email = r['email']
        if email not in email_stats:
            email_stats[email] = {'total': 0, 'success': 0, 'failed': 0}
        email_stats[email]['total'] += 1
        if r['success']:
            email_stats[email]['success'] += 1
        else:
            email_stats[email]['failed'] += 1
    
    for email, stats in email_stats.items():
        success_rate = stats['success'] / stats['total'] * 100
        print(f"  {email}: {stats['success']}/{stats['total']} successful ({success_rate:.1f}%)")
    
    return status_codes

def export_results(results, filename=None):
    """Export results to CSV for further analysis"""
    if not filename:
        filename = f"rate_limit_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['timestamp', 'email', 'request_num', 'status_code', 'location', 'elapsed_ms', 'success']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for r in results:
            # Clean up dict for CSV
            csv_row = {k: v for k, v in r.items() if k in fieldnames}
            writer.writerow(csv_row)
    
    print(f"\n💾 Results exported to: {filename}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Rate limit test for magic-link endpoint')
    parser.add_argument('--emails', nargs='+', 
                       default=['arjun1@ornn.com', 'arjun2@ornn.com', 'arjun3@ornn.com', 'arjun4@ornn.com', 'arjun5@ornn.com', 'arjun6@ornn.com'],
                       help='Email addresses to test')
    parser.add_argument('--total', type=int, default=100,
                       help='Total number of requests to send')
    parser.add_argument('--concurrent', type=int, default=5,
                       help='Number of concurrent requests')
    parser.add_argument('--delay', type=float, default=0.5,
                       help='Delay between requests in seconds')
    parser.add_argument('--export', action='store_true',
                       help='Export results to CSV')
    
    args = parser.parse_args()
    
    print("🔐 Magic Link Rate Limit Test")
    print("⚠️  ONLY use with email addresses you own!")
    print("=" * 60)
    
    # Confirm before running
    response = input(f"\nSend {args.total} requests to {', '.join(args.emails)}? (y/N): ")
    if response.lower() != 'y':
        print("Test cancelled.")
        exit(0)
    
    # Run the test
    results = run_rate_limit_test(
        emails=args.emails,
        total_requests=args.total,
        concurrent=args.concurrent,
        delay=args.delay
    )
    
    # Analyze results
    analyze_results(results)
    
    # Export if requested
    if args.export:
        export_results(results)
    
    # Check for specific security concerns
    print("\n" + "=" * 60)
    print("🔒 SECURITY OBSERVATIONS")
    print("=" * 60)
    
    # Check for response inconsistencies that could indicate enumeration
    unique_responses = set()
    for r in results:
        response_key = f"{r['status_code']}_{r.get('location', '')}"
        unique_responses.add(response_key)
    
    if len(unique_responses) > 1:
        print("⚠️  Different responses observed for different emails")
        print("   This could indicate user enumeration!")
    else:
        print("✅ Consistent responses across emails (no visible enumeration)")
    
    print("\n📝 Next steps:")
    print("  1. Monitor email inboxes for unexpected magic links")
    print("  2. Check server logs for HTTP 429 responses (rate limiting)")
    print("  3. Run a more extensive test with higher volume if authorized")
    print("  4. Document findings for security team review")