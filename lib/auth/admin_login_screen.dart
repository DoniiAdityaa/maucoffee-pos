import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import config dan UI system kita
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/model/user_model.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/navigation/navigation.dart';
import 'package:maucoffee/ui/widget_sharing/page_route_helper.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // Animations
  late AnimationController _contentController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _contentController.forward();

    // Reset error saat user mulai mengetik lagi
    _emailController.addListener(() {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    });
    _passwordController.addListener(() {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isTermsAccepted) {
      CustomFeedback.showError(context, "Please accept Terms of Service first");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.session != null) {
        final prefs = serviceLocator<UserPreference>();
        prefs.clearData();
        await prefs.setToken(response.session!.accessToken);
        await prefs.setLoginRole('admin');

        final adminUser = UserModel(
          id: response.user?.id,
          name:
              response.user?.userMetadata?['full_name'] as String? ??
              response.user?.email?.split('@')[0] ??
              "Owner Maucoffee",
          email: response.user?.email,
          photo: response.user?.userMetadata?['avatar_url'] as String?,
        );
        await prefs.setUser(adminUser);

        try {
          final employeeRepo = serviceLocator<EmployeeRepository>();
          await employeeRepo.ensureAdminAsEmployee(
            adminId: adminUser.id!,
            name: adminUser.name!,
            email: adminUser.email,
          );
        } catch (e) {
          debugPrint("Gagal mendaftarkan admin ke employees table: $e");
        }

        if (mounted) {
          AppNavigator.pushAndRemoveUntil(
            context,
            const MainNavigation(),
          );
        }
      }
    } catch (e) {
      String friendlyMessage;

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('invalid_credentials') ||
          errorStr.contains('invalid login credentials')) {
        friendlyMessage = 'Email atau password salah. Silakan coba lagi.';
      } else if (errorStr.contains('email not confirmed')) {
        friendlyMessage = 'Email belum dikonfirmasi. Hubungi administrator.';
      } else if (errorStr.contains('network') || errorStr.contains('socket')) {
        friendlyMessage = 'Tidak ada koneksi internet. Periksa jaringan kamu.';
      } else {
        friendlyMessage = 'Login gagal. Silakan coba beberapa saat lagi.';
      }
      setState(() {
        _errorMessage = friendlyMessage;
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1207), Color(0xFF2A1A0A), Color(0xFF1A1008)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Back Button ──
              Padding(
                padding: const EdgeInsets.only(left: spacing3, top: spacing2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: spacing7),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: spacing5),

                          // ── Header Section ──
                          SlideTransition(
                            position: _headerSlide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Small brand tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: spacing3,
                                      vertical: spacing1 + 1,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: const Color(
                                        0xFFE27D00,
                                      ).withOpacity(0.12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFE27D00,
                                        ).withOpacity(0.25),
                                      ),
                                    ),
                                    child: Text(
                                      "☕  Business Owner",
                                      style: xxsBold.copyWith(
                                        color: const Color(0xFFE9A44C),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: spacing5),
                                  Text(
                                    "Welcome\nBack",
                                    style: TextStyle(
                                      fontFamily: 'poppins',
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.1,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: spacing2),
                                  Text(
                                    "Sign in with your email and password to manage your coffee shop.",
                                    style: sRegular.copyWith(
                                      color: Colors.white.withOpacity(0.4),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: spacing7),

                          // ── Form Inputs ──
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    label: "Email Address",

                                    controller: _emailController,
                                    hintText: "Enter your email",
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return "Email is required";
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(val.trim())) {
                                        return "Enter a valid email address";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: spacing5),
                                  _buildTextField(
                                    label: "Password",
                                    controller: _passwordController,
                                    hintText: "Enter your password",
                                    obscureText: !_isPasswordVisible,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white30,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return "Password is required";
                                      }
                                      if (val.length < 6) {
                                        return "Password must be at least 6 characters";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Error Message ──
                          if (_errorMessage != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: xsRegular.copyWith(
                                        color: Colors.redAccent,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: spacing6),

                          // ── Terms Checkbox ──
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _isTermsAccepted = !_isTermsAccepted;
                                        });
                                      },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 16,
                                      sigmaY: 16,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(spacing5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                          color: _isTermsAccepted
                                              ? const Color(
                                                  0xFFE27D00,
                                                ).withOpacity(0.4)
                                              : Colors.white.withOpacity(0.08),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              color: _isTermsAccepted
                                                  ? const Color(0xFFE27D00)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: _isTermsAccepted
                                                    ? const Color(0xFFE27D00)
                                                    : Colors.white.withOpacity(
                                                        0.25,
                                                      ),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: _isTermsAccepted
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: spacing4),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                text: "I accept the ",
                                                style: xsRegular.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  height: 1.4,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: "Terms of Service",
                                                    style: xsBold.copyWith(
                                                      color: const Color(
                                                        0xFFE9A44C,
                                                      ),
                                                    ),
                                                  ),
                                                  const TextSpan(text: " and "),
                                                  TextSpan(
                                                    text: "Privacy Policy",
                                                    style: xsBold.copyWith(
                                                      color: const Color(
                                                        0xFFE9A44C,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: spacing6),

                          // ── Sign In Button ──
                          SlideTransition(
                            position: _buttonSlide,
                            child: FadeTransition(
                              opacity: _buttonFade,
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : _handleEmailPasswordSignIn,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: _isTermsAccepted
                                        ? const LinearGradient(
                                            colors: [
                                              primaryColor,
                                              Color(0xFFC56D00),
                                            ],
                                          )
                                        : null,
                                    color: _isTermsAccepted
                                        ? null
                                        : Colors.white.withOpacity(0.08),
                                    boxShadow: _isTermsAccepted
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(
                                                0.25,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            "Sign In",
                                            style: smBold.copyWith(
                                              color: _isTermsAccepted
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.25,
                                                    ),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: spacing7),

                          // ── Footer ──
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: bottomPadding + spacing6,
                              ),
                              child: Text(
                                "Your data is securely handled",
                                style: xsRegular.copyWith(
                                  color: Colors.white.withOpacity(0.2),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: xsBold.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: sMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: sRegular.copyWith(color: Colors.white24),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white30, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: spacing4,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
