import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kGold = Color(0xFFEAB308);
  static const Color _kDark = Color(0xFF1F2937);

  Future<void> _updateAvatar(String avatarName) async {
    await _db.collection('users').doc(_auth.currentUser!.uid).update({'avatar': avatarName});
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(_auth.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Profile Error"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () async {
                      await _auth.signOut();
                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  )
                ],
              ),
              body: const Center(child: Text("No Profile Data found. Please logout and re-register.")),
            );
          }

          final int points = data['points'] ?? 0;
          final String currentAvatar = data['avatar'] ?? '';
          final String name = data['name'] ?? 'User';
          final String email = data['email'] ?? '';
          final String phone = data['phone'] ?? '';
          final String address = data['address'] ?? '';

          return CustomScrollView(
            slivers: [
              // Immersive Profile Header
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Gradient Banner
                    Container(
                      height: 190,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF5E1E), Color(0xFFD94A1A)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Back & Logout
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _auth.signOut();
                                      if (mounted) {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text("Logout",
                                              style: TextStyle(
                                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Decorative circles
                          Positioned(
                            top: -20,
                            right: -30,
                            child: IgnorePointer(
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar positioned overlapping the banner bottom
                    Positioned(
                      bottom: -50,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentAvatar.isEmpty ? Colors.grey.shade200 : null,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))
                              ],
                              image: currentAvatar.isNotEmpty
                                  ? DecorationImage(
                                      image: AssetImage('assets/images/$currentAvatar.png'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: currentAvatar.isEmpty
                                ? const Icon(Icons.person_rounded, size: 52, color: Colors.grey)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Space for avatar overlap
              const SliverToBoxAdapter(child: SizedBox(height: 64)),

              // Name & Email
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kDark)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      const SizedBox(height: 24),

                      // Loyalty Points Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFFF7ED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAB308),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Loyalty Points",
                                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                                  Text("$points pts",
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _kGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("MEMBER",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avatar Selection
                      _sectionCard(
                        title: "Choose Your Avatar",
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAvatarOption('3d_male_avatar', currentAvatar == '3d_male_avatar', "Male"),
                            _buildAvatarOption('3d_female_avatar', currentAvatar == '3d_female_avatar', "Female"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Language Selection
                      _sectionCard(
                        title: "App Language",
                        child: Consumer<LocaleProvider>(
                          builder: (context, localeProvider, child) {
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildLangChip(context, localeProvider, 'en', '🇺🇸 English'),
                                _buildLangChip(context, localeProvider, 'th', '🇹🇭 ภาษาไทย'),
                                _buildLangChip(context, localeProvider, 'zh', '🇨🇳 中文'),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      _sectionCard(
                        title: "Contact Info",
                        child: Column(
                          children: [
                            _editableRow(
                              context,
                              icon: Icons.phone_outlined,
                              label: "Phone",
                              value: phone.isEmpty ? 'Not set' : phone,
                              onEdit: () => _editFieldDialog(
                                context,
                                label: 'Phone Number',
                                current: phone,
                                field: 'phone',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _editableRow(
                              context,
                              icon: Icons.location_on_outlined,
                              label: "Delivery Address",
                              value: address.isEmpty ? 'Tap to set address' : address,
                              onEdit: () => _editFieldDialog(
                                context,
                                label: 'Delivery Address',
                                current: address,
                                field: 'address',
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _editFieldDialog(
    BuildContext context, {
    required String label,
    required String current,
    required String field,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final ctrl = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              await _db.collection('users').doc(_auth.currentUser!.uid).update({field: ctrl.text.trim()});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Widget _editableRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: _kPrimary.withValues(alpha: 0.5), size: 16),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(String avatarName, bool isSelected, String label) {
    return GestureDetector(
      onTap: () => _updateAvatar(avatarName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kPrimary : Colors.grey.shade200,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: _kPrimary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
                image: DecorationImage(
                  image: AssetImage('assets/images/$avatarName.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _kPrimary : Colors.grey.shade500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, LocaleProvider localeProvider, String code, String label) {
    final isSelected = localeProvider.locale.languageCode == code;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          localeProvider.setLocale(Locale(code));
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? _kPrimary : Colors.grey.shade300),
      ),
    );
  }
}
