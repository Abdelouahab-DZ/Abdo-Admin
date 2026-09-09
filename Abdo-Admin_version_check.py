#!/usr/bin/env python3

import sys
import time
from shutil import which

import requests

# Colors
R = "\033[31m"
G = "\033[32m"
C = "\033[36m"
W = "\033[0m"

VERSION = "1.9.0"
VERSION_URL = (
    "https://raw.githubusercontent.com/"
    "Abdelouahab-DZ/Abdo-Admin/main/version.txt"
)

def check_dependencies():
    print(G + "[+]" + C + " Checking Dependencies And Packages..." + W)

    if which("python3") is None:
        print(R + "[-] " + W + "python3" + C + " is not Installed!" + W)
        return False

    try:
        import requests  # noqa: F401
    except ImportError:
        print(R + "[-] " + W + "requests" + C + " is not Installed!" + W)
        return False

    return True


def ver_check():
    print(
        G + "[+]" + C +
        " Checking the Abdo-Admin for updates....",
        end=""
    )

    try:
        response = requests.get(VERSION_URL, timeout=5)
        response.raise_for_status()

        github_version = response.text.strip()

        if not github_version:
            print(
                C + "[" + R +
                " Invalid version " +
                C + "]" + W
            )
            return

        if VERSION == github_version:
            print(
                C + "[" + G +
                " No Updates " +
                C + "]" + W + "\n"
            )
            time.sleep(0.8)
        else:
            print(
                C + "[" + R +
                " Available : {} ".format(github_version) +
                C + "]" + W + "\n"
            )
            time.sleep(1.5)

    except requests.RequestException as error:
        print(
            "\n" + R + "[-]" + C +
            " Connection Error : " + W + str(error)
        )


def main():
    if not check_dependencies():
        return 1

    try:
        ver_check()
    except KeyboardInterrupt:
        print(
            "\n" + R + "[!]" + C +
            " Keyboard Interrupt." + W
        )
        return 130

    return 0


if __name__ == "__main__":
    sys.exit(main())
