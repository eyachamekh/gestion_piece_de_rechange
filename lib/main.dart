import 'package:flutter/material.dart';
// import 'data/data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spare Parts App',
      // home: HomePage(),
      home: LoginPage(),
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.blue),
            SizedBox(height: 20),

            Text(
              "Login",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  createRoute(HomePage()),
                );
              },
              child: Text("Login"),
            )
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalParts = 0;
  int lowStockCount = 0;
  int scannedCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final parts = await fetchParts();
      setState(() {
        totalParts = parts.length;
        lowStockCount = parts.where((p) => (p["quantity"] ?? 0) <= 5).length;
        scannedCount = parts.where((p) => p["scanned"] == true).length;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Welcome back 👋",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  "Spare Parts Manager",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                loading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        children: [
                          _statCard("Parts", "$totalParts", Icons.inventory_2_outlined),
                          SizedBox(width: 12),
                          _statCard("Scanned", "$scannedCount", Icons.qr_code_scanner),
                          SizedBox(width: 12),
                          _statCard("Low Stock", "$lowStockCount", Icons.warning_amber_outlined),
                        ],
                      ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quick Actions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _actionCard(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: "Start Scanning",
                  subtitle: "Identify a part using your camera",
                  color: Color(0xFF1565C0),
                  onTap: () => Navigator.push(context, createRoute(ScanPage())),
                ),
                SizedBox(height: 12),
                _actionCard(
                  context,
                  icon: Icons.list_alt,
                  title: "View Spare Parts",
                  subtitle: "Browse and search all parts",
                  color: Color(0xFF00897B),
                  onTap: () => Navigator.push(context, createRoute(ListPage())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      Navigator.push(context, createRoute(LoadingPage(image: _image)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text("Scan a Part",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Use your camera or gallery to identify a spare part",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Color(0xFF1565C0).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.document_scanner_outlined,
                        size: 70, color: Color(0xFF1565C0)),
                  ),
                  SizedBox(height: 40),
                  _scanOption(
                    icon: Icons.camera_alt_outlined,
                    title: "Take a Photo",
                    subtitle: "Use your camera to capture the part",
                    onTap: () => pickImage(ImageSource.camera),
                  ),
                  SizedBox(height: 16),
                  _scanOption(
                    icon: Icons.photo_library_outlined,
                    title: "Choose from Gallery",
                    subtitle: "Select an existing image",
                    onTap: () => pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF1565C0), size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final Map data;
  ResultPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final int qty = data["quantity"] ?? 0;
    final bool lowStock = qty <= 5;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text("Part Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Identified spare part information",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      children: [
                        if (data["image"] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(data["image"],
                                height: 140, fit: BoxFit.contain),
                          ),
                        SizedBox(height: 20),
                        _infoTile(Icons.build_outlined, "Part Name", data["piece"] ?? "-"),
                        Divider(height: 1),
                        _infoTile(Icons.tag, "Reference", data["reference"] ?? "-"),
                        Divider(height: 1),
                        _infoTile(Icons.location_on_outlined, "Location", data["location"] ?? "-"),
                        Divider(height: 1),
                        _infoTile(
                          Icons.inventory_2_outlined,
                          "Quantity",
                          qty.toString(),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lowStock
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lowStock ? "Low Stock" : "In Stock",
                              style: TextStyle(
                                color: lowStock ? Colors.red : Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF1565C0), size: 18),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

Widget buildRow(String title, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );
}
//animation 
Route createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(1.0, 0.0);
      var end = Offset.zero;
      var curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

class LoadingPage extends StatefulWidget {
  final File? image;

  LoadingPage({this.image});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        createRoute(ResultPage(data: {
          "piece": "Filtre hydraulique",
          "reference": "FH-4587",
          "location": "Stock A - Shelf 3",
          "quantity": 12,
          "image": "assets/images/filtreHydraulique.png"
        })),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                "Analyzing Part...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Please wait while we identify your part",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List allParts = [];
  List filteredList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadParts();
  }

  Future<void> loadParts() async {
    List data = await fetchParts();
    setState(() {
      allParts = data;
      filteredList = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text("Spare Parts",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("${allParts.length} parts available",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search parts...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredList = allParts.where((item) {
                          return item["piece"]
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey[300]),
                            SizedBox(height: 12),
                            Text("No parts found",
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final int qty = item["quantity"] ?? 0;
                          final bool lowStock = qty <= 5;

                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context, createRoute(ResultPage(data: item))),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Color(0xFF1565C0).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.build_outlined,
                                        color: Color(0xFF1565C0), size: 22),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item["piece"] ?? "-",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        SizedBox(height: 4),
                                        Text(item["reference"] ?? "-",
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: lowStock
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          lowStock ? "Low" : "OK",
                                          style: TextStyle(
                                            color: lowStock
                                                ? Colors.red
                                                : Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text("Qty: $qty",
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11)),
                                    ],
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

//récupération des données depuis le backend
Future<List> fetchParts() async {
  final response =
      await http.get(Uri.parse("http://192.168.100.7:3000/api/parts")); // ipconfig for PC's IPv4
      // await http.get(Uri.parse("http://10.0.2.2:3000/api/parts"));
      

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to load data");
  }
}