# OpenWA QR Proxy - Multi-Instance Support

## About

This project provides a **QR proxy for OpenWA** with support for **multiple instances**. It allows you to:

- Run multiple WhatsApp sessions simultaneously on different ports
- Capture the QR code for login without using the terminal
- Serve the QR code as a **PNG** for frontend integration (`/qr.png`) or as JSON (`/qr` or `/qr/raw`)
- Track login/session status through a `/status` endpoint
- Enable a **Python socket client** to safely connect once the session is ready
- Automatically handle OpenWA lifecycle events (`qr`, `authenticated`, `ready`, `auth_failure`, and `STARTUP` events)

---

## Features

### Multi-Instance Support
- **Multiple sessions** - Run different WhatsApp accounts on separate ports
- **Isolated configurations** - Each instance has its own port, API key, and session folder
- **Easy management** - Start, stop, and restart individual instances or all at once

### Proxy Endpoints (per instance)
- **/qr.png** → Returns scannable QR code image
- **/qr** → Returns JSON with base64 QR code
- **/qr/raw** → Returns raw event data from OpenWA
- **/status** → Returns session status: `waiting | qr | scanned | loading | authenticated | ready | failure`
- **/** → Real-time QR code monitoring web interface

---

## Requirements

- Node.js >= 18
- npm >= 8
- PM2 (process manager)
- OpenWA CLI (`@open-wa/wa-automate`) >= 4.30
- Python socket client (optional)

---

## Setup

### 1. Install Linux Packages
```bash
sudo apt-get update && sudo apt-get install -y \
   libatk-bridge2.0-0t64 \
   libatk1.0-0t64 \
   libdrm2 \
   libxkbcommon0 \
   libxcomposite1 \
   libxdamage1 \
   libxrandr2 \
   libgbm1 \
   libasound2t64 \
   libpangocairo-1.0-0 \
   libpango-1.0-0 \
   libcairo2 \
   libnss3 \
   libxss1 \
   fonts-liberation \
   libappindicator3-1 \
   libgtk-3-0t64
```

### 2. Clone this repository
```bash
git clone <your-repo-url>
cd open-wa-nodejs
```

### 3. Install dependencies
```bash
npm install
npm install -g pm2
```

### 4. Configure instances

Copy the example configuration and customize it:

```bash
cp instances.example.json instances.json
```

Edit `instances.json` to define your WhatsApp instances:

```json
{
  "instances": [
    {
      "name": "jemmy",
      "openwa_port": 8003,
      "proxy_port": 8002,
      "api_key": "my_secret_api_key",
      "session_folder": "jemmy_session"
    },
    {
      "name": "christoper",
      "openwa_port": 8005,
      "proxy_port": 8004,
      "api_key": "christoper_secret_key",
      "session_folder": "christoper_session"
    }
  ]
}
```

**Configuration fields:**
- `name` - Unique identifier for the instance (used in commands)
- `openwa_port` - Port for OpenWA socket server (for API clients)
- `proxy_port` - Port for QR proxy web interface (for QR scanning)
- `api_key` - Secret key for API authentication
- `session_folder` - Directory name for storing session data

---

## Usage

### Quick Start

```bash
# Show all available commands
make help

# List configured instances
make list-instances

# Start a specific instance
make start-instance INSTANCE=jemmy

# Start all instances
make start-all-instances

# Check status of all instances
make status

# Stop a specific instance
make stop-instance INSTANCE=jemmy

# Stop all instances
make stop-all-instances
```

### Available Commands

#### Multi-Instance Commands
```bash
make list-instances                    # List all configured instances
make start-instance INSTANCE=<name>    # Start a specific instance
make stop-instance INSTANCE=<name>     # Stop a specific instance
make restart-instance INSTANCE=<name>  # Restart a specific instance
make start-all-instances               # Start all instances
make stop-all-instances                # Stop all instances
make status                            # Show PM2 status
```

#### Utility Commands
```bash
make install          # Install npm dependencies
make clean            # Remove QR code images
make nuke-all         # Stop and delete ALL PM2 processes (use with caution!)
make help             # Show this help message
```

#### Legacy Commands (backward compatibility)
```bash
make start-proxy      # Start QR proxy without PM2 (port 8002)
make start-openwa     # Start OpenWA without PM2 (port 8003)
make start-all        # Start with PM2 (legacy - starts first instance)
make stop-all         # Stop legacy PM2 services
```

---

## Accessing Instances

Once an instance is running, access its endpoints:

### For the "jemmy" instance (proxy_port: 8002):
- **QR Monitor**: http://localhost:8002/
- **QR Image**: http://localhost:8002/qr.png
- **QR JSON**: http://localhost:8002/qr
- **Status**: http://localhost:8002/status

### For the "christoper" instance (proxy_port: 8004):
- **QR Monitor**: http://localhost:8004/
- **QR Image**: http://localhost:8004/qr.png
- **QR JSON**: http://localhost:8004/qr
- **Status**: http://localhost:8004/status

---

## Frontend Integration

Embed the QR in your frontend using:

```html
<!-- For jemmy instance -->
<img src="http://localhost:8002/qr.png" alt="WhatsApp QR Code" />

<!-- For christoper instance -->
<img src="http://localhost:8004/qr.png" alt="WhatsApp QR Code" />
```

Poll `/status` to detect when the session is ready for Python socket connection.

---

## Python Socket Client Integration

Once `/status` returns `"ready"`, your Python socket client can safely connect:

### For jemmy instance:
```python
SOCKET_URL = "http://localhost:8003"  # Use openwa_port
API_KEY = "my_secret_api_key"
```

### For christoper instance:
```python
SOCKET_URL = "http://localhost:8005"  # Use openwa_port
API_KEY = "christoper_secret_key"
```

---

## Adding a New Instance

1. Copy `instances.example.json` to `instances.json` if you haven't already
2. Edit `instances.json` and add a new entry with unique ports:
   ```json
   {
     "name": "new_user",
     "openwa_port": 8007,
     "proxy_port": 8006,
     "api_key": "their_api_key",
     "session_folder": "new_user_session"
   }
   ```

2. Start the new instance:
   ```bash
   make start-instance INSTANCE=new_user
   ```

3. Access at http://localhost:8006/

---

## Notes

- Ensure all configured ports are **free** before starting instances
- Each instance runs in **isolation** with its own PM2 process
- The `/status` endpoint ensures your Python socket client only connects when the session is ready
- Use `make status` or `pm2 list` to view all running instances
- Session data is stored in the configured `session_folder` for each instance
- QR codes automatically refresh (handled by OpenWA CLI)
- FastAPI or any frontend can reliably consume `/qr.png` and `/status` without terminal interaction

---

## Troubleshooting

### Port already in use
```bash
# Check what's using the port
sudo lsof -i :8002

# Stop the conflicting instance
make stop-instance INSTANCE=jemmy
```

### View instance logs
```bash
# View logs for a specific instance
pm2 logs qr-proxy-jemmy
pm2 logs openwa-jemmy

# View all logs
pm2 logs
```

### Reset an instance
```bash
# Stop and delete the instance
make stop-instance INSTANCE=jemmy

# Optionally remove session data
rm -rf jemmy_session

# Restart (will create new QR)
make start-instance INSTANCE=jemmy
```

### Nuke everything (start fresh)
```bash
make nuke-all
```
