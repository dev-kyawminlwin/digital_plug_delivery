import 'package:flutter/material.dart';
import '../admin/menu_manager_tab.dart';
import '../admin/vendor_ratings_tab.dart';
import '../admin/vendor_ledger_tab.dart';
import '../admin/coupon_manager_tab.dart';
import '../admin/vendor_fleet_tab.dart';
import 'shop_orders_tab.dart';
import 'shop_settings_tab.dart';

class ShopManagementScreen extends StatefulWidget {
  final String businessId;
  final String shopName;
  final String shopLogo;

  const ShopManagementScreen({
    super.key,
    required this.businessId,
    required this.shopName,
    required this.shopLogo,
  });

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);
  static const Color _kCard = Color(0xFF1E293B);

  static const _tabs = [
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
    (icon: Icons.restaurant_menu_rounded, label: 'Menu'),
    (icon: Icons.local_offer_rounded, label: 'Coupons'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Ledger'),
    (icon: Icons.star_rounded, label: 'Reviews'),
    (icon: Icons.motorcycle_rounded, label: 'Fleet'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() => _tabIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F2937), Color(0xFF374151)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Shop logo
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white10,
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: ClipOval(
                            child: widget.shopLogo.isNotEmpty
                                ? Image.memory(
                                    Uri.parse('data:image/jpeg;base64,${widget.shopLogo}')
                                        .data!
                                        .contentAsBytes(),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.storefront_rounded,
                                    color: Colors.white60, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.shopName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                              Text(_tabs[_tabIndex].label,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: _kPrimary,
                    indicatorWeight: 3,
                    labelColor: _kPrimary,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    tabAlignment: TabAlignment.start,
                    tabs: _tabs
                        .map((t) => Tab(
                              icon: Icon(t.icon, size: 18),
                              text: t.label,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ShopOrdersTab(businessId: widget.businessId),
                MenuManagerTab(businessId: widget.businessId),
                CouponManagerTab(businessId: widget.businessId),
                VendorLedgerTab(businessId: widget.businessId),
                VendorRatingsTab(businessId: widget.businessId),
                VendorFleetTab(businessId: widget.businessId),
                ShopSettingsTab(businessId: widget.businessId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
