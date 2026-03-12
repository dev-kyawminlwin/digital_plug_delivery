import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shop_menu_screen.dart';
import '../auth/login_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_order_history_tab.dart';
import 'customer_wishlist_tab.dart';
import '../admin/admin_dashboard.dart';
import '../rider/rider_home.dart';

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  int _bottomNavIndex = 0;
  String _selectedCategory = 'All';

  static const Color _kPrimary = Color(0xFF1E3A8A);
  static const Color _kGold = Color(0xFFEAB308);
  static const Color _kDark = Color(0xFF1F2937);

  void _handleProfileTap() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen()));
    }
  }

  Widget _buildBodyContent() {
    switch (_bottomNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildSearchPlaceholder();
      case 2:
        return const CustomerWishlistTab();
      case 3:
        return const CustomerOrderHistoryTab();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildSearchPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Search coming soon", style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 96;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // App Bar Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📍 Tachileik",
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text("Deliver Here",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kDark)),
                      ],
                    ),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        bool isLoggedIn = snapshot.hasData;
                        return GestureDetector(
                          onTap: _handleProfileTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLoggedIn
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFFFF7ED),
                              border: Border.all(
                                color: isLoggedIn
                                    ? const Color(0xFF10B981).withOpacity(0.4)
                                    : const Color(0xFFEA580C).withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                              color: isLoggedIn ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hero text
                const Text(
                  "Tachileik's Best.",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.1, color: _kDark),
                ),
                const Text(
                  "Fast delivery. 🛵",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.1, color: _kPrimary),
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                      const SizedBox(width: 10),
                      Text("Search restaurants & food...",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Chips
                _buildCategoryChips(),
                const SizedBox(height: 28),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Restaurants near you",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark)),
                    Text("See all", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Shop Grid
        _buildShopGrid(bottomPad),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Main', 'Soups', 'Salads', 'Drinks'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _kPrimary : Colors.grey.shade300,
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopGrid(double bottomPad) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .where('subscriptionStatus', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(child: Text("Error loading shops", style: TextStyle(color: Colors.grey.shade500))),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        final businesses = snapshot.data!.docs;
        if (businesses.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No restaurants open right now",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = businesses[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildShopCard(context, doc.id, data);
              },
              childCount: businesses.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopMenuScreen(
              businessId: docId,
              businessName: data['name'] ?? 'Shop',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with gradient overlay
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                      Image.memory(
                        base64Decode(data['imageUrl']),
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => _shopPlaceholder(),
                      )
                    else
                      _shopPlaceholder(),

                    // Gradient for text contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
                          ),
                        ),
                      ),
                    ),

                    // Rating Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: _kGold, size: 13),
                            SizedBox(width: 3),
                            Text("4.8", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['name'] ?? 'Unnamed Shop',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, color: Color(0xFFEA580C), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          data['deliveryFee'] != null ? "MMK ${data['deliveryFee']}" : "Free",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      color: _kPrimary.withOpacity(0.08),
      child: const Icon(Icons.storefront_rounded, size: 48, color: _kPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBodyContent()),
            // Floating Bottom Nav
            Positioned(
              bottom: bottomPad + 16,
              left: 24,
              right: 24,
              child: _buildFloatingNavBar(),
            ),
            // Role-aware Back-to-Panel FAB for admin / rider
            _buildRoleFab(bottomPad),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFab(double bottomPad) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final role = (snap.data!.data() as Map<String, dynamic>?)?['role'] as String?;
        if (role != 'admin' && role != 'rider') return const SizedBox.shrink();
        return Positioned(
          bottom: bottomPad + 96,
          right: 20,
          child: GestureDetector(
            onTap: () {
              if (role == 'admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderHome()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: role == 'admin' ? const Color(0xFF1E3A8A) : const Color(0xFF059669),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (role == 'admin' ? const Color(0xFF1E3A8A) : const Color(0xFF059669)).withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role == 'admin' ? Icons.storefront_rounded : Icons.motorcycle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Back to Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingNavBar() {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, "Home"),
      (Icons.search_rounded, Icons.search, "Search"),
      (Icons.favorite_rounded, Icons.favorite_border, "Saved"),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, "Orders"),
    ];
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(color: _kDark.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final isSelected = _bottomNavIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _bottomNavIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isSelected ? items[index].$1 : items[index].$2,
                size: 26,
                color: isSelected ? Colors.white : Colors.white38,
              ),
            ),
          );
        }),
      ),
    );
  }
}
