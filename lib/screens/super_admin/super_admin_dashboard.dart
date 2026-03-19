import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../shared/guest_language_switcher.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});
  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _currentIndex = 0;
  static const Color _kGold = Color(0xFFEAB308);


  final _tabTitles = ['Platform Overview', 'Analytics', 'Shops', 'Riders', 'Users'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildOverviewTab(),
      const _AnalyticsTab(),
      const _ShopsTab(),
      const _RidersTab(),
      const _UsersTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.shield_rounded, color: _kGold, size: 16),
                          SizedBox(width: 6),
                          Text('FOUNDER',
                              style: TextStyle(
                                  color: _kGold, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                        ]),
                        const SizedBox(height: 4),
                        Text(_tabTitles[_currentIndex],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        // Language switcher
                        const DashboardLanguageSwitcher(),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Founder Account'),
                                content: const Text('Sign out from the Founder Dashboard?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Log Out'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await FirebaseAuth.instance.signOut();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview'),
                _navItem(1, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
                _navItem(2, Icons.storefront_rounded, Icons.storefront_outlined, 'Shops'),
                _navItem(3, Icons.motorcycle_rounded, Icons.motorcycle_outlined, 'Riders'),
                _navItem(4, Icons.people_rounded, Icons.people_outline, 'Users'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final sel = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF6D28D9).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sel ? active : inactive,
                color: sel ? const Color(0xFF6D28D9) : Colors.grey.shade400, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? const Color(0xFF6D28D9) : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnap) {
        double gmv = 0;
        int total = 0;
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        double monthlyGmv = 0;
        if (orderSnap.hasData) {
          for (var doc in orderSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            if (d['status'] == 'completed') {
              final amt = (d['totalPrice'] ?? 0) + (d['deliveryFee'] ?? 0);
              gmv += amt;
              total++;
              final dynamic cl = d['createdAt'];
              final createdAt = cl is Timestamp ? cl.toDate() : (cl is String ? DateTime.tryParse(cl) : null);
              if (createdAt != null && createdAt.isAfter(startOfMonth)) monthlyGmv += amt;
            }
          }
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL GMV (ALL TIME)', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2)),
                        const SizedBox(height: 6),
                        Text('THB ${gmv.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('This Month: THB ${monthlyGmv.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.delivery_dining_rounded, color: _kGold, size: 18),
                            const SizedBox(width: 8),
                            Text('$total Deliveries Completed',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white54),
                        tooltip: 'Clean Platform Revenue Data',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Reset Platform Revenue?'),
                              content: const Text('This will permanently delete ALL Completed orders across the entire platform. This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final snapshot = await FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').get();
                                    for (var doc in snapshot.docs) {
                                      await doc.reference.delete();
                                    }
                                  },
                                  child: const Text('Delete All', style: TextStyle(color: Colors.white)),
                                ),
                              ]
                            )
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('REGISTERED BUSINESSES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.8)),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                final biz = snap.data!.docs;
                if (biz.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('No businesses yet. Go to Shops tab to add one.'))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final doc = biz[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['subscriptionStatus'] == 'active';
                    final dynamic sl = data['subscriptionEnd'];
                    final subEnd = sl is Timestamp ? sl.toDate() : (sl is String ? DateTime.tryParse(sl) : null);
                    final isAtRisk = isActive && subEnd != null && subEnd.isBefore(DateTime.now().add(const Duration(days: 3)));
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isAtRisk ? Border.all(color: Colors.red, width: 1.5) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: Icon(isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: isActive ? Colors.green : Colors.red, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (subEnd != null)
                                Text(
                                  isAtRisk ? '⚠️ Expires ${subEnd.toLocal().toString().split(' ')[0]}'
                                      : 'Expires ${subEnd.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(
                                      color: isAtRisk ? Colors.red : Colors.grey, fontSize: 12,
                                      fontWeight: isAtRisk ? FontWeight.bold : FontWeight.normal),
                                ),
                            ],
                          )),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? Colors.orange : const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final newStatus = isActive ? 'inactive' : 'active';
                              FirebaseFirestore.instance.collection('businesses').doc(doc.id).update({
                                'subscriptionStatus': newStatus,
                                if (!isActive)
                                  'subscriptionEnd': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
                              });
                            },
                            child: Text(isActive ? 'Revoke' : 'Activate',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ]),
                      ),
                    );
                  }, childCount: biz.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

