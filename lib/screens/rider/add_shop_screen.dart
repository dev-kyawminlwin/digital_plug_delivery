import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController(text: '20');
  final _minOrderCtrl = TextEditingController(text: '0');

  String _selectedCategory = 'Coffee & Drinks';
  String? _logoBase64;
  bool _isSaving = false;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);
  static const Color _kBg = Color(0xFFF9FAFB);

  static const List<String> _categories = [
    'Coffee & Drinks',
    'Bubble Tea',
    'Food & Rice',
    'Noodles',
    'Bakery',
    'Desserts',
    'Fresh Juice',
    'Thai Food',
    'Burmese Food',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _minOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    final resized = img.copyResize(decoded, width: 300);
    final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 75));
    setState(() => _logoBase64 = base64Encode(compressed));
  }

  Future<void> _submitShop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final riderDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final riderName = (riderDoc.data() as Map?)?['name'] as String? ?? 'Rider';

    try {
      await FirebaseFirestore.instance.collection('businesses').add({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'category': _selectedCategory,
        'deliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 20.0,
        'minOrderAmount': double.tryParse(_minOrderCtrl.text) ?? 0.0,
        'logo': _logoBase64 ?? '',
        'isOpen': false,
        'ownedByRiderId': uid,
        'ownedByRiderName': riderName,
        'status': 'pending',          // ← SuperAdmin needs to approve
        'rejectionReason': '',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'subscriptionStatus': 'active',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Shop submitted! Waiting for platform approval (usually within 24 hours).')),
            ]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add a Shop',
            style: TextStyle(color: _kDark, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFF3F4F6))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: _kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your shop will appear on the marketplace after the platform approves it — usually within 24 hours.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 13, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Logo picker
            _sectionLabel('Shop Logo'),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _logoBase64 != null ? _kPrimary : const Color(0xFFE5E7EB),
                    width: _logoBase64 != null ? 2 : 1,
                  ),
                ),
                child: _logoBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.memory(base64Decode(_logoBase64!), fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text('Tap to upload logo', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ]),
              ),
            ),
            const SizedBox(height: 20),

            // Basic Info
            _sectionLabel('Basic Info'),
            _card(Column(children: [
              _field(_nameCtrl, 'Shop Name', Icons.storefront_outlined, required: true),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Short Description', Icons.description_outlined, maxLines: 2),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, type: TextInputType.phone),
            ])),
            const SizedBox(height: 20),

            // Category
            _sectionLabel('Category'),
            _card(DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF6B7280), size: 20),
                  border: InputBorder.none),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            )),
            const SizedBox(height: 20),

            // Location
            _sectionLabel('Delivery Info'),
            _card(Column(children: [
              _field(_addressCtrl, 'Shop Address', Icons.location_on_outlined, required: true, maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_deliveryFeeCtrl, 'Delivery Fee (THB)', Icons.motorcycle_outlined,
                    type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_minOrderCtrl, 'Min Order (THB)', Icons.shopping_cart_outlined,
                    type: TextInputType.number)),
              ]),
            ])),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit for Approval',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280), letterSpacing: 0.5)),
      );

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: child,
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kPrimary, width: 2)),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      );
}
