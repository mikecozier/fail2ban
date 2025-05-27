## 📄 `README.md`

````markdown
# 🔐 Fail2Ban SSHD Report Script

A lightweight Bash script that generates a daily report of SSH brute-force attempts blocked by Fail2Ban, enriched with GeoIP, ISP details, and VPN detection — and sends it via email.

---

## 📊 What It Does

- 🕵️ Lists all IPs banned by Fail2Ban's `sshd` jail
- 🌍 Uses `geoiplookup` to identify the attacker's country
- 🏢 Looks up ISP/org data with `ipinfo.io`
- 🧠 Flags likely VPNs and data center origins
- 📌 Includes AbuseIPDB links for each IP
- 🌐 Summarizes attack patterns by country and username
- ✉️ Emails a daily report with all findings
- 🗂 Archives reports locally by date

---

## 📦 Output Sample

```text
📊 Daily Intrusion Summary:
 - Total banned IPs: 34
 - VPN-likely IPs: 10
 - Countries involved: 14
 - Unique usernames attempted: 10
 - Most attacked username: from

🌐 Attacks by Country:
 - US (United States): 13
 - CN (China): 6
 - RU (Russia): 3
...

🧑‍💻 Top Usernames Attempted (Last 7 Days):
    8 from
    5 ubuntu
    4 support
...

🛡️ Banned IPs:
 - 134.209.56.195 (US) | Org: DigitalOcean | VPN: Likely
   Abuse: https://www.abuseipdb.com/check/134.209.56.195
...
````

---

## ⚙️ Requirements

Install the following tools:

* `fail2ban`
* `geoip-bin`
* `jq`
* `curl`
* `mutt`
* `journalctl` (from `systemd`)

### On Ubuntu/Debian:

```bash
sudo apt install fail2ban geoip-bin jq curl mutt
```

---

## 📬 Setup

1. Clone the repo and copy the script:

   ```bash
   git clone https://github.com/yourusername/fail2ban-sshd-report.git
   cd fail2ban-sshd-report
   ```

2. Edit the script and set:

   * `TO_EMAIL` to your destination email
   * `MUTTRC` to your `.muttrc` config path

3. Make executable:

   ```bash
   chmod +x f2b-daily-report.sh
   ```

4. (Optional) Test run manually:

   ```bash
   ./f2b-daily-report.sh
   ```

5. Add to `cron` for daily reports:

   ```bash
   crontab -e
   ```

   Add this line to run at 6AM daily:

   ```
   0 6 * * * /path/to/f2b-daily-report.sh
   ```

---

## 📁 Logs

Reports are also saved locally to:

```
/var/log/fail2ban/sshd-report-YYYY-MM-DD.log
```

---

## 🔐 Author

**Michael Cozier**
DevOps Intern | Linux & Automation Enthusiast

---

## 🛡️ License

MIT License. Feel free to modify and adapt.
