import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CouponManagerTab extends StatefulWidget {
  final String businessId;
  const CouponManagerTab({super.key, required this.businessId});

  @override
  State<CouponManagerTab> createState() => _CouponManagerTabState();
}

class _CouponManagerTabState extends State<CouponManagerTab> {
  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  void _showCreateCouponSheet(BuildContext context) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    String type = 'fixed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Coupon',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kDark)),
                const SizedBox(height: 20),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDeco('Coupon Code (e.g. SAVE20)', Icons.local_offer_rounded),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco(
                          type == 'fixed' ? 'Discount (THB)' : 'Discount (%)',
                          Icons.discount_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: type,
                      onChanged: (v) => setSheet(() => type = v!),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('THB')),
                        DropdownMenuItem(value: 'percent', child: Text('%')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Min Order Amount (THB)', Icons.shopping_cart_outlined),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      final value = double.tryParse(valueCtrl.text.trim()) ?? 0;
                      final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
                      if (code.isEmpty || value <= 0) return;
                      await FirebaseFirestore.instance.collection('coupons').add({
                        'code': code,
                        'type': type,
                        'value': value,
                        'minOrder': minOrder,
                        'businessId': widget.businessId,
                        'active': true,
                        'createdAt': FieldValue.serverTimestamp(),
                        'usageCount': 0,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Create Coupon',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPrimary, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCouponSheet(context),
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('businessId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          // Sort client-side (newest first) — avoids needing a composite Firestore index
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'];
              final bTs = (b.data() as Map)['createdAt'];
              if (aTs == null || bTs == null) return 0;
              return (bTs as dynamic).compareTo(aTs as dynamic);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No coupons yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark)),
                  const SizedBox(height: 8),
                  Text('Create your first promo code to attract customers!',
                      style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateCouponSheet(context),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Create Coupon', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final code = data['code'] as String? ?? '';
              final type = data['type'] as String? ?? 'fixed';
              final value = (data['value'] as num?)?.toDouble() ?? 0;
              final minOrder = (data['minOrder'] as num?)?.toDouble() ?? 0;
              final active = data['active'] as bool? ?? true;
              final usage = data['usageCount'] as int? ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: active ? Colors.transparent : Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: active ? _kPrimary.withOpacity(0.1) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_offer_rounded,
                          color: active ? _kPrimary : Colors.grey.shade400, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(code,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900,
                                    color: active ? _kDark : Colors.grey.shade400,
                                    letterSpacing: 1)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFF10B981) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(active ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                      color: active ? Colors.white : Colors.grey.shade500,
                                      fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            type == 'percent'
                                ? '$value% off${minOrder > 0 ? ' (Min: THB ${minOrder.toStringAsFixed(0)})' : ''}'
                                : 'THB ${value.toStringAsFixed(0)} off${minOrder > 0 ? ' (Min: THB ${minOrder.toStringAsFixed(0)})' : ''}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          Text('Used $usage times',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Toggle active
                    Switch(
                      value: active,
                      onChanged: (v) => FirebaseFirestore.instance
                          .collection('coupons')
                          .doc(docs[i].id)
                          .update({'active': v}),
                      activeColor: _kPrimary,
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Delete Coupon?'),
                            content: Text('Delete "$code"? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance.collection('coupons').doc(docs[i].id).delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
