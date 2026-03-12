import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorFleetTab extends StatelessWidget {
  final String businessId;

  const VendorFleetTab({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Querying users collection for role == rider and isAvailable == true
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isAvailable', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final onlineRiders = snapshot.data!.docs;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1F2937),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.motorcycle, color: Colors.greenAccent, size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${onlineRiders.length}",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        "Riders Online Now",
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      )
                    ],
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Available Fleet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (onlineRiders.isEmpty)
              const Expanded(child: Center(child: Text("No riders are currently online.")))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: onlineRiders.length,
                  itemBuilder: (context, index) {
                    final data = onlineRiders[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['name'] ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Ready for dispatch"),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
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
