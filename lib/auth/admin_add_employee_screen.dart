import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminAddEmployeeScreen extends StatefulWidget {
  final String deviceUuid;

  const AdminAddEmployeeScreen({super.key, required this.deviceUuid});

  @override
  State<AdminAddEmployeeScreen> createState() => _AdminAddEmployeeScreenState();
}

class _AdminAddEmployeeScreenState extends State<AdminAddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'Cashier';
  bool _isLoading = false;

  final List<String> _roles = ['Cashier', 'Admin'];

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newEmployee = EmployeeModel(
        id: widget.deviceUuid, // Simpan device_uuid sebagai ID karyawan
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Karyawan ${_nameController.text} berhasil didaftarkan!",
            ),
            backgroundColor: successColor,
          ),
        );
        // Kembali ke scanner dan kirim data 'true' untuk menandakan sukses
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mendaftarkan karyawan: $e"),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: sMedium.copyWith(color: textDarkSecondary),
      hintText: hintText,
      hintStyle: sRegular.copyWith(color: textDarkTertiary),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: primaryColor)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing5,
        vertical: spacing4,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius200),
        borderSide: const BorderSide(color: borderFormDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius200),
        borderSide: const BorderSide(color: borderFormDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius200),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius200),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius200),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black50,
      appBar: AppBar(
        title: Text(
          "Register New Staff",
          style: mdBold.copyWith(color: textDarkPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textDarkPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(spacing6),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card (Device ID)
                Container(
                  padding: const EdgeInsets.all(spacing5),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(borderRadius300),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phonelink_setup_rounded,
                        color: primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: spacing4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Device ID (Unique)",
                              style: xxsBold.copyWith(color: primaryColor700),
                            ),
                            const SizedBox(height: spacing1),
                            Text(
                              widget.deviceUuid,
                              style: sBold.copyWith(color: textDarkPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: spacing6),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Nama karyawan harus diisi";
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    "Employee Name *",
                    hintText: "Enter full name",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  style: sMedium.copyWith(color: textDarkPrimary),
                ),
                const SizedBox(height: spacing5),

                // Role Dropdown Selection
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: _buildInputDecoration(
                    "Select Role",
                    prefixIcon: Icons.badge_outlined,
                  ),
                  style: sMedium.copyWith(color: textDarkPrimary),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(
                        role,
                        style: sMedium.copyWith(color: textDarkPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: spacing5),

                // Phone Input (Optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    "Phone Number (Optional)",
                    hintText: "e.g. 081234567890",
                    prefixIcon: Icons.phone_android_rounded,
                  ),
                  style: sMedium.copyWith(color: textDarkPrimary),
                ),
                const SizedBox(height: spacing5),

                // Email Input (Optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    "Email Address (Optional)",
                    hintText: "e.g. staff@maucoffee.com",
                    prefixIcon: Icons.email_outlined,
                  ),
                  style: sMedium.copyWith(color: textDarkPrimary),
                ),
                const SizedBox(height: spacing10),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius300),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : Text(
                            "Register Karyawan",
                            style: smBold.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
