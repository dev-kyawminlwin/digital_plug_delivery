import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ShopSettingsTab extends StatefulWidget {
  final String businessId;
  const ShopSettingsTab({super.key, required this.businessId});

  @override
  State<ShopSettingsTab> createState() => _ShopSettingsTabState();
}

class _ShopSettingsTabState extends State<ShopSettingsTab> {
  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();

  bool _isOpen = false;
  bool _isSaving = false;
  bool _loaded = false;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('businesses').doc(widget.businessId).get();
    final d = doc.data() ?? {};
    setState(() {
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _addressCtrl.text = d['address'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _deliveryFeeCtrl.text = '${(d['deliveryFee'] as num?)?.toInt() ?? 20}';
      _minOrderCtrl.text = '${(d['minOrderAmount'] as num?)?.toInt() ?? 0}';
      _isOpen = d['isOpen'] as bool? ?? false;
      _logoBase64 = d['logo'] as String?;
      _loaded = true;
    });
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).update({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'deliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 20.0,
      'minOrderAmount': double.tryParse(_minOrderCtrl.text) ?? 0.0,
      'isOpen': _isOpen,
      if (_logoBase64 != null) 'logo': _logoBase64,
    });
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Settings saved!'),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Open/Closed toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _isOpen ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(_isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                  color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isOpen ? 'Shop is Open' : 'Shop is Closed',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                    Text(_isOpen ? 'Customers can see & order' : 'Hidden from marketplace',
                        style: TextStyle(
                            fontSize: 12,
                            color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ],
                ),
              ),
              Switch(
                value: _isOpen,
                onChanged: (v) async {
                  setState(() => _isOpen = v);
                  await FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(widget.businessId)
                      .update({'isOpen': v});
                },
                activeColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Logo
        _label('Shop Logo'),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: _logoBase64 != null && _logoBase64!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.memory(base64Decode(_logoBase64!),
                        fit: BoxFit.cover, width: double.infinity),
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    Text('Tap to change logo', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ]),
          ),
        ),
        const SizedBox(height: 20),

        // Basic info
        _label('Shop Info'),
        _card(Column(children: [
          _field(_nameCtrl, 'Shop Name', Icons.storefront_outlined),
          const SizedBox(height: 12),
          _field(_descCtrl, 'Description', Icons.description_outlined, maxLines: 2),
          const SizedBox(height: 12),
          _field(_phoneCtrl, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_addressCtrl, 'Address', Icons.location_on_outlined, maxLines: 2),
        ])),
        const SizedBox(height: 20),

        _label('Pricing'),
        _card(Row(children: [
          Expanded(child: _field(_deliveryFeeCtrl, 'Delivery Fee (THB)',
              Icons.motorcycle_outlined, type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field(_minOrderCtrl, 'Min Order (THB)',
              Icons.shopping_cart_outlined, type: TextInputType.number)),
        ])),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280), letterSpacing: 0.5)),
      );

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: child,
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2)),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
}
