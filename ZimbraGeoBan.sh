#!/bin/bash

# jq kontrolü ve yükleme
if ! command -v jq &> /dev/null; then
    echo "jq bulunamadı. Yükleniyor..."
    
    # Eğer apt-get varsa
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y jq
    
    # Eğer snap varsa
    elif command -v snap &> /dev/null; then
        sudo snap install jq
    
    # Eğer yum varsa
    elif command -v yum &> /dev/null; then
        sudo yum install jq
    
    else
        echo "jq yüklemek için uygun paket yöneticisi bulunamadı. Lütfen manuel olarak yükleyin."
        exit 1
    fi
fi

# Bugünün tarihini al
current_date=$(date +"%Y-%m-%d")
log_directory="logs"

# Log dizinini kontrol et ve oluştur
if [ ! -d "$log_directory" ]; then
    mkdir -p "$log_directory"
fi

# Log dosyasını oluştur ve tarihi ekleyerek aç
log_file="$log_directory/zimbra_ban_$current_date.log"
email_recipient="enes.sahin@dal.net.tr"
from_email="admin@enessahins.com.tr"   # change this 

# Banlanan ve Banlanmayan IP sayacı başlat
banlanan_ip_sayisi=0
banlanmayan_ip_sayisi=0

declare -A country_ban_count


echo -e "----- Banlama İşlemi Başlatıldı [$(date)] -----\n" >> "$log_file"

# Fonksiyon: IP bilgilerini al
get_ip_info() {
    ip_address=$1
    is_bogon=$2
    url="https://ipinfo.io/${ip_address}/json"
    response=$(curl -s "$url")

    if [ $? -eq 0 ]; then
        country=$(echo "$response" | jq -r '.country // "Bilinmiyor"')
        ip=$(echo "$response" | jq -r '.ip // "Bilinmiyor"')

        if [ "$country" == "TR" ] || [ "$country" == "Bilinmiyor" ] || [ "$is_bogon" == "true" ]; then
            echo -e "$(date) - $ip Adresi ($country): Banlanmadı\n" >> "$log_file"
            ((banlanmayan_ip_sayisi++))
        else
            fail2ban-client -vvv set zimbra-web banip $ip
            fail2ban-client -vvv set zimbra-smtp banip $ip
            echo -e "$(date) - $ip Adresi ($country): Banlandı\n" >> "$log_file"
            ((banlanan_ip_sayisi++))
            ((country_ban_count["$country"]++))
        fi
    else
        echo "$(date) - $ip Adresi (Bilinmiyor): Hata - Veri alınamadı." >> "$log_file"
    fi
}

# login girisi yapanlari tespit et
cat /var/log/zimbra.log | grep "authentication failed" | awk -F'[][]' '/\[.*\]/{gsub(/.*\[/,"",$4); print $4}' | grep -v [a-z] | sort | uniq > iplistesi.txt

# smtp uzerinden baglanan yabanci IP adreslerini tespit et
#awk '/ connect from/ {print $8}' /var/log/mail.log | grep unknown | awk '{print $1}' | cut -d[ -f2 | cut -d] -f1 | sort | uniq >> iplistesi.txt
awk '/ connect from/ {print $8}' /var/log/mail.log | awk -F '[][]' '{print $2}' | sort | uniq >> iplistesi.txt


# birlestir ayni IP adreslerini filitrele
cat iplistesi.txt | sort | uniq | tee iplistesi.txt

# IP bilgilerini almak için iplistesi.txt dosyasını oku
while IFS= read -r ip_address; do
    get_ip_info "$ip_address"
done < iplistesi.txt

echo -e "----- Banlama İşlemi Tamamlandı [$(date)] -----\n" >> "$log_file"
echo "Toplam Banlanan IP Sayısı: $banlanan_ip_sayisi" >> "$log_file"
echo "Toplam Banlanmayan IP Sayısı: $banlanmayan_ip_sayisi" >> "$log_file"

for country in "${!country_ban_count[@]}"; do
    echo "Toplam $country ülkesinden banlanan IP sayısı: ${country_ban_count[$country]}" >> "$log_file"
    echo -e "-----------------------------------\n\n" >> "$log_file"

done

# E-posta gönderme fonksiyonu
send_email() {
    # E-posta başlık ve içeriği
    email_subject="Zimbra Ban Script - $current_date Tarama Raporu - `hostname`"
    email_content="Merhaba,\n\nZimbra Ban Script günlük rapor:\n\n$(cat "$log_file")\n\nSaygılarımla"


    # E-posta başlık ve içeriğini birleştir
    email_header="Subject: $email_subject\nFrom: $from_email\nTo: $email_recipient\n"

    # E-postayı gönder
    echo -e "$email_header\n$email_content" | /usr/sbin/sendmail -f "$from_email" "$email_recipient"
}

# E-posta gönderme fonksiyonunu çağır
send_email
