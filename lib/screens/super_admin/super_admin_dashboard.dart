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

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildOverviewTab(),
      const _AddShopTab(),
      const _AddRiderTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Founder Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Add Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: "Add Rider"),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Platform Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 5),
              Text("Manage registered businesses and track global volume"),
            ],
          ),
        ),
        
        // Phase 7: Global App-Wide Analytics Stream
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
          builder: (context, orderSnapshot) {
            double globalGmv = 0;
            int totalCompletedOrders = 0;
            
            if (orderSnapshot.hasData) {
              totalCompletedOrders = orderSnapshot.data!.docs.length;
              for (var doc in orderSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                globalGmv += (data['totalPrice'] ?? 0) + (data['deliveryFee'] ?? 0);
              }
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: const Color(0xFFEAB308).withOpacity(0.2), // Light Gold
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Global GMV", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      Text("MMK ${globalGmv.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Total Deliveries", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      Text("$totalCompletedOrders", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final businesses = snapshot.data!.docs;

              if (businesses.isEmpty) {
                return const Center(child: Text("No businesses registered yet."));
              }

              return ListView.builder(
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  final doc = businesses[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  final name = data['name'] ?? 'Unknown Business';
                  final status = data['subscriptionStatus'] ?? 'inactive';
                  final subEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();
                  
                  final isActive = status == 'active' && 
                                   subEnd != null && 
                                   subEnd.isAfter(DateTime.now());

                  // Phase 7: Subscription Churn Risk Warning
                  bool isAtRisk = false;
                  if (isActive && subEnd != null) {
                    final threeDaysFromNow = DateTime.now().add(const Duration(days: 3));
                    if (subEnd.isBefore(threeDaysFromNow)) {
                      isAtRisk = true;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Highlight border red if at risk of churn
                    shape: isAtRisk ? RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        child: Icon(
                          isActive ? Icons.check_circle : Icons.error,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ID: ${doc.id}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (subEnd != null)
                            Text(
                              "Expires: ${subEnd.toLocal().toString().split(' ')[0]}", 
                              style: TextStyle(
                                fontSize: 12, 
                                color: isAtRisk ? Colors.red : Colors.grey[700],
                                fontWeight: isAtRisk ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? const Color(0xFFEAB308) : Colors.green, // Gold vs Green
                        ),
                        onPressed: () {
                          // Toggle subscription status
                          final newStatus = isActive ? 'inactive' : 'active';
                          FirebaseFirestore.instance.collection('businesses').doc(doc.id).update({
                            'subscriptionStatus': newStatus,
                            // If reactivating, optionally push the date forward 30 days
                            if (!isActive) 'subscriptionEnd': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)))
                          });
                        },
                        child: Text(isActive ? "Revoke" : "Activate", style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddShopTab extends StatefulWidget {
  const _AddShopTab();

  @override
  State<_AddShopTab> createState() => _AddShopTabState();
}

class _AddShopTabState extends State<_AddShopTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  String _bizName = '';
  String _adminName = '';
  String _email = '';
  String _password = '';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await _authService.createAdminAsSuperAdmin(
          email: _email,
          password: _password,
          businessName: _bizName,
          adminName: _adminName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop and Admin created successfully!')));
          _formKey.currentState!.reset();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text("Onboard New Shop", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: "Shop/Business Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _bizName = v!,
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Admin's Full Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _adminName = v!,
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Admin Login Email"),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _email = v!,
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Admin Password"),
              obscureText: true,
              validator: (v) => v!.length < 6 ? "Minimum 6 chars" : null,
              onSaved: (v) => _password = v!,
            ),
            const SizedBox(height: 30),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: _submit,
                  child: const Text("Create Shop Account", style: TextStyle(fontSize: 16)),
              )
          ],
        ),
      ),
    );
  }
}

class _AddRiderTab extends StatefulWidget {
  const _AddRiderTab();

  @override
  State<_AddRiderTab> createState() => _AddRiderTabState();
}

class _AddRiderTabState extends State<_AddRiderTab> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  String _riderName = '';
  String _email = '';
  String _password = '';
  String? _selectedBusinessId;

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedBusinessId != null) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await _authService.createRiderAsSuperAdmin(
          email: _email,
          password: _password,
          riderName: _riderName,
          businessId: _selectedBusinessId!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider created successfully!')));
          _formKey.currentState!.reset();
          setState(() => _selectedBusinessId = null);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      if (mounted) setState(() => _isLoading = false);
    } else if (_selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Shop to assign this Rider to.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text("Onboard New Rider", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: "Rider's Full Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _riderName = v!,
            ),
            const SizedBox(height: 10),
            
            // StreamBuilder to fetch active businesses for the dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final shops = snapshot.data!.docs;
                if (shops.isEmpty) return const Text("You must create a Shop first.");

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Assign to Shop"),
                  value: _selectedBusinessId,
                  items: shops.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedBusinessId = val);
                  },
                );
              }
            ),

            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Rider Login Email"),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _email = v!,
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Rider Password"),
              obscureText: true,
              validator: (v) => v!.length < 6 ? "Minimum 6 chars" : null,
              onSaved: (v) => _password = v!,
            ),
            const SizedBox(height: 30),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                  onPressed: _submit,
                  child: const Text("Create Rider Account", style: TextStyle(fontSize: 16, color: Colors.white)),
              )
          ],
        ),
      ),
    );
  }
}
