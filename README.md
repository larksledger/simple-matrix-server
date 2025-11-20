# My Matrix Homeserver

## Prerequisites

- **A Computer/Server**: This can be a Raspberry Pi, an old laptop running Linux, or your main Windows PC (running 24/7).

- **A Domain Name**: You need a domain (like my-chat-server.com). You can get one for cheap from Namecheap, Porkbun, or use a free one like DuckDNS.

- **Access to your Router**: You will need to change settings on your Wi-Fi router.

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

## 2. Create your Server Folder
1. Create a new folder on your computer named `matrix-server`
2. Inside this folder, you will create **two files** eith the exact names and contents below (alternatively you can `git clone` this repository, if you know what that means)

### File 1: `docker-compose.yml`
Create a file named `docker-compose.yml` and paste this code. 

**Change**: Replace `your-domain.com` in the `CONDUIT_SERVER_NAME` line with your actual domain.

```yaml
services:
  # The Matrix Server
  conduit:
    image: matrixconduit/matrix-conduit:latest
    container_name: conduit
    restart: unless-stopped
    environment:
      CONDUIT_SERVER_NAME: "your-domain.com" # <--- CHANGE THIS
      CONDUIT_ALLOW_REGISTRATION: "true"
      CONDUIT_DATABASE_PATH: /var/lib/matrix-conduit/
      CONDUIT_PORT: 6167
      CONDUIT_MAX_REQUEST_SIZE: 20000000
      CONDUIT_TRUSTED_SERVERS: '["matrix.org"]'
    volumes:
      - ./conduit_db:/var/lib/matrix-conduit/
    networks:
      - matrix_net

  # The Web Server & SSL Manager
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8448:8448"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_data:/data
      - ./caddy_config:/config
    networks:
      - matrix_net

  # Dynamic DNS Updater (Keeps your domain pointed to your home IP)
  ddns-updater:
    image: qmcgaw/ddns-updater
    container_name: ddns-updater
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./ddns_data:/updater/data
    networks:
      - matrix_net

networks:
  matrix_net:
```

### File 2: `Caddyfile`
Create a file named `Caddyfile` (no `.txt` extension!) and paste this code. 

**Change**: Replace **ALL 4** instances of `your-domain.com` with your actual domain name.

```
your-domain.com, your-domain.com:8448 {
    # 1. Handle Federation (.well-known delegation)
    # This tells other servers "I am here!"
    handle_path /.well-known/matrix/server {
        header Content-Type application/json
        header Access-Control-Allow-Origin *
        respond `{"m.server": "your-domain.com:443"}`
    }

    # 2. Handle Client Discovery
    # This tells your phone "The server is at this URL"
    handle_path /.well-known/matrix/client {
        header Content-Type application/json
        header Access-Control-Allow-Origin *
        respond `{"m.homeserver": {"base_url": "https://your-domain.com"}}`
    }

    # 3. Proxy traffic to Conduit
    reverse_proxy /_matrix/* conduit:6167
    reverse_proxy /_synapse/* conduit:6167

    # Enable compression for speed
    encode zstd gzip
}
```

## 3. Configure your Router (Port Forwarding)

For the outside world to see your server, you must open "doors" in your router.

1.Log in to your router (usually `192.168.1.1` or `192.168.0.1`).

2. Find **Port Forwarding** settings.

3. Forward the following ports to your computer's local IP address (e.g., `192.168.1.50`):

    - **Port 80** (TCP) -> Port 80

    - **Port 443** (TCP) -> Port 443

    - **Port 8448** (TCP) -> Port 8448

## 4. Start the Server
1. Open your terminal/PowerShell inside your `matrix-server` folder.
2. Run the start command:
```bash
docker compose up -d
```

## 5. Set up Dynamic DNS
1. Opem your web browser and go to `http://localhost:8000`
2. You will see the **DDNS Updater** interface.
3. Enter your domain provider's credentials (e.g. Namecheap, DuckDNS token).
4. This ensures that if your home internet IP changes, your domain will automatically find your new IP.

## 6. Connect Your Client
You can now use any Matrix client. We will use Element.

1. Download Element for your phone or computer.

2. Click Create Account.

3. Crucial Step: Look for "Edit", "Change", or "Custom Server".

    - By default, it selects `matrix.org`. You must change this!

    - Enter your domain: `https://your-domain.com`

4. Enter a username and password.

5. Click Register. You are now chatting on your own private server!

### ⚠️ Important Security Note

Once you have created your account, go back to `docker-compose.yml` and change: `CONDUIT_ALLOW_REGISTRATION: "false"`. Then run `docker compose up -d` again. This prevents strangers from creating accounts on your private server.
