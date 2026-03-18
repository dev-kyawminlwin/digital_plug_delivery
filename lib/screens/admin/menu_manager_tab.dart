import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'product_editor_screen.dart';

class MenuManagerTab extends StatefulWidget {
  final String businessId;

  const MenuManagerTab({super.key, required this.businessId});

  @override
  State<MenuManagerTab> createState() => _MenuManagerTabState();
}

class _MenuManagerTabState extends State<MenuManagerTab> {
  String _searchQuery = "";

  void _routeToEditor({ProductModel? product}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditorScreen(businessId: widget.businessId, product: product)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _routeToEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Sticky Top Search Bar
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search your menu...",
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.transparent)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade100, width: 2)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('businessId', isEqualTo: widget.businessId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Your menu is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text("Click 'Add Item' below to start selling!", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    )
                  );
                }

                // Map docs to Models and filter by Search Query
                List<ProductModel> allProducts = docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                
                if (_searchQuery.isNotEmpty) {
                  allProducts = allProducts.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
                  if (allProducts.isEmpty) {
                    return Center(child: Text("No items match '$_searchQuery'", style: TextStyle(color: Colors.grey.shade600)));
                  }
                }

                // Group by Category
                Map<String, List<ProductModel>> grouped = {};
                for (var p in allProducts) {
                  grouped.putIfAbsent(p.category, () => []).add(p);
                }
                final sortedCategories = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, catIndex) {
                    final category = sortedCategories[catIndex];
                    final products = grouped[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
                          child: Row(
                            children: [
                              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFFF5E1E), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Text(category.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey.shade600, letterSpacing: 1.2)),
                              const SizedBox(width: 8),
                              Text("(${products.length})", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        ...products.map((product) => _buildPremiumProductCard(product)).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: product.isAvailable ? Colors.white : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: product.isAvailable ? Colors.transparent : Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.fastfood, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text("THB ${product.basePrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                if (product.customOptions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text("Options: ${product.customOptions.join(', ')}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
                if (product.optionGroups.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text("Groups: ${product.optionGroups.length}", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
                ],
                if (product.addOns.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text("+ ${product.addOns.length} Add-ons", style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                ],
                if (product.discountPrice != null) ...[
                  const SizedBox(height: 2),
                  Text("Discounted! (THB ${product.discountPrice!.toStringAsFixed(0)})", style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
                if (!product.isAvailable) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text("OUT OF STOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: product.isAvailable,
                  activeColor: Colors.white, activeTrackColor: Colors.green,
                  inactiveThumbColor: Colors.red.shade400, inactiveTrackColor: Colors.red.shade100,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('products').doc(product.id).update({'isAvailable': val});
                  },
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () => _routeToEditor(product: product),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Delete Menu Item?", style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                                Navigator.pop(c);
                              },
                              child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
