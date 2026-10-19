import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../data/models/trip_filter_model.dart';
import 'search_trips_event.dart';
import 'search_trips_state.dart';

class SearchTripsBloc extends Bloc<SearchTripsEvent, SearchTripsState> {
  final TripRepository tripRepository;
  int _requestGeneration = 0;

  SearchTripsBloc({required this.tripRepository})
    : super(
        SearchTripsState(
          selectedDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ) {
    on<LoadTripsEvent>(_onLoadTrips);
    on<ChangeSelectedDateEvent>(_onChangeSelectedDate);
    on<ApplyFilterEvent>(_onApplyFilter);
    on<ChangeSortTypeEvent>(_onChangeSortType);
    on<ResetFilterEvent>(_onResetFilter);
  }

  Future<void> _onLoadTrips(
    LoadTripsEvent event,
    Emitter<SearchTripsState> emit,
  ) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: SearchTripsStatus.loading,
        fromCityId: event.fromCityId,
        toCityId: event.toCityId,
        selectedDate: event.date,
        allTrips: const [],
        filteredTrips: const [],
        errorMessage: '',
      ),
    );

    try {
      final d = event.date;
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final trips = await tripRepository.searchTrips(
        fromCityId: event.fromCityId,
        toCityId: event.toCityId,
        date: dateStr,
      );
      if (generation != _requestGeneration || emit.isDone) return;

      // Extract unique operators, vehicle types, amenities
      final operators = trips.map((t) => t.operatorName).toSet().toList();
      final vehicleTypes = trips.map((t) => t.vehicleType).toSet().toList();
      final amenities = trips.expand((t) => t.amenities).toSet().toList();

      final filtered = _applyFilterAndSort(
        trips,
        state.currentFilter,
        state.currentSort,
      );

      emit(
        state.copyWith(
          status: SearchTripsStatus.success,
          allTrips: trips,
          filteredTrips: filtered,
          availableOperators: operators,
          availableVehicleTypes: vehicleTypes,
          availableAmenities: amenities,
        ),
      );
    } catch (e) {
      if (generation != _requestGeneration || emit.isDone) return;
      emit(
        state.copyWith(
          status: SearchTripsStatus.failure,
          errorMessage: 'Lỗi tải danh sách chuyến xe: $e',
        ),
      );
    }
  }

  void _onChangeSelectedDate(
    ChangeSelectedDateEvent event,
    Emitter<SearchTripsState> emit,
  ) {
    ++_requestGeneration;
    emit(state.copyWith(selectedDate: event.newDate));
    if (state.fromCityId.isNotEmpty && state.toCityId.isNotEmpty) {
      add(
        LoadTripsEvent(
          fromCityId: state.fromCityId,
          toCityId: state.toCityId,
          date: event.newDate,
        ),
      );
    }
  }

  void _onApplyFilter(ApplyFilterEvent event, Emitter<SearchTripsState> emit) {
    final filtered = _applyFilterAndSort(
      state.allTrips,
      event.filter,
      state.currentSort,
    );
    emit(state.copyWith(currentFilter: event.filter, filteredTrips: filtered));
  }

  void _onChangeSortType(
    ChangeSortTypeEvent event,
    Emitter<SearchTripsState> emit,
  ) {
    final sorted = _applyFilterAndSort(
      state.allTrips,
      state.currentFilter,
      event.sortType,
    );
    emit(state.copyWith(currentSort: event.sortType, filteredTrips: sorted));
  }

  void _onResetFilter(ResetFilterEvent event, Emitter<SearchTripsState> emit) {
    const defaultFilter = TripFilterModel();
    final resetTrips = _applyFilterAndSort(
      state.allTrips,
      defaultFilter,
      state.currentSort,
    );
    emit(
      state.copyWith(currentFilter: defaultFilter, filteredTrips: resetTrips),
    );
  }

  List<TripModel> _applyFilterAndSort(
    List<TripModel> source,
    TripFilterModel filter,
    TripSortType sort,
  ) {
    var result = source.where((trip) {
      // Filter time of day
      if (filter.selectedTimeSlots.isNotEmpty) {
        final matchesAnySlot = filter.selectedTimeSlots.any(
          (slot) => slot.matches(trip.departureTime),
        );
        if (!matchesAnySlot) return false;
      }

      // Filter operators
      if (filter.selectedOperators.isNotEmpty) {
        if (!filter.selectedOperators.contains(trip.operatorName)) {
          return false;
        }
      }

      // Filter vehicle types
      if (filter.selectedVehicleTypes.isNotEmpty) {
        if (!filter.selectedVehicleTypes.contains(trip.vehicleType)) {
          return false;
        }
      }

      // Filter amenities
      if (filter.selectedAmenities.isNotEmpty) {
        final hasAllAmenities = filter.selectedAmenities.every(
          (a) => trip.amenities.contains(a),
        );
        if (!hasAllAmenities) {
          return false;
        }
      }

      // Filter price range
      if (trip.discountPrice < filter.minPrice ||
          trip.discountPrice > filter.maxPrice) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    switch (sort) {
      case TripSortType.earliest:
        result.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case TripSortType.latest:
        result.sort((a, b) => b.departureTime.compareTo(a.departureTime));
        break;
      case TripSortType.priceAsc:
        result.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
        break;
      case TripSortType.priceDesc:
        result.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
        break;
      case TripSortType.ratingDesc:
        result.sort((a, b) {
          if (a.rating == null) return b.rating == null ? 0 : 1;
          if (b.rating == null) return -1;
          return b.rating!.compareTo(a.rating!);
        });
        break;
    }

    return result;
  }
}
