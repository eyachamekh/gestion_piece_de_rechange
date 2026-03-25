const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());

app.use(express.json());

const spareParts = [
  {
    piece: "Filtre hydraulique",
    reference: "FH-4587",
    location: "Stock A - Shelf 3",
    quantity: 12,
    image: "assets/images/filtreHydraulique.png",
  },
  {
    piece: "Pompe à eau",
    reference: "PE-1234",
    location: "Stock B - Shelf 1",
    quantity: 5,
    image: "assets/images/filtreHydraulique.png",
  },
];


// GET ALL
app.get("/api/parts", (req, res) => {
  res.json(spareParts);
});

// SEARCH
app.get("/api/parts/search", (req, res) => {
  const query = req.query.q?.toLowerCase();

  const results = spareParts.filter((item) =>
    item.piece.toLowerCase().includes(query)
  );

  res.json(results);
});


// START SERVER
app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});