// ─── ANALYTICS TAB ────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!.docs;

        // Per-shop revenue
        final shopRevenue = <String, double>{};
        final shopNames = <String, String>{};
        // Per-rider earnings
        final riderEarnings = <String, double>{};
        final riderNames = <String, String>{};
        // Per-user spending
        final userSpending = <String, double>{};
        final userNames = <String, String>{};
        // Monthly revenue (last 6 months)
        final monthlyRev = <String, double>{};

        for (var doc in orders) {
          final d = doc.data() as Map<String, dynamic>;
          final amt = ((d['totalPrice'] ?? 0) as num).toDouble();
          final dFee = ((d['deliveryFee'] ?? 0) as num).toDouble();
          final total = amt + dFee;

          // Shop revenue
          final bId = d['businessId'] as String?;
          if (bId != null) {
            shopRevenue[bId] = (shopRevenue[bId] ?? 0) + amt;
            shopNames[bId] = d['businessName'] ?? bId;
          }

          // Rider earnings
          final rId = d['riderId'] as String?;
          if (rId != null) {
            riderEarnings[rId] = (riderEarnings[rId] ?? 0) + dFee;
            riderNames[rId] = d['riderName'] ?? rId;
          }

          // User spending
          final cId = d['customerId'] as String?;
          if (cId != null) {
            userSpending[cId] = (userSpending[cId] ?? 0) + total;
            userNames[cId] = d['customerName'] ?? cId;
          }

          // Monthly revenue
          final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            final key = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
            monthlyRev[key] = (monthlyRev[key] ?? 0) + total;
          }
        }

        final sortedMonths = monthlyRev.keys.toList()..sort();
        final sortedShops = shopRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final sortedRiders = riderEarnings.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final sortedUsers = userSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Monthly Revenue'),
            const SizedBox(height: 12),
            if (sortedMonths.isEmpty)
              _emptyHint('No completed orders yet.')
            else
              ...sortedMonths.reversed.take(6).map((month) => _analyticsRow(
                  Icons.calendar_month_rounded, const Color(0xFF6D28D9),
                  month, 'THB ${monthlyRev[month]!.toStringAsFixed(0)}')),

            const SizedBox(height: 24),
            _sectionTitle('Shop Revenue'),
            const SizedBox(height: 12),
            if (sortedShops.isEmpty)
              _emptyHint('No shop revenue yet.')
            else
              ...sortedShops.map((e) => _analyticsRow(
                  Icons.storefront_rounded, const Color(0xFF1E3A8A),
                  shopNames[e.key] ?? e.key, 'THB ${e.value.toStringAsFixed(0)}')),

            const SizedBox(height: 24),
            _sectionTitle('Rider Earnings (Delivery Fees)'),
            const SizedBox(height: 12),
            if (sortedRiders.isEmpty)
              _emptyHint('No rider earnings yet.')
            else
              ...sortedRiders.map((e) => _analyticsRow(
                  Icons.motorcycle_rounded, const Color(0xFF059669),
                  riderNames[e.key] ?? e.key, 'THB ${e.value.toStringAsFixed(0)}')),

            const SizedBox(height: 24),
            _sectionTitle('Top Customers by Spending'),
            const SizedBox(height: 12),
            if (sortedUsers.isEmpty)
              _emptyHint('No registered customer orders yet.')
            else
              ...sortedUsers.take(10).map((e) => _analyticsRow(
                  Icons.person_rounded, const Color(0xFFEA580C),
                  userNames[e.key] ?? e.key, 'THB ${e.value.toStringAsFixed(0)}')),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)));

  Widget _emptyHint(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)));

  Widget _analyticsRow(IconData icon, Color color, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ]),
    );
  }
}

// ─── SHOPS TAB ────────────────────────────────────────────────────────────────
class _ShopsTab extends StatefulWidget {
  const _ShopsTab();
  @override
  State<_ShopsTab> createState() => _ShopsTabState();
}

