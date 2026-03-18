import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorFleetTab extends StatelessWidget {
  final String businessId;

  const VendorFleetTab({super.key, required this.businessId});

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  Future<void> _hireRiderForDay(BuildContext context, String riderId, String riderName) async {
    // Record a day-hire request in the business's subcollection
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('hireRequests')
        .add({
      'riderId': riderId,
      'riderName': riderName,
      'date': DateTime.now().toIso8601String().split('T').first,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text("Hire request sent to $riderName"),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Assigned Riders (permanent fleet for this business)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'rider')
                .where('businessId', isEqualTo: businessId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              final riders = snap.data!.docs;
              final online = riders.where((r) => (r.data() as Map)['isAvailable'] == true).length;

              return CustomScrollView(
                slivers: [
                  // Fleet Stats Banner
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kDark,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _kDark.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _fleetStat("$online", "Online Now", Colors.greenAccent),
                          Container(width: 1, height: 40, color: Colors.white12),
                          _fleetStat("${riders.length}", "Total Fleet", Colors.white),
                          Container(width: 1, height: 40, color: Colors.white12),
                          _fleetStat("${riders.length - online}", "Offline", Colors.redAccent),
                        ],
                      ),
                    ),
                  ),

                  // Section header
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text("YOUR ASSIGNED RIDERS",
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280), letterSpacing: 0.8)),
                    ),
                  ),

                  if (riders.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.motorcycle_rounded, size: 72, color: Color(0xFFE5E7EB)),
                            SizedBox(height: 16),
                            Text("No riders assigned to your shop yet.",
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = riders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isOnline = data['isAvailable'] as bool? ?? false;
                          final walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isOnline
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                    child: Icon(Icons.motorcycle_rounded,
                                        color: isOnline ? Colors.green : Colors.grey, size: 24),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.green : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(data['name'] ?? 'Rider',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(
                                isOnline ? "● Online — Ready for dispatch" : "○ Offline",
                                style: TextStyle(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("THB ${walletBalance.toStringAsFixed(0)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                                  const Text("wallet", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: riders.length,
                      ),
                    ),

                  // Hire from available riders section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text("HIRE FOR TODAY",
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280), letterSpacing: 0.8)),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'rider')
                          .where('isAvailable', isEqualTo: true)
                          .snapshots(),
                      builder: (context, availSnap) {
                        if (!availSnap.hasData) return const SizedBox.shrink();

                        // Only show riders NOT already assigned to this business
                        final available = availSnap.data!.docs.where((r) {
                          final d = r.data() as Map<String, dynamic>;
                          return d['businessId'] != businessId;
                        }).toList();

                        if (available.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text("No freelance riders available right now",
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: available.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_rounded, color: Colors.green),
                                ),
                                title: Text(data['name'] ?? 'Rider',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text("Available for hire", style: TextStyle(color: Colors.green, fontSize: 12)),
                                trailing: ElevatedButton(
                                  onPressed: () => _hireRiderForDay(context, doc.id, data['name'] ?? 'Rider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text("Hire Today", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fleetStat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]);
  }
}
