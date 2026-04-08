const express = require("express");
const cors = require("cors");
const mysql = require("mysql2");
const jwt = require("jsonwebtoken");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);

const app = express();
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const SECRET = "mysecretkey";

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, path.join(__dirname, "uploads")),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "piece_de_rechange",
});

// 🔐 LOGIN WITH JWT
app.post("/api/login", (req, res) => {
  const { email, password } = req.body;
  db.query(
    "SELECT * FROM users WHERE email=? AND password=?",
    [email, password],
    (err, results) => {
      if (err || !results || results.length === 0) return res.status(401).json({ success: false });
      const user = results[0];
      const token = jwt.sign({ id: user.id, role: user.role }, SECRET, { expiresIn: "1h" });
      res.json({ success: true, token, role: user.role });
    }
  );
});

// 🔒 Middleware
function verifyToken(req, res, next) {
  const header = req.headers["authorization"];
  if (!header) return res.sendStatus(403);
  const token = header.split(" ")[1];
  jwt.verify(token, SECRET, (err, decoded) => {
    if (err) return res.sendStatus(401);
    req.user = decoded;
    next();
  });
}

// 📦 GET PARTS
app.get("/api/parts", verifyToken, (req, res) => {
  db.query("SELECT * FROM parts", (err, results) => {
    res.json(results);
  });
});

// ➕ ADD PART (with 3 images)
app.post("/api/parts", verifyToken, upload.fields([
  { name: "image1", maxCount: 1 },
  { name: "image2", maxCount: 1 },
  { name: "image3", maxCount: 1 },
]), (req, res) => {
  const { reference, location, quantity } = req.body;
  const files = req.files || {};
  const image1 = files["image1"] ? files["image1"][0].filename : null;
  const image2 = files["image2"] ? files["image2"][0].filename : null;
  const image3 = files["image3"] ? files["image3"][0].filename : null;
  db.query(
    "INSERT INTO parts (reference, location, quantity, image1, image2, image3) VALUES (?, ?, ?, ?, ?, ?)",
    [reference, location, quantity, image1, image2, image3],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, id: result.insertId });
    }
  );
});

// ✏️ UPDATE PART
app.put("/api/parts/:id", verifyToken, (req, res) => {
  const { reference, location, quantity } = req.body;
  db.query(
    "UPDATE parts SET reference=?, location=?, quantity=? WHERE id=?",
    [reference, location, quantity, req.params.id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

// ❌ DELETE PART
app.delete("/api/parts/:id", verifyToken, (req, res) => {
  db.query("DELETE FROM parts WHERE id=?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
