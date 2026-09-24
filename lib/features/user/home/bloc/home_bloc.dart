import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/trip_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository tripRepository;

  HomeBloc({required this.tripRepository})
      : super(HomeState(departureDate: DateTime.now().add(const Duration(days: 1)))) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<ChangeServiceTypeEvent>(_onChangeServiceType);
    on<SwapCitiesEvent>(_onSwapCities);
    on<SelectDepartureCityEvent>(_onSelectDepartureCity);
    on<SelectDestinationCityEvent>(_onSelectDestinationCity);
    on<SelectDepartureDateEvent>(_onSelectDepartureDate);
    on<SelectReturnDateEvent>(_onSelectReturnDate);
    on<ToggleRoundTripEvent>(_onToggleRoundTrip);
    on<UpdateTicketCountEvent>(_onUpdateTicketCount);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final cities = await tripRepository.getCities();
      final popularRoutes = await tripRepository.getPopularRoutes();
      final operators = await tripRepository.getOperators();

      final defaultDepartureCity = cities.firstWhere(
        (c) => c.id == 'HCM',
        orElse: () => cities.isNotEmpty ? cities.first : cities.first,
      );

      final defaultDestinationCity = cities.firstWhere(
        (c) => c.id == 'DL',
        orElse: () => cities.length > 1 ? cities[1] : cities.first,
      );

      emit(state.copyWith(
        status: HomeStatus.success,
        cities: cities,
        popularRoutes: popularRoutes,
        operators: operators,
        departureCity: defaultDepartureCity,
        destinationCity: defaultDestinationCity,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'Không thể tải dữ liệu trang chủ: $e',
      ));
    }
  }

  void _onChangeServiceType(
    ChangeServiceTypeEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedService: event.serviceType));
  }

  void _onSwapCities(
    SwapCitiesEvent event,
    Emitter<HomeState> emit,
  ) {
    final temp = state.departureCity;
    emit(state.copyWith(
      departureCity: state.destinationCity,
      destinationCity: temp,
    ));
  }

  void _onSelectDepartureCity(
    SelectDepartureCityEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureCity: event.city));
  }

  void _onSelectDestinationCity(
    SelectDestinationCityEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(destinationCity: event.city));
  }

  void _onSelectDepartureDate(
    SelectDepartureDateEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureDate: event.date));
  }

  void _onSelectReturnDate(
    SelectReturnDateEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(returnDate: event.date));
  }

  void _onToggleRoundTrip(
    ToggleRoundTripEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      isRoundTrip: event.isRoundTrip,
      returnDate: event.isRoundTrip
          ? (state.returnDate ?? state.departureDate.add(const Duration(days: 2)))
          : null,
    ));
  }

  void _onUpdateTicketCount(
    UpdateTicketCountEvent event,
    Emitter<HomeState> emit,
  ) {
    if (event.count >= 1 && event.count <= 10) {
      emit(state.copyWith(ticketCount: event.count));
    }
  }
}
