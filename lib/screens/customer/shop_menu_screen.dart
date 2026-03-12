import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'checkout_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class ShopMenuScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const ShopMenuScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen> {
  // Key: unique ID combining productId + selected options. Value: {product details, qty, options map}
  final Map<String, Map<String, dynamic>> _cart = {};
  double _cartTotal = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final favorites = List<String>.from(data['favoriteShops'] ?? []);
      if (favorites.contains(widget.businessId) && mounted) {
        setState(() => _isFavorite = true);
      }
    }
  }

  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await docRef.update({
        'favoriteShops': FieldValue.arrayUnion([widget.businessId])
      });
    } else {
      await docRef.update({
        'favoriteShops': FieldValue.arrayRemove([widget.businessId])
      });
    }
  }

  void _addToCart(ProductModel product, int qty, Map<String, String> selectedOptions) {
    // Generate a unique key based on selected options so different variations don't overwrite
    String optionsKey = selectedOptions.entries.map((e) => "${e.key}:${e.value}").join('|');
    String cartKey = "${product.id}_$optionsKey";

    setState(() {
      if (_cart.containsKey(cartKey)) {
        _cart[cartKey]!['qty'] = (_cart[cartKey]!['qty'] as int) + qty;
      } else {
        _cart[cartKey] = {
          'product': product,
          'qty': qty,
          'options': selectedOptions,
        };
      }
      _cartTotal += (product.basePrice * qty);
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    
    if (FirebaseAuth.instance.currentUser == null) {
      // User is not logged in, force login/registration
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // User is logged in, proceed to checkout
    // Transforming the cart so it fits the CheckoutScreen map temporarily, 
    // or we can pass the new cart format. Let's pass the new cart format!
    // But since Checkout is currently expecting Map<String, int>, we need a separate PR for that line or we pass something it can use.
    // Assuming checkout_screen.dart is also updated to use this new map.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          businessId: widget.businessId,
          businessName: widget.businessName,
          cart: _cart.map((k, v) => MapEntry(k, v['qty'] as int)), // Legacy support for quantity counts temporarily
          detailedCart: _cart, // Pass detailed cart
          subtotal: _cartTotal,
        ),
      ),
    );
  }

  // Beautiful Modal matching the Middle Reference Image
  void _showProductDetailsModal(ProductModel product) {
    int localQty = 1;
    Map<String, String> selectedOptions = {};

    // Initialize first option as default if they exist
    for (var group in product.optionGroups) {
      if (group['options'] != null && (group['options'] as List).isNotEmpty) {
        selectedOptions[group['title']] = group['options'][0] as String;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                   // The Dark Top Half
                  Container(
                    height: 250, // Matches the reference dark top
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2937), // Dark Gray
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),

                  // Floating Overlays (Back & Heart) seen in reference
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                    ),
                  ),

                  // Content
                  Column(
                    children: [
                      const SizedBox(height: 80), // Push image down
                      
                      // 1. Massive Bleeding Image
                      Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            )
                          ]
                        ),
                        child: product.imageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(product.imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Icon(Icons.fastfood, size: 100, color: Theme.of(context).primaryColor),
                                ),
                              )
                            : Icon(Icons.fastfood, size: 100, color: Theme.of(context).primaryColor),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 2. Details in the white sheet
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                            ),
                            const SizedBox(height: 16),
                            
                            // Badges Row
                            Row(
                              children: [
                                const Icon(Icons.alarm, size: 20, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                const Text("20 min", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 20),
                                const Icon(Icons.local_fire_department, size: 20, color: Colors.orange),
                                const SizedBox(width: 4),
                                const Text("320 kcal", style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                const Icon(Icons.star, size: 24, color: Color(0xFFEAB308)),
                                const SizedBox(width: 4),
                                const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            Text(
                              product.customOptions.isNotEmpty 
                                  ? product.customOptions.join(', ') 
                                  : "A delicious and freshly prepared ${product.name} crafted with authentic ingredients, perfect for satisfying your cravings. Includes fragrant rice and sides.",
                              style: TextStyle(height: 1.6, fontSize: 15, color: Colors.grey.shade600),
                            ),
                            
                            if (product.optionGroups.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              ...product.optionGroups.map((group) {
                                String groupTitle = group['title'];
                                List<dynamic> options = group['options'] ?? [];
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupTitle,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                    ),
                                    const SizedBox(height: 8),
                                    ...options.map((optionText) {
                                      return RadioListTile<String>(
                                        title: Text(optionText.toString()),
                                        value: optionText.toString(),
                                        groupValue: selectedOptions[groupTitle],
                                        activeColor: Theme.of(context).primaryColor,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setModalState(() => selectedOptions[groupTitle] = val);
                                          }
                                        },
                                      );
                                    }).toList(),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }).toList(),
                            ],
                            const SizedBox(height: 100), // Extra padding for scrolling
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Floating Bottom Add to Cart Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 20, offset: const Offset(0, -20))
                        ]
                      ),
                      child: Row(
                        children: [
                          // Quantity Selector
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () {
                                    if(localQty > 1) setModalState(() => localQty--);
                                  },
                                ),
                                Text("$localQty", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () => setModalState(() => localQty++),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Dark Pill Button
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                _addToCart(product, localQty, selectedOptions);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Add to Cart   MMK ${(product.basePrice * localQty).toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Column(
            children: [
               // Custom Header instead of AppBar
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.businessName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorite ? Colors.redAccent : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Menu List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('businessId', isEqualTo: widget.businessId)
                      .where('isAvailable', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text("Menu is currently empty."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final product = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        
                        // Count how many of this product are in the cart across all variations
                        int qtyInCart = 0;
                        _cart.forEach((k, v) {
                          if ((v['product'] as ProductModel).id == product.id) {
                            qtyInCart += (v['qty'] as int);
                          }
                        });

                        return GestureDetector(
                          onTap: () => _showProductDetailsModal(product),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: product.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.memory(
                                            base64Decode(product.imageUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) => Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                                          ),
                                        )
                                      : Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                                      const SizedBox(height: 6),
                                      Text("MMK ${product.basePrice.toStringAsFixed(0)}", 
                                          style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      if (qtyInCart > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F2937), 
                                            borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: Text(
                                            "$qtyInCart added", 
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Custom Floating Checkout Cart
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _checkout,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2937).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: Text("${_cart.values.fold(0, (sum, item) => sum + (item['qty'] as int))}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          const Text("View Cart", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("MMK ${_cartTotal.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
