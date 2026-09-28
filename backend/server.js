require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mysql = require("mysql2");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const detectImageMime = require("./image_mime");

const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);

const app = express();
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const SECRET = process.env.JWT_SECRET;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 8 * 1024 * 1024,
    fieldSize: 10 * 1024 * 1024,
    files: 7,
  },
});
const imageUploadFields = Array.from({ length: 7 }, (_, index) => ({
  name: `image${index + 1}`,
  maxCount: 1,
}));
const maxTotalImageBytes = 48 * 1024 * 1024;

function parseImageUpload(req, res, next) {
  upload.fields(imageUploadFields)(req, res, (err) => {
    if (err) {
      const status =
        err.code === "LIMIT_FILE_SIZE" || err.code === "LIMIT_FILE_COUNT"
          ? 413
          : 400;
      return res.status(status).json({ error: err.message });
    }

    const totalBytes = Object.values(req.files || {}).reduce(
      (total, files) =>
        total + files.reduce((size, file) => size + file.size, 0),
      0,
    );
    if (totalBytes > maxTotalImageBytes) {
      return res.status(413).json({
        error: "The combined image upload must not exceed 48 MiB.",
      });
    }
    return next();
  });
}
// //laptop
// const db = mysql.createConnection({
//   host: process.env.DB_HOST || "localhost",
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   database: process.env.DB_NAME,
// });
//phone
const db = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: {
    // rejectUnauthorized: true,
    rejectUnauthorized: false,
  },
    waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});
