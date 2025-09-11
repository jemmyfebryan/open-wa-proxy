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