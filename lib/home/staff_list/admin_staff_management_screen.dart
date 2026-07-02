import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maucoffee/home/cubit/employee_cubit.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class AdminStaffManagementScreen extends StatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  State<AdminStaffManagementScreen> createState() => _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState extends State<AdminStaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    context.read<EmployeeCubit>().fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    if (role.toLowerCase() == 'admin') {
      return const Color(0xFFE27D00); // Premium Warm Orange
    }
    return const Color(0xFF8B5E3C); // Cashier Warm Brown
  }

  void _showEditEmployeeBottomSheet(BuildContext context, EmployeeModel employee) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee.name);
    final phoneController = TextEditingController(text: employee.phone ?? '');
    final emailController = TextEditingController(text: employee.email ?? '');
    String selectedRole = employee.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(statefulCtx).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E140A).withValues(alpha: 0.95),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(spacing6),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBottomSheetHandle(),
                          const SizedBox(height: spacing4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ubah Detail Staf",
                                style: mBold.copyWith(color: Colors.white),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                                onPressed: () => Navigator.pop(sheetCtx),
                              ),
                            ],
                          ),
                          const SizedBox(height: spacing5),
                          
                          // Input Name
                          _buildFormInputField(
                            controller: nameController,
                            label: "Nama Lengkap",
                            hintText: "Nama Lengkap",
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: spacing4),
                          
                          // Input Phone
                          _buildFormInputField(
                            controller: phoneController,
                            label: "Nomor Telepon",
                            hintText: "Contoh: 08123456789",
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: spacing4),
                          
                          // Input Email
                          _buildFormInputField(
                            controller: emailController,
                            label: "Alamat Email",
                            hintText: "Contoh: staff@maucoffee.com",
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: spacing5),
                          
                          // Role Choice (ONLY Cashier & Admin)
                          Text(
                            "Peran / Role",
                            style: xsBold.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: spacing3),
                          Row(
                            children: ['Cashier', 'Admin'].map((role) {
                              final isSelected = selectedRole.toLowerCase() == role.toLowerCase();
                              final roleColor = _getRoleColor(role);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: spacing1),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setModalState(() {
                                        selectedRole = role;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: spacing3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isSelected 
                                            ? roleColor.withValues(alpha: 0.15) 
                                            : Colors.white.withValues(alpha: 0.04),
                                        border: Border.all(
                                          color: isSelected 
                                              ? roleColor.withValues(alpha: 0.6) 
                                              : Colors.white.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Text(
                                        role,
                                        style: xsBold.copyWith(
                                          color: isSelected ? roleColor : Colors.white60,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: spacing7),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(sheetCtx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Batal",
                                    style: sBold.copyWith(color: Colors.white60),
                                  ),
                                ),
                              ),
                              const SizedBox(width: spacing3),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE27D00), Color(0xFFC56D00)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (!formKey.currentState!.validate()) {
                                        HapticFeedback.heavyImpact();
                                        return;
                                      }

                                      final updatedEmployee = EmployeeModel(
                                        id: employee.id,
                                        adminId: employee.adminId,
                                        name: nameController.text.trim(),
                                        role: selectedRole,
                                        phone: phoneController.text.trim().isEmpty 
                                            ? null 
                                            : phoneController.text.trim(),
                                        email: emailController.text.trim().isEmpty 
                                            ? null 
                                            : emailController.text.trim(),
                                        isActive: employee.isActive,
                                        createdAt: employee.createdAt,
                                      );

                                      HapticFeedback.mediumImpact();
                                      Navigator.pop(sheetCtx);
                                      
                                      try {
                                        await context.read<EmployeeCubit>().updateEmployee(updatedEmployee);
                                        if (context.mounted) {
                                          CustomFeedback.showSuccess(
                                            context,
                                            "Profil staf ${updatedEmployee.name} berhasil diperbarui.",
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          CustomFeedback.showError(
                                            context,
                                            "Gagal mengubah data staf: $e",
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Simpan",
                                      style: sBold.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
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
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1F150A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: Text(
          "Hapus Akun Staf",
          style: mdBold.copyWith(color: Colors.white),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus '${employee.name}'? Akses masuk dan data absensi staf ini akan terhapus secara permanen.",
          style: sRegular.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Batal",
              style: sMedium.copyWith(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.heavyImpact();
              Navigator.pop(dialogCtx);
              
              if (employee.id != null) {
                try {
                  await context.read<EmployeeCubit>().deleteEmployee(employee.id!);
                  if (context.mounted) {
                    CustomFeedback.showSuccess(
                      context,
                      "Akun staf '${employee.name}' berhasil dihapus.",
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    CustomFeedback.showError(
                      context,
                      "Gagal menghapus staf: $e",
                    );
                  }
                }
              }
            },
            child: Text(
              "Hapus",
              style: sBold.copyWith(color: const Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: spacing2),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildFormInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: xsBold.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: spacing3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: sMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: sRegular.copyWith(color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(spacing5),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1207), Color(0xFF2A1A0A), Color(0xFF1A1008)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing4,
        vertical: spacing3,
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
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: spacing4),
          Text(
            "Kelola Staf",
            style: lgBold.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing6,
        vertical: spacing2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          style: smMedium.copyWith(color: Colors.white),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Cari nama atau peran staf...",
            hintStyle: smRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.25),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: spacing4,
              vertical: 12,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white30,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    final roleColor = _getRoleColor(employee.role);
    final isAdmin = employee.role.toLowerCase() == 'admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: spacing4),
      child: _glassCard(
        padding: const EdgeInsets.all(spacing4),
        child: Row(
          children: [
            // Custom premium avatar with gradient borders
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isAdmin
                      ? [const Color(0xFFE27D00), const Color(0xFFFF9F29)]
                      : [const Color(0xFF5D4037), const Color(0xFF8D6E63)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  employee.name.isNotEmpty 
                      ? employee.name.substring(0, 1).toUpperCase() 
                      : "?",
                  style: smBold.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: spacing4),
            
            // Name and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: smBold.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: spacing2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacing2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: roleColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          employee.role,
                          style: xxsBold.copyWith(color: roleColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: Colors.white38),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            employee.phone!,
                            style: xxsRegular.copyWith(color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (employee.email != null && employee.email!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.email_rounded, size: 12, color: Colors.white38),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            employee.email!,
                            style: xxsRegular.copyWith(color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: spacing3),
            
            // Reusable modern buttons for Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showEditEmployeeBottomSheet(context, employee);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: spacing2),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showDeleteConfirmationDialog(context, employee);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.15)),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: spacing4),
                
                // Employee List
                Expanded(
                  child: BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                      if (state.status == EmployeeStatus.loading && state.employees.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE27D00)),
                          ),
                        );
                      }

                      if (state.status == EmployeeStatus.error) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFFF6B6B),
                                size: 48,
                              ),
                              const SizedBox(height: spacing4),
                              Text(
                                "Gagal memuat daftar staf",
                                style: smBold.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: spacing2),
                              Text(
                                state.errorMessage ?? "Terjadi kesalahan tidak dikenal.",
                                style: xsRegular.copyWith(color: Colors.white38),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: spacing4),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE27D00),
                                ),
                                onPressed: () {
                                  context.read<EmployeeCubit>().fetchEmployees();
                                },
                                child: const Text("Coba Lagi"),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredList = state.employees.where((e) {
                        final nameMatch = e.name.toLowerCase().contains(_searchQuery);
                        final roleMatch = e.role.toLowerCase().contains(_searchQuery);
                        return nameMatch || roleMatch;
                      }).toList();

                      if (filteredList.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<EmployeeCubit>().fetchEmployees(),
                          color: const Color(0xFFE27D00),
                          backgroundColor: const Color(0xFF2A1A0A),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      color: Colors.white24,
                                      size: 64,
                                    ),
                                    const SizedBox(height: spacing4),
                                    Text(
                                      _searchQuery.isEmpty 
                                          ? "Belum ada staf yang terdaftar." 
                                          : "Staf tidak ditemukan.",
                                      style: smMedium.copyWith(color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Sort Admin to the top, then sort by name
                      final sortedList = List<EmployeeModel>.from(filteredList);
                      sortedList.sort((a, b) {
                        final aIsAdmin = a.role.toLowerCase() == 'admin';
                        final bIsAdmin = b.role.toLowerCase() == 'admin';
                        if (aIsAdmin && !bIsAdmin) return -1;
                        if (!aIsAdmin && bIsAdmin) return 1;
                        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                      });

                      return RefreshIndicator(
                        onRefresh: () => context.read<EmployeeCubit>().fetchEmployees(),
                        color: const Color(0xFFE27D00),
                        backgroundColor: const Color(0xFF2A1A0A),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: spacing6,
                            right: spacing6,
                            bottom: spacing8,
                          ),
                          itemCount: sortedList.length,
                          itemBuilder: (context, index) {
                            return _buildEmployeeCard(sortedList[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
