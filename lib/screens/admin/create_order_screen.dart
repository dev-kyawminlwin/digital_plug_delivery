import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  String? _selectedRiderId;
  String? _selectedRiderName;
  String _selectedPaymentMethod = 'Cash'; // Phase 8: Default Payment Method

  void _submitOrder() async {
    if (_formKey.currentState!.validate() && _selectedRiderId != null) {
      // 1. Get current Admin's UID
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 2. Fetch Admin's Business ID
      final adminDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final businessId = adminDoc.data()?['businessId'];

      if (businessId == null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error: No associated business ID found.')),
           );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('orders').add({
        'businessId': businessId, // Critical: Ties the order to the shop
        'customerName': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'totalPrice': double.parse(_priceController.text),
        'deliveryFee': double.parse(_feeController.text),
        'riderId': _selectedRiderId,
        'riderName': _selectedRiderName,
        'paymentMethod': _selectedPaymentMethod, // Phase 8
        'status': 'assigned',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Created Successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Order")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Customer Name"), validator: (v) => v!.isEmpty ? "Required" : null),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Address"), maxLines: 2),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: "Total Price"), keyboardType: TextInputType.number),
              TextFormField(controller: _feeController, decoration: const InputDecoration(labelText: "Delivery Fee"), keyboardType: TextInputType.number),

              const SizedBox(height: 20),

              // Phase 8: Payment Method Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Payment Method"),
                value: _selectedPaymentMethod,
                items: ['Cash', 'KPay', 'KBZ Pay', 'Wave Money', 'Aya Pay'].map((String method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Rider Selection Dropdown
              // 1. First get the admin's business ID
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
                builder: (context, adminSnapshot) {
                  if (!adminSnapshot.hasData) return const CircularProgressIndicator();

                  final businessId = adminSnapshot.data?.get('businessId');
                  if (businessId == null) return const Text("Error: No business ID found.");

                  // 2. Then stream riders for ONLY that business ID
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'rider')
                        .where('businessId', isEqualTo: businessId) // Filter by Business ID
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();

                      var riders = snapshot.data!.docs;

                      if (riders.isEmpty) return const Text("No riders assigned to your business yet.");

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Select Rider"),
                        value: _selectedRiderId,
                        items: riders.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRiderId = value;
                            _selectedRiderName = riders.firstWhere((d) => d.id == value)['name'];
                          });
                        },
                      );
                    },
                  );
                }
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitOrder,
                child: const Text("Create Order"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}