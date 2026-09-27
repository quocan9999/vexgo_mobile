import 'package:equatable/equatable.dart';
import '../../../../data/models/city_model.dart';
import '../../../../data/models/service_type.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

class ChangeServiceTypeEvent extends HomeEvent {
  final ServiceType serviceType;
  const ChangeServiceTypeEvent(this.serviceType);

  @override
  List<Object?> get props => [serviceType];
}

class SwapCitiesEvent extends HomeEvent {
  const SwapCitiesEvent();
}

class SelectDepartureCityEvent extends HomeEvent {
  final CityModel city;
  const SelectDepartureCityEvent(this.city);

  @override
  List<Object?> get props => [city];
}

class SelectDestinationCityEvent extends HomeEvent {
  final CityModel city;
  const SelectDestinationCityEvent(this.city);

  @override
  List<Object?> get props => [city];
}

class SelectDepartureDateEvent extends HomeEvent {
  final DateTime date;
  const SelectDepartureDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class SelectReturnDateEvent extends HomeEvent {
  final DateTime? date;
  const SelectReturnDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class ToggleRoundTripEvent extends HomeEvent {
  final bool isRoundTrip;
  const ToggleRoundTripEvent(this.isRoundTrip);

  @override
  List<Object?> get props => [isRoundTrip];
}

class UpdateTicketCountEvent extends HomeEvent {
  final int count;
  const UpdateTicketCountEvent(this.count);

  @override
  List<Object?> get props => [count];
}
