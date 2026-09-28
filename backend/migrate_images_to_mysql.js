const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");
const detectImageMime = require("./image_mime");

require("dotenv").config({ path: path.join(__dirname, ".env") });

const imageSlots = Array.from({ length: 7 }, (_, index) => index + 1);
const requiredColumns = imageSlots.flatMap((slot) => [
  `image${slot}_data`,
  `image${slot}_mime`,
]);
const uploadsDirectory = path.join(__dirname, "uploads");

async function main() {
  for (const name of ["DB_HOST", "DB_USER", "DB_PASSWORD", "DB_NAME"]) {
    if (!process.env[name]) {
      throw new Error(`Required database environment variable ${name} is missing.`);
    }
  }

  const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false },
    waitForConnections: true,
    connectionLimit: 2,
    queueLimit: 0,
  });

  let migratedImages = 0;
  const missingFiles = [];
  const oversizedFiles = [];

  try {
    const [columnRows] = await pool.query("SHOW COLUMNS FROM parts");
    const existingColumns = new Set(columnRows.map((column) => column.Field));
    const missingColumns = requiredColumns.filter(
      (column) => !existingColumns.has(column),
    );
    if (missingColumns.length > 0) {
      const missingColumnDefinitions = missingColumns.map((column) => {
        const type = column.endsWith("_data")
          ? "MEDIUMBLOB NULL"
          : "VARCHAR(100) NULL";
        return `ADD COLUMN ${column} ${type}`;
      });
      console.error(
        `Missing image columns: ${missingColumns.join(", ")}\n` +
          "Run this SQL, then rerun the migration:\n" +
          `ALTER TABLE parts\n  ${missingColumnDefinitions.join(",\n  ")};`,
      );
      process.exitCode = 1;
      return;
    }

    const filenameColumns = imageSlots.map((slot) => `image${slot}`).join(", ");
    const [parts] = await pool.query(
      `SELECT id, ${filenameColumns} FROM parts ORDER BY id`,
    );
    console.log(`Found ${parts.length} parts. Starting image migration.`);

    for (const part of parts) {
      for (const slot of imageSlots) {
        const filename = part[`image${slot}`];
        if (typeof filename !== "string" || filename.trim() === "") continue;

        const filePath = path.resolve(uploadsDirectory, filename);
        if (path.dirname(filePath) !== path.resolve(uploadsDirectory)) {
          console.error(`Part ${part.id}, image${slot}: unsafe filename skipped.`);
          missingFiles.push(`part ${part.id}, image${slot}: ${filename}`);
          continue;
        }
        if (!fs.existsSync(filePath)) {
          console.error(`Part ${part.id}, image${slot}: missing file ${filename}`);
          missingFiles.push(`part ${part.id}, image${slot}: ${filename}`);
          continue;
        }

        const imageBuffer = await fs.promises.readFile(filePath);
        if (imageBuffer.length > 16 * 1024 * 1024 - 1) {
          const message = `part ${part.id}, image${slot}: ${filename} exceeds the MEDIUMBLOB limit.`;
          console.error(message);
          oversizedFiles.push(message);
          continue;
        }
        const mimeType = detectImageMime(imageBuffer, filename);
        const [result] = await pool.query(
          `UPDATE parts
           SET image${slot}_data=?, image${slot}_mime=?
           WHERE id=? AND image${slot}_data IS NULL`,
          [imageBuffer, mimeType, part.id],
        );
        if (result.affectedRows > 0) {
          migratedImages += 1;
          console.log(
            `Migrated part ${part.id}, image${slot} (${mimeType}, ${imageBuffer.length} bytes).`,
          );
        } else {
          console.log(
            `Skipped part ${part.id}, image${slot}: BLOB already exists.`,
          );
        }
      }
    }

    console.log(`Migration complete. Images migrated: ${migratedImages}.`);
    console.log(`Missing files: ${missingFiles.length}.`);
    console.log(`Oversized files: ${oversizedFiles.length}.`);
    if (missingFiles.length > 0 || oversizedFiles.length > 0) {
      process.exitCode = 1;
    }
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error("Image migration failed:", error.message);
  process.exitCode = 1;
});
