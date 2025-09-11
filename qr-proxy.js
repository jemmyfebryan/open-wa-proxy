import express from "express";

const app = express();
app.use(express.json({ limit: "10mb" }));

let lastQr = null;
let lastEvent = null;
let status = "waiting";

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
      console.log("📲 QR updated");
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

// Raw event JSON
app.get("/qr/raw", (req, res) => {
  if (!lastEvent) return res.status(404).json({ error: "No QR event yet" });
  res.json(lastEvent);
});

// Serve QR as PNG image
app.get("/qr.png", (req, res) => {
  if (!lastQr) return res.status(404).send("No QR yet");

  const base64 = lastQr.replace(/^data:image\/png;base64,/, "");
  const buffer = Buffer.from(base64, "base64");

  res.writeHead(200, {
    "Content-Type": "image/png",
    "Content-Length": buffer.length,
  });
  res.end(buffer);
});

// Session status
app.get("/status", (req, res) => {
  res.json({ status });
});

app.listen(5000, () => {
  console.log("🌐 QR proxy running at http://localhost:5000");
  console.log("   → /qr (JSON)");
  console.log("   → /qr/raw (raw event)");
  console.log("   → /qr.png (PNG image)");
  console.log("   → /status");
});
