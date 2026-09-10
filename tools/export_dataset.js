const fs = require('fs');
const path = require('path');
const mysql = require(path.join(__dirname, '..', 'backend', 'node_modules', 'mysql2'));

const ROOT = path.resolve(__dirname, '..');
const UPLOADS = path.join(ROOT, 'backend', 'uploads');
const OUT = path.join(ROOT, 'spare_parts_dataset');
const IMAGES_OUT = path.join(OUT, 'images');
const TRAIN = path.join(IMAGES_OUT, 'train');
const VAL = path.join(IMAGES_OUT, 'val');
const TEST = path.join(IMAGES_OUT, 'test');

function ensureDir(p){ if(!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true }); }
ensureDir(OUT); ensureDir(IMAGES_OUT); ensureDir(TRAIN); ensureDir(VAL); ensureDir(TEST);

function isJpegOrPng(filePath){ try{ const fd = fs.openSync(filePath, 'r'); const buf = Buffer.alloc(8); fs.readSync(fd, buf, 0, 8, 0); fs.closeSync(fd); // JPEG FF D8
  if(buf[0]===0xFF && buf[1]===0xD8) return 'jpeg';
  if(buf[0]===0x89 && buf[1]===0x50 && buf[2]===0x4E && buf[3]===0x47) return 'png';
  return null; } catch(e){ return null; } }

