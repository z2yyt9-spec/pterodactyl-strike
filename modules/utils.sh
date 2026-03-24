#!/bin/bash

# Utilitas untuk logging dan helper functions

init_logging() {
    mkdir -p "$LOGS_DIR" "$OUTPUTS_DIR/session_data"
    LOG_FILE="$LOGS_DIR/attack.log"
    FINGERPRINT_LOG="$LOGS_DIR/fingerprint.log"
    DEFACE_LOG="$LOGS_DIR/deface_result.log"
    
    echo "=== Attack Started: $(date) ===" >> "$LOG_FILE"
}

log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
    echo -e "${GREEN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

check_dependencies() {
    local deps=("curl" "wget" "python3" "dig" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dependency missing: $dep"
            return 1
        fi
    done
    return 0
}

random_user_agent() {
    local agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    )
    echo "${agents[$RANDOM % ${#agents[@]}]}"
}
