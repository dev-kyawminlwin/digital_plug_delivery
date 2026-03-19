import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CheckoutScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final Map<String, int> cart;
  final Map<String, Map<String, dynamic>>? detailedCart;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.cart,
    this.detailedCart,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();

  String _selectedPaymentMethod = 'Cash';
  bool _isPlacingOrder = false;
  double _deliveryFee = 0.0;
  bool _isLoadingFee = true;
  double _customerLat = 0.0;
  double _customerLng = 0.0;

  // Feature 1: Promo codes
  double _couponDiscount = 0.0;
  String _couponStatus = ''; // '', 'valid', 'invalid'
  String _appliedCouponId = '';
  bool _isCheckingCoupon = false;

  // Feature 5: Min order
  double _minOrderAmount = 0.0;

  // Feature 6: Loyalty points
  int _loyaltyBalance = 0;
  bool _redeemPoints = false;
  double _pointsDiscount = 0.0; // 100 pts = 10 THB

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _calculateDeliveryFee();
    _loadShopSettings();
    _loadLoyaltyBalance();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
      });
    }
  }

  Future<void> _loadShopSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _minOrderAmount = (data['minOrderAmount'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  Future<void> _loadLoyaltyBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _loyaltyBalance = (doc.data() as Map<String, dynamic>)['loyaltyPoints'] as int? ?? 0;
      });
    }
  }

  Future<void> _calculateDeliveryFee() async {
    final bizDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .get();
    double baseFee = 20.0;
    GeoPoint? shopLoc;
    if (bizDoc.exists && bizDoc.data() != null) {
      final data = bizDoc.data()!;
      if (data['deliveryFee'] != null) {
        baseFee = double.tryParse(data['deliveryFee'].toString()) ?? 20.0;
      }
      shopLoc = data['location'];
    }
    double distKm = 0.0;
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _customerLat = pos.latitude;
        _customerLng = pos.longitude;
        if (shopLoc != null) {
          final distm = Geolocator.distanceBetween(
              shopLoc.latitude, shopLoc.longitude, pos.latitude, pos.longitude);
          distKm = distm / 1000.0;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _deliveryFee = baseFee + (distKm * 10.0);
        _isLoadingFee = false;
      });
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isCheckingCoupon = true);

    final snap = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code)
        .where('active', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) {
      setState(() {
        _couponStatus = 'invalid';
        _couponDiscount = 0;
        _appliedCouponId = '';
        _isCheckingCoupon = false;
      });
      return;
    }

    final data = snap.docs.first.data();
    final type = data['type'] as String? ?? 'fixed'; // 'fixed' or 'percent'
    final value = (data['value'] as num?)?.toDouble() ?? 0.0;
    final minOrder = (data['minOrder'] as num?)?.toDouble() ?? 0.0;

    if (widget.subtotal < minOrder) {
      setState(() {
        _couponStatus = 'invalid';
        _couponDiscount = 0;
        _appliedCouponId = '';
        _isCheckingCoupon = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Minimum order of THB ${minOrder.toStringAsFixed(0)} required for this coupon.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final discount = type == 'percent'
        ? (widget.subtotal * value / 100).clamp(0, widget.subtotal)
        : value.clamp(0, widget.subtotal);

    setState(() {
      _couponStatus = 'valid';
      _couponDiscount = discount;
      _appliedCouponId = snap.docs.first.id;
      _isCheckingCoupon = false;
    });
  }

  double get _totalAfterDiscounts {
    double total = widget.subtotal + _deliveryFee - _couponDiscount;
    if (_redeemPoints) total -= _pointsDiscount;
    return total.clamp(0, double.infinity);
  }

  void _toggleRedeemPoints() {
    setState(() {
      _redeemPoints = !_redeemPoints;
      // 100 pts = 10 THB, max redemption = 50% of subtotal
      final maxRedeemable = widget.subtotal * 0.5;
      _pointsDiscount = (_loyaltyBalance / 100 * 10).clamp(0, maxRedeemable);
    });
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_minOrderAmount > 0 && widget.subtotal < _minOrderAmount) return;
    setState(() => _isPlacingOrder = true);

    String orderSummary = '';
    if (widget.detailedCart != null) {
      widget.detailedCart!.forEach((key, item) {
        final product = item['product'];
        final qty = item['qty'];
        orderSummary += '${product.name} x$qty\n';
      });
    } else {
      widget.cart.forEach((id, qty) => orderSummary += 'Product $id x$qty\n');
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final final_total = _totalAfterDiscounts;
      final pointsEarned = (final_total / 10).floor(); // 1 point per 10 THB

      final orderData = {
        'businessId': widget.businessId,
        'businessName': widget.businessName,
        'customerId': uid,
        'isGuestOrder': uid == 'guest',
        'customerName': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'itemsSummary': orderSummary.trim(),
        'subtotal': widget.subtotal,
        'couponDiscount': _couponDiscount,
        'pointsDiscount': _redeemPoints ? _pointsDiscount : 0.0,
        'couponId': _appliedCouponId,
        'deliveryFee': _deliveryFee,
        'totalPrice': final_total,
        'riderId': '',
        'riderName': '',
        'paymentMethod': _selectedPaymentMethod,
        'status': 'looking_for_rider',
        'createdAt': FieldValue.serverTimestamp(),
        'customerLat': _customerLat,
        'customerLng': _customerLng,
        'pointsEarned': pointsEarned,
        'cancelledAt': null,
      };

      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Award loyalty points (only for logged-in users)
      if (uid != 'guest' && pointsEarned > 0) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'loyaltyPoints': FieldValue.increment(pointsEarned),
        });
      }

      // Deduct redeemed points
      if (_redeemPoints && uid != 'guest' && _pointsDiscount > 0) {
        final redeemedPts = (_pointsDiscount / 10 * 100).round();
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'loyaltyPoints': FieldValue.increment(-redeemedPts),
        });
      }

      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showReceipt(docRef.id, final_total, orderSummary, pointsEarned);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showReceipt(String orderId, double total, String summary, int pointsEarned) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed! 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('${widget.businessName}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 20),

            // Order ID chip
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: orderId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Order ID copied!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_rounded, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text('Order #${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receipt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _receiptRow('Subtotal', 'THB ${widget.subtotal.toStringAsFixed(0)}'),
                  if (_deliveryFee > 0) _receiptRow('Delivery Fee', 'THB ${_deliveryFee.toStringAsFixed(0)}'),
                  if (_couponDiscount > 0) _receiptRow('Coupon Discount', '- THB ${_couponDiscount.toStringAsFixed(0)}', green: true),
                  if (_redeemPoints && _pointsDiscount > 0) _receiptRow('Points Redeemed', '- THB ${_pointsDiscount.toStringAsFixed(0)}', green: true),
                  const Divider(height: 16),
                  _receiptRow('TOTAL', 'THB ${total.toStringAsFixed(0)}', bold: true),
                  if (pointsEarned > 0) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFEAB308), size: 16),
                      const SizedBox(width: 6),
                      Text('+$pointsEarned loyalty points earned!',
                          style: const TextStyle(color: Color(0xFFEAB308), fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CTA Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Home', style: TextStyle(color: Color(0xFF6B7280))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      Navigator.of(context).pushNamed('/track/$orderId');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Track Order',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false, bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? _kDark : Colors.grey.shade600,
          )),
          Text(value, style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: green ? const Color(0xFF16A34A) : (bold ? _kDark : Colors.grey.shade700),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final belowMin = _minOrderAmount > 0 && widget.subtotal < _minOrderAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout',
            style: TextStyle(color: _kDark, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF3F4F6)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Min Order Warning ──────────────────────────────────────────
            if (belowMin)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Minimum order is THB ${_minOrderAmount.toStringAsFixed(0)}. '
                        'Add THB ${(_minOrderAmount - widget.subtotal).toStringAsFixed(0)} more.',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Order Summary ──────────────────────────────────────────────
            _sectionLabel('Order Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.storefront_rounded, color: _kPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(widget.businessName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
                  ]),
                  const SizedBox(height: 12),
                  if (widget.detailedCart != null)
                    ...widget.detailedCart!.values.map((item) {
                      final product = item['product'];
                      final qty = item['qty'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${product.name} x$qty',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                            Text('THB ${(product.basePrice * qty).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 20),
                  _priceLine('Subtotal', 'THB ${widget.subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  if (_isLoadingFee)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    )
                  else
                    _priceLine('Delivery Fee', 'THB ${_deliveryFee.toStringAsFixed(0)}'),
                  if (_couponDiscount > 0) ...[
                    const SizedBox(height: 4),
                    _priceLine('Coupon Discount', '- THB ${_couponDiscount.toStringAsFixed(0)}', color: Colors.green),
                  ],
                  if (_redeemPoints && _pointsDiscount > 0) ...[
                    const SizedBox(height: 4),
                    _priceLine('Points Discount', '- THB ${_pointsDiscount.toStringAsFixed(0)}', color: Colors.green),
                  ],
                  const Divider(height: 16),
                  _priceLine('Total', 'THB ${_totalAfterDiscounts.toStringAsFixed(0)}',
                      isBold: true, valueColor: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Coupon Code ────────────────────────────────────────────────
            _sectionLabel('Promo Code'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecor(),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter code (e.g. SAVE20)',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.local_offer_rounded, color: Color(0xFF6B7280), size: 20),
                        suffixIcon: _couponStatus == 'valid'
                            ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                            : _couponStatus == 'invalid'
                                ? const Icon(Icons.cancel_rounded, color: Colors.red)
                                : null,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isCheckingCoupon ? null : _applyCoupon,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isCheckingCoupon
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Apply',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Loyalty Points ─────────────────────────────────────────────
            if (_loyaltyBalance >= 100) ...[
              _sectionLabel('Loyalty Points'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: _cardDecor(),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFEAB308), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_loyaltyBalance points available',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: _kDark)),
                          Text('= THB ${(_loyaltyBalance / 100 * 10).toStringAsFixed(0)} discount',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _redeemPoints,
                      onChanged: (_) => _toggleRedeemPoints(),
                      activeColor: _kPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Delivery Details ───────────────────────────────────────────
            _sectionLabel('Delivery Details'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor(),
              child: Column(children: [
                _textField(_nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                _textField(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _textFieldMulti(_addressCtrl, 'Full Delivery Address', Icons.location_on_outlined),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Payment ────────────────────────────────────────────────────
            _sectionLabel('Payment Method'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: _cardDecor(),
              child: DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.payment_outlined, color: Color(0xFF6B7280))),
                items: ['Cash', 'KPay', 'KBZ Pay', 'Wave Money']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
              ),
            ),
            const SizedBox(height: 32),

            // ── Place Order Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isPlacingOrder || belowMin) ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isPlacingOrder
                    ? const SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        belowMin
                            ? 'Min Order: THB ${_minOrderAmount.toStringAsFixed(0)}'
                            : 'Place Order',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.5)),
      );

  Widget _priceLine(String label, String value, {bool isBold = false, Color? valueColor, Color? color}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: isBold ? _kDark : Colors.grey.shade600)),
          Text(value, style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? valueColor ?? (isBold ? _kDark : Colors.grey.shade700),
          )),
        ],
      );

  Widget _textField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPrimary, width: 2)),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );

  Widget _textFieldMulti(TextEditingController ctrl, String label, IconData icon) =>
      TextFormField(
        controller: ctrl,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kPrimary, width: 2)),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );
}
