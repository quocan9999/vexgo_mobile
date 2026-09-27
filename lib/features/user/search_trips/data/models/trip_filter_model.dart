import 'package:equatable/equatable.dart';

enum TripSortType {
  earliest,
  latest,
  priceAsc,
  priceDesc,
  ratingDesc,
}

extension TripSortTypeExt on TripSortType {
  String get label {
    switch (this) {
      case TripSortType.earliest:
        return 'Giờ đi sớm nhất';
      case TripSortType.latest:
        return 'Giờ đi muộn nhất';
      case TripSortType.priceAsc:
        return 'Giá tăng dần';
      case TripSortType.priceDesc:
        return 'Giá giảm dần';
      case TripSortType.ratingDesc:
        return 'Đánh giá cao nhất';
    }
  }
}

enum TimeSlot {
  earlyMorning, // 00:00 - 06:00
  morning, // 06:00 - 12:00
  afternoon, // 12:00 - 18:00
  evening, // 18:00 - 24:00
}

extension TimeSlotExt on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.earlyMorning:
        return 'Sáng sớm (00:00 - 06:00)';
      case TimeSlot.morning:
        return 'Buổi sáng (06:00 - 12:00)';
      case TimeSlot.afternoon:
        return 'Buổi chiều (12:00 - 18:00)';
      case TimeSlot.evening:
        return 'Buổi tối (18:00 - 24:00)';
    }
  }

  bool matches(String timeStr) {
    // timeStr format "HH:mm"
    final parts = timeStr.split(':');
    if (parts.isEmpty) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    switch (this) {
      case TimeSlot.earlyMorning:
        return hour >= 0 && hour < 6;
      case TimeSlot.morning:
        return hour >= 6 && hour < 12;
      case TimeSlot.afternoon:
        return hour >= 12 && hour < 18;
      case TimeSlot.evening:
        return hour >= 18 && hour <= 23;
    }
  }
}

class TripFilterModel extends Equatable {
  final List<TimeSlot> selectedTimeSlots;
  final List<String> selectedOperators;
  final List<String> selectedVehicleTypes;
  final List<String> selectedAmenities;
  final double minPrice;
  final double maxPrice;

  const TripFilterModel({
    this.selectedTimeSlots = const [],
    this.selectedOperators = const [],
    this.selectedVehicleTypes = const [],
    this.selectedAmenities = const [],
    this.minPrice = 100000,
    this.maxPrice = 500000,
  });

  bool get hasActiveFilters =>
      selectedTimeSlots.isNotEmpty ||
      selectedOperators.isNotEmpty ||
      selectedVehicleTypes.isNotEmpty ||
      selectedAmenities.isNotEmpty ||
      minPrice > 100000 ||
      maxPrice < 500000;

  int get activeFilterCount {
    int count = 0;
    count += selectedTimeSlots.length;
    count += selectedOperators.length;
    count += selectedVehicleTypes.length;
    count += selectedAmenities.length;
    if (minPrice > 100000 || maxPrice < 500000) count += 1;
    return count;
  }

  TripFilterModel copyWith({
    List<TimeSlot>? selectedTimeSlots,
    List<String>? selectedOperators,
    List<String>? selectedVehicleTypes,
    List<String>? selectedAmenities,
    double? minPrice,
    double? maxPrice,
  }) {
    return TripFilterModel(
      selectedTimeSlots: selectedTimeSlots ?? this.selectedTimeSlots,
      selectedOperators: selectedOperators ?? this.selectedOperators,
      selectedVehicleTypes: selectedVehicleTypes ?? this.selectedVehicleTypes,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  @override
  List<Object?> get props => [
        selectedTimeSlots,
        selectedOperators,
        selectedVehicleTypes,
        selectedAmenities,
        minPrice,
        maxPrice,
      ];
}
