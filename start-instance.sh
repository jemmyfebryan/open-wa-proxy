#!/bin/bash
# Helper script to start an instance
# Usage: ./start-instance.sh <instance_name>

INSTANCE_NAME=$1

if [ -z "$INSTANCE_NAME" ]; then
  echo "❌ Error: Instance name is required"
  exit 1
fi

# Extract config from instances.json
CONFIG=$(node -e "const d=require('./instances.json'); const i=d.instances.find(x=>x.name==='$INSTANCE_NAME'); if(!i) process.exit(1); console.log(JSON.stringify(i));")

if [ $? -ne 0 ]; then
  echo "❌ Instance '$INSTANCE_NAME' not found in instances.json"
  exit 1
fi

# Parse values
PROXY_PORT=$(echo "$CONFIG" | node -e "const d=JSON.parse(require('fs').readFileSync(0)); console.log(d.proxy_port);")
OPENWA_PORT=$(echo "$CONFIG" | node -e "const d=JSON.parse(require('fs').readFileSync(0)); console.log(d.openwa_port);")
API_KEY=$(echo "$CONFIG" | node -e "const d=JSON.parse(require('fs').readFileSync(0)); console.log(d.api_key);")
SESSION=$(echo "$CONFIG" | node -e "const d=JSON.parse(require('fs').readFileSync(0)); console.log(d.session_folder);")

echo "🚀 Starting instance: $INSTANCE_NAME"
echo "   → Proxy port: $PROXY_PORT"
echo "   → OpenWA port: $OPENWA_PORT"
echo "   → Session folder: $SESSION"

# Start QR proxy
PROXY_PORT=$PROXY_PORT INSTANCE_NAME=$INSTANCE_NAME pm2 start server.js --name "qr-proxy-$INSTANCE_NAME" --interpreter node -- "$PROXY_PORT" "$INSTANCE_NAME"

# Start OpenWA
pm2 start npx --name "openwa-$INSTANCE_NAME" -- @open-wa/wa-automate --socket -p "$OPENWA_PORT" -k "$API_KEY" --ev "http://localhost:$PROXY_PORT/events" --session-id "$SESSION" --qr-timeout 0 --auth-timeout 0

echo "✅ Instance '$INSTANCE_NAME' started"
echo "   → pm2 logs qr-proxy-$INSTANCE_NAME"
echo "   → pm2 logs openwa-$INSTANCE_NAME"
echo "   → View QR at: http://localhost:$PROXY_PORT/"
