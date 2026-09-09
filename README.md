# Abdo-Admin

A Bash-based web path scanner with a `robots.txt` checker and optional result logging.

> **Authorization:** Only use this tool against websites you own or have explicit permission to test.

## Features

- Checks `robots.txt`.
- Reads paths from a wordlist.
- Tests paths with HTTP requests.
- Supports configurable concurrent scans.
- Optionally saves scan results.
- Optional `Abdo-Admin_version_check.py` integration.
- Handles `Ctrl+C` cleanup.
- Validates required dependencies and user input.

## Requirements

- Bash
- `curl`
- Optional: Python 3 and `requests`, for the version check

## Installation

```bash
git clone https://github.com/Abdelouahab-DZ/Abdo-Admin.git
cd Abdo-Admin
chmod +x Abdo-Admin.sh
```

Create or place your wordlist as:

```text
wordlist.txt
```

## Usage

Run:

```bash
./Abdo-Admin.sh
```

The script asks for:

1. Website
2. Wordlist
3. Whether to save output
4. Number of concurrent threads

Example:

```text
Website: https://example.com
Wordlist: wordlist.txt
Save output: yes
Threads: 15
```

## Output

When output saving is enabled, results are stored under a directory named after the target host:

```text
example.com/
├── output.txt
└── robots.txt
```

Targets may be entered with or without `http://` or `https://`. If no scheme is
provided, HTTPS is used.

## Wordlist format

Put one path per line:

```text
admin
login
dashboard
robots.txt
```

The script requests each path relative to the target website.

## Notes

- A `200` or `201` response is reported as a successful result.
- Network errors and other HTTP status codes are reported but do not stop the scan.
- A timeout is used for HTTP requests to reduce the chance of the script hanging on slow targets.
- The scanner is intentionally simple and is not a replacement for a full web security testing framework.

## Project structure

```text
Abdo-Admin/
├── Abdo-Admin Dependency Installer.sh
├── Abdo-Admin.sh
├── wordlist.txt
├── version.txt
├── Abdo-Admin_version_check.py        # optional update checker
├── README.md
└── LICENSE
```

## License

Add a license that matches how you want others to use and distribute this project.
