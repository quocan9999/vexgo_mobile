import 'package:equatable/equatable.dart';
import '../../../../data/models/trip_model.dart';
import '../data/models/trip_filter_model.dart';

enum SearchTripsStatus { initial, loading, success, failure }

class SearchTripsState extends Equatable {
  final SearchTripsStatus status;
  final List<TripModel> allTrips;
  final List<TripModel> filteredTrips;
  final DateTime selectedDate;
  final TripFilterModel currentFilter;
  final TripSortType currentSort;
  final List<String> availableOperators;
  final List<String> availableVehicleTypes;
  final List<String> availableAmenities;
  final String fromCityId;
  final String toCityId;
  final String? errorMessage;

  const SearchTripsState({
    this.status = SearchTripsStatus.initial,
    this.allTrips = const [],
    this.filteredTrips = const [],
    required this.selectedDate,
    this.currentFilter = const TripFilterModel(),
    this.currentSort = TripSortType.earliest,
    this.availableOperators = const [],
    this.availableVehicleTypes = const [],
    this.availableAmenities = const [],
    this.fromCityId = '',
    this.toCityId = '',
    this.errorMessage,
  });

  int get minPriceInResults {
    if (filteredTrips.isEmpty) return 240000;
    return filteredTrips.map((t) => t.discountPrice).reduce((a, b) => a < b ? a : b);
  }

  SearchTripsState copyWith({
    SearchTripsStatus? status,
    List<TripModel>? allTrips,
    List<TripModel>? filteredTrips,
    DateTime? selectedDate,
    TripFilterModel? currentFilter,
    TripSortType? currentSort,
    List<String>? availableOperators,
    List<String>? availableVehicleTypes,
    List<String>? availableAmenities,
    String? fromCityId,
    String? toCityId,
    String? errorMessage,
  }) {
    return SearchTripsState(
      status: status ?? this.status,
      allTrips: allTrips ?? this.allTrips,
      filteredTrips: filteredTrips ?? this.filteredTrips,
      selectedDate: selectedDate ?? this.selectedDate,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
      availableOperators: availableOperators ?? this.availableOperators,
      availableVehicleTypes: availableVehicleTypes ?? this.availableVehicleTypes,
      availableAmenities: availableAmenities ?? this.availableAmenities,
      fromCityId: fromCityId ?? this.fromCityId,
      toCityId: toCityId ?? this.toCityId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allTrips,
        filteredTrips,
        selectedDate,
        currentFilter,
        currentSort,
        availableOperators,
        availableVehicleTypes,
        availableAmenities,
        fromCityId,
        toCityId,
        errorMessage,
      ];
}
