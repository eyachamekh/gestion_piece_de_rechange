const express = require("express");
const cors = require("cors");
const mysql = require("mysql2");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
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
  database: "piece_de_rechanges",
});

// LOGIN WITH JWT
app.post("/api/login", (req, res) => {
  const { email, password } = req.body;
  db.query(
    "SELECT * FROM users WHERE email=? LIMIT 1",
    [email],
    (err, results) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (!results || results.length === 0) {
        return res.status(401).json({ success: false });
      }
      const user = results[0];
      const storedPassword = String(user.password || "");
      const isHash = /^\$2[aby]\$\d{2}\$/.test(storedPassword);
      const finishLogin = () => {
        const token = jwt.sign({ id: user.id, role: user.role }, SECRET, { expiresIn: "24h" });
        res.json({ success: true, token, role: user.role });
      };
      if (isHash) {
        return bcrypt.compare(password, storedPassword, (compareErr, valid) => {
          if (compareErr) return res.status(500).json({ success: false });
          if (!valid) return res.status(401).json({ success: false });
          finishLogin();
        });
      }
      if (storedPassword !== password) {
        return res.status(401).json({ success: false });
      }
      bcrypt.hash(password, 12, (hashErr, hash) => {
        if (hashErr) return res.status(500).json({ success: false });
        db.query("UPDATE users SET password=? WHERE id=?", [hash, user.id], (updateErr) => {
          if (updateErr) return res.status(500).json({ success: false });
          finishLogin();
        });
      });
    }
  );
});

//  Middleware
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

//  GET PARTS
app.get("/api/parts", verifyToken, (req, res) => {
  db.query("SELECT * FROM parts", (err, results) => {
    res.json(results);
  });
});

function normalizeReferenceValue(value) {
  return String(value || '')
    .toUpperCase()
    .trim()
    .replace(/[^A-Z0-9]/g, '');
}

//  SEARCH PARTS BY REFERENCE (exact then partial)
app.get("/api/parts/search-reference", verifyToken, (req, res) => {
  const rawReference = (req.query.reference || '').toString().trim();
  if (!rawReference) {
    return res.status(400).json({ error: 'reference query param is required' });
  }

  const normalizedReference = normalizeReferenceValue(rawReference);
  if (!normalizedReference) {
    return res.status(400).json({ error: 'reference query param is required' });
  }

  const exactSql = `
    SELECT *
    FROM parts
    WHERE UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(reference, ''), ' ', ''), '-', ''), '.', ''), '/', ''), '_', '')) = ?
    LIMIT 1
  `;

  db.query(exactSql, [normalizedReference], (err, exactRows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (exactRows && exactRows.length > 0) {
      return res.json({ exact: true, results: exactRows });
    }

    const partialSql = `
      SELECT *
      FROM parts
      WHERE UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(reference, ''), ' ', ''), '-', ''), '.', ''), '/', ''), '_', '')) LIKE ?
      LIMIT 50
    `;
    db.query(partialSql, ['%' + normalizedReference + '%'], (err2, rows) => {
      if (err2) return res.status(500).json({ error: err2.message });
      return res.json({ exact: false, results: rows });
    });
  });
});

// ADD PART (with 3 to 7 images & embeddings)
app.post("/api/parts", verifyToken, upload.fields([
  { name: "image1", maxCount: 1 },
  { name: "image2", maxCount: 1 },
  { name: "image3", maxCount: 1 },
  { name: "image4", maxCount: 1 },
  { name: "image5", maxCount: 1 },
  { name: "image6", maxCount: 1 },
  { name: "image7", maxCount: 1 },
]), (req, res) => {
  const { reference, location, quantity, embedding1, embedding2, embedding3, embedding4, embedding5, embedding6, embedding7 } = req.body;
  const files = req.files || {};
  const image1 = files["image1"] ? files["image1"][0].filename : null;
  const image2 = files["image2"] ? files["image2"][0].filename : null;
  const image3 = files["image3"] ? files["image3"][0].filename : null;
  const image4 = files["image4"] ? files["image4"][0].filename : null;
  const image5 = files["image5"] ? files["image5"][0].filename : null;
  const image6 = files["image6"] ? files["image6"][0].filename : null;
  const image7 = files["image7"] ? files["image7"][0].filename : null;
  const created_at = new Date().toISOString().slice(0, 19).replace("T", " ");
  db.query(
    "INSERT INTO parts (reference, location, quantity, image1, image2, image3, image4, image5, image6, image7, embedding1, embedding2, embedding3, embedding4, embedding5, embedding6, embedding7, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    [reference, location, quantity, image1, image2, image3, image4, image5, image6, image7, embedding1 || null, embedding2 || null, embedding3 || null, embedding4 || null, embedding5 || null, embedding6 || null, embedding7 || null, created_at],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, id: result.insertId });
    }
  );
});

