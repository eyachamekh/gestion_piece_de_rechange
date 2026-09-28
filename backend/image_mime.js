const path = require("path");

const extensionMimeTypes = {
  ".avif": "image/avif",
  ".bmp": "image/bmp",
  ".gif": "image/gif",
  ".heic": "image/heic",
  ".heif": "image/heif",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".png": "image/png",
  ".tif": "image/tiff",
  ".tiff": "image/tiff",
  ".webp": "image/webp",
};

function detectImageMime(buffer, filename, declaredMime) {
  if (buffer && buffer.length >= 12) {
    if (
      buffer[0] === 0xff &&
      buffer[1] === 0xd8 &&
      buffer[2] === 0xff
    ) {
      return "image/jpeg";
    }
    if (buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
      return "image/png";
    }
    if (
      buffer.subarray(0, 6).toString("ascii") === "GIF87a" ||
      buffer.subarray(0, 6).toString("ascii") === "GIF89a"
    ) {
      return "image/gif";
    }
    if (
      buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
      buffer.subarray(8, 12).toString("ascii") === "WEBP"
    ) {
      return "image/webp";
    }
    if (buffer.subarray(0, 2).toString("ascii") === "BM") {
      return "image/bmp";
    }
    if (
      buffer.subarray(0, 4).equals(Buffer.from([0x49, 0x49, 0x2a, 0x00])) ||
      buffer.subarray(0, 4).equals(Buffer.from([0x4d, 0x4d, 0x00, 0x2a]))
    ) {
      return "image/tiff";
    }
    if (
      buffer.subarray(4, 8).toString("ascii") === "ftyp" &&
      /^(heic|heix|hevc|hevx|mif1|msf1)$/.test(
        buffer.subarray(8, 12).toString("ascii"),
      )
    ) {
      return path.extname(filename || "").toLowerCase() === ".heif"
        ? "image/heif"
        : "image/heic";
    }
    if (
      buffer.subarray(4, 8).toString("ascii") === "ftyp" &&
      buffer.subarray(8, 12).toString("ascii") === "avif"
    ) {
      return "image/avif";
    }
  }

  if (declaredMime && declaredMime.startsWith("image/")) {
    return declaredMime;
  }
  return (
    extensionMimeTypes[path.extname(filename || "").toLowerCase()] ||
    "application/octet-stream"
  );
}

module.exports = detectImageMime;