class _ShopsTabState extends State<_ShopsTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showForm = false;
  String _bizName = '', _adminName = '', _email = '', _password = '';

  static const _kPurple = Color(0xFF6D28D9);

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      await _authService.createAdminAsSuperAdmin(
          email: _email, password: _password, businessName: _bizName, adminName: _adminName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Shop & Admin created!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
        _formKey.currentState!.reset();
        setState(() => _showForm = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _deleteShop(BuildContext ctx, String docId, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Shop'),
        content: Text('Delete "$name"? This also removes its products and orders from your analytics.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('businesses').doc(docId).delete();
              // Delete associated products
              final products = await FirebaseFirestore.instance
                  .collection('products').where('businessId', isEqualTo: docId).get();
              for (var p in products.docs) p.reference.delete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── PENDING APPROVALS ─────────────────────────────────────────────────
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (ctx, pendSnap) {
          final pending = pendSnap.data?.docs ?? [];
          if (pending.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(children: [
                    const Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 8),
                    Text('${pending.length} Shop${pending.length > 1 ? 's' : ''} Awaiting Approval',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E), fontSize: 14)),
                  ]),
                ),
                ...pending.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] as String? ?? 'Unknown';
                  final riderName = d['ownedByRiderName'] as String? ?? 'Unknown Rider';
                  final address = d['address'] as String? ?? '';
                  final category = d['category'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF92400E)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  fontSize: 15, color: Color(0xFF1F2937)))),
                        ]),
                        const SizedBox(height: 4),
                        Text('By: $riderName · $category',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        if (address.isNotEmpty)
                          Text(address, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        const SizedBox(height: 10),
                        Row(children: [
                          // Approve
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('businesses')
                                    .doc(doc.id)
                                    .update({
                                  'status': 'approved',
                                  'approvedAt': FieldValue.serverTimestamp(),
                                  'isOpen': false,
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reject
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                              label: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final reasonCtrl = TextEditingController();
                                final reason = await showDialog<String>(
                                  context: ctx,
                                  builder: (dctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Reject Shop'),
                                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text('Tell "$name" why their shop was rejected:',
                                          style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: reasonCtrl,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'e.g. Incomplete information',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ]),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(dctx, reasonCtrl.text.trim()),
                                        child: const Text('Reject', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (reason != null) {
                                  await FirebaseFirestore.instance
                                      .collection('businesses')
                                      .doc(doc.id)
                                      .update({
                                    'status': 'rejected',
                                    'rejectionReason': reason,
                                  });
                                }
                              },
                            ),
                          ),
                        ]),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      // ── EXISTING SHOPS LIST ───────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          const Expanded(
              child: Text('Registered Shops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
          ElevatedButton.icon(
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'Add Shop'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ]),
      ),
      if (_showForm)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _field('Shop / Business Name', Icons.storefront_outlined, (v) => _bizName = v!),
                const SizedBox(height: 12),
                _field('Admin\'s Full Name', Icons.person_outline, (v) => _adminName = v!),
                const SizedBox(height: 12),
                _field('Admin Email', Icons.email_outlined, (v) => _email = v!, type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field('Password (min 6)', Icons.lock_outline, (v) => _password = v!, obscure: true, minLen: 6),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0),
                          child: const Text('Create Shop Account', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ]),
            ),
          ),
        ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No shops yet. Tap "Add Shop" above.',
                    style: TextStyle(color: Colors.grey.shade500)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final isActive = data['subscriptionStatus'] == 'active';
                final subEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Icon(Icons.storefront_rounded,
                          color: isActive ? Colors.green : Colors.red, size: 20),
                    ),
                    title: Text(data['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        isActive
                            ? 'Active · Expires ${subEnd?.toLocal().toString().split(' ')[0] ?? "?"}'
                            : 'Inactive',
                        style: TextStyle(
                            color: isActive ? Colors.green.shade700 : Colors.red, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.orange : _kPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            minimumSize: Size.zero),
                        onPressed: () {
                          final newStatus = isActive ? 'inactive' : 'active';
                          FirebaseFirestore.instance.collection('businesses').doc(doc.id).update({
                            'subscriptionStatus': newStatus,
                            if (!isActive)
                              'subscriptionEnd': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
                          });
                        },
                        child: Text(isActive ? 'Revoke' : 'Activate',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        onPressed: () => _deleteShop(ctx, doc.id, data['name'] ?? 'Shop'),
                        tooltip: 'Delete Shop',
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _field(String label, IconData icon, void Function(String?) onSaved,
      {TextInputType type = TextInputType.text, bool obscure = false, int minLen = 1}) {
    return TextFormField(
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true, fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPurple, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (v.length < minLen) return 'Min $minLen characters';
        return null;
      },
      onSaved: onSaved,
    );
  }
}

// ─── RIDERS TAB ───────────────────────────────────────────────────────────────
class _RidersTab extends StatefulWidget {
  const _RidersTab();
  @override
  State<_RidersTab> createState() => _RidersTabState();
}

class _RidersTabState extends State<_RidersTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showForm = false;
  String _riderName = '', _email = '', _password = '';
  String? _selectedBusinessId;

  static const _kGreen = Color(0xFF059669);

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a shop first.')));
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      await _authService.createRiderAsSuperAdmin(
          email: _email, password: _password, riderName: _riderName, businessId: _selectedBusinessId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rider account created!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
        _formKey.currentState!.reset();
        setState(() {
          _showForm = false;
          _selectedBusinessId = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _deleteRider(BuildContext ctx, String docId, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Rider'),
        content: Text('Remove rider "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          const Expanded(
              child: Text('Registered Riders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
          ElevatedButton.icon(
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'Add Rider'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ]),
      ),
      if (_showForm)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)]),
            child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: _dec("Rider's Full Name", Icons.person_outline),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _riderName = v!,
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final shops = snap.data!.docs;
                    if (shops.isEmpty) return const Text('Create a shop first.');
                    return DropdownButtonFormField<String>(
                      value: _selectedBusinessId,
                      decoration: _dec('Assign to Shop', Icons.storefront_outlined),
                      items: shops.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'] ?? 'Shop'))).toList(),
                      onChanged: (v) => setState(() => _selectedBusinessId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Rider Email', Icons.email_outlined),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _email = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  obscureText: true,
                  decoration: _dec('Password (min 6)', Icons.lock_outline),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  onSaved: (v) => _password = v!,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0),
                          child: const Text('Create Rider Account', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ]),
            ),
          ),
        ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'rider').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.motorcycle_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No riders yet. Tap "Add Rider" above.',
                    style: TextStyle(color: Colors.grey.shade500)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                        backgroundColor: _kGreen.withValues(alpha: 0.1),
                        child: const Icon(Icons.motorcycle_rounded, color: _kGreen, size: 20)),
                    title: Text(data['name'] ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deleteRider(ctx, doc.id, data['name'] ?? 'Rider'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
    filled: true, fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kGreen, width: 2)),
    labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    isDense: true,
  );
}

