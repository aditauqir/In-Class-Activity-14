import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/fcm_banner.dart';
import '../widgets/phosphor_icons.dart';
import 'profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  final AuthService authService;

  ProductsScreen({
    super.key,
    AuthService? authService,
  }) : authService = authService ?? AuthService();

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _products = FirebaseFirestore.instance.collection('products');
  late final _productStream = _products.snapshots();

  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String? _filterError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _minPriceController.addListener(_onFilterChanged);
    _maxPriceController.addListener(_onFilterChanged);
    _checkAndPopulateIfEmpty();
  }

  Future<void> _checkAndPopulateIfEmpty() async {
    try {
      final doc = await _products.doc('1G1YHEGLhlpMJZLFDv1f').get();
      if (!doc.exists) {
        await _populateDatabase();
      }
    } catch (e) {
      debugPrint('Firestore check error: $e');
    }
  }

  Future<void> _populateDatabase() async {
    final initialProducts = {
      '1G1YHEGLhlpMJZLFDv1f': {'name': 'Autumn Sample', 'price': 0.00},
      '4eSMZKz0o0SYS6QAyRUn': {'name': 'Cedar Mug', 'price': 15.00},
      'D6mltzP7QXuQIQKEMk8f': {'name': 'Wool Scarf', 'price': 32.00},
      'GDHkc9tNeHqX9AJc4BsM': {'name': 'Pumpkin Spice Loaf', 'price': 9.99},
    };
    for (final entry in initialProducts.entries) {
      await _products.doc(entry.key).set(entry.value);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final query = _searchController.text.trim().toLowerCase();
    final minStr = _minPriceController.text.trim();
    final maxStr = _maxPriceController.text.trim();

    double? minVal;
    double? maxVal;
    String? error;

    if (minStr.isNotEmpty) {
      final parsed = double.tryParse(minStr);
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        error = 'Min price must be a valid non-negative number';
      } else {
        minVal = parsed;
      }}

    if (maxStr.isNotEmpty) {
      final parsed = double.tryParse(maxStr);
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        error = 'Max price must be a valid non-negative number';
      } else {
        maxVal = parsed;
      }}

    if (error == null && minVal != null && maxVal != null && minVal > maxVal) {
      error = 'Min price ($minVal) cannot exceed Max price ($maxVal)';
    }

    setState(() {
      _searchQuery = query;
      _minPrice = minVal;
      _maxPrice = maxVal;
      _filterError = error;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _searchQuery = '';
      _minPrice = null;
      _maxPrice = null;
      _filterError = null;
    }); }

  Future<void> _createOrUpdate([QueryDocumentSnapshot<Map<String, dynamic>>? document]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ProductEditor(
        products: _products,
        document: document,
      ),
    ); }

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name" (ID: $id)?',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _products.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "$name" deleted successfully.', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on FirebaseException catch (error) {
      debugPrint('Delete failed (${error.code}): ${error.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed (${error.code}). Check connection/rules.', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Unexpected error on delete: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIcon.arrowLeft, size: 22, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(authService: widget.authService),
              ),
            );
          },
        ),
        title: Text(
          'Autumn Product Manager',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'In-Class 13 Profile & Auth',
            icon: const PhosphorIcon(PhosphorIcon.identificationBadge, size: 26, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(authService: widget.authService),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Top Banner: Activity 14 FCM Courier
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FcmBanner(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Transparent Search and Filter component (no borders, no box background)
                              TextField(
                                controller: _searchController,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search by name',
                                  hintStyle: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black87, width: 1.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: GoogleFonts.outfit(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Min price',
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: GoogleFonts.outfit(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Max price',
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _resetFilters,
                                    child: Text(
                                      'Reset',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_filterError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    _filterError!,
                                    style: GoogleFonts.outfit(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Real-time Firestore Product List Stream
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _productStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Products could not load (${snapshot.error}).\nCheck connection and Firestore permissions.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.red.shade700),
                              ),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Colors.black87),
                            ),
                          ),
                        );
                      }

                      final documents = snapshot.data!.docs;
                      if (documents.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No products yet. Tap + to add one.',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final filteredDocs = documents.where((doc) {
                        final data = doc.data();
                        final rawName = data['name'];
                        final rawPrice = data['price'];

                        if (rawName is! String || rawPrice is! num) return false;
                        final nameLower = rawName.trim().toLowerCase();
                        final price = rawPrice.toDouble();

                        if (_searchQuery.isNotEmpty && !nameLower.contains(_searchQuery)) {
                          return false;
                        }

                        if (_filterError != null) return false;

                        if (_minPrice != null && price < _minPrice!) return false;
                        if (_maxPrice != null && price > _maxPrice!) return false;

                        return true;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No products found matching filters.',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final document = filteredDocs[index];
                              final data = document.data();
                              final name = data['name'];
                              final price = data['price'];
                              final imageUrl = data['imageUrl'] as String?;

                              if (name is! String ||
                                  name.trim().isEmpty ||
                                  price is! num ||
                                  !price.isFinite ||
                                  price < 0) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Invalid product ${document.id}: check name/price types.',
                                    style: GoogleFonts.outfit(color: Colors.red.shade700),
                                  ),
                                );
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8FD),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            price.toDouble().toStringAsFixed(2),
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'ID: ${document.id}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit product',
                                      icon: const PhosphorIcon(PhosphorIcon.pencilSimple, size: 20, color: Colors.black54),
                                      onPressed: () => _createOrUpdate(document),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete product',
                                      icon: const PhosphorIcon(PhosphorIcon.trash, size: 20, color: Colors.black54),
                                      onPressed: () => _deleteProduct(document.id, name),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: filteredDocs.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create product',
        backgroundColor: const Color(0xFFEDE7F6),
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 2,
        onPressed: () => _createOrUpdate(),
        child: const PhosphorIcon(PhosphorIcon.plus, size: 24, color: Colors.black87),
      ),
    );
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({
    super.key,
    required this.products,
    this.document,
  });

  final CollectionReference<Map<String, dynamic>> products;
  final QueryDocumentSnapshot<Map<String, dynamic>>? document;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.document?.data()['name'] as String? ?? '',
  );
  late final _price = TextEditingController(
    text: widget.document?.data()['price']?.toString() ?? '',
  );
  late final _imageUrl = TextEditingController(
    text: widget.document?.data()['imageUrl'] as String? ?? '',
  );

  var _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final data = <String, Object>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
      if (_imageUrl.text.trim().isNotEmpty) 'imageUrl': _imageUrl.text.trim(),
    };

    try {
      final document = widget.document;
      if (document == null) {
        await widget.products.add(data);
      } else {
        await widget.products.doc(document.id).update(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      debugPrint('Product save failed (${error.code}): ${error.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Save failed (${error.code}). Check connection and permissions.';
      });
    } catch (e) {
      debugPrint('Product save failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Save failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.document == null ? 'Create Product' : 'Edit Product',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || !amount.isFinite || amount < 0
                        ? 'Enter a finite price of zero or more'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  enabled: !_saving,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Firebase Storage / Image URL (Optional)',
                    labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                  ),
                ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _saveError!,
                      style: GoogleFonts.outfit(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Save Product',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
