import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorRatingsTab extends StatelessWidget {
  final String businessId;

  const VendorRatingsTab({super.key, required this.businessId});

  static const Color _kDark = Color(0xFF1F2937);
  static const Color _kGold = Color(0xFFEAB308);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_half_rounded, size: 72, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No ratings yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                Text('Great service earns 5 stars! ⭐', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        }

        double totalRating = 0;
        for (var doc in reviews) {
          totalRating += (doc['rating'] as num).toDouble();
        }
        final double avgRating = totalRating / reviews.length;

        return Column(
          children: [
            // ── Premium Ratings Header ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF374151)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: _kGold, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _kGold, size: 14,
                          )),
                          const SizedBox(width: 6),
                          Text('${reviews.length} reviews', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Review list ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final data = reviews[index].data() as Map<String, dynamic>;
                  final int stars = (data['rating'] as num).toInt();
                  final date = data['createdAt'] != null
                      ? (data['createdAt'] is Timestamp
                          ? (data['createdAt'] as Timestamp).toDate()
                          : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
                      : DateTime.now();
                  final initials = data['customerId'].toString().substring(0, 2).toUpperCase();
                  final avatarColors = [
                    Colors.orange.shade400, Colors.blue.shade400, Colors.purple.shade400,
                    Colors.teal.shade400, Colors.pink.shade400,
                  ];
                  final avatarColor = avatarColors[index % avatarColors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: avatarColor.withValues(alpha: 0.15),
                          child: Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: _kGold, size: 15,
                                  )),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM dd').format(date),
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order #${data['orderId'].toString().substring(0, 8)}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                              if (data['comment'] != null && (data['comment'] as String).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(data['comment'], style: const TextStyle(color: _kDark, fontSize: 13, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
