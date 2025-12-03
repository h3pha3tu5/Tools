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

**Coeus** is a Python script to search through **Edge** and **Chrpmoim** History archives.  
It extracts URL visit data, including:

- Timestamp of visit  
- Referrer URL  
- Visit source  
- Transition type  
- Associated downloads and their URL chains  

This tool is designed for **DFIR (Digital Forensics and Incident Response)** purposes and produces a **forensic-friendly output**.

---

## Usage

### Prerequisites

- Python 3.x  
- SQLite3 database file (usually named `History`) from Edge or Chrome  

### Running the Script

```bash
python3 searcher.py <search_string> [--db /path/to/History]

# Search for all visits containing "login"
python3 searcher.py login

# Search using a specific History file
python3 searcher.py "example.com" --db "/Users/username/AppData/Local/Microsoft/Edge/User Data/Default/History"
