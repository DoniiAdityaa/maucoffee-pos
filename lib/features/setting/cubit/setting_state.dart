part of 'setting_cubit.dart';

class SettingState extends Equatable {
  final String cafeName;
  final String cafeAddress;
  final String cafePhone;
  final String paperSize;
  final String lastSyncTime;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final String? successMessage;

  const SettingState({
    required this.cafeName,
    required this.cafeAddress,
    required this.cafePhone,
    required this.paperSize,
    required this.lastSyncTime,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.successMessage,
  });

  factory SettingState.initial() {
    return const SettingState(
      cafeName: "Maucoffee POS",
      cafeAddress: "Jl. Kenangan Manis No. 45, Jakarta",
      cafePhone: "0812-3456-7890",
      paperSize: "58mm",
      lastSyncTime: "Belum pernah sinkronisasi",
    );
  }

  SettingState copyWith({
    String? cafeName,
    String? cafeAddress,
    String? cafePhone,
    String? paperSize,
    String? lastSyncTime,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    String? successMessage,
  }) {
    return SettingState(
      cafeName: cafeName ?? this.cafeName,
      cafeAddress: cafeAddress ?? this.cafeAddress,
      cafePhone: cafePhone ?? this.cafePhone,
      paperSize: paperSize ?? this.paperSize,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        cafeName,
        cafeAddress,
        cafePhone,
        paperSize,
        lastSyncTime,
        isLoading,
        isSyncing,
        errorMessage,
        successMessage,
      ];
}
