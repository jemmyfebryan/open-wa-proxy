import express from "express";
// 💡 Required for serving static files (like the HTML page)
import path from "path"; 
import { fileURLToPath } from 'url';

// Helper to get directory name in ES Module scope
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: "10mb" }));

let lastQr = null;
let lastEvent = null;
let status = "waiting";
let hostNumber = null;
let lastQrTimestamp = Date.now(); 

// Utility: normalize startup messages into states
function parseStartupMessage(msg) {
  if (!msg) return null;
  const text = msg.toLowerCase();

  if (text.includes("qr code scanned") || text.includes("successfulscan")) {
    return "scanned";
  }
  if (text.includes("loading your chats") || text.includes("injecting") || text.includes("reinjecting")) {
    return "loading";
  }
  if (text.includes("client is ready") || text.includes("@open-wa ready")) {
    return "ready";
  }
  if (text.includes("failure")) {
    return "failure";
  }
  return null;
}

// 💡 NEW: Serve the client HTML file on the root path
app.get("/", (req, res) => {
    // Assumes client.html is in the same directory as server.js
    res.sendFile(path.join(__dirname, 'client.html'));
});

app.post("/events", (req, res) => {
  const body = req.body;
  console.log("[QR-PROXY] raw body:", body);

  if (!body || !body.namespace) {
    return res.status(400).json({ error: "Invalid payload" });
  }

  lastEvent = body;
  const namespace = body.namespace;
  const data = body.data;

  if (namespace === "qr") {
    const qr = typeof data === "string" ? data : data?.base64 || data?.qr || null;
    if (qr) {
      lastQr = qr;
      status = "qr";
      lastQrTimestamp = Date.now(); 
      console.log(`📲 QR updated. New timestamp: ${lastQrTimestamp}`);
    }
  } else if (namespace === "authenticated") {
    status = "authenticated";
    lastQr = null;
    console.log("✅ Authenticated");
  } else if (namespace === "ready") {
    status = "ready";
    lastQr = null;
    console.log("🤖 Client ready");
  } else if (namespace === "auth_failure") {
    status = "failure";
    console.log("❌ Auth failure");
  } else if (namespace === "STARTUP") {
    const newState = parseStartupMessage(data);
    if (newState) {
      status = newState;
      console.log(`🔄 Startup → ${newState}`);
    }
  }

  res.json({ ok: true });
});

// JSON QR (base64)
app.get("/qr", (req, res) => {
  if (!lastQr) return res.status(404).json({ error: "No QR yet" });
  res.json({ qr: lastQr });
});

// Serve QR as PNG image
app.get("/qr.png", (req, res) => {
  if (!lastQr) return res.status(404).send("No QR yet");

  const base64 = lastQr.replace(/^data:image\/png;base64,/, "");
  const buffer = Buffer.from(base64, "base64");

  res.writeHead(200, {
    "Content-Type": "image/png",
    "Content-Length": buffer.length,
    // Add the timestamp as a non-caching header for good measure, though the client-side cache busting is the main mechanism
    "Cache-Control": "no-cache, no-store, must-revalidate", 
  });
  res.end(buffer);
});

// Endpoint: Get the latest QR timestamp
app.get("/qr-timestamp", (req, res) => {
  if (!lastQr) return res.status(404).json({ error: "No QR yet" });
  res.json({ timestamp: lastQrTimestamp, status });
});

// Session status
app.get("/status", (req, res) => {
  res.json({ status });
});

// host number
app.get("/hostnumber", (req, res) => {
  if (!hostNumber) return res.status(404).json({ error: "Host number not available yet" });
  res.json({ hostNumber });
});

app.listen(8002, () => {
  console.log("🌐 QR proxy running at http://localhost:8002");
  console.log("   → View Realtime QR at: http://localhost:8002/"); // The main client URL
});