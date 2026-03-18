import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../services/image_helper.dart';
import 'dart:convert';

class ProductEditorScreen extends StatefulWidget {
  final String businessId;
  final ProductModel? product;

  const ProductEditorScreen({super.key, required this.businessId, this.product});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late double _basePrice;
  double? _discountPrice;
  late String _description;
  late String _category;
  late String _customOptionsString;
  String? _base64Image;
  
  late List<Map<String, dynamic>> _optionGroups;
  late List<Map<String, dynamic>> _addOns;

  bool _isSaving = false;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  final List<String> _commonCategories = ["Meals", "Drinks", "Desserts", "Specials", "Breakfast"];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = p?.name ?? "";
    _basePrice = p?.basePrice ?? 0;
    _discountPrice = p?.discountPrice;
    _description = p?.description ?? "";
    _category = p?.category ?? "Meals";
    _customOptionsString = p?.customOptions.join(', ') ?? "";
    _base64Image = (p?.imageUrl.isNotEmpty == true) ? p!.imageUrl : null;
    
    _optionGroups = p != null ? p.optionGroups.map((g) => Map<String, dynamic>.from(g)).toList() : [];
    _addOns = p != null ? p.addOns.map((a) => Map<String, dynamic>.from(a)).toList() : [];
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final List<String> options = _customOptionsString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final validOptionGroups = _optionGroups.where((g) {
        final title = g['title'] as String;
        final gOptions = g['options'] as List;
        return title.isNotEmpty && gOptions.isNotEmpty;
      }).toList();

      final validAddOns = _addOns.where((a) {
        final name = a['name'] as String;
        return name.isNotEmpty;
      }).toList();

      final productData = ProductModel(
        id: widget.product?.id ?? '',
        businessId: widget.businessId,
        name: _name,
        category: _category,
        basePrice: _basePrice,
        discountPrice: _discountPrice,
        description: _description,
        customOptions: options,
        optionGroups: validOptionGroups,
        addOns: validAddOns,
        imageUrl: _base64Image ?? '',
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        isAvailable: widget.product?.isAvailable ?? true,
      ).toMap();

      if (widget.product == null) {
        await FirebaseFirestore.instance.collection('products').add(productData);
      } else {
        await FirebaseFirestore.instance.collection('products').doc(widget.product!.id).update(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menu Item Saved Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      setState(() => _isSaving = false);
    }
  }

  Widget _buildSectionShell(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kPrimary, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.product == null ? "Create New Item" : "Edit Item", style: const TextStyle(fontWeight: FontWeight.bold, color: _kDark)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _kDark),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. BASIC INFO
            _buildSectionShell("Basic Details", Icons.info_outline, [
              GestureDetector(
                onTap: () async {
                  final b64 = await ImageHelper.pickAndCompressImage();
                  if (b64 != null) setState(() => _base64Image = b64);
                },
                child: Container(
                  width: double.infinity, height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _base64Image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text("Tap to upload product photo", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: "Product Name",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSaved: (v) => _description = v ?? "",
              ),
              const SizedBox(height: 16),
              const Text("Category", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _commonCategories.map((c) {
                  bool isSel = _category == c;
                  return ChoiceChip(
                    label: Text(c, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    selected: isSel,
                    selectedColor: _kPrimary,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _category = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('customCat_$_category'),
                initialValue: _category,
                decoration: InputDecoration(
                  hintText: "Or type custom category...",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (v) => _category = v.trim(),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _category = v!.isNotEmpty ? v : _category,
              ),
            ]),

            // 2. PRICING
            _buildSectionShell("Pricing", Icons.sell_outlined, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _basePrice > 0 ? _basePrice.toStringAsFixed(0) : '',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Price (THB)",
                        prefixIcon: const Icon(Icons.payments, color: Colors.green),
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                      onSaved: (v) => _basePrice = double.tryParse(v!) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _discountPrice != null ? _discountPrice!.toStringAsFixed(0) : '',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Discount (THB)",
                        prefixIcon: const Icon(Icons.local_offer, color: Colors.red),
                        filled: true, fillColor: Colors.red.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onSaved: (v) => _discountPrice = (v != null && v.isNotEmpty) ? (double.tryParse(v) ?? 0) : null,
                    ),
                  ),
                ],
              ),
            ]),

            // 3. GROUPS & ADD-ONS
            _buildSectionShell("Customization Variables", Icons.tune_rounded, [
              const Text("Basic Options (Comma separated)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: _customOptionsString,
                decoration: InputDecoration(
                  hintText: "e.g., Hot, Iced, Frappe",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSaved: (v) => _customOptionsString = v ?? "",
              ),
              const Divider(height: 32),
              
              // Option Groups
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Option Groups (e.g. Meat Choices)", style: TextStyle(fontWeight: FontWeight.bold, color: _kDark)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: () => setState(() => _optionGroups.add({"title": "", "options": []})),
                  )
                ],
              ),
              ...List.generate(_optionGroups.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: _optionGroups[index]['title'],
                              decoration: const InputDecoration(labelText: "Group Title", isDense: true),
                              onChanged: (val) => _optionGroups[index]['title'] = val,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: (_optionGroups[index]['options'] as List).join(', '),
                              decoration: const InputDecoration(labelText: "Options (comma separated)", isDense: true),
                              onChanged: (val) => _optionGroups[index]['options'] = val.split(',').map((e) => e.trim()).toList(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _optionGroups.removeAt(index)),
                      )
                    ],
                  ),
                );
              }),
              const Divider(height: 32),

              // Add-Ons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Premium Add-ons (e.g. +Cheese)", style: TextStyle(fontWeight: FontWeight.bold, color: _kDark)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                    onPressed: () => setState(() => _addOns.add({"name": "", "price": 0.0})),
                  )
                ],
              ),
              ...List.generate(_addOns.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepOrange.shade100)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: _addOns[index]['name'],
                          decoration: const InputDecoration(labelText: "Add-on Name", isDense: true),
                          onChanged: (val) => _addOns[index]['name'] = val,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: _addOns[index]['price'].toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "+ THB", isDense: true),
                          onChanged: (val) => _addOns[index]['price'] = double.tryParse(val) ?? 0.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _addOns.removeAt(index)),
                      )
                    ],
                  ),
                );
              }),
            ]),
            
            const SizedBox(height: 100), // Padding for sticky bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: Colors.black45, elevation: 8,
            ),
            onPressed: _isSaving ? null : _saveProduct,
            child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Save Product Configuration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
