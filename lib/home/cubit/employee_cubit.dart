import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:maucoffee/repository/employee_repository.dart';

part 'employee_state.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _employeeRepository;

  EmployeeCubit(this._employeeRepository) : super(const EmployeeState());

  // Memuat daftar semua staf terdaftar
  Future<void> fetchEmployees() async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _employeeRepository.getEmployees();
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          employees: employees,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  // Mengubah data staf (Nama, Peran/Role, No. Telepon, Email)
  Future<void> updateEmployee(EmployeeModel employee) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.updateEmployee(employee);
      await fetchEmployees();
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  // Menghapus staf dari database
  Future<void> deleteEmployee(String id) async {
    // Optimistic update: langsung hapus dari list lokal secara sinkron agar UI responsif
    final updatedList = state.employees.where((e) => e.id != id).toList();
    emit(
      state.copyWith(status: EmployeeStatus.loading, employees: updatedList),
    );

    try {
      await _employeeRepository.deleteEmployee(id);
      await fetchEmployees();
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
      // Kembalikan data dari server jika gagal hapus
      await fetchEmployees();
    }
  }
}
