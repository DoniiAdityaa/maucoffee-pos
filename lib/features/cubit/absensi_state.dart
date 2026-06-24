part of 'absensi_cubit.dart';

enum AbsensiStatus { initial, loading, success, error }

class AbsensiState extends Equatable {
  final AbsensiStatus status;
  final List<AbsensiModel> activeShifts;
  final List<AbsensiModel> historyShifts;
  final String? errorMessage;

  const AbsensiState({
    this.status = AbsensiStatus.initial,
    this.activeShifts = const [],
    this.historyShifts = const [],
    this.errorMessage,
  });

  AbsensiState copyWith({
    AbsensiStatus? status,
    List<AbsensiModel>? activeShifts,
    List<AbsensiModel>? historyShifts,
    String? Function()? errorMessage,
  }) {
    return AbsensiState(
      status: status ?? this.status,
      activeShifts: activeShifts ?? this.activeShifts,
      historyShifts: historyShifts ?? this.historyShifts,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeShifts,
    historyShifts,
    errorMessage,
  ];
}
