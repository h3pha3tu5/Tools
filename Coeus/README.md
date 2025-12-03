```
   ____     ____      _____   __    __    _____ 
  / ___)   / __ \    / ___/   ) )  ( (   / ____\
 / /      / /  \ \  ( (__    ( (    ) ) ( (___  
( (      ( ()  () )  ) __)    ) )  ( (   \___ \ 
( (      ( ()  () ) ( (      ( (    ) )      ) )
 \ \___   \ \__/ /   \ \___   ) \__/ (   ___/ / 
  \____)   \____/     \____\  \______/  /____/  
```                 
# Coeus 0.1

**Author:** h3phaetus  

## Project Description

**Coeus** is a Python and script to search through **Edge** and **Chrpmoim** History archives.  
It extracts URL visit data, including:

- Timestamp of visit  
- Referrer URL  
- Visit source  
- Transition type  
- Associated downloads and their URL chains  

This tool is designed for **DFIR (Digital Forensics and Incident Response)** purposes and produces a **forensic-friendly output**.

**Functional in Python, still a work in progress in Bash**

---

## Prerequisites

### Python Version

- Python 3.x

### SQLite

- SQLite3 database file (usually named `History`) from Edge or Chrome.

### Bash Version (for Bash script)

- Bash 4.0 or higher (required for associative arrays and certain features).
- `sqlite3` command-line utility must be installed and available in `PATH`.

---

## Usage

### Python Script

Run the Python version of Coeus to search the History SQLite database:

```bash
# Search for all visits containing "login"
python3 searcher.py login

# Search using a specific History file
python3 searcher.py "example.com" --db "/Users/username/AppData/Local/Microsoft/Edge/User Data/Default/History"
```
### Bash Script

Run the Bash version of Coeus to search the History SQLite database:

```bash
# Make the script executable (first time only)
chmod +x searcher.sh

# Search for "login" using default History file in current directory
./searcher.sh login

# Search using a specific History file
./searcher.sh "example.com" "/Users/username/AppData/Local/Microsoft/Edge/User Data/Default/History"
```
