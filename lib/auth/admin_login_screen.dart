import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import config dan UI system kita
import 'package:maucoffee/config/env/env.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/navigation/navigation.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  bool _isTermsAccepted = false;
  bool _isLoading = false;

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
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_isTermsAccepted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please accept Terms of Service first",
            style: sMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE04040),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(spacing6),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: Env.googleWebClientId,
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Failed to get Google auth token.';
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.session != null) {
        final prefs = serviceLocator<UserPreference>();
        await prefs.setToken(response.session!.accessToken);
        await prefs.setLoginRole('admin');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigation(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sign-in failed: $e",
              style: sMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE04040),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(spacing6),
          ),
        );
      }
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
            colors: [
              Color(0xFF1C1207),
              Color(0xFF2A1A0A),
              Color(0xFF1A1008),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Back Button ──
              Padding(
                padding: const EdgeInsets.only(
                  left: spacing3,
                  top: spacing2,
                ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: spacing7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),

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
                                  color:
                                      const Color(0xFFE27D00).withOpacity(0.12),
                                  border: Border.all(
                                    color: const Color(0xFFE27D00)
                                        .withOpacity(0.25),
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

                              const SizedBox(height: spacing6),

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
                              const SizedBox(height: spacing3),
                              Text(
                                "Sign in with your Google account to manage\nyour coffee shop.",
                                style: sRegular.copyWith(
                                  color: Colors.white.withOpacity(0.4),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

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
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(spacing5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withOpacity(0.06),
                                    border: Border.all(
                                      color: _isTermsAccepted
                                          ? const Color(0xFFE27D00)
                                              .withOpacity(0.4)
                                          : Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Custom iOS-style checkbox
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
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
                                                : Colors.white
                                                    .withOpacity(0.25),
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
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              height: 1.4,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: "Terms of Service",
                                                style: xsBold.copyWith(
                                                  color:
                                                      const Color(0xFFE9A44C),
                                                ),
                                              ),
                                              const TextSpan(text: " and "),
                                              TextSpan(
                                                text: "Privacy Policy",
                                                style: xsBold.copyWith(
                                                  color:
                                                      const Color(0xFFE9A44C),
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

                      const SizedBox(height: spacing5),

                      // ── Google Sign-in Button ──
                      SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonFade,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _isTermsAccepted
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.08),
                                boxShadow: _isTermsAccepted
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _isLoading
                                  ? Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _isTermsAccepted
                                                ? const Color(0xFF1C1207)
                                                : Colors.white.withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/images/icons8-google.svg",
                                          width: 22,
                                          height: 22,
                                        ),
                                        const SizedBox(width: spacing3),
                                        Text(
                                          "Continue with Google",
                                          style: smBold.copyWith(
                                            color: _isTermsAccepted
                                                ? const Color(0xFF1C1207)
                                                : Colors.white
                                                    .withOpacity(0.25),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ── Footer ──
                      Center(
                        child: Padding(
                          padding:
                              EdgeInsets.only(bottom: bottomPadding + spacing6),
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
            ],
          ),
        ),
      ),
    );
  }
}
