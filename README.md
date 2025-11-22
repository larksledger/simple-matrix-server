# My Matrix Homeserver

This repo is designed to hopefully be an accessible resource on how you could host your own [Matrix](https://matrix.org/) server, so that you can have private, end-to-end encrypted chats with your friends and families and don't need to trust companies to not infringe on your privacy.

If you follow this guide, by the end you will have a

- Matrix server, [Dendrite](https://github.com/element-hq/dendrite) to be exact
- Your own, free domain, which will always point to your network, even if your ISP-assigned IP changes regularly
- As a reverse proxy, [Caddy](https://caddyserver.com/), which automatically cares about https certificates, redirects `matrix.yourdomain.org` to your matrix server and is a solid piece of infrastructure if you ever want to host more self-hosted services

## Prerequisites

- **A Computer/Server**: This can be a Raspberry Pi, an old laptop running Linux, or your main Windows PC (running 24/7).

- **A Domain Name**: You need a domain (like my-chat-server.com). You can get one for cheap from Namecheap, Porkbun, or use a free one like DuckDNS.

- **Access to your Router**: You will need to change settings on your Wi-Fi router.
  - Namely, you need to forward ports **80** and **443** to ports **80** and **443** on your server.

---

## 1. Install Docker & Docker Compose

Before creating files, you need the engine that runs them.

### 🪟 For Windows Users

1. Download and install Docker Desktop for Windows.

2. During installation, ensure **WSL 2** (Windows Subsystem for Linux) is selected.

3. Once installed, open Docker Desktop to ensure it's running.

4. Open PowerShell and type `docker compose version` to verify it's working.

### 🐧 For Linux Users (Ubuntu/Debian)
Run these commands in your terminal to install Docker and the Compose plugin:
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 🐧 For Linux Users (other)
You probably already know how to install Docker in your Distro.

## 2. Setup
### Automatic Setup
The most convenient way of setting the server up is cloning this repository, changing into `simple-matrix-server` and executing the included setup script:
```bash
git clone https://github.com/larksledger/simple-matrix-server
cd simple-matrix-server
bash setup.sh
```

This will setup the server with some opinionated defaults, which you may disagree with.
The setup will ask you for your preferred subdomain for the matrix server and your domain name. For examplem, if you registered `yourdomain.duckdns.org` with duckdns, you would answer the script something like this:

```bash
Enter the subdomain prefix (e.g., chat, matrix): matrix
Enter your domain name (e.g., mydomain.net): yourdomain.duckdns.org
```

This configures the server such that matrix clients would need to connect to `matrix.yourdomain.duckdns.org`.

#### Manual post-setup
The setup sript cannot perform everything for you. The configuration for the dynamical DNS will still be missing, as it varies with each DynDNS provider and there are many of these providers. The configuration is in `ddns_data/config.json`. You can refer to the [documentation](https://github.com/qdm12/ddns-updater/tree/master/docs) for your provider to fill in the blanks. 

### Manual setup
TODO

## 3. Post Setup
### Adding users
By default, registration of new users is disabled. If you want to add users, you have to add them with the `create-account` utility in the dendrite container. For your convenience, there is the `add_user.sh` script that makes this interaction a little faster.

## TODOs
- Federation
- TURN server
