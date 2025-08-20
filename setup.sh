#!/bin/bash
set -e

SONAR_DIR="/opt/sonarqube"
DOMAIN_NAME="sonarqube.hepapi.com"

echo "🛠️ Docker, docker-compose ve nginx kuruluyor..."
apt update
apt install -y docker.io docker-compose nginx

echo "📁 SonarQube dizini oluşturuluyor..."
mkdir -p $SONAR_DIR

echo "📂 Docker-compose dosyasını $SONAR_DIR içine kopyalayın ve bu script'i orada çalıştırın."
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

echo "🌐 NGINX konfigürasyonu hazırlanıyor..."

cat <<EOF > /etc/nginx/sites-available/sonarqube
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
nginx -t && systemctl reload nginx

echo "🧹 Varsayılan NGINX konfigürasyonu kaldırılıyor..."
rm -f /etc/nginx/sites-enabled/default

echo ""
echo "✅ Kurulum tamamlandı!"
echo "🌐 SonarQube http://$DOMAIN_NAME adresinden erişilebilir."
echo "🛠 Servis yönetimi için:"
echo "   systemctl status sonarqube"
echo "   systemctl restart sonarqube"
