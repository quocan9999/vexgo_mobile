import 'package:equatable/equatable.dart';
import '../data/models/trip_filter_model.dart';

abstract class SearchTripsEvent extends Equatable {
  const SearchTripsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTripsEvent extends SearchTripsEvent {
  final String fromCityId;
  final String toCityId;
  final DateTime date;

  const LoadTripsEvent({
    required this.fromCityId,
    required this.toCityId,
    required this.date,
  });

  @override
  List<Object?> get props => [fromCityId, toCityId, date];
}

class ChangeSelectedDateEvent extends SearchTripsEvent {
  final DateTime newDate;

  const ChangeSelectedDateEvent(this.newDate);

  @override
  List<Object?> get props => [newDate];
}

class ApplyFilterEvent extends SearchTripsEvent {
  final TripFilterModel filter;

  const ApplyFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ChangeSortTypeEvent extends SearchTripsEvent {
  final TripSortType sortType;

  const ChangeSortTypeEvent(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

class ResetFilterEvent extends SearchTripsEvent {
  const ResetFilterEvent();
}
