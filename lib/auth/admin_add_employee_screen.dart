import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class AdminAddEmployeeScreen extends StatefulWidget {
  final String deviceUuid;

  const AdminAddEmployeeScreen({super.key, required this.deviceUuid});

  @override
  State<AdminAddEmployeeScreen> createState() => _AdminAddEmployeeScreenState();
}

class _AdminAddEmployeeScreenState extends State<AdminAddEmployeeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'Cashier';
  bool _isLoading = false;

  final List<String> _roles = ['Cashier', 'Admin'];

  // Animation
  late AnimationController _entryController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newEmployee = EmployeeModel(
        id: widget.deviceUuid,
        adminId: Supabase.instance.client.auth.currentUser?.id,
        name: _nameController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        isActive: true,
      );

      final employeeRepo = serviceLocator<EmployeeRepository>();
      await employeeRepo.addEmployee(newEmployee);

      if (mounted) {
        CustomFeedback.showSuccess(context, "${_nameController.text} has been registered!");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomFeedback.showError(context, "Failed to register: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: xsBold.copyWith(
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: spacing2),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: smMedium.copyWith(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: smRegular.copyWith(
                color: Colors.white.withOpacity(0.2),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: spacing5,
                vertical: spacing4,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: const Color(0xFFE27D00).withOpacity(0.6),
                      size: 20,
                    )
                  : null,
              errorStyle: xsRegular.copyWith(
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ),
        ),
      ],
    );
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
              // ── Header ──
              Padding(
                padding: const EdgeInsets.only(
                  left: spacing3,
                  right: spacing5,
                  top: spacing2,
                ),
                child: Row(
                  children: [
                    GestureDetector(
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
                    const SizedBox(width: spacing4),
                    Text(
                      "Register Staff",
                      style: mdBold.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(spacing6),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: spacing4),

                            // ── Device ID Card ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(spacing5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFFE27D00)
                                            .withOpacity(0.12),
                                        const Color(0xFFE27D00)
                                            .withOpacity(0.04),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFE27D00)
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: const Color(0xFFE27D00)
                                              .withOpacity(0.15),
                                        ),
                                        child: const Icon(
                                          Icons.phonelink_setup_rounded,
                                          color: Color(0xFFE9A44C),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: spacing4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Device ID",
                                              style: xxsBold.copyWith(
                                                color: const Color(0xFFE9A44C),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.deviceUuid,
                                              style: xsBold.copyWith(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                letterSpacing: 0.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: spacing7),

                            // ── Name Field ──
                            _buildField(
                              controller: _nameController,
                              label: "EMPLOYEE NAME",
                              hint: "Enter full name",
                              icon: Icons.person_outline_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Name is required";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: spacing5),

                            // ── Role Selection (iOS-style segmented) ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ROLE",
                                  style: xsBold.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: spacing2),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white.withOpacity(0.06),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: _roles.map((role) {
                                      final isSelected =
                                          _selectedRole == role;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _selectedRole = role;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              color: isSelected
                                                  ? const Color(0xFFE27D00)
                                                  : Colors.transparent,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFE27D00)
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                            0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  role == 'Cashier'
                                                      ? Icons
                                                          .point_of_sale_rounded
                                                      : Icons
                                                          .admin_panel_settings_rounded,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.35),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: spacing2),
                                                Text(
                                                  role,
                                                  style: smBold.copyWith(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.35),
                                                    letterSpacing: -0.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: spacing5),

                            // ── Phone Field (Optional) ──
                            _buildField(
                              controller: _phoneController,
                              label: "PHONE NUMBER (OPTIONAL)",
                              hint: "e.g. 081234567890",
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: spacing5),

                            // ── Email Field (Optional) ──
                            _buildField(
                              controller: _emailController,
                              label: "EMAIL (OPTIONAL)",
                              hint: "e.g. staff@maucoffee.com",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: spacing9),

                            // ── Submit Button ──
                            GestureDetector(
                              onTap: _isLoading ? null : _submitForm,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE27D00),
                                      Color(0xFFD06A00),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE27D00)
                                          .withOpacity(0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
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
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.person_add_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: spacing3),
                                          Text(
                                            "Register Employee",
                                            style: smBold.copyWith(
                                              color: Colors.white,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            SizedBox(height: bottomPadding + spacing6),
                          ],
                        ),
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
}
