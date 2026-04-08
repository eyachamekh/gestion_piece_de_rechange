import 'package:flutter/material.dart';
// import 'data/data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:translator/translator.dart';
final translator = GoogleTranslator();
final langNotifier = ValueNotifier<String>("en");

Future<String> translateText(String text, String lang) async {
  if (lang == "en") return text;
  var translation = await translator.translate(text, to: lang);
  return translation.text;
}

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const TranslatedText(this.text, {this.style});

  @override
  _TranslatedTextState createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = translateText(widget.text, langNotifier.value);
    langNotifier.addListener(_onLangChanged);
  }

  void _onLangChanged() {
    setState(() {
      _future = translateText(widget.text, langNotifier.value);
    });
  }

  @override
  void dispose() {
    langNotifier.removeListener(_onLangChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        return Text(snapshot.data ?? widget.text, style: widget.style);
      },
    );
  }
}
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void changeLang() {
    if (langNotifier.value == "en") {
      langNotifier.value = "fr";
    } else if (langNotifier.value == "fr") {
      langNotifier.value = "ar";
    } else {
      langNotifier.value = "en";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spare Parts App',
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
            TranslatedText("Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            ValueListenableBuilder<String>(
              valueListenable: langNotifier,
              builder: (_, lang, __) => TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: lang == "fr" ? "E-mail" : lang == "ar" ? "البريد الإلكتروني" : "Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: langNotifier,
              builder: (_, lang, __) => TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: lang == "fr" ? "Mot de passe" : lang == "ar" ? "كلمة المرور" : "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                var result = await login(
                  emailController.text,
                  passwordController.text,
                );
                if (result["success"] == true) {
                  Navigator.push(
                    context,
                    createRoute(HomePage(role: result["role"], token: result["token"])),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: TranslatedText("Login failed")),
                  );
                }
              },
              child: TranslatedText("Login"),
            )
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String role;
  final String token;
  HomePage({required this.role, required this.token});
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
      final parts = await fetchParts(widget.token);
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
                    TranslatedText("Welcome back 👋",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.language, color: Colors.white),
                          onPressed: () => MyApp.of(context)?.changeLang(),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.white),
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            createRoute(LoginPage()),
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
                TranslatedText("Spare Parts Manager",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
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
                TranslatedText("Quick Actions",
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
                if (widget.role == "admin")
                  _actionCard(
                    context,
                    icon: Icons.list_alt,
                    title: "View Spare Parts",
                    subtitle: "Browse and search all parts",
                    color: Color(0xFF00897B),
                    onTap: () => Navigator.push(context, createRoute(ListPage(token: widget.token))),
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
            TranslatedText(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                  TranslatedText(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  TranslatedText(subtitle,
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
                // Text("Scan a Part",
                //     style: TextStyle(
                //         color: Colors.white,
                //         fontSize: 26,
                //         fontWeight: FontWeight.bold))
                TranslatedText("Scan Piece",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                TranslatedText("Use your camera or gallery to identify a spare part",
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
                  TranslatedText(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 3),
                  TranslatedText(subtitle,
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
                TranslatedText("Part Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                TranslatedText("Identified spare part information",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          if (["image1", "image2", "image3"].any((k) => data[k] != null))
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ["image1", "image2", "image3"]
                      .where((k) => data[k] != null)
                      .map((k) => Container(
                            margin: EdgeInsets.only(right: 10),
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                "http://10.0.2.2:3000/uploads/${data[k]}",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ))
                      .toList(),
                ),
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
                        SizedBox(height: 8),
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
                            child: TranslatedText(
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
                TranslatedText(label,
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
              TranslatedText("Analyzing Part...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TranslatedText("Please wait while we identify your part",
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
  final String token;
  ListPage({required this.token});
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
    List data = await fetchParts(widget.token);
    setState(() {
      allParts = data;
      filteredList = data;
      loading = false;
    });
  }

  Future<void> _deletePart(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: TranslatedText("Delete Part"),
        content: TranslatedText("Are you sure you want to delete this part?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: TranslatedText("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: TranslatedText("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await http.delete(
      Uri.parse("http://10.0.2.2:3000/api/parts/$id"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    setState(() {
      allParts.removeWhere((p) => p["id"] == id);
      filteredList.removeWhere((p) => p["id"] == id);
    });
  }

  void _showAddDialog() {
    final refCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final List<File?> images = [null, null, null];
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: TranslatedText("Add Part"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: langNotifier,
                  builder: (_, lang, __) => Column(
                    children: [
                      TextField(controller: refCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Référence" : lang == "ar" ? "المرجع" : "Reference")),
                      SizedBox(height: 8),
                      TextField(controller: locCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Emplacement" : lang == "ar" ? "الموقع" : "Location")),
                      SizedBox(height: 8),
                      TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Quantité" : lang == "ar" ? "الكمية" : "Quantity"), keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TranslatedText("Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (i) => GestureDetector(
                    onTap: () async {
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) setStateDialog(() => images[i] = File(picked.path));
                    },
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Color(0xFF1565C0).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF1565C0).withOpacity(0.3)),
                        image: images[i] != null
                            ? DecorationImage(image: FileImage(images[i]!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: images[i] == null
                          ? Icon(Icons.add_a_photo_outlined, color: Color(0xFF1565C0), size: 28)
                          : null,
                    ),
                  )),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: TranslatedText("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse("http://10.0.2.2:3000/api/parts");
                final request = http.MultipartRequest("POST", uri)
                  ..headers["Authorization"] = "Bearer ${widget.token}"
                  ..fields["reference"] = refCtrl.text
                  ..fields["location"] = locCtrl.text
                  ..fields["quantity"] = qtyCtrl.text;
                for (int i = 0; i < 3; i++) {
                  if (images[i] != null) {
                    request.files.add(await http.MultipartFile.fromPath("image${i + 1}", images[i]!.path));
                  }
                }
                await request.send();
                Navigator.pop(context);
                loadParts();
              },
              child: TranslatedText("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showTakeDialog(Map item) {
    final qtyCtrl = TextEditingController();
    final int available = item["quantity"] ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: TranslatedText("Take Parts"),
        content: ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: lang == "fr" ? "Quantité à prendre" : lang == "ar" ? "الكمية المأخوذة" : "Quantity to take",
              helperText: lang == "fr" ? "Disponible: $available" : lang == "ar" ? "المتاح: $available" : "Available: $available",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: TranslatedText("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final take = int.tryParse(qtyCtrl.text) ?? 0;
              if (take <= 0 || take > available) return;
              final newQty = available - take;
              final res = await http.put(
                Uri.parse("http://10.0.2.2:3000/api/parts/${item["id"]}"),
                headers: {
                  "Authorization": "Bearer ${widget.token}",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({
                  "reference": item["reference"],
                  "location": item["location"],
                  "quantity": newQty,
                }),
              );
              if (res.statusCode == 200) {
                Navigator.pop(context);
                loadParts();
              }
            },
            child: TranslatedText("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map item) {
    final refCtrl = TextEditingController(text: item["reference"] ?? "");
    final locCtrl = TextEditingController(text: item["location"] ?? "");
    final qtyCtrl = TextEditingController(text: item["quantity"].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: TranslatedText("Edit Part"),
        content: ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: refCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Référence" : lang == "ar" ? "المرجع" : "Reference")),
              TextField(controller: locCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Emplacement" : lang == "ar" ? "الموقع" : "Location")),
              TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: lang == "fr" ? "Quantité" : lang == "ar" ? "الكمية" : "Quantity"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: TranslatedText("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final res = await http.put(
                Uri.parse("http://10.0.2.2:3000/api/parts/${item["id"]}"),
                headers: {
                  "Authorization": "Bearer ${widget.token}",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({
                  "reference": refCtrl.text,
                  "location": locCtrl.text,
                  "quantity": int.tryParse(qtyCtrl.text) ?? 0,
                }),
              );
              if (res.statusCode == 200) {
                Navigator.pop(context);
                loadParts();
              }
            },
            child: TranslatedText("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Color(0xFF1565C0),
        child: Icon(Icons.add, color: Colors.white),
      ),
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
                TranslatedText("Spare Parts",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                TranslatedText("${allParts.length} parts available",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: langNotifier,
                    builder: (_, lang, __) => TextField(
                    decoration: InputDecoration(
                      hintText: lang == "fr" ? "Rechercher..." : lang == "ar" ? "بحث..." : "Search parts...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredList = allParts.where((item) {
                          return (item["reference"] ?? "")
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
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
                            TranslatedText("No parts found",
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

                          return Dismissible(
                            key: Key(item["id"].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deletePart(item["id"]),
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
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF1565C0).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.build_outlined,
                                            color: Color(0xFF1565C0), size: 22),
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item["reference"] ?? "-",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14)),
                                            SizedBox(height: 4),
                                            Text(item["location"] ?? "-",
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: lowStock
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: TranslatedText(
                                          lowStock ? "Low" : "OK",
                                          style: TextStyle(
                                            color: lowStock ? Colors.red : Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _iconBtn(Icons.remove_circle_outline, Colors.orange, () => _showTakeDialog(item)),
                                      _iconBtn(Icons.visibility_outlined, Color(0xFF1565C0), () {
                                        Navigator.push(context, createRoute(ResultPage(data: item)));
                                      }),
                                      _iconBtn(Icons.edit_outlined, Color(0xFF00897B), () => _showEditDialog(item)),
                                      _iconBtn(Icons.delete_outline, Colors.red, () => _deletePart(item["id"])),
                                    ],
                                  ),
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
Future<List> fetchParts(String token) async {
  final response = await http.get(
    Uri.parse("http://10.0.2.2:3000/api/parts"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to load data");
  }
}

//Login function
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse("http://10.0.2.2:3000/api/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "password": password,
    }),
  );

  return jsonDecode(response.body);
}