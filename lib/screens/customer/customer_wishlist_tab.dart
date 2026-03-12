import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'shop_menu_screen.dart';

class CustomerWishlistTab extends StatelessWidget {
  const CustomerWishlistTab({super.key});

  static const Color _kPrimary = Color(0xFF1E3A8A);

  Future<void> _removeFavorite(String userId, String businessId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'favoriteShops': FieldValue.arrayRemove([businessId]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bottomPad = MediaQuery.of(context).padding.bottom + 96;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Please log in to see your favorites.",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const Center(child: Text("No Profile Data"));

        final favorites = List<String>.from(userData['favoriteShops'] ?? []);

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  "No favorites yet.\nTap ♥ on a shop to save it here!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('businesses')
              .where(FieldPath.documentId, whereIn: favorites.take(10).toList())
              .snapshots(),
          builder: (context, shopSnapshot) {
            if (!shopSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final shops = shopSnapshot.data!.docs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    "${shops.length} Saved Restaurant${shops.length != 1 ? 's' : ''}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final doc = shops[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border_rounded, color: Colors.white, size: 24),
                              SizedBox(height: 4),
                              Text("Remove",
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text("Remove Favorite?"),
                              content: Text("Remove ${data['name'] ?? 'this shop'} from your favorites?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: const Text("Remove", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) => _removeFavorite(user.uid, doc.id),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopMenuScreen(
                                  businessId: doc.id,
                                  businessName: data['name'] ?? 'Shop',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 110,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                  child: SizedBox(
                                    width: 110,
                                    height: double.infinity,
                                    child: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                                        ? Image.memory(
                                            base64Decode(data['imageUrl']),
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) => _placeholder(),
                                          )
                                        : _placeholder(),
                                  ),
                                ),
                                // Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unnamed Shop',
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 15),
                                            const SizedBox(width: 4),
                                            const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const Spacer(),
                                            const Icon(Icons.delivery_dining_rounded, color: Color(0xFFEA580C), size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              data['deliveryFee'] != null ? "MMK ${data['deliveryFee']}" : "Free",
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Swipe hint
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: _kPrimary.withOpacity(0.08),
      child: const Icon(Icons.storefront_rounded, size: 36, color: _kPrimary),
    );
  }
}
