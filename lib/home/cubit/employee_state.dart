part of 'employee_cubit.dart';

enum EmployeeStatus { initial, loading, success, error }

class EmployeeState extends Equatable {
  final EmployeeStatus status;
  final List<EmployeeModel> employees;
  final String? errorMessage;

  const EmployeeState({
    this.status = EmployeeStatus.initial,
    this.employees = const [],
    this.errorMessage,
  });

  EmployeeState copyWith({
    EmployeeStatus? status,
    List<EmployeeModel>? employees,
    String? Function()? errorMessage,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employees, errorMessage];
}
