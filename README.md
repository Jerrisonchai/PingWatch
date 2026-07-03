# 📡 PingWatch: Lightweight Network & Server Monitor

PingWatch is a zero-installation, blazing-fast Windows Batch script designed to monitor the health of your servers, shared folders, and web applications. 

It reads a simple text file, automatically detects what kind of target it is looking at, runs a read-only health check (using built-in Windows tools like `ping`, `curl`, and `if exist`), and outputs a beautiful, color-coded dashboard directly to your terminal before saving a pristine log file for your records.

## ✨ Features
* **🧠 Auto-Detect Routing:** Automatically knows whether to test a Web URL (HTTP status), a directory path (UNC/Local access), or an IP/Hostname (ICMP Ping).
* **🎨 ANSI Color Terminal:** Beautiful, easy-to-read live console output with green/red status indicators.
* **📂 Automated Archiving:** Creates an `Archive` folder and writes perfectly formatted, tabular text logs for every run.
* **🕒 Locale-Safe Timestamps:** Uses WMI to guarantee YYYY-MM-DD log formats, completely bypassing regional Windows date-flip bugs.
* **🤖 Sassy System Summaries:** Generates an automated, slightly sarcastic health assessment based on your success percentage (e.g., "FLAWLESS VICTORY" vs. "SYSTEM MELTDOWN").
* **🪶 100% Safe & Lightweight:** Read-only operations. Safe to run manually or on a 1-minute scheduled cron job without stressing your network or consuming RAM.

---

## 🚀 Quick Start Guide

### 1. The Setup
You only need two files in the exact same folder for this to work.
1. `check_connections.bat` (The main engine)
2. `targets.txt` (Your target list)

### 2. Configuring `targets.txt`
Create a text file named `targets.txt` in the same directory as the script. List your targets one per line. 

You can (and should) add a custom description for each target by using a **comma** `,`. The script will pad your descriptions perfectly for the final table.

**Example `targets.txt` format:**
```text
[https://www.google.com](https://www.google.com), External Internet Gateway
192.168.1.50, Primary Database Server
ServerName01, Application Host
\\192.168.2.4\purchase, Shared Purchasing Drive
10.0.0.99
