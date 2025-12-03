import sqlite3
import argparse
from datetime import datetime

def decode_transition(t):
    t &= 0xFFFFFFFF
    core_types = {
        0: "LINK", 1: "TYPED", 2: "AUTO_BOOKMARK", 3: "AUTO_SUBFRAME",
        4: "MANUAL_SUBFRAME", 5: "GENERATED", 6: "START_PAGE",
        7: "FORM_SUBMIT", 8: "RELOAD",
    }
    qualifiers = {
        0x00800000: "FORWARD_BACK", 0x01000000: "FROM_ADDRESS_BAR",
        0x02000000: "HOME_PAGE", 0x04000000: "FROM_API", 0x08000000: "CHAIN_START",
        0x10000000: "CHAIN_END", 0x20000000: "CLIENT_REDIRECT", 0x40000000: "SERVER_REDIRECT",
    }
    core = t & 0xFF
    q = t & ~0xFF
    decoded = [core_types.get(core, f"UNKNOWN_CORE({core})")]
    for mask, name in qualifiers.items():
        if q & mask:
            decoded.append(name)
    return decoded

def safe_render(raw_string: str) -> str:
    raw_bytes = raw_string.encode("utf-8", errors="replace")
    decoded = raw_bytes.decode("unicode_escape", errors="backslashreplace")
    decoded = decoded.replace("\x1b", "\\x1b")
    return ''.join(c if c.isprintable() else f'\\x{ord(c):02x}' for c in decoded)

def main():
    parser = argparse.ArgumentParser(
        description="Search History and Downloads for URLs target string."
    )
    parser.add_argument(
        "search_string",
        type=str,
        nargs='?',
        help="Substring to search for in URLs or download URLs"
    )
    parser.add_argument(
        "--db",
        type=str,
        default="History",
        help="Path to History SQLite file (default: ./History)"
    )
    args = parser.parse_args()

    if not args.search_string:
        parser.print_usage()
        print("Error: You must provide a search string.")
        return

    search_string = args.search_string
    db_file = args.db

    try:
        conn = sqlite3.connect(db_file)
    except sqlite3.Error as e:
        print(f"Error opening database '{db_file}': {e}")
        return

    cursor = conn.cursor()

    visit_query = """
    SELECT 
        urls.url AS visited_url,
        DATETIME(visits.visit_time/1000000 - 11644473600, 'unixepoch') AS visit_timestamp,
        referrer.url AS referrer_url,
        visit_source.source AS visit_source_type,
        visits.transition AS transition_type
    FROM urls
    JOIN visits 
        ON urls.id = visits.url
    LEFT JOIN visits AS ref_visit
        ON visits.from_visit = ref_visit.id
    LEFT JOIN urls AS referrer
        ON ref_visit.url = referrer.id
    LEFT JOIN visit_source 
        ON visits.id = visit_source.id
    WHERE urls.url LIKE '%' || ? || '%'
    ORDER BY visits.visit_time DESC;
    """

    cursor.execute("PRAGMA table_info(downloads_url_chains);")
    columns = [row[1] for row in cursor.fetchall()]
    if 'download_id' in columns:
        join_column = 'download_id'
    elif 'id' in columns:
        join_column = 'id'
    else:
        print("Error: downloads_url_chains table does not have a joinable column.")
        conn.close()
        return

    download_query = f"""
    SELECT 
        downloads.current_path,
        GROUP_CONCAT(downloads_url_chains.url, ' -> ') AS url_chain
    FROM downloads
    LEFT JOIN downloads_url_chains
        ON downloads.id = downloads_url_chains.{join_column}
    WHERE downloads_url_chains.url LIKE '%' || ? || '%'
    GROUP BY downloads.id
    ORDER BY downloads.start_time DESC;
    """

    try:
        cursor.execute(visit_query, (search_string,))
        visit_results = cursor.fetchall()
        cursor.execute(download_query, (search_string,))
        download_results = cursor.fetchall()
    except sqlite3.Error as e:
        print(f"Error executing query: {e}")
        conn.close()
        return

    downloads_by_url = []
    for file_path, url_chain in download_results:
        downloads_by_url.append((file_path, url_chain))

    if visit_results:
        for row in visit_results:
            visited_url, timestamp, referrer, source, transition = row

            print("\n" + "="*80 + "\n")

            print("Visited URL:   ", safe_render(visited_url))
            print("Timestamp:     ", timestamp)
            print("Referrer URL:  ", safe_render(referrer) if referrer else None)
            print("Visit Source:  ", safe_render(str(source)) if source else None)
            print("Transition:    ", decode_transition(transition))

            print("\n" + "-"*80 + "\n")

            matched = False
            for file_path, url_chain in downloads_by_url:
                if search_string in url_chain or search_string in visited_url:
                    matched = True
                    print("Downloaded File Path: ", safe_render(file_path))
                    if url_chain:
                        print("URL Chain:           ", safe_render(url_chain))
                    print()  
            if not matched:
                print("No associated downloads found.")

        print("\n" + "="*80 + "\n")
    else:
        print(f"No URL visit results found for '{search_string}'.")

    conn.close()

if __name__ == "__main__":
    main()
