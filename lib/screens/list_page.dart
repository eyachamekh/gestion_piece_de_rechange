import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gestion_piece_de_rechange/config/api_config.dart';
import 'package:gestion_piece_de_rechange/screens/result_page.dart';
import 'package:gestion_piece_de_rechange/services/api_service.dart';
import 'package:gestion_piece_de_rechange/services/auth_headers.dart';
import 'package:gestion_piece_de_rechange/services/image_classifier_service.dart';
import 'package:gestion_piece_de_rechange/services/mlkit_translation_service.dart';
import 'package:gestion_piece_de_rechange/services/safety_stock_service.dart';
import 'package:gestion_piece_de_rechange/models/safety_stock_result.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/order_alert_banner.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/widgets/custom_bottom_navigation_bar.dart';

class ListPage extends StatefulWidget {
  final String token;
  final String role;

  const ListPage({required this.token, this.role = 'admin', super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List allParts = [];
  List filteredList = [];
  List _activities = [];
  List<SafetyStockResult> _orderAlerts = [];
  bool _bannerDismissed = false;
  bool loading = true;
  static const int _pageSize = 15;
  int _currentPage = 0;

  int get _pageCount =>
      filteredList.isEmpty ? 1 : (filteredList.length / _pageSize).ceil();

  List get _pageItems {
    final start = _currentPage * _pageSize;
    final safeStart = start > filteredList.length ? filteredList.length : start;
    final end = start + _pageSize > filteredList.length
        ? filteredList.length
        : start + _pageSize;
    return filteredList.sublist(safeStart, end);
  }

  @override
  void initState() {
    super.initState();
    loadParts();
  }

  Future<void> loadParts() async {
    final data = await fetchParts(widget.token);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.url('/api/activities')),
        headers: makeAuthHeaders(widget.token),
      );
      if (res.statusCode == 200) _activities = jsonDecode(res.body);
    } catch (_) {}

    final alerts = SafetyStockService.getOrderAlerts(
      parts: data,
      activities: _activities,
    );

