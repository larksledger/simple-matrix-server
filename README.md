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
  # 1. The Matrix Server (Conduit)
  conduit:
    image: matrixconduit/matrix-conduit:latest
    container_name: conduit
    restart: unless-stopped
    environment:
      # Replace with your actual domain
      CONDUIT_SERVER_NAME: "your-domain.com" # <--- EDIT THIS
      # Allow new users to register? (true/false)
      CONDUIT_ALLOW_REGISTRATION: "true"
      CONDUIT_ALLOW_FEDERATION: "false"
      CONDUIT_ALLOW_CHECK_FOR_UPDATES: "true"
      CONDUIT_TRUSTED_SERVERS: "[]"
      CONDUIT_ADDRESS: "0.0.0.0"
      CONDUIT_DATABASE_PATH: /var/lib/matrix-conduit/
      CONDUIT_PORT: 6167
      CONDUIT_MAX_REQUEST_SIZE: 20000000 # ~20MB file upload limit
      CONDUIT_CONFIG: ""
      CONDUIT_DATABASE_BACKEND: "rocksdb"
    ports:
      - "6167:6167"
    volumes:
      - ./conduit_db:/var/lib/matrix-conduit/
    networks:
      - matrix_net

  # 2. The Reverse Proxy (Caddy)
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8448:8448" # Required for Matrix Federation
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_data:/data
      - ./caddy_config:/config
    networks:
      - matrix_net

  # 3. Dynamic DNS Updater
  # A beginner-friendly container with a Web UI to manage your IP updates
  ddns-updater:
    image: qmcgaw/ddns-updater
    container_name: ddns-updater
    restart: unless-stopped
    ports:
      - "8000:8000" # Web UI accessible at http://localhost:8000
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
# 1. The Matrix Subdomain
# This handles the actual traffic and federation
matrix.your-domain.com, matrix.your-domain.com:8448 {
    reverse_proxy conduit:6167
    encode zstd gzip
}

# 2. The Root Domain (Opional)
your-domain.com {

    # OPTIONAL: Put a "Coming Soon" page here for your future website
    respond "This is my extensible home server! Matrix is running on the subdomain."
}
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

## Miscellaneous
- On openSuse, I had problems with docker and firewalld, and also with SELinux. My solution was to disable firewalld and temporarily `sudo setenforce 0`, so that docker can create the needed directories for the containers. 