const dbConf = { host: 'localhost', user: 'root', password: '', database: 'piece_de_rechanges' };
const con = mysql.createConnection(dbConf);
con.connect(err=>{
  if(err){ console.error('DB_CONNECT_ERROR', err.message); process.exit(2); }
  con.query('SELECT id,reference,image1,image2,image3,image4,image5,image6,image7 FROM parts', (err2, rows)=>{
    if(err2){ console.error('DB_QUERY_ERROR', err2.message); process.exit(3); }

    const parts = rows.map(r=>({ id: r.id, reference: r.reference, images: [r.image1,r.image2,r.image3,r.image4,r.image5,r.image6,r.image7].filter(x=>x && x.toString().trim() !== '') }));

    const report = {
      total_parts: parts.length,
      total_unique_referenced_images: 0,
      total_exported: 0,
      total_missing: 0,
      total_invalid: 0,
      duplicate_references: [],
      images_per_part: {},
      train_per_part: {},
      val_per_part: {},
      test_per_part: {},
      parts_with_0_images: [],
      parts_with_1_image: [],
      parts_with_2_images: [],
      parts_with_3_4_images: [],
      parts_with_5_plus_images: [],
      min_images_per_part: null,
      max_images_per_part: null,
      avg_images_per_part: null,
      parts: []
    };

    // collect unique referenced images
    const globalSet = new Set();
    const filenameToParts = {};

    parts.forEach(p=>{
      const unique = [...new Set(p.images)];
      p.images = unique;
      unique.forEach(fn=>{ globalSet.add(fn); filenameToParts[fn] = filenameToParts[fn] || []; filenameToParts[fn].push(p.id); });
    });

    report.total_unique_referenced_images = globalSet.size;

    // validate and copy per part
    parts.forEach(p=>{
      const pid = p.id;
      const imgs = p.images;
      report.images_per_part[pid] = imgs.length;
      report.parts.push({ id: pid, reference: p.reference, image_count: imgs.length, images: imgs });

      if(imgs.length===0) report.parts_with_0_images.push(pid);
      if(imgs.length===1) report.parts_with_1_image.push(pid);
      if(imgs.length===2) report.parts_with_2_images.push(pid);
      if(imgs.length>=3 && imgs.length<=4) report.parts_with_3_4_images.push(pid);
      if(imgs.length>=5) report.parts_with_5_plus_images.push(pid);

      // compute split counts
      const n = imgs.length;
      let trainCount = Math.floor(n * 0.7);
      let valCount = Math.floor(n * 0.15);
      let testCount = n - trainCount - valCount;
      if(n>0 && trainCount===0){ trainCount = 1; if(valCount>0) { valCount = Math.max(0, valCount-1); } else if(testCount>0){ testCount = Math.max(0, testCount-1); } }
      if(n>1 && valCount===0 && testCount===0 && trainCount>1){ valCount = 1; trainCount = Math.max(1, trainCount-1); }

      report.train_per_part[pid] = trainCount;
      report.val_per_part[pid] = valCount;
      report.test_per_part[pid] = testCount;

      // create folder
      const partTrain = path.join(TRAIN, `PART_${pid}`);
      const partVal = path.join(VAL, `PART_${pid}`);
      const partTest = path.join(TEST, `PART_${pid}`);
      ensureDir(partTrain); ensureDir(partVal); ensureDir(partTest);

      // iterate images and copy according to split
      let idx = 0;
      const seen = new Set();
      imgs.forEach(fn=>{
        if(seen.has(fn)) { report.duplicate_references.push({ part: pid, file: fn }); return; }
        seen.add(fn);
        const src = path.join(UPLOADS, fn);
        const exists = fs.existsSync(src);
        if(!exists){ report.total_missing += 1; return; }
        const kind = isJpegOrPng(src);
        if(!kind){ report.total_invalid += 1; return; }
        // determine dest
        let destFolder;
        if(idx < trainCount) destFolder = partTrain;
        else if(idx < trainCount + valCount) destFolder = partVal;
        else destFolder = partTest;
        const dest = path.join(destFolder, fn);
        try{ if(!fs.existsSync(dest)) fs.copyFileSync(src, dest); report.total_exported += 1; } catch(e){ console.error('COPY_ERROR', src, e.message); }
        idx += 1;
      });

    }); // end parts loop

    // duplicates across parts
    const duplicatesAcross = [];
    Object.keys(filenameToParts).forEach(fn=>{ if(filenameToParts[fn].length>1) duplicatesAcross.push({ file: fn, parts: filenameToParts[fn] }); });
    report.duplicate_references_across_parts = duplicatesAcross;

    // stats
    const counts = parts.map(p=>p.images.length);
    report.min_images_per_part = counts.length? Math.min(...counts):0;
    report.max_images_per_part = counts.length? Math.max(...counts):0;
    report.avg_images_per_part = counts.length? (counts.reduce((a,b)=>a+b,0)/counts.length):0;

    // totals per split
    const totalTrain = Object.values(report.train_per_part).reduce((a,b)=>a+b,0);
    const totalVal = Object.values(report.val_per_part).reduce((a,b)=>a+b,0);
    const totalTest = Object.values(report.test_per_part).reduce((a,b)=>a+b,0);
    report.total_train = totalTrain; report.total_val = totalVal; report.total_test = totalTest;

    // write report file
    fs.writeFileSync(path.join(OUT, 'dataset_report.json'), JSON.stringify(report, null, 2));

    // write README
    const readme = `Spare parts dataset export\n\nThis dataset was exported from the project's MySQL parts table.\n\nSource images: backend/uploads/ (original files are not moved or modified).\n\nEach part from the parts table was exported into a folder: images/{train,val,test}/PART_<id>/.\nTrain/val/test split: approx 70/15/15 per part (see dataset_report.json for exact counts).\n\nNotes:\n- Images were validated by checking JPEG/PNG file signatures. Files failing the signature check were marked invalid and not copied.\n- Missing files (referenced in DB but not found in backend/uploads) are reported in dataset_report.json.\n- There are no YOLO bounding-box labels in the repo; this export prepares a classification/embedding dataset (one folder per class).\n\nLimitations:\n- Some parts have few images; classes with fewer than 3 images should be considered low-data and may require additional photos for robust training.\n- Detection datasets (YOLO) require bounding-box labels which are not present.\n`;
    fs.writeFileSync(path.join(OUT, 'README.md'), readme);

    console.log('EXPORT_COMPLETE', JSON.stringify({ report_file: path.join(OUT,'dataset_report.json'), total_parts: report.total_parts, total_unique_referenced_images: report.total_unique_referenced_images, total_exported: report.total_exported, total_missing: report.total_missing, total_invalid: report.total_invalid }));

    con.end();
  });
});
