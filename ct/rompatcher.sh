#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: THEH0P
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/marcrobledo/RomPatcher.js

source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVED/raw/branch/main/misc/build.func)

APP="RomPatcher.js"
var_tags="romhacking;patcher;webapp"
var_cpu="1"
var_ram="512"
var_disk="3"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/rompatcher ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/marcrobledo/RomPatcher.js/releases/latest |
    grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"

    $STD systemctl stop rompatcher

    rm -rf /opt/rompatcher
    mkdir -p /opt/rompatcher

    TMP=$(mktemp -d)
    wget -q "https://github.com/marcrobledo/RomPatcher.js/archive/refs/tags/${RELEASE}.tar.gz" \
      -O "${TMP}/rompatcher.tar.gz"
    tar -xzf "${TMP}/rompatcher.tar.gz" --strip-components=1 -C /opt/rompatcher
    rm -rf "${TMP}"

    chown -R www-data:www-data /opt/rompatcher

    systemctl start rompatcher

    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
