## S-UI
Advanced Web Panel built on `SagerNet/Sing-Box`, based on the last version of `alireza0/s-ui`.

> **Disclaimer:** This project is for personal learning and communication only, please do not use it for illegal purposes.

## Quick Overview
| Feature | Supported |
| -------------------------------------- | :----------------: |
| Multi-protocol | :heavy_check_mark: |
| Multi-language | :heavy_check_mark: |
| Multi-client/Inbound | :heavy_check_mark: |
| Advanced Traffic Routing Interface | :heavy_check_mark: |
| Client, Traffic, and System Status | :heavy_check_mark: |
| Subscription Links (link/json/clash + info) | :heavy_check_mark: |
| Dark/Light Theme | :heavy_check_mark: |
| API Interface | :heavy_check_mark: |

## Supported Platforms
| Platform | Architecture | Status |
|----------|--------------|---------|
| Linux | amd64, arm64, armv7, armv6, armv5, 386, s390x | Supported |
| Windows | amd64, 386, arm64 | Supported |
| macOS | amd64, arm64 | Experimental Support |

## Default Installation Info
- Panel Port: 2095
- Panel Path: /app/
- Subscription Port: 2096
- Subscription Path: /sub/
- Username/Password: admin

## Install or Upgrade to the Latest Version

### Linux/macOS
```sh
bash <(curl -Ls https://raw.githubusercontent.com/admin8800/s-ui/main/install.sh)
```

### Windows
1. Download the latest Windows version from [GitHub Releases](https://github.com/admin8800/s-ui/releases/latest).
2. Extract the ZIP file.
3. Run `install-windows.bat` as an administrator.
4. Follow the installation wizard.

## Install Older Versions

**Step 1:** To install a specific older version, append the version tag with `v` at the end of the installation command. For example, version `v1.0.0`:

## Manual Installation

### Linux/macOS
1. Get the latest version of S-UI for your system and architecture from GitHub: [https://github.com/admin8800/s-ui/releases/latest](https://github.com/admin8800/s-ui/releases/latest)
2. **Optional:** Get the latest `s-ui.sh`: [https://raw.githubusercontent.com/admin8800/s-ui/main/s-ui.sh](https://raw.githubusercontent.com/admin8800/s-ui/main/s-ui.sh)
3. **Optional:** Copy `s-ui.sh` to `/usr/bin/` and execute `chmod +x /usr/bin/s-ui`.
4. Extract the s-ui tar.gz file to your chosen directory and enter the extracted directory.
5. Copy the `*.service` file to `/etc/systemd/system/`, then execute `systemctl daemon-reload`.
6. Use `systemctl enable s-ui --now` to enable start on boot and start the S-UI service.
7. Use `systemctl enable sing-box --now` to start the sing-box service.

### Windows
1. Get the latest Windows version from GitHub: [https://github.com/admin8800/s-ui/releases/latest](https://github.com/admin8800/s-ui/releases/latest)
2. Download the appropriate Windows package, e.g., `s-ui-windows-amd64.zip`.
3. Extract the ZIP file to your chosen directory.
4. Run `install-windows.bat` as an administrator.
5. Follow the installation wizard.
6. Access the panel: http://localhost:2095/app

## Uninstall S-UI

```sh
sudo -i

systemctl disable s-ui --now

rm -f /etc/systemd/system/sing-box.service
systemctl daemon-reload

rm -fr /usr/local/s-ui
rm /usr/bin/s-ui
```

## Install with Docker

<details>
   <summary>Click to view details</summary>

### Usage

**Step 1:** Install Docker

```shell
curl -fsSL https://get.docker.com | sh
```

**Step 2:** Install S-UI

> Docker compose method

```shell
services:
  s-ui:
    image: ghcr.io/admin8800/s-ui
    container_name: s-ui
    hostname: "s-ui"
    network_mode: host
    volumes:
      - "./db:/app/db"
      - "./cert:/app/cert"
    tty: true
    restart: unless-stopped
    entrypoint: "./entrypoint.sh"
```
`docker compose up -d`

> Direct docker usage

```shell
mkdir s-ui && cd s-ui

docker run -itd \
    --network host \
    -v $PWD/db/:/app/db/ \
    -v $PWD/cert/:/root/cert/ \
    --name s-ui \
    --restart=unless-stopped \
    ghcr.io/admin8800/s-ui
```

> Build image yourself

```shell
git clone https://github.com/admin8800/s-ui
docker build -t s-ui .
```

</details>

## Manual Run (Contributing to Development)

<details>
   <summary>Click to view details</summary>

### Build and Run the Complete Project
```shell
./runSUI.sh
```

### Clone Repository
```shell
# Clone repository
git clone https://github.com/admin8800/s-ui
```

### - Frontend
For frontend code, please see [frontend](frontend).

### - Backend
> Please build the frontend at least once first.

Build Backend:
```shell
# Remove old frontend build files
rm -fr web/html/*
# Apply new frontend build files
cp -R frontend/dist/ web/html/
# Build
go build -o sui main.go
```

Run Backend (execute in the repository root):
```shell
./sui
```

</details>

## Languages
- English
- Persian
- Vietnamese
- Simplified Chinese
- Traditional Chinese
- Russian

## Features
- Supported Protocols:
  - General Protocols: Mixed, SOCKS, HTTP, HTTPS, Direct, Redirect, TProxy
  - V2Ray-based Protocols: VLESS, VMess, Trojan, Shadowsocks
  - Other Protocols: ShadowTLS, Hysteria, Hysteria2, Naive, TUIC
- Supports XTLS protocol.
- Provides an advanced traffic routing interface, supporting PROXY Protocol, External, transparent proxy, SSL certificates, and port configuration.
- Provides advanced inbound and outbound configuration interfaces.
- Supports client traffic limits and expiration times.
- Displays online clients, inbound/outbound traffic statistics, and system status monitoring.
- Subscription service supports adding external links and subscriptions.
- Web panel and subscription service support HTTPS secure access (requires your own domain and SSL certificate).
- Dark/Light themes.

## Environment Variables

<details>
  <summary>Click to view details</summary>

### Usage

| Variable | Type | Default Value |
| -------------- | :--------------------------------------------: | :------------ |
| SUI_LOG_LEVEL | `"debug"` \| `"info"` \| `"warn"` \| `"error"` | `"info"` |
| SUI_DEBUG | `boolean` | `false` |
| SUI_BIN_FOLDER | `string` | `"bin"` |
| SUI_DB_FOLDER | `string` | `"db"` |
| SINGBOX_API | `string` | - |

</details>

## SSL Certificates

<details>
  <summary>Click to view details</summary>

### Certbot

```bash
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

certbot certonly --standalone --register-unsafely-without-email --non-interactive --agree-tos -d <your-domain>
```

</details>

#### Credits to the original author: alireza0
