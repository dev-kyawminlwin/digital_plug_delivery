import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../services/image_helper.dart';

class MenuManagerTab extends StatefulWidget {
  final String businessId;

  const MenuManagerTab({super.key, required this.businessId});

  @override
  State<MenuManagerTab> createState() => _MenuManagerTabState();
}

class _MenuManagerTabState extends State<MenuManagerTab> {
  void _showAddProductDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = "";
    double basePrice = 0;
    String description = "";
    String customOptionsString = "";
    String category = "Meals";
    String? base64Image;
    List<Map<String, dynamic>> optionGroups = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Menu Item"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (base64Image != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text("✅ Image Attached", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text("Attach Image"),
                        onPressed: () async {
                          final b64 = await ImageHelper.pickAndCompressImage();
                          if (b64 != null) {
                            setDialogState(() => base64Image = b64);
                          }
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Product Name"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => name = v!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Price (MMK)"),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => basePrice = double.tryParse(v!) ?? 0,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Description (Optional)"),
                        onSaved: (v) => description = v ?? "",
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: "Category"),
                        items: ["Meals", "Drinks", "Soup", "Vegetables"].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => category = val);
                          }
                        },
                      ),
                      if (category == 'Meals') ...[
                        const SizedBox(height: 16),
                        const Text("Meal Options (e.g., Meat choices)", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(optionGroups.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: optionGroups[index]['title'],
                                    decoration: const InputDecoration(labelText: "Group Title (e.g., Meat)"),
                                    onChanged: (val) => optionGroups[index]['title'] = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: (optionGroups[index]['options'] as List).join(','),
                                    decoration: const InputDecoration(labelText: "Options (comma separated)"),
                                    onChanged: (val) {
                                      optionGroups[index]['options'] = val.split(',').map((e) => e.trim()).toList();
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() => optionGroups.removeAt(index));
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                        if (optionGroups.length < 4)
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add Option Group"),
                            onPressed: () {
                              setDialogState(() => optionGroups.add({"title": "", "options": []}));
                            },
                          ),
                      ],
                      // Legacy custom options field for backwards compatibility or default generic options
                      if (category != 'Meals')
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Options (comma separated)",
                            hintText: "e.g., Cold, Hot",
                          ),
                          onSaved: (v) => customOptionsString = v ?? "",
                        ),
                    ],
                  );
                }
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  
                  final List<String> options = customOptionsString
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  // Cleanup empty option groups before saving
                  final validOptionGroups = optionGroups.where((g) {
                    final title = g['title'] as String;
                    final gOptions = g['options'] as List;
                    return title.isNotEmpty && gOptions.isNotEmpty;
                  }).toList();

                  await FirebaseFirestore.instance.collection('products').add(
                    ProductModel(
                      id: '', // Firestore auto-generates
                      businessId: widget.businessId,
                      name: name,
                      category: category,
                      basePrice: basePrice,
                      description: description,
                      customOptions: options,
                      optionGroups: validOptionGroups,
                      imageUrl: base64Image ?? '',
                      createdAt: DateTime.now(),
                    ).toMap()
                  );

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save Item"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Item"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('businessId', isEqualTo: widget.businessId)
            // Note: In production you'd normally order by name or createdAt, 
            // but that might require building a Firestore Index first.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Your menu is empty. Add your first item!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final product = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: product.isAvailable ? Colors.transparent : Colors.red, width: 2),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MMK ${product.basePrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      if (product.customOptions.isNotEmpty)
                        Text("Options: ${product.customOptions.join(', ')}", style: const TextStyle(fontSize: 12)),
                      if (product.optionGroups.isNotEmpty)
                        Text("Groups: ${product.optionGroups.length}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      if (!product.isAvailable)
                        const Text("OUT OF STOCK", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: product.isAvailable,
                        activeTrackColor: Colors.green,
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                            'isAvailable': val,
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text("Delete Menu Item?"),
                              content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                                    Navigator.pop(c);
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
