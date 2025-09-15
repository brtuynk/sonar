#!/bin/bash
set -e

SONAR_DIR="/opt/sonarqube"

echo "🛠️ Docker ve docker-compose kuruluyor..."
apt update
apt install -y docker.io docker-compose

echo "📁 SonarQube dizini oluşturuluyor..."
mkdir -p $SONAR_DIR

echo "📂 Docker-compose ve .env dosyaları $SONAR_DIR içine kopyalanıyor..."
cp ./docker-compose.yml $SONAR_DIR/
cp ./.env $SONAR_DIR/

cd $SONAR_DIR

echo "🚀 SonarQube servisleri başlatılıyor..."
docker-compose up -d

echo "📝 systemd servisi oluşturuluyor..."

cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=$SONAR_DIR
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
RemainAfterExit=yes
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

echo ""
echo "✅ Kurulum tamamlandı!"
echo "🌐 SonarQube'e erişmek için makinenizin IP adresini veya alan adını 9000 portu ile kullanabilirsiniz."
echo "   Örnek: http://<makine_ip_adresi>:9000"
echo "🛠 Servis yönetimi için:"
echo "   systemctl status sonarqube"
echo "   systemctl restart sonarqube"