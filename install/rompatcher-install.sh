#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: THEH0P
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/marcrobledo/RomPatcher.js

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
APP="RomPatcher"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  git \
  nginx \
  nano
msg_ok "Installed Dependencies"

msg_info "Fetching Latest ${APP} Release"
RELEASE=$(curl -fsSL https://api.github.com/repos/marcrobledo/RomPatcher.js/releases/latest |
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
msg_ok "Latest release: v${RELEASE}"

msg_info "Downloading ${APP} v${RELEASE}"
mkdir -p /opt/rompatcher
TMP=$(mktemp -d)
wget -q "https://github.com/marcrobledo/RomPatcher.js/archive/refs/tags/${RELEASE}.tar.gz" \
  -O "${TMP}/rompatcher.tar.gz"
tar -xzf "${TMP}/rompatcher.tar.gz" --strip-components=1 -C /opt/rompatcher
rm -rf "${TMP}"
msg_ok "Downloaded and extracted ${APP}"

msg_info "Setting Permissions"
chown -R www-data:www-data /opt/rompatcher
chmod -R 755 /opt/rompatcher
find /opt/rompatcher -type f -exec chmod 644 {} \;
msg_ok "Permissions set"

msg_info "Configuring Nginx"
cat >/etc/nginx/sites-available/rompatcher <<'EOF'
server {
    listen 80;
    server_name _;

    root /opt/rompatcher;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|ico|svg|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    client_max_body_size 512M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
}
EOF

ln -sf /etc/nginx/sites-available/rompatcher /etc/nginx/sites-enabled/rompatcher
rm -f /etc/nginx/sites-enabled/default
$STD systemctl enable nginx
$STD systemctl restart nginx
msg_ok "Nginx configured"

msg_info "Creating systemd Service"
cat >/etc/systemd/system/rompatcher.service <<'EOF'
[Unit]
Description=RomPatcher.js Web Server (nginx)
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PIDFile=/run/nginx.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
$STD systemctl enable --now nginx
msg_ok "Service enabled and started"

echo "${RELEASE}" >/opt/${APP}_version.txt

motd_ssh
customize
cleanup_lxc
