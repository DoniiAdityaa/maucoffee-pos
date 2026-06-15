import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import config dan UI system kita
import 'package:maucoffee/config/env/env.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _isTermsAccepted = false;
  bool _isLoading = false; // State untuk efek loading

  Future<void> _handleGoogleSignIn() async {
    // 1. Validasi persetujuan Syarat & Ketentuan
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap setujui Syarat dan Ketentuan terlebih dahulu."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Inisialisasi Google Sign In dengan Client ID Web yang barusan kita buat
      await GoogleSignIn.instance.initialize(
        serverClientId: Env.googleWebClientId,
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw 'Batal atau gagal mendapatkan akun Google.';
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Batal atau gagal mendapatkan token otentikasi Google.';
      }

      // 3. Kirim ID Token tersebut ke Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.session != null) {
        // 4. Simpan token & role di local storage SharedPreferences
        final prefs = serviceLocator<UserPreference>();
        await prefs.setToken(response.session!.accessToken);
        await prefs.setLoginRole('admin');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Google Admin Berhasil!")),
          );

          // Masuk ke halaman utama dashboard admin
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal login Google: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textDarkPrimary,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: spacing7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: spacing6),

              Text(
                "Start Selling",
                style: lBold.copyWith(color: textDarkPrimary, fontSize: 32),
              ),
              const SizedBox(height: spacing2),

              Text(
                "Sign in first to start using the Mau Coffee app",
                style: sRegular.copyWith(color: textDarkSecondary),
              ),

              const SizedBox(height: spacing10),

              // Checkbox Persetujuan
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isTermsAccepted,
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _isTermsAccepted = value ?? false;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "I accept ",
                        style: sRegular.copyWith(color: textDarkPrimary),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: sRegular.copyWith(
                              color: const Color(0xFF4176E3),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: sRegular.copyWith(
                              color: const Color(0xFF4176E3),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: spacing8),

              // Tombol Sign in with Google / Loading Indicator
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4176E3), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius300),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/images/icons8-google.svg",
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: spacing3),
                            Text(
                              "Sign in with Google",
                              style: sMedium.copyWith(
                                color: textDarkPrimary,
                                fontSize: 16,
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
