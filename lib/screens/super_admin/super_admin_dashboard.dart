import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _currentIndex = 0;

  // Deep Purple + Gold palette
  static const Color _kPurple = Color(0xFF6D28D9);
  static const Color _kPurpleDeep = Color(0xFF4C1D95);
  static const Color _kGold = Color(0xFFEAB308);
  static const Color _kDark = Color(0xFF1F2937);

  final List<String> _tabTitles = ["Platform Overview", "Add Shop", "Add Rider"];

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildOverviewTab(),
      const _AddShopTab(),
      const _AddRiderTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── Deep Purple Header ─────────────────────────────────────
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
                        const Row(
                          children: [
                            Icon(Icons.shield_rounded, color: _kGold, size: 16),
                            SizedBox(width: 6),
                            Text("FOUNDER",
                                style: TextStyle(color: _kGold, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabTitles[_currentIndex],
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Founder Account"),
                            content: const Text("Sign out from the Founder Dashboard?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text("Log Out"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await FirebaseAuth.instance.signOut();
                                  // AuthGate handles redirect
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
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body ─────────────────────────────────────────────────
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(0, Icons.analytics_rounded, Icons.analytics_outlined, "Overview"),
                _navItem(1, Icons.storefront_rounded, Icons.storefront_outlined, "Add Shop"),
                _navItem(2, Icons.motorcycle_rounded, Icons.motorcycle_rounded, "Add Rider"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kPurple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? _kPurple : Colors.grey.shade400, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? _kPurple : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
      builder: (context, orderSnapshot) {
        double globalGmv = 0;
        int totalCompleted = 0;
        if (orderSnapshot.hasData) {
          totalCompleted = orderSnapshot.data!.docs.length;
          for (var doc in orderSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            globalGmv += (data['totalPrice'] ?? 0) + (data['deliveryFee'] ?? 0);
          }
        }

        return CustomScrollView(
          slivers: [
            // GMV Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: _kPurple.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GLOBAL GMV",
                        style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text("MMK ${globalGmv.toStringAsFixed(0)}",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delivery_dining_rounded, color: _kGold, size: 18),
                          const SizedBox(width: 8),
                          Text("$totalCompleted Deliveries Completed",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Business List
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text("REGISTERED BUSINESSES",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280), letterSpacing: 0.8)),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                final businesses = snapshot.data!.docs;
                if (businesses.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text("No businesses yet.")));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = businesses[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final status = data['subscriptionStatus'] ?? 'inactive';
                      final subEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();
                      final isActive = status == 'active' &&
                          subEnd != null &&
                          subEnd.isAfter(DateTime.now());
                      final isAtRisk = isActive &&
                          subEnd != null &&
                          subEnd.isBefore(DateTime.now().add(const Duration(days: 3)));

                      return Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isAtRisk
                              ? Border.all(color: Colors.red, width: 1.5)
                              : null,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isActive ? Colors.green : Colors.red,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (subEnd != null)
                                      Text(
                                        isAtRisk
                                            ? "⚠️ Expires ${subEnd.toLocal().toString().split(' ')[0]}"
                                            : "Expires ${subEnd.toLocal().toString().split(' ')[0]}",
                                        style: TextStyle(
                                            color: isAtRisk ? Colors.red : Colors.grey,
                                            fontSize: 12,
                                            fontWeight: isAtRisk ? FontWeight.bold : FontWeight.normal),
                                      ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive ? Colors.orange : _kPurple,
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
                                      'subscriptionEnd': Timestamp.fromDate(
                                          DateTime.now().add(const Duration(days: 30))),
                                  });
                                },
                                child: Text(isActive ? "Revoke" : "Activate",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: businesses.length,
                  ),
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

// ─── ADD SHOP TAB ───────────────────────────────────────────────────────────
class _AddShopTab extends StatefulWidget {
  const _AddShopTab();
  @override
  State<_AddShopTab> createState() => _AddShopTabState();
}

class _AddShopTabState extends State<_AddShopTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _bizName = '', _adminName = '', _email = '', _password = '';

  static const Color _kPurple = Color(0xFF6D28D9);

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      await _authService.createAdminAsSuperAdmin(
        email: _email, password: _password, businessName: _bizName, adminName: _adminName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Shop & Admin created!"),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Onboard New Shop",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text("Creates both the business record and admin login.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            _field("Shop / Business Name", Icons.storefront_outlined, (v) => _bizName = v!),
            const SizedBox(height: 14),
            _field("Admin's Full Name", Icons.person_outline, (v) => _adminName = v!),
            const SizedBox(height: 14),
            _field("Admin Login Email", Icons.email_outlined, (v) => _email = v!,
                type: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _field("Admin Password (min 6)", Icons.lock_outline, (v) => _password = v!,
                obscure: true, minLen: 6),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text("Create Shop Account",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, void Function(String?) onSaved,
      {TextInputType type = TextInputType.text, bool obscure = false, int minLen = 1}) {
    return TextFormField(
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Required";
        if (v.length < minLen) return "Minimum $minLen characters";
        return null;
      },
      onSaved: onSaved,
    );
  }
}

// ─── ADD RIDER TAB ──────────────────────────────────────────────────────────
class _AddRiderTab extends StatefulWidget {
  const _AddRiderTab();
  @override
  State<_AddRiderTab> createState() => _AddRiderTabState();
}

class _AddRiderTabState extends State<_AddRiderTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _riderName = '', _email = '', _password = '';
  String? _selectedBusinessId;

  static const Color _kPurple = Color(0xFF6D28D9);

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop to assign this rider to.')),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      await _authService.createRiderAsSuperAdmin(
        email: _email, password: _password, riderName: _riderName, businessId: _selectedBusinessId!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Rider account created!"),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _formKey.currentState!.reset();
        setState(() => _selectedBusinessId = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Onboard New Rider",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text("Creates a rider login and assigns them to a shop.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Rider's Full Name",
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B7280), size: 20),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPurple, width: 2)),
                labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _riderName = v!,
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final shops = snapshot.data!.docs;
                if (shops.isEmpty) return const Text("Create a shop first.");
                return DropdownButtonFormField<String>(
                  value: _selectedBusinessId,
                  decoration: InputDecoration(
                    labelText: "Assign to Shop",
                    prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF6B7280), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPurple, width: 2)),
                    labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  items: shops.map((doc) {
                    return DropdownMenuItem(value: doc.id, child: Text(doc['name'] ?? 'Shop'));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBusinessId = val),
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Rider Login Email",
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 20),
                filled: true, fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPurple, width: 2)),
                labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _email = v!,
            ),
            const SizedBox(height: 14),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Rider Password (min 6)",
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 20),
                filled: true, fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPurple, width: 2)),
                labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              ),
              validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
              onSaved: (v) => _password = v!,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // Green for rider creation
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text("Create Rider Account",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
