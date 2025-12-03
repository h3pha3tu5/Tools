#!/usr/bin/env bash
# Chrome/Edge History & Downloads Search
# Author: h3paetus

set -e

if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "Error: sqlite3 is not installed or not in PATH."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <search_string> [history_db_file]"
    exit 1
fi

SEARCH="$1"
DB_FILE="${2:-History}"  # default to 'History' in current directory

# Check file exists
if [ ! -f "$DB_FILE" ]; then
    echo "Error: History file '$DB_FILE' not found."
    exit 1
fi

# Decode transition
decode_transition() {
    local t=$1
    (( t &= 0xFFFFFFFF ))
    local core=$(( t & 0xFF ))
    local q=$(( t & ~0xFF ))
    local label=""
    case $core in
        0) label="LINK" ;;
        1) label="TYPED" ;;
        2) label="AUTO_BOOKMARK" ;;
        3) label="AUTO_SUBFRAME" ;;
        4) label="MANUAL_SUBFRAME" ;;
        5) label="GENERATED" ;;
        6) label="START_PAGE" ;;
        7) label="FORM_SUBMIT" ;;
        8) label="RELOAD" ;;
        *) label="UNKNOWN_CORE($core)" ;;
    esac
    (( (q & 0x00800000) != 0 )) && label+=" FORWARD_BACK"
    (( (q & 0x01000000) != 0 )) && label+=" FROM_ADDRESS_BAR"
    (( (q & 0x02000000) != 0 )) && label+=" HOME_PAGE"
    (( (q & 0x04000000) != 0 )) && label+=" FROM_API"
    (( (q & 0x08000000) != 0 )) && label+=" CHAIN_START"
    (( (q & 0x10000000) != 0 )) && label+=" CHAIN_END"
    (( (q & 0x20000000) != 0 )) && label+=" CLIENT_REDIRECT"
    (( (q & 0x40000000) != 0 )) && label+=" SERVER_REDIRECT"
    echo "$label"
}

convert_chrome_time() {
    local t=$1
    local unix_time=$(( t / 1000000 - 11644473600 ))
    if date --version >/dev/null 2>&1; then
        date -d "@$unix_time" '+%Y-%m-%d %H:%M:%S'
    else
        date -r $unix_time '+%Y-%m-%d %H:%M:%S'
    fi
}

safe_render() {
    local input="$1"
    echo -n "$input" | perl -pe 's/([^\x20-\x7E])/sprintf("\\x%02X",ord($1))/ge'
}

# Query visits
VISIT_RESULTS=$(sqlite3 -csv -noheader "$DB_FILE" "
SELECT urls.url, visits.visit_time, visits.transition,
       COALESCE(referrer.url,'') AS ref_url,
       COALESCE(visit_source.source,'') AS vsource
FROM urls
JOIN visits ON urls.id = visits.url
LEFT JOIN visits AS ref_visit ON visits.from_visit = ref_visit.id
LEFT JOIN urls AS referrer ON ref_visit.url = referrer.id
LEFT JOIN visit_source ON visits.id = visit_source.id
WHERE urls.url LIKE '%$SEARCH%'
ORDER BY visits.visit_time DESC;
")

# Query downloads + url chains
DOWNLOAD_RESULTS=$(sqlite3 -csv -noheader "$DB_FILE" "
SELECT downloads.current_path,
       GROUP_CONCAT(downloads_url_chains.url, ' -> ')
FROM downloads
LEFT JOIN downloads_url_chains
       ON downloads.id = downloads_url_chains.id
WHERE downloads_url_chains.url LIKE '%$SEARCH%'
   OR downloads.current_path LIKE '%$SEARCH%'
GROUP BY downloads.id;
")

# Store downloads in a list of strings
DOWNLOAD_LIST=()
while IFS=, read -r d_path d_chain; do
    DOWNLOAD_LIST+=("$d_path|||$d_chain")
done <<< "$DOWNLOAD_RESULTS"

# Process visits
while IFS=, read -r url visit_time transition ref_url vsource; do
    echo
    echo "================================================================================"
    echo
    echo "Visited URL:   $(safe_render "$url")"
    echo "Timestamp:     $(convert_chrome_time "$visit_time")"
    echo "Referrer URL:  $(safe_render "$ref_url")"
    echo "Visit Source:  $(safe_render "$vsource")"
    echo "Transition:    $(decode_transition "$transition")"
    echo
    echo "--------------------------------------------------------------------------------"
    echo

    found_downloads=false
    for val in "${DOWNLOAD_LIST[@]}"; do
        file_path="${val%%|||*}"
        url_chain="${val#*|||}"
        if [[ "$url_chain" == *"$SEARCH"* ]] || [[ "$url" == *"$SEARCH"* ]]; then
            found_downloads=true
            echo "Downloaded File Path: $(safe_render "$file_path")"
            if [[ -n "$url_chain" ]]; then
                echo "URL Chain:           $(safe_render "$url_chain")"
            fi
            echo
        fi
    done
    if ! $found_downloads; then
        echo "No associated downloads found."
    fi
done <<< "$VISIT_RESULTS"

echo
echo "================================================================================"
echo
