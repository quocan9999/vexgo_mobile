import 'package:equatable/equatable.dart';
import '../../../../data/models/city_model.dart';
import '../../../../data/models/operator_model.dart';
import '../../../../data/models/popular_route_model.dart';
import '../../../../data/models/service_type.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final ServiceType selectedService;

  // Dữ liệu xe khách
  final List<CityModel> cities;
  final List<PopularRouteModel> popularRoutes;
  final List<OperatorModel> operators;
  final CityModel? departureCity;
  final CityModel? destinationCity;
  final int ticketCount;

  // Ngày đi & khứ hồi
  final DateTime departureDate;
  final DateTime? returnDate;
  final bool isRoundTrip;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedService = ServiceType.bus,
    this.cities = const [],
    this.popularRoutes = const [],
    this.operators = const [],
    this.departureCity,
    this.destinationCity,
    this.ticketCount = 1,
    required this.departureDate,
    this.returnDate,
    this.isRoundTrip = false,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    ServiceType? selectedService,
    List<CityModel>? cities,
    List<PopularRouteModel>? popularRoutes,
    List<OperatorModel>? operators,
    CityModel? departureCity,
    CityModel? destinationCity,
    int? ticketCount,
    DateTime? departureDate,
    DateTime? returnDate,
    bool? isRoundTrip,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedService: selectedService ?? this.selectedService,
      cities: cities ?? this.cities,
      popularRoutes: popularRoutes ?? this.popularRoutes,
      operators: operators ?? this.operators,
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      ticketCount: ticketCount ?? this.ticketCount,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedService,
        cities,
        popularRoutes,
        operators,
        departureCity,
        destinationCity,
        ticketCount,
        departureDate,
        returnDate,
        isRoundTrip,
        errorMessage,
      ];
}
