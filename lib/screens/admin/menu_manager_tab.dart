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
  void _showAddOrEditProductDialog({ProductModel? product}) {
    final _formKey = GlobalKey<FormState>();
    String name = product?.name ?? "";
    double basePrice = product?.basePrice ?? 0;
    double? discountPrice = product?.discountPrice;
    String description = product?.description ?? "";
    String customOptionsString = product?.customOptions.join(', ') ?? "";
    String category = product?.category ?? "Meals";
    String? base64Image = (product?.imageUrl.isNotEmpty == true) ? product!.imageUrl : null;
    List<Map<String, dynamic>> optionGroups = product != null 
        ? product.optionGroups.map((g) => Map<String, dynamic>.from(g)).toList() 
        : [];
    List<Map<String, dynamic>> addOns = product != null
        ? product.addOns.map((a) => Map<String, dynamic>.from(a)).toList()
        : [];

    final TextEditingController categoryCtrl = TextEditingController(text: category);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? "Add Menu Item" : "Edit Menu Item"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (base64Image != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text("✅ Image Attached", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: Text(base64Image == null ? "Attach Image" : "Change Image"),
                        onPressed: () async {
                          final b64 = await ImageHelper.pickAndCompressImage();
                          if (b64 != null) {
                            setDialogState(() => base64Image = b64);
                          }
                        },
                      ),
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: "Product Name"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => name = v!,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: basePrice > 0 ? basePrice.toStringAsFixed(0) : '',
                              decoration: const InputDecoration(labelText: "Price (MMK)"),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? "Required" : null,
                              onSaved: (v) => basePrice = double.tryParse(v!) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: discountPrice != null ? discountPrice!.toStringAsFixed(0) : '',
                              decoration: const InputDecoration(labelText: "Discount Price (Opt)"),
                              keyboardType: TextInputType.number,
                              onSaved: (v) => discountPrice = (v != null && v.isNotEmpty) ? (double.tryParse(v) ?? 0) : null,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(labelText: "Description (Optional)"),
                        onSaved: (v) => description = v ?? "",
                      ),
                      const SizedBox(height: 12),
                      
                      // Dynamic Category Field
                      const Text("Category", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextFormField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(hintText: "e.g. Steaks, Breakfast, Cafe"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => category = v!,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ["Meals", "Drinks", "Specials", "Breakfast"].map((c) => ActionChip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            setDialogState(() {
                              categoryCtrl.text = c;
                            });
                          },
                        )).toList(),
                      ),
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

                      TextFormField(
                        initialValue: customOptionsString,
                        decoration: const InputDecoration(
                          labelText: "Basic Options (comma separated)",
                          hintText: "e.g., Cold, Hot",
                        ),
                        onSaved: (v) => customOptionsString = v ?? "",
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text("Custom Add-ons (e.g., Extra Cheese +500) [Optional]", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      const SizedBox(height: 8),
                      ...List.generate(addOns.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: addOns[index]['name'],
                                  decoration: const InputDecoration(labelText: "Add-on Name"),
                                  onChanged: (val) => addOns[index]['name'] = val,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: addOns[index]['price'].toString(),
                                  decoration: const InputDecoration(labelText: "+Price"),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    addOns[index]['price'] = double.tryParse(val) ?? 0.0;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() => addOns.removeAt(index));
                                },
                              )
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.deepOrange),
                        label: const Text("Add New Topping", style: TextStyle(color: Colors.deepOrange)),
                        onPressed: () {
                          setDialogState(() => addOns.add({"name": "", "price": 0.0}));
                        },
                      ),
                      const SizedBox(height: 16),
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

                  final validOptionGroups = optionGroups.where((g) {
                    final title = g['title'] as String;
                    final gOptions = g['options'] as List;
                    return title.isNotEmpty && gOptions.isNotEmpty;
                  }).toList();

                  final validAddOns = addOns.where((a) {
                    final name = a['name'] as String;
                    return name.isNotEmpty;
                  }).toList();

                  final productData = ProductModel(
                    id: product?.id ?? '', // Auto-generates if new
                    businessId: widget.businessId,
                    name: name,
                    category: category,
                    basePrice: basePrice,
                    discountPrice: discountPrice,
                    description: description,
                    customOptions: options,
                    optionGroups: validOptionGroups,
                    addOns: validAddOns,
                    imageUrl: base64Image ?? '',
                    createdAt: product?.createdAt ?? DateTime.now(),
                    isAvailable: product?.isAvailable ?? true,
                  ).toMap();

                  if (product == null) {
                    await FirebaseFirestore.instance.collection('products').add(productData);
                  } else {
                    await FirebaseFirestore.instance.collection('products').doc(product.id).update(productData);
                  }

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(product == null ? "Save Item" : "Update Item"),
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
        onPressed: () => _showAddOrEditProductDialog(),
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
                      if (product.addOns.isNotEmpty)
                        Text("+ ${product.addOns.length} Add-ons", style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
                      if (product.discountPrice != null)
                        Text("Discounted! (MMK ${product.discountPrice!.toStringAsFixed(0)})", style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddOrEditProductDialog(product: product),
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
