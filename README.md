# OpenWA QR Proxy

## About

This project provides a **QR proxy for OpenWA**. It allows you to:

- Capture the QR code for login without using the terminal.
- Serve the QR code as a **PNG** for frontend integration (`/qr.png`) or as JSON (`/qr` or `/qr/raw`).
- Track login/session status through a `/status` endpoint.
- Enable a **Python socket client** to safely connect once the session is ready.
- Automatically handle OpenWA lifecycle events (`qr`, `authenticated`, `ready`, `auth_failure`, and `STARTUP` events).

---

## Features

- **/qr.png** → Returns scannable QR code image.
- **/qr** → Returns JSON with base64 QR code.
- **/qr/raw** → Returns raw event data from OpenWA.
- **/status** → Returns session status: `waiting | qr | scanned | loading | authenticated | ready | failure`.
- Uses OpenWA CLI in **socket mode** (`--socket`) for robust Python client integration.

---

## Requirements

- Node.js >= 18
- npm >= 8
- OpenWA CLI (`@open-wa/wa-automate`) >= 4.30
- Python socket client (optional)

---

## Setup

1. Install Linux Packages
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

2. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd <project-folder>
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Start the QR proxy server:
   ```bash
   node qr-proxy.js
   ```

5. Start OpenWA in socket mode:
   ```bash
   npx @open-wa/wa-automate --socket -p 8002 -k <YOUR_API_KEY> \
     --ev http://localhost:5000/events
   ```

6. Access endpoints:
   - `http://localhost:5000/qr.png` → QR image for frontend scanning.
   - `http://localhost:5000/qr` → Base64 JSON.
   - `http://localhost:5000/qr/raw` → Raw event JSON.
   - `http://localhost:5000/status` → Session status for Python socket client.

---

## Frontend Integration

Embed the QR in your frontend using:

```html
<img src="http://localhost:5000/qr.png" alt="WhatsApp QR Code" />
```

Poll `/status` to detect when the session is ready for Python socket connection.

---

## Python Socket Client Integration

Once `/status` returns `"ready"`, your Python socket client can safely connect to:

```python
SOCKET_URL = "http://localhost:8002"
API_KEY = "<YOUR_API_KEY>"
```

Then you can use `on_message`, `send_message`, etc.

---

## Notes

- Ensure that port `8002` is free before starting OpenWA CLI.  
- The `/status` endpoint ensures your Python socket client only connects when the session is ready.  
- FastAPI or any frontend can now reliably consume `/qr.png` and `/status` without interacting with the terminal.
