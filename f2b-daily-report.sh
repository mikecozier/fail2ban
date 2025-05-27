#!/bin/bash

TO_EMAIL="youremail@hotmail.com"
MUTTRC="/home/usernamehere/mail/.muttrc"

# Timestamp
DATE=$(date '+%Y-%m-%d %H:%M:%S')
SUBJECT="🚨 Fail2Ban SSHD Report - $DATE"

# Get banned IPs from Fail2Ban
BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep 'Banned IP list:' | cut -d ':' -f2- | tr -s ' ')
BANNED_SUMMARY="No IPs currently banned."

if [ -n "$BANNED_IPS" ]; then
    BANNED_SUMMARY="Banned IPs with GeoIP:"
    for ip in $BANNED_IPS; do
        LOCATION=$(geoiplookup "$ip" | cut -d ':' -f2-)
        BANNED_SUMMARY+="\n - $ip (${LOCATION})"
    done
fi

# Top usernames attempted
USERNAMES=$(journalctl _SYSTEMD_UNIT=ssh.service | grep 'Invalid user' | awk '{for (i=1;i<=NF;i++) if ($i=="user") print $(i+1)}' | sort | uniq -c | sort -nr | head -10)
USER_SECTION="Top Usernames Attempted:\n$USERNAMES"

# Compose email body
BODY="Fail2Ban SSHD Report - $DATE

$BANNED_SUMMARY

$USER_SECTION
"

# Send the report via mutt with custom config
echo -e "$BODY" | mutt -F "$MUTTRC" -s "$SUBJECT" -- "$TO_EMAIL"

