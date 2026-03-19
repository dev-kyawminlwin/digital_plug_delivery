import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/business_service.dart';
import '../shared/app_components.dart';
import '../../main.dart';
import '../admin/admin_dashboard.dart';
import '../rider/rider_home.dart';
import '../customer/marketplace_home.dart';
import 'welcome_screen.dart';
import '../shared/guest_language_switcher.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final _authService = AuthService();
  final _userService = UserService();
  final _businessService = BusinessService();

  Future<void> login() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showError(AppLocalizations.of(context)!.fillAllFields);
      return;
    }
    setState(() => isLoading = true);

    try {
      final credential = await _authService.loginUser(email: email, password: pass);

      if (!mounted) return;

      final userData = await _userService.getUserData(credential.user!.uid);

      if (!mounted) return;

      if (userData == null) {
        await _userService.createSuperAdmin(credential.user!.uid, email);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      final role = (userData['role'] as String?)?.trim();
      final businessId = userData['businessId'];

      if (mounted) {
        if (role == 'admin') {
          if (businessId == null) throw "No business ID linked to this admin.";
          final bizData = await _businessService.getBusinessData(businessId);
          if (bizData == null) throw "Business record not found.";
          
          final isActive = _businessService.isSubscriptionActive(bizData);
          if (!isActive) {
            Navigator.pushReplacementNamed(context, '/subscription_expired');
            return;
          }
        }

        if (role == 'super_admin' || role == 'admin' || role == 'rider' || role == 'customer') {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        } else {
          await _authService.logout();
          _showError("Unrecognized user role: $role");
        }
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          GuestLanguageSwitcher(),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E1E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, size: 40, color: Color(0xFFFF5E1E)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header Texts
                  Text(l.tachileikDelivery, style: const TextStyle(fontSize: 16, color: Color(0xFFFF5E1E), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l.welcomeBack, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(l.loginSubtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
                  const SizedBox(height: 48),

                  _buildFloatingField(
                    controller: emailController,
                    hintText: l.emailHint,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: l.passwordHint,
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Options row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _rememberMe,
                            activeColor: const Color(0xFFFF5E1E),
                            onChanged: (v) => setState(() => _rememberMe = v),
                          ),
                          Text(l.saveMe, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text(l.forgotPassword, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: l.loginBtn,
                    onPressed: login,
                    isLoading: isLoading,
                  ),
                  
                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.noAccount, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
                      GestureDetector(
                        onTap: () => WelcomeScreen.showRegistrationOptions(context),
                        child: Text(l.signUp, style: const TextStyle(color: Color(0xFFFF5E1E), fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
}