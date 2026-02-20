#!/usr/bin/env python3
"""
Interactive Onboarding TUI for Just Enough Nix
Arrow keys to navigate, Enter to select
"""

import sys
import os
import termios
import tty
import subprocess

# Colors
class C:
    R = '\033[91m'
    G = '\033[92m'
    Y = '\033[93m'
    B = '\033[94m'
    C = '\033[96m'
    BD = '\033[1m'
    DM = '\033[2m'
    RS = '\033[0m'
    BG = '\033[44m'
    W = '\033[97m'

def clear():
    os.system('clear')

def header():
    clear()
    print(f"""{C.C}
   _    _           _                  _   _      _ _
  / \\  | | ___ _ __| |_ ___  _ __ __ _| \\ | | ___| | | __ _
 / _ \\ | |/ _ \\ '__| __/ _ \\| '__/ _` |  \\| |/ _ \\ | |/ _` |
/ ___ \\| |  __/ |  | || (_) | | | (_| | |\\ |  __/ | | (_| |
/_/   \\_\\_|\\___|_|   \\__\\___/|_|  \\__, |_| \\_|\\___|_|_|\\__,_|
                                  |___/        {C.BD}Onboarding{C.RS}
""")

def getch():
    """Get single keypress"""
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            ch += sys.stdin.read(2)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return ch

def menu(title, opts, desc, default=0):
    """Arrow key menu"""
    sel = default
    while True:
        header()
        print(f"{C.B}▶ {title}{C.RS}\n")
        for i, opt in enumerate(opts):
            if i == sel:
                print(f"{C.BG}{C.W}{C.BD} → {opt} {C.RS}")
                if desc[i]:
                    print(f"   {C.Y}  {desc[i]}{C.RS}")
            else:
                print(f"   {C.DM}{opt}{C.RS}")
                if desc[i]:
                    print(f"   {C.DM}  {desc[i]}{C.RS}")
        print(f"\n{C.DM}↑↓ Navigate, Enter Select{C.RS}")
        
        k = getch()
        if k == '\x1b[A':
            sel = (sel - 1) % len(opts)
        elif k == '\x1b[B':
            sel = (sel + 1) % len(opts)
        elif k in ['\r', '\n']:
            return sel
        elif k == 'q':
            sys.exit()

def input_text(prompt, default=""):
    """Text input"""
    header()
    print(f"{C.B}▶ {prompt}{C.RS}")
    if default:
        print(f"{C.DM}(default: {default}){C.RS}")
    print()
    
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    termios.tcsetattr(fd, termios.TCSADRAIN, old)
    
    res = input(f"{C.BD}> {C.RS}").strip()
    return res if res else default

def detect_gpu():
    """Detect GPU"""
    try:
        r = subprocess.run(['nvidia-smi', '--query-gpu=driver_version', '--format=csv,noheader'],
                          capture_output=True, text=True, timeout=3)
        if r.returncode == 0:
            v = r.stdout.strip().split('\n')[0].strip()
            if v and v != 'N/A':
                return ('nvidia', v)
    except:
        pass
    try:
        r = subprocess.run(['lspci'], capture_output=True, text=True)
        if 'intel' in r.stdout.lower():
            return ('intel', None)
    except:
        pass
    return (None, None)

def yes_no(prompt, default=True):
    """Yes/No question"""
    sel = 0 if default else 1
    opts = ['Yes', 'No']
    while True:
        header()
        print(f"{C.B}▶ {prompt}{C.RS}\n")
        for i, o in enumerate(opts):
            mark = '[✓]' if i == sel else '[ ]'
            if i == sel:
                print(f"{C.BG}{C.W} {mark} {o} {C.RS}")
            else:
                print(f" {C.DM}{mark} {o}{C.RS}")
        print(f"\n{C.DM}↑↓ Navigate, Enter Select{C.RS}")
        
        k = getch()
        if k == '\x1b[A' or k == '\x1b[B':
            sel = 1 - sel
        elif k in ['\r', '\n']:
            return sel == 0
        elif k == 'q':
            sys.exit()

def main():
    # Detect GPU
    gpu, ver = detect_gpu()
    
    # Step 1: Name
    name = input_text("Step 1/4: System Identity\n\nSystem name (e.g., laptop-x1)", 
                      os.environ.get('HOSTNAME', 'my-system'))
    
    # Step 2: Type
    types = ['desktop', 'laptop', 'headless', 'minimal']
    descs = [
        'Full desktop with GPU acceleration',
        'Portable setup with power saving',
        'Server (no GUI)',
        'Basic setup, no window manager'
    ]
    tidx = menu("Step 2/4: System Type", types, descs, default=1)
    
    # Step 3: Graphics
    gopts = ['none', 'default', 'nvidia', 'bumblebee', 'intel']
    gdesc = [
        'No wrapper, use system OpenGL',
        'Auto-detect GPU type',
        'NVIDIA proprietary drivers',
        'NVIDIA Optimus hybrid',
        'Intel integrated graphics'
    ]
    gdefault = 2 if gpu == 'nvidia' else (4 if gpu == 'intel' else 1)
    gidx = menu("Step 3/4: Graphics Configuration", gopts, gdesc, gdefault)
    
    # Step 4: NVIDIA options
    nv_auto = True
    nv_ver = None
    if gopts[gidx] == 'nvidia':
        header()
        if ver:
            print(f"{C.G}Detected NVIDIA driver: {ver}{C.RS}\n")
        nv_auto = yes_no("Step 4/4: Enable auto-detection at boot?", True)
        if not nv_auto:
            nv_ver = input_text("Enter version to pin (e.g., 570.133.07)", ver or "570.133.07")
    
    # Summary
    header()
    print(f"{C.G}{C.BD}✓ Configuration Complete{C.RS}\n")
    print(f"  Name:     {C.BD}{name}{C.RS}")
    print(f"  Type:     {C.BD}{types[tidx]}{C.RS}")
    print(f"  Graphics: {C.BD}{gopts[gidx]}{C.RS}")
    if gopts[gidx] == 'nvidia':
        print(f"  Auto-detect: {C.BD}{'Yes' if nv_auto else 'No'}{C.RS}")
        if nv_ver:
            print(f"  Version: {C.BD}{nv_ver}{C.RS}")
    print(f"\n{C.Y}Next: home-manager switch --flake ~/.config/nix{C.RS}")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{C.R}Cancelled.{C.RS}")
        sys.exit(1)