// ─── USERS TAB ────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showForm = false;
  String _name = '', _email = '', _password = '', _phone = '';

  static const _kOrange = Color(0xFFEA580C);

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      // Use auth service to create customer account
      final uid = await _authService.createCustomerAsSuperAdmin(
          email: _email, password: _password, name: _name, phone: _phone);
      if (mounted && uid != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Customer account created!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
        _formKey.currentState!.reset();
        setState(() => _showForm = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _deleteUser(BuildContext ctx, String docId, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User'),
        content: Text('Remove user "$name" from the platform?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          const Expanded(
              child: Text('Registered Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
          ElevatedButton.icon(
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'Add User'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ]),
      ),
      if (_showForm)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)]),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _field('Full Name', Icons.person_outline, (v) => _name = v!),
                const SizedBox(height: 12),
                _field('Phone Number', Icons.phone_outlined, (v) => _phone = v!, type: TextInputType.phone),
                const SizedBox(height: 12),
                _field('Email', Icons.email_outlined, (v) => _email = v!, type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field('Password (min 6)', Icons.lock_outline, (v) => _password = v!, obscure: true, minLen: 6),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0),
                          child: const Text('Create User Account', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ]),
            ),
          ),
        ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No registered users yet.', style: TextStyle(color: Colors.grey.shade500)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                        backgroundColor: _kOrange.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, color: _kOrange, size: 20)),
                    title: Text(data['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${data['email'] ?? ''} · ${data['phone'] ?? ''}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deleteUser(ctx, doc.id, data['name'] ?? 'User'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _field(String label, IconData icon, void Function(String?) onSaved,
      {TextInputType type = TextInputType.text, bool obscure = false, int minLen = 1}) {
    return TextFormField(
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true, fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kOrange, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (v.length < minLen) return 'Min $minLen characters';
        return null;
      },
      onSaved: onSaved,
    );
  }
}
