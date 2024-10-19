# ZimbraGeoBan

ZimbraGeoBan is a bash script that automates the banning of unauthorized or suspicious IP addresses connecting to a Zimbra server. It identifies failed authentication attempts and unwanted SMTP connections from non-Turkish (non-TR) IPs and bans them using `fail2ban`. The script also generates a daily log and sends an email report.

## Features

- Automatically bans IPs that fail to authenticate or connect to Zimbra services.
- Filters and excludes IPs from Turkey (TR) and bogon addresses (private IP ranges).
- Bans IPs via `fail2ban` for both Zimbra web (`zimbra-web`) and Zimbra SMTP (`zimbra-smtp`) services.
- Generates daily logs of the banned and unbanned IPs.
- Sends an email report with the number of banned IPs, categorized by country.

## Prerequisites

- **Zimbra**: Make sure Zimbra is installed and configured.
- **Fail2Ban**: Ensure `fail2ban` is installed and properly set up with rules for `zimbra-web` and `zimbra-smtp`.
- **jq**: The script requires `jq` to parse JSON data.

## Installation

1. Clone the repository or download the script.
    ```bash
    git clone https://github.com/enessahins/ZimbraGeoBan.git
    ```

2. Ensure the script has executable permissions.
    ```bash
    chmod +x ZimbraGeoBan.sh
    ```

3. Install `jq` if it's not already installed. The script automatically checks for `jq` and installs it using the appropriate package manager (`apt-get`, `yum`, or `snap`).

## Usage

1. Edit the script to set the correct email addresses.
    - Update the `from_email` variable with your admin email address.
    - Update the `email_recipient` with the email address that should receive the daily report.

2. Run the script manually:
    ```bash
    ./ZimbraGeoBan.sh
    ```

   Or schedule it to run daily using a cron job:
    ```bash
    crontab -e
    ```

    Add the following line to run it every day at midnight:
    ```bash
    0 0 * * * /path/to/ZimbraGeoBan.sh
    ```

## How It Works

- The script checks `/var/log/zimbra.log` for failed authentication attempts and `/var/log/mail.log` for SMTP connections.
- It uses `curl` to fetch geographic data from `ipinfo.io` and determines whether to ban an IP based on the country.
- IPs from Turkey (`TR`) or bogon IPs (private addresses) are not banned, but all others are banned using `fail2ban`.
- A log is maintained in the `logs` directory, with separate logs created for each day.
- An email report is sent summarizing the ban activity for the day, including the number of IPs banned per country.

## Log and Email Report

- Logs are stored in the `logs` directory and named `zimbra_ban_YYYY-MM-DD.log` based on the current date.
- The email report includes:
  - The total number of banned and unbanned IPs.
  - A breakdown of banned IPs by country.

## Customization

- **Log Directory**: Change the log directory by modifying the `log_directory` variable.
- **Email Settings**: Modify the `from_email` and `email_recipient` variables for custom email addresses.
- **Ban Conditions**: To adjust the countries or conditions for banning IPs, modify the `get_ip_info` function where country checks occur.

## Example Log Output

***
----- Banlama İşlemi Başlatıldı [2024-10-19 12:00:00] -----

2024-10-19 12:01:02 - 192.0.2.1 Adresi (US): Banlandı 2024-10-19 12:02:15 - 198.51.100.1 Adresi (FR): Banlandı 2024-10-19 12:03:44 - 203.0.113.1 Adresi (TR): Banlanmadı

----- Banlama İşlemi Tamamlandı [2024-10-19 12:04:00] ----- Toplam Banlanan IP Sayısı: 2 Toplam Banlanmayan IP Sayısı: 1 Toplam US ülkesinden banlanan IP sayısı: 1 Toplam FR ülkesinden banlanan IP sayısı: 1
***


For installation Fail2ban for Zimbra
https://blog.zimbra.com/2022/08/configuring-fail2ban-on-zimbra/
