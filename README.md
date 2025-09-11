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

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd <project-folder>
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the QR proxy server:
   ```bash
   node qr-proxy.js
   ```

4. Start OpenWA in socket mode:
   ```bash
   npx @open-wa/wa-automate --socket -p 8002 -k <YOUR_API_KEY> \
     --ev http://localhost:5000/events
   ```

5. Access endpoints:
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

## Makefile

A simple Makefile for common tasks:

```makefile
# Variables
NODE=node
NPX=npx
QR_PROXY=qr-proxy.js
OPENWA_PORT=8002
API_KEY=my_secret_api_key

# Install dependencies
install:
	npm install

# Start QR Proxy server
start-proxy:
	$(NODE) $(QR_PROXY)

# Start OpenWA CLI with socket mode
start-openwa:
	$(NPX) @open-wa/wa-automate --socket -p $(OPENWA_PORT) -k $(API_KEY) \
		--ev http://localhost:5000/events

# Full start (proxy + open-wa)
start-all:
	@echo "Start the proxy in one terminal:"
	@echo "  make start-proxy"
	@echo "Then start OpenWA in another terminal:"
	@echo "  make start-openwa"

# Clean QR images (if any)
clean:
	rm -f qr_code.png
```

---

## Notes

- Ensure that port `8002` is free before starting OpenWA CLI.  
- The `/status` endpoint ensures your Python socket client only connects when the session is ready.  
- FastAPI or any frontend can now reliably consume `/qr.png` and `/status` without interacting with the terminal.
