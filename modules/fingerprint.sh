#!/bin/bash

# Modul fingerprinting untuk mendeteksi versi, endpoint, dan konfigurasi panel

fingerprint_target() {
    log_info "Starting fingerprinting on $TARGET_URL"
    
    local fingerprint_result=""
    
    # Deteksi versi dari response headers
    log_info "Detecting version from headers..."
    local version_headers=$(curl -s -I -k "$TARGET_URL" | grep -i "x-powered-by" || echo "")
    if [[ -n "$version_headers" ]]; then
        echo "$version_headers" >> "$FINGERPRINT_LOG"
        fingerprint_result+="Headers: $version_headers\n"
    fi
    
    # Deteksi dari meta generator
    log_info "Checking meta generator..."
    local meta_gen=$(curl -s -k "$TARGET_URL" | grep -oP '<meta name="generator" content="[^"]+"' || echo "")
    if [[ -n "$meta_gen" ]]; then
        echo "$meta_gen" >> "$FINGERPRINT_LOG"
        fingerprint_result+="Meta: $meta_gen\n"
    fi
    
    # Deteksi endpoint API yang terekspos
    log_info "Discovering API endpoints..."
    local api_endpoints=(
        "/api/application"
        "/api/client"
        "/api/remote"
        "/api/settings"
        "/api/users"
        "/api/servers"
        "/api/nodes"
        "/api/locations"
        "/api/nests"
        "/api/eggs"
    )
    
    local discovered_endpoints=""
    for endpoint in "${api_endpoints[@]}"; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" -k "${TARGET_URL}${endpoint}" 2>/dev/null)
        if [[ "$status" != "404" && "$status" != "000" ]]; then
            discovered_endpoints+="$endpoint (HTTP $status)\n"
            echo "Discovered: $endpoint (HTTP $status)" >> "$FINGERPRINT_LOG"
        fi
    done
    
    # Deteksi panel version dari asset path
    log_info "Extracting version from assets..."
    local asset_version=$(curl -s -k "$TARGET_URL" | grep -oP '/assets/pterodactyl-[a-f0-9]+' | head -1 || echo "")
    if [[ -n "$asset_version" ]]; then
        echo "Asset version pattern: $asset_version" >> "$FINGERPRINT_LOG"
        fingerprint_result+="Asset: $asset_version\n"
    fi
    
    # Cek apakah menggunakan SSL/TLS
    log_info "Checking SSL configuration..."
    local ssl_info=$(echo | openssl s_client -connect "$TARGET:443" -servername "$TARGET" 2>/dev/null | openssl x509 -noout -issuer -subject -dates 2>/dev/null || echo "SSL not configured")
    echo "$ssl_info" >> "$FINGERPRINT_LOG"
    
    # Cek keberadaan file konfigurasi yang terekspos
    log_info "Checking exposed configuration files..."
    local config_files=(
        ".env"
        "config.php"
        "config.yml"
        "database.yml"
        ".git/config"
        "storage/logs/laravel.log"
    )
    
    for conf_file in "${config_files[@]}"; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" -k "${TARGET_URL}/${conf_file}" 2>/dev/null)
        if [[ "$status" == "200" ]]; then
            echo "EXPOSED: $conf_file (HTTP $status)" >> "$FINGERPRINT_LOG"
            fingerprint_result+="EXPOSED CONFIG: $conf_file\n"
        fi
    done
    
    # Simpan hasil fingerprint
    echo -e "$fingerprint_result" > "$FINGERPRINT_LOG"
    
    log_success "Fingerprinting completed. Results saved to $FINGERPRINT_LOG"
    
    # Export discovered endpoints untuk digunakan modul lain
    export DISCOVERED_ENDPOINTS="$discovered_endpoints"
}

# Eksekusi jika dijalankan langsung
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fingerprint_target
fi
