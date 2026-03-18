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
  List<String> _favoriteProducts = []; // Phase 6: Product Modal Favorites
  String _selectedCategory = 'All'; // Phase 6: Category Filtering
  String _shopImageUrl = '';

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _fetchShopDetails();
  }

  void _fetchShopDetails() async {
    final doc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
    if(doc.exists && mounted) {
      setState(() {
        _shopImageUrl = doc.data()?['imageUrl'] ?? '';
      });
    }
  }

  void _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final favorites = List<String>.from(data['favoriteShops'] ?? []);
      final favProds = List<String>.from(data['favoriteProducts'] ?? []);
      if (mounted) {
        setState(() {
          if (favorites.contains(widget.businessId)) _isFavorite = true;
          _favoriteProducts = favProds;
        });
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

  void _addToCart(ProductModel product, int qty, Map<String, String> selectedOptions, List<Map<String, dynamic>> selectedAddOns) {
    // Generate a unique key based on selected options and addons
    String optionsKey = selectedOptions.entries.map((e) => "${e.key}:${e.value}").join('|');
    var sortedAddons = List.from(selectedAddOns)..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    String addonsKey = sortedAddons.map((e) => "${e['name']}").join('|');
    
    String cartKey = "${product.id}_${optionsKey}_$addonsKey";

    double toppingTotal = selectedAddOns.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());
    double baseAmount = product.discountPrice ?? product.basePrice;
    double unitPrice = baseAmount + toppingTotal;

    setState(() {
      if (_cart.containsKey(cartKey)) {
        _cart[cartKey]!['qty'] = (_cart[cartKey]!['qty'] as int) + qty;
      } else {
        _cart[cartKey] = {
          'product': product,
          'qty': qty,
          'options': selectedOptions,
          'addOns': selectedAddOns,
          'unitPrice': unitPrice,
        };
      }
      _cartTotal += (unitPrice * qty);
    });
  }

  void _removeFromCart(String cartKey) {
    setState(() {
      if (_cart.containsKey(cartKey)) {
        final item = _cart[cartKey]!;
        _cartTotal -= (item['unitPrice'] as double) * (item['qty'] as int);
        _cart.remove(cartKey);
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          businessId: widget.businessId,
          businessName: widget.businessName,
          cart: _cart.map((k, v) => MapEntry(k, v['qty'] as int)), // Legacy
          detailedCart: _cart, 
          subtotal: _cartTotal,
        ),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setCartState) {
            if (_cart.isEmpty) {
              Navigator.pop(context);
              return const SizedBox();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Order", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _cart.length,
                      separatorBuilder: (c, i) => Divider(color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        String key = _cart.keys.elementAt(index);
                        var item = _cart[key]!;
                        ProductModel p = item['product'];
                        int q = item['qty'];
                        double uPrice = item['unitPrice'];
                        Map<String, String> opts = item['options'];
                        List<Map<String, dynamic>> adds = item['addOns'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade100,
                                ),
                                child: p.imageUrl.isNotEmpty 
                                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(p.imageUrl), fit: BoxFit.cover))
                                    : const Icon(Icons.fastfood, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text("THB ${uPrice.toStringAsFixed(0)} x $q", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                    if (opts.isNotEmpty)
                                      Text(opts.values.join(', '), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    if (adds.isNotEmpty)
                                      Text(adds.map((e) => "+${e['name']}").join(', '), style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // Remove Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  _removeFromCart(key);
                                  setCartState(() {});
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom Checkout Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E1E),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        _checkout(); // Proceed
                      },
                      child: Text(
                        "Proceed to Checkout - THB ${_cartTotal.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  // Modern E-Commerce Modal with Add-ons Support
  void _showProductDetailsModal(ProductModel product) {
    int localQty = 1;
    Map<String, String> selectedOptions = {};
    List<Map<String, dynamic>> selectedAddOns = [];

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
            
            double baseAmount = product.discountPrice ?? product.basePrice;
            double currentUnitPrice = baseAmount + selectedAddOns.fold(0.0, (sum, a) => sum + (a['price'] as num).toDouble());
            double totalCartPrice = currentUnitPrice * localQty;

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                  // Scrollable Content
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Edge-to-Edge Image (No more profile circle)
                        SizedBox(
                          height: 280,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              product.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                      child: Image.memory(
                                        base64Decode(product.imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.fastfood, size: 80, color: Colors.grey)),
                                      ),
                                    )
                                  : Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1F2937),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                      ),
                                      child: const Icon(Icons.fastfood, size: 100, color: Colors.white24),
                                    ),
                              // Gradient Overlay for top buttons
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                                      stops: const [0.0, 0.4]
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 2. Details in the white sheet
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 16),
                              
                              // Badges Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.star, size: 24, color: Color(0xFFEAB308)),
                                  const SizedBox(width: 4),
                                  const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              Text(
                                product.customOptions.isNotEmpty 
                                    ? product.customOptions.join(', ') 
                                    : "A delicious and freshly prepared ${product.name}. Crafted with authentic ingredients, perfect for satisfying your cravings.",
                                style: TextStyle(height: 1.6, fontSize: 15, color: Colors.grey.shade600),
                              ),
                              
                              // Option Groups (Radio Selectors)
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

                              // Add-ons (Toppings)
                              if (product.addOns.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  "Add-ons / Toppings",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                ),
                                const SizedBox(height: 8),
                                ...product.addOns.map((addon) {
                                  bool isSelected = selectedAddOns.any((a) => a['name'] == addon['name']);
                                  return CheckboxListTile(
                                    title: Text(addon['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text("+ THB ${addon['price'].toString()}", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                    value: isSelected,
                                    activeColor: const Color(0xFFFF5E1E),
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          selectedAddOns.add(addon);
                                        } else {
                                          selectedAddOns.removeWhere((a) => a['name'] == addon['name']);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ],

                              const SizedBox(height: 120), // Extra padding for scrolling past floating bar
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Overlays (Back & Heart) 
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF1F2937)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          return;
                        }
                        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                        bool isFav = _favoriteProducts.contains(product.id);
                        
                        setModalState(() {
                          if (isFav) {
                            _favoriteProducts.remove(product.id);
                          } else {
                            _favoriteProducts.add(product.id);
                          }
                        });
                        
                        if (!isFav) {
                          await docRef.update({'favoriteProducts': FieldValue.arrayUnion([product.id])});
                        } else {
                          await docRef.update({'favoriteProducts': FieldValue.arrayRemove([product.id])});
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          _favoriteProducts.contains(product.id) ? Icons.favorite_rounded : Icons.favorite_border, 
                          color: _favoriteProducts.contains(product.id) ? Colors.redAccent : Colors.grey.shade400, 
                          size: 20
                        ),
                      ),
                    ),
                  ),

                  // 3. Floating Bottom Add to Cart Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 20, offset: const Offset(0, -28))
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
                                backgroundColor: const Color(0xFF1F2937),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                _addToCart(product, localQty, selectedOptions, selectedAddOns);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Add to Cart   THB ${totalCartPrice.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
          CustomScrollView(
            slivers: [
              // Storefront Immersive Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent, // Let background bleed
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 18),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.redAccent : const Color(0xFF1F2937),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _shopImageUrl.isNotEmpty
                          ? Image.memory(base64Decode(_shopImageUrl), fit: BoxFit.cover, errorBuilder: (c, o, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.storefront_rounded, size: 80, color: Colors.grey)))
                          : Container(color: Colors.grey.shade200, child: const Icon(Icons.storefront, size: 80, color: Colors.grey)),
                      
                      // Dark gradient for text & blur for "ambient" feel
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      // Store Info Overlay (Vibe)
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.businessName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Rating Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 16),
                                      const SizedBox(width: 4),
                                      const Text("4.8 (200+ runs)", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Time Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      const Text("15-20 min", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Menu List Stream
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('businessId', isEqualTo: widget.businessId)
                    .where('isAvailable', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}")));
                  if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

                  final docs = snapshot.data!.docs;
                  
                  // Extract unique categories dynamically
                  final Set<String> categories = {'All'};
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['category'] != null && data['category'] != '') {
                      categories.add(data['category'] as String);
                    }
                  }
                  final categoryList = categories.toList();

                  // Filter docs based on selected category
                  final filteredDocs = _selectedCategory == 'All' 
                      ? docs 
                      : docs.where((doc) => (doc.data() as Map<String, dynamic>)['category'] == _selectedCategory).toList();

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Text("Menu is currently empty.")));
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      // Dynamic Category Scroller
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categoryList.length,
                            itemBuilder: (context, index) {
                              final cat = categoryList[index];
                              final isSelected = cat == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFFF5E1E),
                                  backgroundColor: Colors.grey.shade100,
                                  showCheckmark: false,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                                  onSelected: (val) {
                                    setState(() => _selectedCategory = cat);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Dynamic Filtered Grid
                      filteredDocs.isEmpty 
                      ? const SliverToBoxAdapter(child: Center(child: Text("No items in this category.")))
                      : SliverPadding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                          sliver: SliverGrid.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final product = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                              
                              int qtyInCart = 0;
                              _cart.forEach((k, v) {
                                if ((v['product'] as ProductModel).id == product.id) {
                                  qtyInCart += (v['qty'] as int);
                                }
                              });

                              return GestureDetector(
                                onTap: () => _showProductDetailsModal(product),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Thumbnail
                                      Expanded(
                                        flex: 11,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              product.imageUrl.isNotEmpty
                                                  ? Image.memory(
                                                      base64Decode(product.imageUrl),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, o, s) => Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), child: Icon(Icons.fastfood, color: Theme.of(context).primaryColor)),
                                                    )
                                                  : Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), child: Icon(Icons.fastfood, color: Theme.of(context).primaryColor)),
                                              
                                              // Gradient for heart
                                              Positioned.fill(
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Floating Heart
                                              const Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Details
                                      Expanded(
                                        flex: 12,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 12),
                                                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 12),
                                                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 12),
                                                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 12),
                                                      Icon(Icons.star_rounded, color: Colors.grey.shade300, size: 12),
                                                      const SizedBox(width: 4),
                                                      Text("4.0", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    product.discountPrice != null
                                                        ? Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text("THB ${product.basePrice.toStringAsFixed(0)}", 
                                                                  style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 11)),
                                                              Text("THB ${product.discountPrice!.toStringAsFixed(0)}", 
                                                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                                            ],
                                                          )
                                                        : Text("THB ${product.basePrice.toStringAsFixed(0)}", 
                                                            style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFF5E1E),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      qtyInCart > 0 ? "x$qtyInCart" : "ADD", 
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ), // Closes Expanded
                                    ], // Closes Column's children
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
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
                onTap: _showCartSheet,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E1E), // Vibrant Orange
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E1E).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  ),
                  child: Row(
                    children: [
                       Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(24)
                        ),
                        child: const Text("CART", style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                      const Spacer(),
                      Text("View Cart (${_cart.values.fold(0, (sum, item) => sum + (item['qty'] as int))} Items) - THB ${_cartTotal.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      const SizedBox(width: 8),
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
