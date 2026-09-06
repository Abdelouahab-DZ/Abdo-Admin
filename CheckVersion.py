import os
import sys
import time
import threading
import requests
import json
import csv
import argparse
import subprocess as subp
from shutil import which

R = '\033[31m'
G = '\033[32m'
C = '\033[36m'
W = '\033[0m'

print(G + '[+]' + C + ' Checking Dependencies And Packages...' + W)
pkgs = ['python3', 'php', 'git']
inst = True
for pkg in pkgs:
    present = which(pkg)
    if present is None:
        print(R + '[-] ' + W + pkg + C + ' is not Installed!')
        inst = False

if not inst:
    exit()

row = []
info = ''
result = ''
version = '1.9.0'

def ver_check():
    print(G + '[+]' + C + ' Checking the Abdo-Admin for updates....', end='')
    # Updated to raw content URL so it fetches a version string instead of full HTML
    ver_url = 'https://raw.githubusercontent.com/Abdelouahab-DZ/Abdo-Admin/main/version.txt'
    try:
        ver_rqst = requests.get(ver_url, timeout=5)
        ver_sc = ver_rqst.status_code
        if ver_sc == 200:
            github_ver = ver_rqst.text.strip()

            if version == github_ver:
                print(C + '[' + G + ' No Updates ' + C + ']' + '\n')
                time.sleep(0.8)
            else:
                print(C + '[' + R + ' Available : {} '.format(github_ver) + C + ']' + '\n')
                time.sleep(1.5)
        else:
            print(C + '[' + R + ' Status : {} '.format(ver_sc) + C + ']' + '\n')
    except Exception as e:
        print('\n' + R + '[-]' + C + ' Exception : ' + W + str(e))

try:
    ver_check()
except KeyboardInterrupt:
    print('\n' + R + '[!]' + C + ' Keyboard Interrupt.' + W)
