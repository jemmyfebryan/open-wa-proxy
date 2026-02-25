# Variables
NODE=node
NPX=npx
QR_PROXY=server.js
INSTANCES_FILE=instances.json

# Default target
.DEFAULT_GOAL := help

# Legacy single-instance config (for backward compatibility)
OPENWA_PORT=8003
API_KEY=my_secret_api_key

# Helper to get instance config from instances.json
# Usage: make get-config INSTANCE=jemmy
get-config:
	@node -e "const data=require('./$(INSTANCES_FILE)'); const i=data.instances.find(x=>x.name==='$(INSTANCE)'); if(i) console.log(JSON.stringify(i)); else process.exit(1)"

# Install dependencies
install:
	npm install

# ============================================
# MULTI-INSTANCE COMMANDS
# ============================================

# Start a specific instance
# Usage: make start-instance INSTANCE=jemmy
start-instance:
	@if [ -z "$(INSTANCE)" ]; then \
		echo "❌ Error: INSTANCE parameter is required"; \
		echo "   Usage: make start-instance INSTANCE=<name>"; \
		echo "   Available instances:"; \
		node -e "const d=require('./$(INSTANCES_FILE)'); d.instances.forEach(i=>console.log('      - '+i.name))"; \
		exit 1; \
	fi
	@echo "🚀 Starting instance: $(INSTANCE)"
	@echo "   → Proxy port: $$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.proxy_port);")"
	@echo "   → OpenWA port: $$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.openwa_port);")"
	@echo "   → Session folder: $$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.session_folder);")"
	@PROXY_PORT=$$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.proxy_port);") \
	OPENWA_PORT=$$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.openwa_port);") \
	API_KEY=$$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.api_key);") \
	SESSION=$$(node -e "const d=require('./$(INSTANCES_FILE)'); const i=d.instances.find(x=>x.name==='$(INSTANCE)'); console.log(i.session_folder);") \
	PROXY_PORT=$$PROXY_PORT INSTANCE_NAME=$(INSTANCE) pm2 start $(QR_PROXY) --name "qr-proxy-$(INSTANCE)" --interpreter $(NODE) -- $$PROXY_PORT $(INSTANCE); \
	pm2 start $(NPX) --name "openwa-$(INSTANCE)" -- @open-wa/wa-automate --socket -p $$OPENWA_PORT -k $$API_KEY --ev http://localhost:$$PROXY_PORT/events --qr-timeout 0 --auth-timeout 0 --session $$SESSION
	@echo "✅ Instance '$(INSTANCE)' started"
	@echo "   → pm2 logs qr-proxy-$(INSTANCE)"
	@echo "   → pm2 logs openwa-$(INSTANCE)"
	@echo "   → View QR at: http://localhost:$$(node -e 'const d=require(\"./$(INSTANCES_FILE)\"); const i=d.instances.find(x=>x.name===\"$(INSTANCE)\"); console.log(i.proxy_port);')/"

# Stop a specific instance
# Usage: make stop-instance INSTANCE=jemmy
stop-instance:
	@if [ -z "$(INSTANCE)" ]; then \
		echo "❌ Error: INSTANCE parameter is required"; \
		echo "   Usage: make stop-instance INSTANCE=<name>"; \
		exit 1; \
	fi
	@echo "🛑 Stopping instance: $(INSTANCE)"
	pm2 stop "qr-proxy-$(INSTANCE)" || true
	pm2 stop "openwa-$(INSTANCE)" || true
	pm2 delete "qr-proxy-$(INSTANCE)" || true
	pm2 delete "openwa-$(INSTANCE)" || true
	@echo "✅ Instance '$(INSTANCE)' stopped"

# Restart a specific instance
# Usage: make restart-instance INSTANCE=jemmy
restart-instance:
	@echo "🔄 Restarting instance: $(INSTANCE)"
	@$(MAKE) stop-instance INSTANCE=$(INSTANCE)
	@$(MAKE) start-instance INSTANCE=$(INSTANCE)

# Start all instances defined in instances.json
start-all-instances:
	@echo "🚀 Starting all instances..."
	@node -e "const d=require('./$(INSTANCES_FILE)'); d.instances.forEach(i => console.log(i.name))" | while read name; do \
		$(MAKE) start-instance INSTANCE=$$name; \
	done
	@echo "✅ All instances started"
	@pm2 list

