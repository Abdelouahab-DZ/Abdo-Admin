#!/usr/bin/env bash

# Abdo-Admin
# Simple web-path and robots.txt checker.
# Use only against websites you own or are authorized to test.

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
    for pid in "${pids[@]:-}"; do
        kill -INT "$pid" >/dev/null 2>&1 || true
    done
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
}

# -----------------------------
# URL normalization and validation
# -----------------------------
normalize_url() {
    local input="$1"
    local scheme

    if [[ "$input" != http://* && "$input" != https://* ]]; then
        input="https://${input}"
    fi

    scheme="${input%%://*}://"
    input="${input#*://}"
    input="${input%%\?*}"
    input="${input%%\#*}"
    input="${input%/}"

    if [[ -z "$input" || "$input" == */* || "$input" == *[[:space:]]* ]]; then
        return 1
    fi

    printf '%s%s' "$scheme" "$input"
}

# -----------------------------
# robots.txt check
# -----------------------------
check_robots() {
    local site="$1"
    local robots_url="${site%/}/robots.txt"
    local response_file
    local http_code
    response_file="$(mktemp)" || return 1

    http_code="$(curl -sSL -o "$response_file" -w '%{http_code}' --max-time 10 \
        "$robots_url" 2>/dev/null || true)"

    if [[ "$http_code" == "200" && -s "$response_file" ]] &&
        ! grep -qi '</html>' "$response_file"; then
        printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} robots.txt found for ${site}${RESET}"

        if [[ -n "$OUTPUT_FILE" ]]; then
            cp -- "$response_file" "${WEB}/robots.txt"
        fi
    else
        printf '%b\n' "      ${GREEN}[${RED}-${GREEN}]${WHITE} No robots.txt found for ${site}${RESET}"
    fi

    rm -f -- "$response_file"
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

    if [[ "$status" =~ ^2[0-9][0-9]$ || "$status" =~ ^3[0-9][0-9]$ ]]; then
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

    if [[ -f "${SCRIPT_DIR}/Abdo-Admin_version_check.py" ]]; then
        require_command python3
        python3 "${SCRIPT_DIR}/Abdo-Admin_version_check.py"
        sleep 1
    fi

    check_dependencies
    banner

    read -r -p $'\e[96m[>]\e[97m Enter your website: ' web_input
    if [[ -z "$web_input" ]]; then
        printf '%b\n' "${RED}[!] Error: invalid website.${RESET}"
        exit 1
    fi

    if ! WEB="$(normalize_url "$web_input")"; then
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
        local output_dir="${WEB#*://}"
        output_dir="${output_dir//:/_}"
        mkdir -p -- "$output_dir"
        OUTPUT_FILE="${output_dir}/output.txt"
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

    check_robots "$WEB"

    if [[ -n "$OUTPUT_FILE" ]]; then
        printf '%b\n' "      ${GREEN}[${WHITE}+${GREEN}]${WHITE} Output: ${OUTPUT_FILE}${RESET}"
    fi

    # Keep no more than THREADS background scans active at once.
    local -a pids=()
    local path
    local pid

    while IFS= read -r path || [[ -n "$path" ]]; do
        [[ -z "$path" ]] && continue

        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        [[ -z "$path" || "$path" == \#* ]] && continue

        scan_path "$WEB" "$path" &
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
