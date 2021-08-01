#! /usr/bin/env python3

from colorama import Fore, Style
import sys
import subprocess as sub
from subprocess import Popen, PIPE
import os
import time
import os.path
import argparse


# Globals
currentDir = os.getcwd()
binDir = currentDir + "/bin/"


info = (Fore.BLUE + "[*] ")
recc = (Fore.YELLOW + "[*] ")
good = (Fore.GREEN + "[+] ")
important = (Fore.CYAN + "[!] " )
printError = (Fore.RED + "[X] ")

parser = argparse.ArgumentParser(description=recc + 'ShadowSteal.py: turn-key easy ShadowSteal setup using Docker! Must be run as sudo, no args required.')
args = parser.parse_args()

title = Fore.CYAN + """\
   _____ _               _                _____ _             _ 
  / ____| |             | |              / ____| |           | |
 | (___ | |__   __ _  __| | _____      _| (___ | |_ ___  __ _| |
  \___ \| '_ \ / _` |/ _` |/ _ \ \ /\ / /\___ \| __/ _ \/ _` | |
  ____) | | | | (_| | (_| | (_) \ V  V / ____) | ||  __/ (_| | |
 |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/ |_____/ \__\___|\__,_|_|

| CVE-2021-36934 | exploit discovered by @jonasLyk | code by HuskyHacks |
""" + Fore.RESET

usage = Fore.CYAN + r"""
PS C:\Users\husky\Desktop> .\ShadowSteal.exe -h
[*] ShadowSteal! Identifies and extracts credentials that can be stolen due to the SeriousSAM (CVE-2021-36934) exploit. Searches from high to low, defaults searching 100 to 1.

Usage:
   [options]

Options:
  -h, --help
  -t, --triage               [*] Triage mode. Quick enumeration, tries to find quick wins.
  -bf, --bruteforce          [*] Bruteforce mode. Enumerates the entire range of possible locations (512 to 1). Takes a bit.
  -b, --bezos                [?] Jeff Bezos Mode
""" + Fore.RESET


def is_root():
    if os.geteuid() == 0:
        return 0
    else:
        print(recc + "You need to run this script as root!\n[*] Usage: sudo python3 ShadowSteal.py")
        exit()

def checkDocker():
        print(info+"Checking Docker...")
        try:
            p = sub.Popen(['docker --version'], shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
            output, error = p.communicate()
            if p.returncode == 0:
                print(good + "Docker is installed!")
            elif p.returncode > 0:
                print(printError + "Docker is not installed. Make sure to install Docker first (on Kali/Ubuntu, run: sudo apt-get install docker.io -y)")
                exit(1)
        except Exception as e:    
            print(printError + str(e))
            exit(1)

def dockerBuild():
    try:
        print(info + "Creating temporary build environment container...")
        sub.call(['docker rm shadowsteal -f 1>/dev/null 2>/dev/null && docker build -t shadowsteal .'], shell=True)
    except Exception as e:    
            print(printError +str(e))
            exit(1)

def dockerRun():
    try:
        print(info + "Starting build container...")
        sub.call(['docker run --name shadowsteal -dt shadowsteal 1>/dev/null'], shell=True)
    except Exception as e:    
            print(printError +str(e))
            exit(1)

def dockerCopy():
    print(info + "Copying payload binary to host...")
    try:
        sub.call(['docker cp shadowsteal:/opt/ShadowSteal/bin/ShadowSteal.exe bin/ 1>/dev/null'], shell=True)
        exists = os.path.isfile(binDir + "ShadowSteal.exe")
        if exists:
            print(good + "Success! ShadowSteal.exe located in the ShadowSteal/bin/ directory on the host.")
            return True
    except Exception as e:    
            print(printError +str(e))
            exit(1)

def dockerKill():
    print(info + "Removing temporary container...")
    try:
        sub.call(['docker rm shadowsteal -f 1>/dev/null'], shell=True)
    except Exception as e:
        print(printError + str(e))
        exit(1)

def printUsage():
    print(important + "All set! Drop ShadowSteal.exe to your target and run it. Happy Hacking!")
    print(usage)

def main():
    print(title)
    is_root()
    checkDocker()
    dockerBuild()
    dockerRun()
    exists = dockerCopy()
    dockerKill()
    if exists:
        printUsage()
    else:
        print(printError + "Something went wrong.")
    exit()


if __name__ == "__main__":
    main()