# Stop all instances
stop-all-instances:
	@echo "🛑 Stopping all instances..."
	@node -e "const d=require('./$(INSTANCES_FILE)'); d.instances.forEach(i => console.log(i.name))" | while read name; do \
		$(MAKE) stop-instance INSTANCE=$$name; \
	done
	@echo "✅ All instances stopped"

# List all instances
list-instances:
	@echo "📋 Configured instances:"
	@node -e "const d=require('./$(INSTANCES_FILE)'); d.instances.forEach(i => console.log('   - '+i.name+' (proxy: '+i.proxy_port+', openwa: '+i.openwa_port+', session: '+i.session_folder+')'))"

# Show status of all instances
status:
	@echo "📊 Instance status:"
	@pm2 list

# ============================================
# LEGACY SINGLE-INSTANCE COMMANDS (backward compatibility)
# ============================================

# Start QR Proxy server (without pm2)
start-proxy:
	$(NODE) $(QR_PROXY)

# Start OpenWA CLI (without pm2)
start-openwa:
	$(NPX) @open-wa/wa-automate --socket -p $(OPENWA_PORT) -k $(API_KEY) \
		--ev http://localhost:8002/events

# Start both with PM2 (legacy - starts first instance from config)
start-all:
	@echo "⚠️  Using legacy start-all. Please use 'make start-all-instances' for multi-instance setup."
	@FIRST_INSTANCE=$$(node -e "const d=require('./$(INSTANCES_FILE)'); console.log(d.instances[0].name)"); \
	$(MAKE) start-instance INSTANCE=$$FIRST_INSTANCE

# Stop both with PM2 (legacy)
stop-all:
	pm2 stop qr-proxy || true
	pm2 stop openwa || true
	pm2 delete qr-proxy || true
	pm2 delete openwa || true
	@echo "🛑 Legacy services stopped"

# Clean QR images (if any)
clean:
	rm -f qr_code.png

# Stop and clean all PM2 processes
nuke-all:
	pm2 stop all || true
	pm2 delete all || true
	@echo "☠️  All PM2 processes nuked"

# Help - show all available commands
help:
	@echo ""
	@echo "📖 Open-WA Multi-Instance Manager"
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📋 Multi-Instance Commands:"
	@echo ""
	@echo "   make list-instances"
	@echo "       List all configured instances from instances.json"
	@echo ""
	@echo "   make start-instance INSTANCE=<name>"
	@echo "       Start a specific instance (e.g., make start-instance INSTANCE=jemmy)"
	@echo ""
	@echo "   make stop-instance INSTANCE=<name>"
	@echo "       Stop a specific instance (e.g., make stop-instance INSTANCE=jemmy)"
	@echo ""
	@echo "   make restart-instance INSTANCE=<name>"
	@echo "       Restart a specific instance"
	@echo ""
	@echo "   make start-all-instances"
	@echo "       Start all instances defined in instances.json"
	@echo ""
	@echo "   make stop-all-instances"
	@echo "       Stop all instances"
	@echo ""
	@echo "   make status"
	@echo "       Show PM2 status of all running instances"
	@echo ""
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "🔧 Setup Commands:"
	@echo ""
	@echo "   make install"
	@echo "       Install npm dependencies"
	@echo ""
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "⚠️  Legacy Commands (single-instance, backward compatibility):"
	@echo ""
	@echo "   make start-proxy"
	@echo "       Start QR proxy without PM2 (port 8002)"
	@echo ""
	@echo "   make start-openwa"
	@echo "       Start OpenWA without PM2 (port 8003)"
	@echo ""
	@echo "   make start-all"
	@echo "       Start with PM2 (legacy - starts first instance)"
	@echo ""
	@echo "   make stop-all"
	@echo "       Stop legacy PM2 services"
	@echo ""
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "🧹 Utility Commands:"
	@echo ""
	@echo "   make clean"
	@echo "       Remove QR code images"
	@echo ""
	@echo "   make nuke-all"
	@echo "       Stop and delete ALL PM2 processes (use with caution!)"
	@echo ""
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════════════════"
	@echo ""

.PHONY: help install get-config start-instance stop-instance restart-instance start-all-instances stop-all-instances list-instances status start-proxy start-openwa start-all stop-all clean nuke-all
