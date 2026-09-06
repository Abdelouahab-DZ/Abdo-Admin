#!/usr/bin/env bash

# Abdo-Admin
# Simple web-path and robots.txt checker.
# Use only against websites you own or are authorized to test.

set -u

# -----------------------------
# Colors and styles
# -----------------------------
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
MAGENTA='\e[95m'
CYAN='\e[96m'
WHITE='\e[97m'
RESET='\e[0m'

BOLD='\e[1m'

DEFAULT_THREADS=15
THREADS=$DEFAULT_THREADS
OUTPUT_FILE=""
WEB=""

# -----------------------------
# Cleanup
# -----------------------------
cleanup() {
    printf '\n'
    # Stop curl processes started by this script when Ctrl+C is pressed.
    pkill -INT -f 'curl' >/dev/null 2>&1 || true
    exit 130
}
trap cleanup INT TERM

# -----------------------------
# Banner
# -----------------------------
banner() {
    printf '%b\n' "${BOLD}${GREEN}|${WHITE} Created By ${BLUE}:${CYAN} Abdelouahab-OM ${RESET}"
    sleep 0.3
    printf '%b\n' "${BOLD}${GREEN}│${WHITE} Version ${BLUE}:${WHITE} 1.9.0 ${RESET}"
    printf '%b\n' "${BOLD}${GREEN}│${WHITE} Code    ${BLUE}:${WHITE} Bash, Python ${RESET}"
    printf '%b\n' "${BOLD}${GREEN}|${WHITE} Date    ${BLUE}:${WHITE} 21 02 2025 ${RESET}"
}

# -----------------------------
# Dependency checks
# -----------------------------
require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf '%b\n' "${RED}[!] Missing dependency: ${command_name}${RESET}"
        exit 1
    fi
}

check_dependencies() {
    require_command curl
    require_command wget
}

# -----------------------------
# URL normalization
# -----------------------------
normalize_host() {
    local input="$1"

    # Remove protocol.
    input="${input#http://}"
    input="${input#https://}"

    # Remove path, query, and fragment.
    input="${input%%/*}"
    input="${input%%\?*}"
    input="${input%%\#*}"

    printf '%s' "$input"
}

# -----------------------------
# robots.txt check
# -----------------------------
check_robots() {
    local site="$1"
    local robots_url="${site%/}/robots.txt"
    local response
    local http_code

    # One request obtains both the body and HTTP status.
    response="$(curl -fsSL --max-time 10 "$robots_url" 2>/dev/null || true)"
    http_code="$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 10 "$robots_url" 2>/dev/null || true)"

    if [[ "$http_code" == "200" && -n "$response" && "$response" != *"</html>"* ]]; then
        printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} robots.txt found for ${site}${RESET}"

        if [[ -n "$OUTPUT_FILE" ]]; then
            wget -q -O "${WEB}/robots.txt" "$robots_url"
        fi
    else
        printf '%b\n' "      ${GREEN}[${RED}-${GREEN}]${WHITE} No robots.txt found for ${site}${RESET}"
    fi
}

# -----------------------------
# Scan one wordlist entry
# -----------------------------
scan_path() {
    local base_url="$1"
    local path="$2"
    local url="${base_url%/}/${path#/}"
    local status

    status="$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null || true)"

    if [[ "$status" == "200" || "$status" == "201" ]]; then
        printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}] ${WHITE}${url} ${YELLOW}~> ${GREEN}${status}${RESET}"

        if [[ -n "$OUTPUT_FILE" ]]; then
            printf '%s\n' "${url} ~> ${status}" >> "$OUTPUT_FILE"
        fi
    else
        printf '%b\n' "      ${GREEN}[${RED}-${GREEN}] ${WHITE}${url} ${BLUE}~> ${RED}${status}${RESET}"

        if [[ -n "$OUTPUT_FILE" ]]; then
            printf '%s\n' "${url} ~> ${status}" >> "$OUTPUT_FILE"
        fi
    fi
}

# -----------------------------
# Main
# -----------------------------
main() {
    local web_input
    local wordlist
    local save_output
    local threads_input
    local total_lines

    if [[ -f CheckVersion.py ]]; then
        require_command python3
        python3 CheckVersion.py
        sleep 1
    fi

    check_dependencies
    banner

    read -r -p $'\e[96m[>]\e[97m Enter your website: ' web_input
    if [[ -z "$web_input" ]]; then
        printf '%b\n' "${RED}[!] Error: invalid website.${RESET}"
        exit 1
    fi

    WEB="$(normalize_host "$web_input")"
    if [[ -z "$WEB" ]]; then
        printf '%b\n' "${RED}[!] Error: could not parse website.${RESET}"
        exit 1
    fi

    read -r -p $'\e[96m[>]\e[97m Enter your wordlist (Default: wordlist.txt): ' wordlist
    wordlist="${wordlist:-wordlist.txt}"

    if [[ ! -f "$wordlist" || ! -r "$wordlist" ]]; then
        printf '%b\n' "${RED}[!] Wordlist not found or not readable: ${wordlist}${RESET}"
        exit 1
    fi

    read -r -p $'\e[96m[>]\e[97m Save output? (yes/no): ' save_output

    if [[ "$save_output" == "yes" ]]; then
        mkdir -p "$WEB"
        OUTPUT_FILE="${WEB}/output.txt"
        : > "$OUTPUT_FILE"
    fi

    read -r -p $'\e[96m[>]\e[97m Enter threads count (Default: 15): ' threads_input
    THREADS="${threads_input:-$DEFAULT_THREADS}"

    if ! [[ "$THREADS" =~ ^[1-9][0-9]*$ ]]; then
        printf '%b\n' "${RED}[!] Threads must be a positive integer.${RESET}"
        exit 1
    fi

    total_lines="$(wc -l < "$wordlist")"
    printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} Total Wordlist: ${total_lines}${RESET}"
    printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} Start Scanning...${RESET}"

    check_robots "https://${WEB}"

    if [[ -n "$OUTPUT_FILE" ]]; then
        printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} Output: ${OUTPUT_FILE}${RESET}"
    fi

    # Keep no more than THREADS background scans active at once.
    local -a pids=()
    local path
    local pid

    while IFS= read -r path || [[ -n "$path" ]]; do
        [[ -z "$path" ]] && continue

        scan_path "https://${WEB}" "$path" &
        pid=$!
        pids+=("$pid")

        if (( ${#pids[@]} >= THREADS )); then
            wait "${pids[0]}" || true
            pids=("${pids[@]:1}")
        fi
    done < "$wordlist"

    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done

    printf '%b\n' "${GREEN}[+] Scan finished.${RESET}"
}

main "$@"
