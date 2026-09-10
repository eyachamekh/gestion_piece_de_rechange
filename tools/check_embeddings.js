const path = require('path'); const mysql = require(path.join(__dirname,'..','backend','node_modules','mysql2'));
const con = mysql.createConnection({ host: 'localhost', user: 'root', password: '', database: 'piece_de_rechanges' });
con.connect(err => {
  if (err) { console.error('DB_CONNECT_ERROR', err.message); process.exit(2); }
  const cols = ['embedding1','embedding2','embedding3','embedding4','embedding5','embedding6','embedding7'];
  let pending = cols.length;
  cols.forEach(col => {
    const q = `SELECT SUM(CASE WHEN ${col} IS NOT NULL AND ${col}!='' THEN 1 ELSE 0 END) AS cnt, SUM(CASE WHEN ${col} IS NOT NULL THEN CHAR_LENGTH(${col}) ELSE 0 END) AS total_len FROM parts`;
    con.query(q, (e, r) => {
      if (e) { console.error('ERR', col, e.message); }
      else { console.log(col, r[0]); }
      if (--pending === 0) {
        // fetch a sample value for embedding1
        con.query("SELECT id, reference, embedding1 FROM parts WHERE embedding1 IS NOT NULL LIMIT 5", (e2, r2) => {
          if (!e2) {
            console.log('SAMPLE_EMBEDDINGS');
            r2.forEach(row => { console.log('PART', row.id, row.reference, 'embedding1_len', row.embedding1 ? row.embedding1.length : 0); console.log(row.embedding1 ? row.embedding1.slice(0,200) : 'NULL'); });
          }
          con.end();
        });
      }
    });
  });
});
