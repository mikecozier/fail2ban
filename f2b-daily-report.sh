#!/bin/bash
i
TO_EMAIL="youremailhere@hotmail.com"
MUTTRC="/home/yourusername/mail/.muttrc"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
SUBJECT="🚨 Fail2Ban SSHD Report - $DATE"

# Dependencies
for cmd in jq geoiplookup curl fail2ban-client mutt journalctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing $cmd. Install it."; exit 1; }
done

# Banned IPs
BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep 'Banned IP list:' | cut -d ':' -f2- | tr -s ' ')
BANNED_IPS=$(echo "$BANNED_IPS" | tr ' ' '\n' | sort -u)
TOTAL_BANNED=$(echo "$BANNED_IPS" | wc -w)

declare -A COUNTRY_COUNT
BANNED_SUMMARY=""
VPN_COUNT=0

# Country name lookup
get_country_name() {
    case "$1" in
        US) echo "United States";;
        CN) echo "China";;
        RU) echo "Russia";;
        DE) echo "Germany";;
        IR) echo "Iran";;
        AU) echo "Australia";;
        AE) echo "UAE";;
        NL) echo "Netherlands";;
        SG) echo "Singapore";;
        PH) echo "Philippines";;
        KR) echo "South Korea";;
        CA) echo "Canada";;
        RO) echo "Romania";;
        GR) echo "Greece";;
        *) echo "$1";;
    esac
}

# Collect details per banned IP
if [ -n "$BANNED_IPS" ]; then
    for ip in $BANNED_IPS; do
        GEO=$(geoiplookup "$ip" | grep 'GeoIP Country' | awk -F': ' '{print $2}' | sed 's/^,//;s/,.*//' | xargs)
        CODE=$(echo "$GEO" | awk '{print $1}' | sed 's/,//g')
        COUNTRY_COUNT["$CODE"]=$((COUNTRY_COUNT["$CODE"] + 1))

        ORG=$(curl -s "https://ipinfo.io/$ip/json" | jq -r '.org // "Unknown"')
        VPN_FLAG="Unknown"
        if echo "$ORG" | grep -Ei 'vpn|digitalocean|ovh|amazon|linode|leaseweb|choopa|vultr|hetzner|contabo|akamai' >/dev/null; then
            VPN_FLAG="Likely"
            VPN_COUNT=$((VPN_COUNT + 1))
        elif echo "$ORG" | grep -Ei 'comcast|verizon|charter|spectrum|at&t|cox' >/dev/null; then
            VPN_FLAG="Unlikely"
        fi

        BANNED_SUMMARY+="\n - $ip ($CODE) | Org: $ORG | VPN: $VPN_FLAG\n   Abuse: https://www.abuseipdb.com/check/$ip"
    done
else
    BANNED_SUMMARY="No IPs currently banned."
fi

# Username attack analysis
# Top 10 usernames attempted in the last 7 days
USERNAMES=$(journalctl -u ssh --since "7 days ago" | grep 'Invalid user' | \
awk '{for (i=1;i<=NF;i++) if ($i=="user") print $(i+1)}' | sort | uniq -c | sort -nr | head -10)

TOTAL_USERS=$(echo "$USERNAMES" | wc -l)
MOST_TRIED_USER=$(echo "$USERNAMES" | head -1 | awk '{print $2}')

if [ -n "$USERNAMES" ]; then
    USER_SECTION="🧑‍💻 Top Usernames Attempted (Last 7 Days):\n$USERNAMES"
else
    USER_SECTION="🧑‍💻 Top Usernames Attempted:\nNo invalid usernames detected."
fi

# Country summary
COUNTRY_SUMMARY="🌐 Attacks by Country:"
while read -r code count; do
    NAME=$(get_country_name "$code")
    COUNTRY_SUMMARY+="\n - $code ($NAME): $count"
done < <(
    for c in "${!COUNTRY_COUNT[@]}"; do
        echo "$c ${COUNTRY_COUNT[$c]}"
    done | sort -k2 -nr
)

# Summary
SUMMARY="📊 Daily Intrusion Summary:
 - Total banned IPs: $TOTAL_BANNED
 - VPN-likely IPs: $VPN_COUNT
 - Countries involved: ${#COUNTRY_COUNT[@]}
 - Unique usernames attempted: $TOTAL_USERS
 - Most attacked username: ${MOST_TRIED_USER:-N/A}"

# Final body
BODY="Fail2Ban SSHD Report - $DATE

$SUMMARY

$COUNTRY_SUMMARY

🛡️ Banned IPs with GeoIP, VPN Flags, and Abuse Links:
$BANNED_SUMMARY

$USER_SECTION
"

# Archive to log file
LOGFILE="/var/log/fail2ban/sshd-report-$(date +%F).log"
echo -e "$BODY" >> "$LOGFILE"
BODY="$BODY\n\n🎯 Log Archived at: $LOGFILE"

# Send via mutt
echo -e "$BODY" | mutt -F "$MUTTRC" -s "$SUBJECT" -- "$TO_EMAIL"