//add database connection test 
db.getConnection((err, connection) => {
  if (err) {
    console.error("❌ Aiven MySQL connection failed:", err.message);
    return;
  }

  console.log("✅ Connected successfully to Aiven MySQL");

  connection.release();
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
const partResponseColumns = [
  "id",
  "reference",
  "location",
  "quantity",
  "`name`",
  "fournisseur_reference",
  "created_at",
  ...Array.from({ length: 7 }, (_, index) => `image${index + 1}`),
  ...Array.from({ length: 7 }, (_, index) => `embedding${index + 1}`),
  ...Array.from(
    { length: 7 },
    (_, index) =>
      `CASE WHEN image${index + 1}_data IS NOT NULL THEN 1 ELSE 0 END AS has_image${index + 1}`,
  ),
].join(", ");

app.get("/api/parts", verifyToken, (req, res) => {
  db.query(`SELECT ${partResponseColumns} FROM parts`, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

function normalizeReferenceValue(value) {
  return String(value || '')
    .toUpperCase()
    .trim()
    .replace(/[^A-Z0-9]/g, '');
}

//  SEARCH PARTS BY REFERENCE (exact then partial) — also searches fournisseur_reference and name
app.get("/api/parts/search-reference", verifyToken, (req, res) => {
  const rawReference = (req.query.reference || '').toString().trim();
  if (!rawReference) {
    return res.status(400).json({ error: 'reference query param is required' });
  }

  const normalizedReference = normalizeReferenceValue(rawReference);
  if (!normalizedReference) {
    return res.status(400).json({ error: 'reference query param is required' });
  }

  const normalize = `UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(%s, ''), ' ', ''), '-', ''), '.', ''), '/', ''), '_', ''))`;
  const normRef  = normalize.replace('%s', 'reference');
  const normFour = normalize.replace('%s', 'fournisseur_reference');

  const exactSql = `
    SELECT ${partResponseColumns} FROM parts
    WHERE ${normRef} = ? OR ${normFour} = ?
    LIMIT 1
  `;

  db.query(exactSql, [normalizedReference, normalizedReference], (err, exactRows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (exactRows && exactRows.length > 0) {
      return res.json({ exact: true, results: exactRows });
    }

    const like = '%' + normalizedReference + '%';
    const partialSql = `
      SELECT ${partResponseColumns} FROM parts
      WHERE ${normRef} LIKE ?
         OR ${normFour} LIKE ?
         OR UPPER(COALESCE(name, '')) LIKE ?
      LIMIT 50
    `;
    db.query(partialSql, [like, like, like], (err2, rows) => {
      if (err2) return res.status(500).json({ error: err2.message });
      return res.json({ exact: false, results: rows });
    });
  });
});

app.get("/api/parts/:id/image/:slot", verifyToken, (req, res) => {
  const partId = Number(req.params.id);
  const slot = Number(req.params.slot);
  if (!Number.isSafeInteger(partId) || partId <= 0) {
    return res.status(400).json({ error: "Invalid part ID." });
  }
  if (!Number.isInteger(slot) || slot < 1 || slot > 7) {
    return res.status(400).json({ error: "Image slot must be between 1 and 7." });
  }

  db.query(
    `SELECT image${slot}_data, image${slot}_mime FROM parts WHERE id=? LIMIT 1`,
    [partId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!rows || rows.length === 0) {
        return res.status(404).json({ error: "Part not found." });
      }
      const { [`image${slot}_data`]: imageData, [`image${slot}_mime`]: imageMime } =
        rows[0];
      if (!imageData) {
        return res.status(404).json({ error: "Image not found." });
      }
      res.set("Content-Type", imageMime || "application/octet-stream");
      res.set("Content-Length", imageData.length);
      return res.send(imageData);
    },
  );
});

// ADD PART (with 1 to 7 images & embeddings)
app.post("/api/parts", verifyToken, parseImageUpload, (req, res) => {
  const {
    reference,
    location,
    quantity,
    name,
    fournisseur_reference,
    embedding1,
    embedding2,
    embedding3,
    embedding4,
    embedding5,
    embedding6,
    embedding7,
  } = req.body;
  const files = req.files || {};
  const columns = [
    "reference",
    "location",
    "quantity",
    "`name`",
    "fournisseur_reference",
    ...Array.from({ length: 7 }, (_, index) => `image${index + 1}`),
    ...Array.from(
      { length: 7 },
      (_, index) => `image${index + 1}_data`,
    ),
    ...Array.from(
      { length: 7 },
      (_, index) => `image${index + 1}_mime`,
    ),
    ...Array.from({ length: 7 }, (_, index) => `embedding${index + 1}`),
    "created_at",
  ];
  const values = [
    reference,
    location,
    quantity,
    name || null,
    fournisseur_reference || null,
    ...Array(7).fill(null),
    ...Array.from({ length: 7 }, (_, index) => {
      const file = files[`image${index + 1}`]?.[0];
      return file ? file.buffer : null;
    }),
    ...Array.from({ length: 7 }, (_, index) => {
      const file = files[`image${index + 1}`]?.[0];
      return file
        ? detectImageMime(file.buffer, file.originalname, file.mimetype)
        : null;
    }),
    embedding1 || null,
    embedding2 || null,
    embedding3 || null,
    embedding4 || null,
    embedding5 || null,
    embedding6 || null,
    embedding7 || null,
    new Date().toISOString().slice(0, 19).replace("T", " "),
  ];
  db.query(
    `INSERT INTO parts (${columns.join(", ")}) VALUES (${columns.map(() => "?").join(", ")})`,
    values,
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, id: result.insertId });
    }
  );
});

//  UPDATE PART (supports optional image uploads)
app.put("/api/parts/:id", verifyToken, (req, res, next) => {
  // If JSON body (no multipart), skip multer
  if (req.is('application/json')) return next();
  parseImageUpload(req, res, next);
}, (req, res) => {
  const {
    reference,
    location,
    quantity,
    name,
    fournisseur_reference,
  } = req.body;
  const files = req.files || {};

  const fields = ["reference=?", "location=?", "quantity=?", "`name`=?", "fournisseur_reference=?"];
  const values = [reference, location, quantity, name !== undefined ? (name || null) : null, fournisseur_reference !== undefined ? (fournisseur_reference || null) : null];

  for (let slot = 1; slot <= 7; slot += 1) {
    const file = files[`image${slot}`]?.[0];
    if (file) {
      fields.push(`image${slot}=?`, `image${slot}_data=?`, `image${slot}_mime=?`);
      values.push(
        null,
        file.buffer,
        detectImageMime(file.buffer, file.originalname, file.mimetype),
      );
      if (req.body[`embedding${slot}`]) {
        fields.push(`embedding${slot}=?`);
        values.push(req.body[`embedding${slot}`]);
      }
    } else if (req.body[`clear_image${slot}`] === "1") {
      fields.push(
        `image${slot}=?`,
        `image${slot}_data=?`,
        `image${slot}_mime=?`,
        `embedding${slot}=?`,
      );
      values.push(null, null, null, null);
    } else if (req.body[`embedding${slot}`]) {
      fields.push(`embedding${slot}=?`);
      values.push(req.body[`embedding${slot}`]);
    }
  }

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
    ["name", "VARCHAR(255) NULL"],
    ["fournisseur_reference", "VARCHAR(255) NULL"],
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

  //phone : create a helth endpoint
  app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'STBG API is running'
  });
  });
  // Initialize database
db.query(ensureActivitiesTable, (schemaErr) => {
  if (schemaErr) console.error("activities table:", schemaErr.message);
  ensurePartsEmbeddings();
  // Laptop
  // app.listen(3000, () => {
  //   console.log("Server running on http://localhost:3000");
  // });

  // phone and laptop
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });

});
