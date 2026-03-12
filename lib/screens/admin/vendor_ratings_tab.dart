import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorRatingsTab extends StatelessWidget {
  final String businessId;

  const VendorRatingsTab({super.key, required this.businessId});

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
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return const Center(child: Text("No ratings received yet."));
        }

        // Calculate Average
        double totalRating = 0;
        for (var doc in reviews) {
          totalRating += (doc['rating'] as num).toDouble();
        }
        double avgRating = totalRating / reviews.length;

        return Column(
          children: [
            // Big Average Header
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1F2937),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFEAB308), size: 40),
                  const SizedBox(width: 12),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "out of 5",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  )
                ],
              ),
            ),

            // List of Reviews
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final data = reviews[index].data() as Map<String, dynamic>;
                  final int stars = (data['rating'] as num).toInt();
                  final date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(data['customerId'].toString().substring(0, 2).toUpperCase()),
                      ),
                      title: Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            color: const Color(0xFFEAB308),
                            size: 16,
                          );
                        }),
                      ),
                      subtitle: Text("Order ID: ${data['orderId'].toString().substring(0, 8)}..."),
                      trailing: Text(DateFormat('MMM dd').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }
}
