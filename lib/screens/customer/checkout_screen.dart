import 'package:flutter/material.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  bool _isPlacingOrder = false;
  double _deliveryFee = 0.0;
  bool _isLoadingFee = true;
  double _customerLat = 0.0;
  double _customerLng = 0.0;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _calculateDeliveryFee();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
      });
    }
  }

  Future<void> _calculateDeliveryFee() async {
    // 1. Fetch shop location and base fee
    final bizDoc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
    double baseFee = 20.0; // default base minimum
    GeoPoint? shopLoc;
    
    if (bizDoc.exists && bizDoc.data() != null) {
      final data = bizDoc.data()!;
      if (data['deliveryFee'] != null) {
        baseFee = double.tryParse(data['deliveryFee'].toString()) ?? 20.0;
      }
      shopLoc = data['location'];
    }

    // 2. Fetch customer GPS & compute distance
    double distKm = 0.0;
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _customerLat = pos.latitude;
        _customerLng = pos.longitude;

        if (shopLoc != null) {
          double distanceMeters = Geolocator.distanceBetween(
             shopLoc.latitude, shopLoc.longitude,
             pos.latitude, pos.longitude,
          );
          distKm = distanceMeters / 1000.0; // Convert to Kilometers
        }
      }
    } catch (e) {
      // Ignored: Default distance remains 0.0
    }

    // 3. Compute dynamic fee: Base Fare + Distance Rate (THB 10 per km)
    double computedFee = baseFee + (distKm * 10.0);
    
    if (mounted) {
      setState(() {
        _deliveryFee = computedFee;
        _isLoadingFee = false;
      });
    }
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPlacingOrder = true);

    String orderSummary = "";
    if (widget.detailedCart != null) {
      widget.detailedCart!.forEach((key, item) {
        final product = item['product'];
        final qty = item['qty'];
        final options = item['options'] as Map<String, String>? ?? {};
        final adds = item['addOns'] as List<Map<String, dynamic>>? ?? [];
        
        orderSummary += "${product.name} x$qty\n";
        if (options.isNotEmpty) {
          orderSummary += "  Options: ${options.entries.map((e) => "${e.key}: ${e.value}").join(', ')}\n";
        }
        if (adds.isNotEmpty) {
          orderSummary += "  Add-ons: ${adds.map((e) => "+${e['name']}").join(', ')}\n";
        }
      });
    } else {
      widget.cart.forEach((productId, qty) {
        orderSummary += "Product $productId x$qty\n";
      });
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      Map<String, dynamic> orderData = {
        'businessId': widget.businessId,
        'customerId': uid,
        'isGuestOrder': uid == 'guest',
        'customerName': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'itemsSummary': orderSummary.trim(),
        'totalPrice': widget.subtotal + _deliveryFee,
        'deliveryFee': _deliveryFee,
        'riderId': '',
        'riderName': '',
        'paymentMethod': _selectedPaymentMethod,
        'status': 'looking_for_rider',
        'createdAt': FieldValue.serverTimestamp(),
        'customerLat': _customerLat,
        'customerLng': _customerLng,
      };

      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      if (mounted) {
        setState(() => _isPlacingOrder = false);
        // Show success then navigate — avoids the double-nav bug
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 16),
                const Text("Order Placed!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Your order is being processed.\nWe're finding you a rider!",
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    // Navigate: replace entire stack with home, then push tracking
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    Navigator.of(context).pushNamed('/track/${docRef.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Track My Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Checkout", style: TextStyle(color: _kDark, fontWeight: FontWeight.bold, fontSize: 18)),
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
            // Order Summary Card
            _sectionLabel("Order Summary"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: _kPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(widget.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Items
                  if (widget.detailedCart != null)
                    ...widget.detailedCart!.values.map((item) {
                      final product = item['product'];
                      final qty = item['qty'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text("${product.name} x$qty",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ),
                            Text(
                              "THB ${(product.basePrice * qty).toStringAsFixed(0)}",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const Divider(height: 20),
                  _priceLine("Subtotal", "THB ${widget.subtotal.toStringAsFixed(0)}"),
                  const SizedBox(height: 6),
                  if (_isLoadingFee)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Delivery Fee", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    )
                  else
                    _priceLine("Delivery Fee", "THB ${_deliveryFee.toStringAsFixed(0)}"),
                  const Divider(height: 16),
                  _priceLine(
                    "Total",
                    "THB ${(widget.subtotal + _deliveryFee).toStringAsFixed(0)}",
                    isBold: true,
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Delivery Details
            _sectionLabel("Delivery Details"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _formField(_nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 12),
                  _formField(_phoneController, "Phone Number", Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _formFieldMulti(_addressController, "Full Delivery Address", Icons.location_on_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment
            _sectionLabel("Payment Method"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.payment_outlined, color: Color(0xFF6B7280)),
                ),
                items: ['Cash', 'KPay', 'KBZ Pay', 'Wave Money'].map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              ),
            ),
            const SizedBox(height: 32),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text("Place Order",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.5)),
    );
  }

  Widget _priceLine(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isBold ? _kDark : Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isBold ? _kDark : Colors.grey.shade700),
            )),
      ],
    );
  }

  Widget _formField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextFormField(
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
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _formFieldMulti(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
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
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
