#!/bin/bash

# Abdo-Admin Dependency Installer

RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
BLUE="$(printf '\033[34m')"
CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"
RESET="$(printf '\033[0m')"

clear

show_menu() {
    echo "${BLUE}================================${RESET}"
    echo "${RED}        Abdo-Admin Setup${RESET}"
    echo "${BLUE}================================${RESET}"
    echo "${CYAN}1.${RESET} Termux"
    echo "${CYAN}2.${RESET} Debian / Ubuntu Linux"
    echo "${CYAN}3.${RESET} Kali Linux"
    echo "${CYAN}4.${RESET} Arch Linux"
    echo "${BLUE}================================${RESET}"
    printf "${RED}Enter your choice (1/2/3/4): ${RESET}"
}

install_python_requests() {
    echo "${CYAN}[+] Installing Python requests...${RESET}"

    if python3 -c "import requests" >/dev/null 2>&1; then
        echo "${GREEN}[+] Python requests is already installed.${RESET}"
        return 0
    fi

    # Try the distribution package first
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y python3-requests
        return $?
    fi

    # Fallback for systems where pip is appropriate
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user requests
        return $?
    fi

    echo "${RED}[-] Unable to install Python requests.${RESET}"
    return 1
}

install_termux() {
    echo "${CYAN}[+] Installing dependencies for Termux...${RESET}"

    pkg update -y || return 1
    pkg upgrade -y || return 1

    pkg install -y \
        python \
        php \
        git \
        toilet || return 1

    python3 -m pip install --upgrade requests || return 1

    echo "${GREEN}[+] Termux dependencies installed successfully.${RESET}"
}

install_debian() {
    echo "${CYAN}[+] Installing dependencies for Debian/Ubuntu...${RESET}"

    sudo apt update || return 1

    sudo apt install -y \
        python3 \
        python3-pip \
        python3-requests \
        php \
        git \
        toilet || return 1

    # Verify requests
    python3 -c "import requests" >/dev/null 2>&1 || {
        echo "${RED}[-] Python requests installation failed.${RESET}"
        return 1
    }

    echo "${GREEN}[+] Linux dependencies installed successfully.${RESET}"
}

install_kali() {
    echo "${CYAN}[+] Installing dependencies for Kali Linux...${RESET}"

    sudo apt update || return 1

    sudo apt install -y \
        python3 \
        python3-pip \
        python3-requests \
        php \
        git \
        toilet || return 1

    python3 -c "import requests" >/dev/null 2>&1 || {
        echo "${RED}[-] Python requests installation failed.${RESET}"
        return 1
    }

    echo "${GREEN}[+] Kali Linux dependencies installed successfully.${RESET}"
}

install_arch() {
    echo "${CYAN}[+] Installing dependencies for Arch Linux...${RESET}"

    sudo pacman -Syu --noconfirm || return 1

    sudo pacman -S --needed --noconfirm \
        python \
        python-pip \
        python-requests \
        php \
        git \
        toilet || return 1

    python3 -c "import requests" >/dev/null 2>&1 || {
        echo "${RED}[-] Python requests installation failed.${RESET}"
        return 1
    }

    echo "${GREEN}[+] Arch Linux dependencies installed successfully.${RESET}"
}

show_result() {
    local status="$1"

    echo
    echo "${BLUE}================================${RESET}"

    if [ "$status" -eq 0 ]; then
        echo "${GREEN}[+] Installation completed successfully!${RESET}"
    else
        echo "${RED}[-] Installation failed.${RESET}"
        echo "${CYAN}Check the error above and try again.${RESET}"
    fi

    echo "${BLUE}================================${RESET}"
}

show_menu
read -r numb

clear

case "$numb" in
    1)
        install_termux
        status=$?
        ;;

    2)
        install_debian
        status=$?
        ;;

    3)
        install_kali
        status=$?
        ;;

    4)
        install_arch
        status=$?
        ;;

    *)
        echo "${RED}[-] Invalid option.${RESET}"
        echo
        echo "${CYAN}Required dependencies:${RESET}"
        echo "  1. Python 3"
        echo "  2. Python requests"
        echo "  3. PHP"
        echo "  4. Git"
        echo "  5. Toilet"
        exit 1
        ;;
esac

show_result "$status"
exit "$status"
