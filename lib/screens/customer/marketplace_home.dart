import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shop_menu_screen.dart';
import '../auth/login_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_order_history_tab.dart';
import 'customer_wishlist_tab.dart';
import 'customer_map_tab.dart'; // Added this import
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

  static const Color _kPrimary = Color(0xFFFF5E1E);
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
        return const CustomerMapTab();
      case 2:
        return const CustomerWishlistTab();
      case 3:
        return const CustomerOrderHistoryTab();
      default:
        return _buildHomeContent();
    }
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
                    // Location / Delivery Address Area
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Delivering to", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFFF5E1E), size: 18),
                            const SizedBox(width: 4),
                            const Text("Current Location", style: TextStyle(color: _kDark, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500, size: 20),
                          ],
                        ),
                      ],
                    ),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, authSnapshot) {
                        bool isLoggedIn = authSnapshot.hasData;

                        if (!isLoggedIn) {
                          return GestureDetector(
                            onTap: _handleProfileTap,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFF7ED),
                                border: Border.all(
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.login_rounded,
                                color: Color(0xFFEA580C),
                                size: 22,
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).snapshots(),
                          builder: (context, userSnapshot) {
                            String avatar = '';
                            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                              if (data != null && data.containsKey('avatar')) {
                                avatar = data['avatar'] ?? '';
                              }
                            }
                            return GestureDetector(
                              onTap: _handleProfileTap,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  ),
                                  image: avatar.isNotEmpty
                                      ? DecorationImage(
                                          image: AssetImage('assets/images/$avatar.png'),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: avatar.isEmpty
                                    ? const Icon(
                                        Icons.person_outline_rounded,
                                        color: _kDark,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hero text
                const Text(
                  "Get Your\nFavorite Meals\nDelivered\nToday!",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.15, color: _kDark),
                ),
                const SizedBox(height: 24),

                // Search Bar with Filter Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                            const SizedBox(width: 12),
                            Text("Find food or restaurant...",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                            BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Category Grid/List
                _buildCategoryChips(),
                const SizedBox(height: 28),
                
                // Promotional Banner
                _buildPromoBanner(),
                const SizedBox(height: 32),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Popular Restaurants",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.5)),
                    Text("See all", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kPrimary)),
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

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Emerald Green pattern
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.fastfood_rounded, size: 120, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Free Delivery!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text("On your first 3 orders\nabove 200 THB.", style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("Claim Now", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <Map<String, dynamic>>[
      {'name': 'All', 'icon': Icons.dashboard_rounded},
      {'name': 'Main', 'icon': Icons.lunch_dining_rounded},
      {'name': 'Soups', 'icon': Icons.ramen_dining_rounded},
      {'name': 'Salads', 'icon': Icons.eco_rounded},
      {'name': 'Drinks', 'icon': Icons.local_cafe_rounded},
    ];
    return SizedBox(
      height: 100, // accommodate shadow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name'] as String),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 14, bottom: 10), // Give room for drop shadow
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected 
                    ? [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with floating badges
            Expanded(
              flex: 14,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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

                    // Floating Time Badge (Top Left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: _kPrimary),
                            const SizedBox(width: 4),
                            const Text("15-20 min", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _kDark)),
                          ],
                        ),
                      ),
                    ),

                    // Floating Heart (Top Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                         padding: const EdgeInsets.all(6),
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.9),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.favorite_rounded, color: Colors.grey, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info Content
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['name'] ?? 'Unnamed Shop',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ratings
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _kGold, size: 16),
                            const SizedBox(width: 4),
                            const Text("4.8", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kDark)),
                            Text(" (120+)", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        // Delivery logic
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['deliveryFee'] != null ? "฿${data['deliveryFee']}" : "Free",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kDark),
                          ),
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
      color: _kPrimary.withValues(alpha: 0.08),
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
            _buildBodyContent(),
            // Floating Bottom Nav
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad + 16, left: 24, right: 24),
                child: _buildFloatingNavBar(),
              ),
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

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad + 96, right: 20),
        child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
          final role = (snap.data!.data() as Map<String, dynamic>?)?['role'] as String?;
          if (role != 'admin' && role != 'rider') return const SizedBox.shrink();

          final isAdmin = role == 'admin';
          final color = isAdmin ? const Color(0xFF1E3A8A) : const Color(0xFF059669);

          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => isAdmin ? const AdminDashboard() : const RiderHome(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isAdmin ? Icons.storefront_rounded : Icons.motorcycle_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text("Back to Panel",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  Widget _buildFloatingNavBar() {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, "Home"),
      (Icons.map_rounded, Icons.map_outlined, "Map"),
      (Icons.favorite_rounded, Icons.favorite_border, "Saved"),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, "Orders"),
    ];
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(items.length, (index) {
          final isSelected = _bottomNavIndex == index;
          final color = isSelected ? Colors.white : Colors.grey.shade400;
          return GestureDetector(
            onTap: () => setState(() => _bottomNavIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF5E1E) : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? items[index].$1 : items[index].$2,
                    size: 24,
                    color: color,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              items[index].$3,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