//  UPDATE PART (supports optional image uploads)
app.put("/api/parts/:id", verifyToken, upload.fields([
  { name: "image1", maxCount: 1 },
  { name: "image2", maxCount: 1 },
  { name: "image3", maxCount: 1 },
  { name: "image4", maxCount: 1 },
  { name: "image5", maxCount: 1 },
  { name: "image6", maxCount: 1 },
  { name: "image7", maxCount: 1 },
]), (req, res) => {
  const { reference, location, quantity, embedding1, embedding2, embedding3, embedding4, embedding5, embedding6, embedding7 } = req.body;
  const files = req.files || {};

  const fields = ["reference=?", "location=?", "quantity=?"];
  const values = [reference, location, quantity];

  if (files["image1"]) { fields.push("image1=?"); values.push(files["image1"][0].filename); }
  if (files["image2"]) { fields.push("image2=?"); values.push(files["image2"][0].filename); }
  if (files["image3"]) { fields.push("image3=?"); values.push(files["image3"][0].filename); }
  if (files["image4"]) { fields.push("image4=?"); values.push(files["image4"][0].filename); }
  if (files["image5"]) { fields.push("image5=?"); values.push(files["image5"][0].filename); }
  if (files["image6"]) { fields.push("image6=?"); values.push(files["image6"][0].filename); }
  if (files["image7"]) { fields.push("image7=?"); values.push(files["image7"][0].filename); }
  if (embedding1) { fields.push("embedding1=?"); values.push(embedding1); }
  if (embedding2) { fields.push("embedding2=?"); values.push(embedding2); }
  if (embedding3) { fields.push("embedding3=?"); values.push(embedding3); }
  if (embedding4) { fields.push("embedding4=?"); values.push(embedding4); }
  if (embedding5) { fields.push("embedding5=?"); values.push(embedding5); }
  if (embedding6) { fields.push("embedding6=?"); values.push(embedding6); }
  if (embedding7) { fields.push("embedding7=?"); values.push(embedding7); }

  values.push(req.params.id);
  db.query(
    `UPDATE parts SET ${fields.join(", ")} WHERE id=?`,
    values,
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

// DELETE PART
app.delete("/api/parts/:id", verifyToken, (req, res) => {
  db.query("DELETE FROM parts WHERE id=?", [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// LOG ACTIVITY (take part) — column must be `date` (reserved word in MySQL)
app.post("/api/activities", verifyToken, (req, res) => {
  const { part_id, reference, taken_by, quantity, date } = req.body;
  db.query(
    "INSERT INTO activities (part_id, reference, taken_by, quantity, `date`) VALUES (?, ?, ?, ?, ?)",
    [part_id, reference, taken_by, quantity, date],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, id: result.insertId });
    }
  );
});

//  GET ACTIVITIES (pour calcul stock de sécurité)
app.get("/api/activities", verifyToken, (req, res) => {
  db.query(
    "SELECT reference, taken_by, quantity, `date` FROM activities ORDER BY `date` DESC",
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results);
    }
  );
});

//  EXPORT DATA (from/to = YYYY-MM-DD calendar days; filter by local calendar date in DB)
app.get("/api/export", verifyToken, (req, res) => {
  const { from, to } = req.query;
  const dayRe = /^\d{4}-\d{2}-\d{2}$/;
  if (!from || !to || !dayRe.test(from) || !dayRe.test(to)) {
    return res.status(400).json({ error: "Query params from and to are required (YYYY-MM-DD)." });
  }

  // Run all 3 queries in parallel
  const q1 = new Promise((resolve, reject) => {
    db.query(
      "SELECT reference, location, quantity, created_at FROM parts WHERE LEFT(TRIM(COALESCE(CAST(created_at AS CHAR(32)), '')), 10) BETWEEN ? AND ? ORDER BY created_at ASC",
      [from, to],
      (err, rows) => err ? reject(err) : resolve(rows)
    );
  });

  const q2 = new Promise((resolve, reject) => {
    db.query(
      "SELECT reference, taken_by, quantity, `date` FROM activities WHERE LEFT(TRIM(COALESCE(CAST(`date` AS CHAR(64)), '')), 10) BETWEEN ? AND ? ORDER BY `date` ASC",
      [from, to],
      (err, rows) => err ? reject(err) : resolve(rows)
    );
  });

  const q3 = new Promise((resolve, reject) => {
    db.query(
      "SELECT reference, location, quantity FROM parts ORDER BY reference ASC",
      (err, rows) => err ? reject(err) : resolve(rows)
    );
  });

  Promise.all([q1, q2, q3])
    .then(([entrees, sorties, stock]) => res.json({ entrees, sorties, stock }))
    .catch(err => {
      console.error("Export error:", err.message);
      res.status(500).json({ error: err.message });
    });
});

const ensureActivitiesTable = `
CREATE TABLE IF NOT EXISTS activities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  part_id INT NOT NULL,
  reference VARCHAR(255) DEFAULT NULL,
  taken_by VARCHAR(255) DEFAULT NULL,
  quantity INT NOT NULL,
  \`date\` VARCHAR(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`;

const ensurePartsEmbeddings = () => {
  const addMissingColumns = [
    ["image4", "VARCHAR(255) NULL"],
    ["image5", "VARCHAR(255) NULL"],
    ["image6", "VARCHAR(255) NULL"],
    ["image7", "VARCHAR(255) NULL"],
    ["embedding4", "LONGTEXT NULL"],
    ["embedding5", "LONGTEXT NULL"],
    ["embedding6", "LONGTEXT NULL"],
    ["embedding7", "LONGTEXT NULL"],
  ];

  const addColumn = (index) => {
    if (index >= addMissingColumns.length) {
      return;
    }
    const [columnName, definition] = addMissingColumns[index];
    db.query(`SHOW COLUMNS FROM parts LIKE '${columnName}'`, (err, results) => {
      if (err) {
        console.error("Error checking parts column:", err.message);
        addColumn(index + 1);
        return;
      }
      if (results.length === 0) {
        db.query(`ALTER TABLE parts ADD COLUMN ${columnName} ${definition}`, (alterErr) => {
          if (alterErr) {
            console.error(`Failed to add column ${columnName}:`, alterErr.message);
          }
          addColumn(index + 1);
        });
      } else {
        addColumn(index + 1);
      }
    });
  };

  db.query("SHOW COLUMNS FROM parts LIKE 'embedding1'", (err, results) => {
    if (err) return console.error("Error checking parts columns:", err.message);
    if (results.length === 0) {
      console.log("Migrating database: adding embedding columns to parts table...");
      db.query(
        "ALTER TABLE parts ADD COLUMN embedding1 LONGTEXT NULL, ADD COLUMN embedding2 LONGTEXT NULL, ADD COLUMN embedding3 LONGTEXT NULL",
        (alterErr) => {
          if (alterErr) console.error("Failed to add embedding columns:", alterErr.message);
          addColumn(0);
        }
      );
    } else {
      addColumn(0);
    }
  });
};

db.query(ensureActivitiesTable, (schemaErr) => {
  if (schemaErr) console.error("activities table:", schemaErr.message);
  ensurePartsEmbeddings();
  app.listen(3000, () => {
    console.log("Server running on http://localhost:3000");
  });
});
