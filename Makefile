# Variables
NODE=node
NPX=npx
QR_PROXY=qr-proxy.js
OPENWA_PORT=8003
API_KEY=my_secret_api_key

# Install dependencies
install:
	npm install

# Start QR Proxy server (without pm2)
start-proxy:
	$(NODE) $(QR_PROXY)

# Start OpenWA CLI (without pm2)
start-openwa:
	$(NPX) @open-wa/wa-automate --socket -p $(OPENWA_PORT) -k $(API_KEY) \
		--ev http://localhost:8002/events

# Start both with PM2
start-all:
	pm2 start $(QR_PROXY) --name qr-proxy --interpreter $(NODE)
	pm2 start $(NPX) --name openwa -- @open-wa/wa-automate --socket -p $(OPENWA_PORT) -k $(API_KEY) --ev http://localhost:8002/events --qr-timeout 0 --auth-timeout 0
	@echo "✅ Both services started with pm2"
	@echo "   → pm2 logs qr-proxy"
	@echo "   → pm2 logs openwa"

# Stop both with PM2
stop-all:
	pm2 stop qr-proxy || true
	pm2 stop openwa || true
	pm2 delete qr-proxy || true
	pm2 delete openwa || true
	@echo "🛑 Both services stopped"

# Clean QR images (if any)
clean:
	rm -f qr_code.png