    setState(() {
      allParts = data;
      filteredList = data;
      _currentPage = 0;
      _orderAlerts = alerts;
      _bannerDismissed = false;
      loading = false;
    });
  }

  Future<void> _deletePart(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const TranslatedText('Delete Part'),
        content: const TranslatedText(
          'Are you sure you want to delete this part?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: STBG.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const TranslatedText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await http.delete(
      Uri.parse(ApiConfig.url('/api/parts/$id')),
      headers: makeAuthHeaders(widget.token),
    );
    setState(() {
      allParts.removeWhere((p) => p['id'] == id);
      filteredList.removeWhere((p) => p['id'] == id);
      if (_currentPage > 0 && _currentPage >= _pageCount) {
        _currentPage = _pageCount - 1;
      }
    });
  }

  void _showAddDialog() {
    final refCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final fournCtrl = TextEditingController();
    final List<File?> images = List<File?>.filled(7, null);
    final picker = ImagePicker();

    Future<ImageSource?> pickSource() async {
      return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const TranslatedText('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const TranslatedText('Take a picture'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const TranslatedText('Add New Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: langNotifier,
                  builder: (_, lang, __) => ValueListenableBuilder<int>(
                    valueListenable:
                        MLKitTranslationService.instance.translationVersion,
                    builder: (_, __, ___) => Column(
                      children: [
                        DialogField(
                          ctrl: refCtrl,
                          label: t('Reference'),
                          icon: Icons.tag_rounded,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: nameCtrl,
                          label: t('Part Name'),
                          icon: Icons.label_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: fournCtrl,
                          label: t('Supplier Reference'),
                          icon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: locCtrl,
                          label: t('Location'),
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: qtyCtrl,
                          label: t('Quantity'),
                          icon: Icons.numbers_rounded,
                          numeric: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Photos: ${images.where((img) => img != null).length} / 7 (minimum 3)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: STBG.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < images.length; i++)
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: GestureDetector(
                          onTap: () async {
                            final source = await pickSource();
                            if (source == null) return;
                            final picked = await picker.pickImage(
                              source: source,
                            );
                            if (picked != null) {
                              setD(() => images[i] = File(picked.path));
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: STBG.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: STBG.steel.withOpacity(0.25),
                                  ),
                                  image: images[i] != null
                                      ? DecorationImage(
                                          image: FileImage(images[i]!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: images[i] == null
                                    ? const Center(
                                        child: Icon(
                                          Icons.add_a_photo_outlined,
                                          color: STBG.steel,
                                          size: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              if (images[i] != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (images.length <= 3) return;
                                      setD(() => images[i] = null);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (images.length < 7)
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: GestureDetector(
                          onTap: () => setD(() => images.add(null)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: STBG.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: STBG.steel.withOpacity(0.25),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: STBG.steel,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const TranslatedText('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: STBG.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final selectedCount = images.where((img) => img != null).length;
                if (selectedCount < 3 || selectedCount > 7) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please add at least 3 photos and no more than 7.',
                      ),
                    ),
                  );
                  return;
                }

                final uri = Uri.parse(ApiConfig.url('/api/parts'));
                final req = http.MultipartRequest('POST', uri)
                  ..headers['Authorization'] = 'Bearer ${widget.token}'
                  ..fields['reference'] = refCtrl.text
                  ..fields['location'] = locCtrl.text
                  ..fields['quantity'] = qtyCtrl.text
                  ..fields['name'] = nameCtrl.text
                  ..fields['fournisseur_reference'] = fournCtrl.text;

                for (int i = 0; i < images.length; i++) {
                  final image = images[i];
                  if (image != null) {
                    req.files.add(
                      await http.MultipartFile.fromPath(
                        'image${i + 1}',
                        image.path,
                      ),
                    );
                    try {
                      final emb = await imageClassifierService.getEmbedding(
                        image,
                      );
                      req.fields['embedding${i + 1}'] = jsonEncode(emb);
                    } catch (e) {
                      debugPrint('Embedding calculation error: $e');
                    }
                  }
                }

                final streamed = await req.send();
                if (!mounted) return;
                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  Navigator.pop(context);
                  loadParts();
                } else {
                  final body = await streamed.stream.bytesToString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error ${streamed.statusCode}: $body'),
                    ),
                  );
                }
              },
              child: const TranslatedText('Add Part'),
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _rotateImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;
    final rotated = img.copyRotate(decoded, angle: 90);
    final outBytes = img.encodeJpg(rotated);
    final tmp = await getTemporaryDirectory();
    final newFile = File(
      '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await newFile.writeAsBytes(outBytes);
    return newFile;
  }

  Future<File> _rotateNetworkImage(String url) async {
    final res = await http.get(Uri.parse(url));
    final decoded = img.decodeImage(res.bodyBytes);
    if (decoded == null) throw Exception('Cannot decode image');
    final rotated = img.copyRotate(decoded, angle: 90);
    final outBytes = img.encodeJpg(rotated);
    final tmp = await getTemporaryDirectory();
    final file = File(
      '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(outBytes);
    return file;
  }

  void _showEditDialog(Map item) {
    final refCtrl = TextEditingController(text: item['reference'] ?? '');
    final locCtrl = TextEditingController(text: item['location'] ?? '');
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());
    final nameCtrl = TextEditingController(text: item['name'] ?? '');
    final fournCtrl = TextEditingController(
      text: item['fournisseur_reference'] ?? '',
    );
    // existing[i] = server filename, null means slot is empty or replaced
    final List<String?> existing = List.generate(
      7,
      (i) => item['image${i + 1}'] as String?,
    );
    final List<XFile?> newImages = List<XFile?>.filled(7, null);
    final picker = ImagePicker();

    Future<ImageSource?> pickSource() async {
      return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const TranslatedText('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const TranslatedText('Take a picture'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const TranslatedText('Edit Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: langNotifier,
                  builder: (_, lang, __) => ValueListenableBuilder<int>(
                    valueListenable:
                        MLKitTranslationService.instance.translationVersion,
                    builder: (_, __, ___) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DialogField(
                          ctrl: refCtrl,
                          label: t('Reference'),
                          icon: Icons.tag_rounded,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: nameCtrl,
                          label: t('Part Name'),
                          icon: Icons.label_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: fournCtrl,
                          label: t('Supplier Reference'),
                          icon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: locCtrl,
                          label: t('Location'),
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 10),
                        DialogField(
                          ctrl: qtyCtrl,
                          label: t('Quantity'),
                          icon: Icons.numbers_rounded,
                          numeric: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < 7; i++)
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: GestureDetector(
                          onTap: () async {
                            final source = await pickSource();
                            if (source == null) return;
                            final picked = await picker.pickImage(
                              source: source,
                            );
                            if (picked != null) {
                              setD(() {
                                newImages[i] = picked;
                                existing[i] = null; // replaced
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: STBG.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: STBG.steel.withOpacity(0.25),
                                  ),
                                  image: newImages[i] != null
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(newImages[i]!.path),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : existing[i] != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            ApiConfig.uploadUrl(existing[i]!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    (newImages[i] == null &&
                                        existing[i] == null)
                                    ? const Center(
                                        child: Icon(
                                          Icons.add_a_photo_outlined,
                                          color: STBG.steel,
                                          size: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              if (newImages[i] != null || existing[i] != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setD(() {
                                      newImages[i] = null;
                                      existing[i] = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              if (newImages[i] != null || existing[i] != null)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      try {
                                        if (newImages[i] != null) {
                                          final rotated =
                                              await _rotateImageFile(
                                                File(newImages[i]!.path),
                                              );
                                          setD(
                                            () => newImages[i] = XFile(
                                              rotated.path,
                                            ),
                                          );
                                        } else if (existing[i] != null) {
                                          final rotated =
                                              await _rotateNetworkImage(
                                                ApiConfig.uploadUrl(
                                                  existing[i]!,
                                                ),
                                              );
                                          setD(() {
                                            newImages[i] = XFile(rotated.path);
                                            existing[i] = null;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('Rotate error: $e');
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.rotate_right,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const TranslatedText('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: STBG.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final previousQuantity =
                    int.tryParse(item['quantity'].toString()) ?? 0;
                final updatedQuantity = int.tryParse(qtyCtrl.text.trim());
                if (updatedQuantity == null || updatedQuantity < 0) return;

                final uri = Uri.parse(
                  ApiConfig.url('/api/parts/${item['id']}'),
                );
                final req = http.MultipartRequest('PUT', uri)
                  ..headers['Authorization'] = 'Bearer ${widget.token}'
                  ..fields['reference'] = refCtrl.text
                  ..fields['location'] = locCtrl.text
                  ..fields['quantity'] = updatedQuantity.toString()
                  ..fields['name'] = nameCtrl.text
                  ..fields['fournisseur_reference'] = fournCtrl.text;
                for (int i = 0; i < 7; i++) {
                  final image = newImages[i];
                  if (image != null) {
                    req.files.add(
                      await http.MultipartFile.fromPath(
                        'image${i + 1}',
                        image.path,
                      ),
                    );
                    try {
                      final emb = await imageClassifierService.getEmbedding(
                        File(image.path),
                      );
                      req.fields['embedding${i + 1}'] = jsonEncode(emb);
                    } catch (e) {
                      debugPrint('Embedding calculation error: $e');
                    }
                  } else if (existing[i] == null) {
                    // slot was cleared — tell backend to remove it
                    req.fields['clear_image${i + 1}'] = '1';
                  }
                }
                final streamed = await req.send();
                if (!mounted) return;
                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  if (updatedQuantity != previousQuantity) {
                    final now = formatLocalDateTimeForApi(DateTime.now());
                    addToHistory({
                      'reference': refCtrl.text,
                      'name': nameCtrl.text,
                      'takenBy': 'Admin',
                      'quantity': (updatedQuantity - previousQuantity).abs(),
                      'previousQuantity': previousQuantity,
                      'newQuantity': updatedQuantity,
                      'action': updatedQuantity > previousQuantity
                          ? 'added'
                          : 'reduced',
                      'date': now,
                    });
                    await saveHistory();
                  }
                  Navigator.pop(context);
                  loadParts();
                } else {
                  final body = await streamed.stream.bytesToString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error ${streamed.statusCode}: $body'),
                    ),
                  );
                }
              },
              child: const TranslatedText('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTakeDialog(Map item) {
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final int available = item['quantity'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const TranslatedText('Withdraw Parts'),
        content: ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => ValueListenableBuilder<int>(
            valueListenable:
                MLKitTranslationService.instance.translationVersion,
            builder: (_, __, ___) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogField(
                  ctrl: nameCtrl,
                  label: t('Person name'),
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 10),
                DialogField(
                  ctrl: qtyCtrl,
                  label: t('Quantity'),
                  icon: Icons.remove_circle_outline,
                  numeric: true,
                  helper: '${t('Available')}: $available',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: STBG.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final take = int.tryParse(qtyCtrl.text) ?? 0;
              if (take <= 0 || take > available || nameCtrl.text.trim().isEmpty)
                return;
              final newQty = available - take;
              final res = await http.put(
                Uri.parse(ApiConfig.url('/api/parts/${item['id']}')),
                headers: authHeaders(widget.token, json: true),
                body: jsonEncode({
                  'reference': item['reference'],
                  'location': item['location'],
                  'quantity': newQty,
                  'name': item['name'],
                  'fournisseur_reference': item['fournisseur_reference'],
                }),
              );
              if (res.statusCode == 200) {
                final now = formatLocalDateTimeForApi(DateTime.now());
                await http.post(
                  Uri.parse(ApiConfig.url('/api/activities')),
                  headers: authHeaders(widget.token, json: true),
                  body: jsonEncode({
                    'part_id': item['id'],
                    'reference': item['reference'],
                    'taken_by': nameCtrl.text.trim(),
                    'quantity': take,
                    'date': now,
                  }),
                );
                addToHistory({
                  'reference': item['reference'],
                  'name': item['name'],
                  'takenBy': nameCtrl.text.trim(),
                  'quantity': take,
                  'date': now,
                });
                saveHistory();
                Navigator.pop(context);
                loadParts();
              }
            },
            child: const TranslatedText('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    DateTime? from;
    DateTime? to;
    bool incE = true;
    bool incS = true;
    bool incSt = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => ValueListenableBuilder<int>(
            valueListenable:
                MLKitTranslationService.instance.translationVersion,
            builder: (_, __, ___) => Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                36 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: STBG.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: STBG.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t('Export to Excel'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: STBG.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(
                        'Generate a report with Entrée, Sortie, and Stock sheets.',
                      ),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t('Period'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: STBG.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DatePickerButton(
                            label: t('From'),
                            date: from,
                            onPick: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) setS(() => from = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DatePickerButton(
                            label: t('To'),
                            date: to,
                            onPick: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) setS(() => to = d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('Include in export'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: STBG.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    ExportCheckbox(
                      label: t('Entrées'),
                      value: incE,
                      onChanged: (v) => setS(() => incE = v ?? true),
                    ),
                    ExportCheckbox(
                      label: t('Sorties'),
                      value: incS,
                      onChanged: (v) => setS(() => incS = v ?? true),
                    ),
                    ExportCheckbox(
                      label: t('État de stock'),
                      value: incSt,
                      onChanged: (v) => setS(() => incSt = v ?? true),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: STBG.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          t('Download Excel'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () async {
                          if (from == null || to == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('Please select a date range')),
                              ),
                            );
                            return;
                          }
                          if (!incE && !incS && !incSt) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('Select at least one section')),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _generateExcel(
                            from!,
                            to!,
                            includeEntree: incE,
                            includeSortie: incS,
                            includeStock: incSt,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _saveExcelBytes(List<int> bytes, String fileName) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      final picked = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (picked == null) return null;
      final path = picked.toLowerCase().endsWith('.xlsx')
          ? picked
          : '$picked.xlsx';
      await File(path).writeAsBytes(data);
      return path;
    } catch (_) {}
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final path = '${dir.path}/$fileName';
        await File(path).writeAsBytes(data);
        return path;
      }
    } catch (_) {}
    final doc = await getApplicationDocumentsDirectory();
    final path = '${doc.path}/$fileName';
    await File(path).writeAsBytes(data);
    return path;
  }

  void _revealFileInFolder(String filePath) {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [File(filePath).parent.path]);
      }
    } catch (_) {}
  }

  Future<void> _generateExcel(
    DateTime from,
    DateTime to, {
    required bool includeEntree,
    required bool includeSortie,
    required bool includeStock,
  }) async {
    Future<String> tr(String text) async {
      return await MLKitTranslationService.instance.translate(
        text,
        targetLang: langNotifier.value,
      );
    }

    String fromStr = formatLocalDateOnly(from);
    String toStr = formatLocalDateOnly(to);
    if (fromStr.compareTo(toStr) > 0) {
      final t = fromStr;
      fromStr = toStr;
      toStr = t;
    }

    final res = await http.get(
      Uri.parse(ApiConfig.url('/api/export?from=$fromStr&to=$toStr')),
      headers: makeAuthHeaders(widget.token),
    );
    if (res.statusCode != 200) {
      if (!mounted) return;
      final failText = await tr('Export failed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failText: ${res.statusCode}')));
      return;
    }

    try {
      final data = jsonDecode(res.body);
      final List entrees = data['entrees'] ?? [];
      List<Map<String, dynamic>> sorties = [];
      for (final e in (data['sorties'] ?? []) as List) {
        if (e is Map) sorties.add(Map<String, dynamic>.from(e));
      }
      final List stock = data['stock'] ?? [];

      if (includeSortie) {
        final keys = <String>{};
        for (final s in sorties) {
          keys.add(
            '${s['reference']}|${s['taken_by']}|${s['quantity']}|${s['date']}',
          );
        }
        for (final h in appHistory) {
          final raw = h['date']?.toString() ?? '';
          if (raw.length < 10) continue;
          final day = raw.substring(0, 10);
          if (day.compareTo(fromStr) < 0 || day.compareTo(toStr) > 0) continue;
          final row = <String, dynamic>{
            'reference': h['reference'],
            'taken_by': h['takenBy'],
            'quantity': h['quantity'],
            'date': h['date'],
          };
          final k =
              '${row['reference']}|${row['taken_by']}|${row['quantity']}|${row['date']}';
          if (!keys.contains(k)) {
            keys.add(k);
            sorties.add(row);
          }
        }
        sorties.sort(
          (a, b) => (a['date']?.toString() ?? '').compareTo(
            b['date']?.toString() ?? '',
          ),
        );
      }

      final trEntree = await tr('Entrée');
      final trSortie = await tr('Sortie');
      final trStockState = await tr('État de stock');

      final excel = xl.Excel.createExcel();
      final shE = excel[trEntree];
      final shS = excel[trSortie];
      final shSt = excel[trStockState];
      excel.delete('Sheet1');
      final titleStyle = xl.CellStyle(
        bold: true,
        fontSize: 13,
        backgroundColorHex: xl.ExcelColor.fromHexString('#0A1628'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      );
      final headerStyle = xl.CellStyle(
        bold: true,
        backgroundColorHex: xl.ExcelColor.fromHexString('#BBDEFB'),
        fontColorHex: xl.ExcelColor.fromHexString('#0D47A1'),
      );

      Future<void> fill(
        xl.Sheet sh,
        bool inc,
        Future<void> Function(
          void Function(String) wT,
          void Function(List<String>) wH,
          void Function(List) wR,
        )
        build,
      ) async {
        int row = 0;
        void wT(String text) {
          final c = sh.cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
          );
          c.value = xl.TextCellValue(text);
          c.cellStyle = titleStyle;
          row++;
        }

        void wH(List<String> hs) {
          for (int i = 0; i < hs.length; i++) {
            final c = sh.cell(
              xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
            );
            c.value = xl.TextCellValue(hs[i]);
            c.cellStyle = headerStyle;
          }
          row++;
        }

        void wR(List vs) {
          for (int i = 0; i < vs.length; i++) {
            final v = vs[i];
            sh
                .cell(
                  xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
                )
                .value = v is int
                ? xl.IntCellValue(v)
                : xl.TextCellValue(v?.toString() ?? '');
          }
          row++;
        }

        if (!inc) {
          wT('—');
          wR([await tr('Section not included in this export.'), '', '', '']);
          return;
        }
        await build(wT, wH, wR);
      }

      await fill(shE, includeEntree, (wT, wH, wR) async {
        wT('${await tr('ENTRÉE')}  ($fromStr → $toStr)');
        wH([
          await tr('Référence'),
          await tr('Emplacement'),
          await tr('Quantité ajoutée'),
          await tr('Date'),
        ]);
        if (entrees.isEmpty) {
          wR([await tr('Aucune entrée dans cette période'), '', '', '']);
        } else {
          for (final e in entrees) {
            wR([e['reference'], e['location'], e['quantity'], e['created_at']]);
          }
        }
      });

      await fill(shS, includeSortie, (wT, wH, wR) async {
        wT('${await tr('SORTIE')}  ($fromStr → $toStr)');
        wH([
          await tr('Référence'),
          await tr('Pris par'),
          await tr('Quantité prise'),
          await tr('Date'),
        ]);
        if (sorties.isEmpty) {
          wR([await tr('Aucune sortie dans cette période'), '', '', '']);
        } else {
          for (final s in sorties) {
            wR([s['reference'], s['taken_by'], s['quantity'], s['date']]);
          }
        }
      });

      await fill(shSt, includeStock, (wT, wH, wR) async {
        wT('${await tr('ÉTAT DE STOCK')} au $toStr');
        wH([
          await tr('Référence'),
          await tr('Emplacement'),
          await tr('Quantité actuelle'),
        ]);
        if (stock.isEmpty) {
          wR([await tr('Aucune pièce'), '', '']);
        } else {
          for (final s in stock) {
            wR([s['reference'], s['location'], s['quantity']]);
          }
        }
      });

      final encoded = excel.encode();
      if (encoded == null) throw Exception(await tr('Excel encoding failed'));
      final fileName = '${await tr('report')}_${fromStr}_${toStr}.xlsx';
      final savedPath = await _saveExcelBytes(encoded, fileName);
      if (!mounted || savedPath == null) return;
      final desktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            desktop ? await tr('File saved successfully.') : '✅ $savedPath',
          ),
          backgroundColor: STBG.success,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: desktop
              ? SnackBarAction(
                  label: await tr('Show in folder'),
                  textColor: Colors.white,
                  onPressed: () => _revealFileInFolder(savedPath),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errText = await tr('Error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errText: $e'), backgroundColor: STBG.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: STBG.headerGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x35000000),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TranslatedText(
                      'Spare Parts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      'Inventory management',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ValueListenableBuilder<String>(
                              valueListenable: langNotifier,
                              builder: (_, lang, __) =>
                                  ValueListenableBuilder<int>(
                                    valueListenable: MLKitTranslationService
                                        .instance
                                        .translationVersion,
                                    builder: (_, __, ___) => TextField(
                                      decoration: InputDecoration(
                                        hintText: t('Search parts...'),
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: Colors.grey[400],
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (v) => setState(() {
                                        filteredList = allParts.where((item) {
                                          final q = v.toLowerCase();
                                          return (item['reference'] ?? '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(q) ||
                                              (item['fournisseur_reference'] ??
                                                      '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(q) ||
                                              (item['name'] ?? '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(q);
                                        }).toList();
                                        _currentPage = 0;
                                      }),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAdmin) ...[
                          HeaderIconBtn(
                            icon: Icons.download_rounded,
                            onTap: () => _showExportSheet(context),
                          ),
                          const SizedBox(width: 8),
                          HeaderIconBtn(
                            icon: Icons.add_rounded,
                            onTap: _showAddDialog,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: STBG.steel),
                      )
                    : Column(
                        children: [
                          if (isAdmin &&
                              _orderAlerts.isNotEmpty &&
                              !_bannerDismissed)
                            OrderAlertBanner(
                              alerts: _orderAlerts,
                              onDismiss: () =>
                                  setState(() => _bannerDismissed = true),
                              onTapAlert: (alert) {
                                final part = allParts.firstWhere(
                                  (p) =>
                                      (p['reference'] ?? '')
                                          .toString()
                                          .toLowerCase() ==
                                      alert.reference.toLowerCase(),
                                  orElse: () => null,
                                );
                                if (part != null) {
                                  Navigator.push(
                                    context,
                                    createRoute(
                                      ResultPage(
                                        data: part,
                                        token: widget.token,
                                        role: widget.role,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          Expanded(
                            child: filteredList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 56,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 10),
                                        const TranslatedText(
                                          'No parts found',
                                          style: TextStyle(
                                            color: STBG.textSecondary,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      80,
                                    ),
                                    itemCount:
                                        _pageItems.length +
                                        (filteredList.isNotEmpty &&
                                                _pageCount > 1
                                            ? 1
                                            : 0),
                                    itemBuilder: (ctx, i) {
                                      if (i == _pageItems.length) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            4,
                                            16,
                                            12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                tooltip: 'Previous page',
                                                onPressed: _currentPage == 0
                                                    ? null
                                                    : () => setState(
                                                        () => _currentPage--,
                                                      ),
                                                icon: const Icon(
                                                  Icons.chevron_left_rounded,
                                                ),
                                              ),
                                              Text(
                                                '${_currentPage + 1} / $_pageCount',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: STBG.textPrimary,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Next page',
                                                onPressed:
                                                    _currentPage >=
                                                        _pageCount - 1
                                                    ? null
                                                    : () => setState(
                                                        () => _currentPage++,
                                                      ),
                                                icon: const Icon(
                                                  Icons.chevron_right_rounded,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      final item = _pageItems[i];
                                      final int qty = item['quantity'] ?? 0;
                                      final bool low = qty <= 5;
                                      SafetyStockResult? alert;
                                      for (final a in _orderAlerts) {
                                        if (a.reference.toLowerCase() ==
                                            (item['reference'] ?? '')
                                                .toString()
                                                .toLowerCase()) {
                                          alert = a;
                                          break;
                                        }
                                      }
                                      return Dismissible(
                                        key: Key(item['id'].toString()),
                                        direction: isAdmin
                                            ? DismissDirection.endToStart
                                            : DismissDirection.none,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                            right: 20,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: STBG.danger,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onDismissed: isAdmin
                                            ? (_) => _deletePart(item['id'])
                                            : null,
                                        child: InkWell(
                                          onTap: () => Navigator.push(
                                            ctx,
                                            createRoute(
                                              ResultPage(
                                                data: item,
                                                token: widget.token,
                                                role: widget.role,
                                              ),
                                            ),
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: !isAdmin
                                                  ? null
                                                  : alert != null
                                                  ? Border.all(
                                                      color: STBG.gold
                                                          .withOpacity(0.5),
                                                      width: 1.5,
                                                    )
                                                  : low
                                                  ? Border.all(
                                                      color: STBG.danger
                                                          .withOpacity(0.25),
                                                    )
                                                  : null,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x0D000000),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                if (isAdmin &&
                                                    item['image1'] == null &&
                                                    item['image2'] == null &&
                                                    item['image3'] == null)
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showEditDialog(item),
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 7,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: STBG.danger
                                                            .withOpacity(0.08),
                                                        borderRadius:
                                                            const BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: STBG.danger
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .image_not_supported_outlined,
                                                            size: 13,
                                                            color: STBG.danger,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: TranslatedText(
                                                              'No photo — Tap to add',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    STBG.danger,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .add_photo_alternate_outlined,
                                                            size: 14,
                                                            color: STBG.danger,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 56,
                                                            height: 56,
                                                            decoration:
                                                                BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        11,
                                                                      ),
                                                                  color: Colors
                                                                      .grey[200],
                                                                ),
                                                            child: Builder(
                                                              builder: (ctxImg) {
                                                                final img =
                                                                    (item['image1'] ??
                                                                    item['image2'] ??
                                                                    item['image3']);
                                                                if (img !=
                                                                    null) {
                                                                  final heroTag =
                                                                      'part-${item['id']}-img-0';
                                                                  return Hero(
                                                                    tag:
                                                                        heroTag,
                                                                    child: ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            11,
                                                                          ),
                                                                      child: Image.network(
                                                                        ApiConfig.uploadUrl(
                                                                          img.toString(),
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder:
                                                                            (
                                                                              c,
                                                                              e,
                                                                              s,
                                                                            ) => const Icon(
                                                                              Icons.broken_image,
                                                                              color: Colors.grey,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                return Container(
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        10,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    gradient: const LinearGradient(
                                                                      colors: [
                                                                        STBG.navy,
                                                                        STBG.steel,
                                                                      ],
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          11,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .settings_outlined,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 19,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 14,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  item['reference'] ??
                                                                      '-',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        14,
                                                                    color: STBG
                                                                        .textPrimary,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 3,
                                                                ),
                                                                if ((item['fournisseur_reference'] ??
                                                                        '')
                                                                    .toString()
                                                                    .isNotEmpty)
                                                                  Text(
                                                                    item['fournisseur_reference']
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                      color: STBG
                                                                          .textSecondary,
                                                                      fontSize:
                                                                          11,
                                                                    ),
                                                                  ),
                                                                if ((item['name'] ??
                                                                        '')
                                                                    .toString()
                                                                    .isNotEmpty)
                                                                  Text(
                                                                    item['name']
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                      color: STBG
                                                                          .textSecondary,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  )
                                                                else
                                                                  Text(
                                                                    item['location'] ??
                                                                        '-',
                                                                    style: const TextStyle(
                                                                      color: STBG
                                                                          .textSecondary,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          if (isAdmin)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical: 7,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: low
                                                                    ? STBG.danger
                                                                          .withOpacity(
                                                                            0.10,
                                                                          )
                                                                    : STBG.navy
                                                                          .withOpacity(
                                                                            0.08,
                                                                          ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                '$qty',
                                                                style: TextStyle(
                                                                  color: low
                                                                      ? STBG.danger
                                                                      : STBG.navy,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          if (isAdmin)
                                                            IconBtn(
                                                              icon: Icons
                                                                  .remove_circle_outline_rounded,
                                                              color:
                                                                  Colors.orange,
                                                              onTap: () =>
                                                                  _showTakeDialog(
                                                                    item,
                                                                  ),
                                                            ),
                                                          IconBtn(
                                                            icon: Icons
                                                                .visibility_outlined,
                                                            color: STBG.steel,
                                                            onTap: () =>
                                                                Navigator.push(
                                                                  ctx,
                                                                  createRoute(
                                                                    ResultPage(
                                                                      data:
                                                                          item,
                                                                      token: widget
                                                                          .token,
                                                                      role: widget
                                                                          .role,
                                                                    ),
                                                                  ),
                                                                ),
                                                          ),
                                                          if (isAdmin)
                                                            IconBtn(
                                                              icon: Icons
                                                                  .edit_outlined,
                                                              color:
                                                                  STBG.success,
                                                              onTap: () =>
                                                                  _showEditDialog(
                                                                    item,
                                                                  ),
                                                            ),
                                                          if (isAdmin)
                                                            IconBtn(
                                                              icon: Icons
                                                                  .delete_outline_rounded,
                                                              color:
                                                                  STBG.danger,
                                                              onTap: () =>
                                                                  _deletePart(
                                                                    item['id'],
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: 0,
              token: widget.token,
              role: widget.role,
            ),
          ),
        ],
      ),
    );
  }
}
