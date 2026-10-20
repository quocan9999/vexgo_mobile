import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_bloc.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_event.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_state.dart';

class DeferredTrips implements TripRepository {
  final requests = <String, Completer<List<TripModel>>>{};
  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) {
    final response = Completer<List<TripModel>>();
    requests[date!] = response;
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final oldFails in [false, true]) {
    test(
      'new date results survive older ${oldFails ? 'failure' : 'success'} response',
      () async {
        final repository = DeferredTrips();
        final bloc = SearchTripsBloc(tripRepository: repository);
        addTearDown(bloc.close);
        bloc.add(
          LoadTripsEvent(
            fromCityId: 'HCM',
            toCityId: 'DL',
            date: DateTime(2030, 1, 1),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(ChangeSelectedDateEvent(DateTime(2030, 1, 2)));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.minPriceInResults, 0);
        final newest = TripModel.fromJson({'tripId': 2, 'price': 320000});
        repository.requests['2030-01-02']!.complete([newest]);
        await bloc.stream.firstWhere(
          (s) => s.status == SearchTripsStatus.success,
        );
        if (oldFails) {
          repository.requests['2030-01-01']!.completeError(
            StateError('old request offline'),
          );
        } else {
          repository.requests['2030-01-01']!.complete([
            TripModel.fromJson({'tripId': 1, 'price': 100000}),
          ]);
        }
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.selectedDate, DateTime(2030, 1, 2));
        expect(bloc.state.filteredTrips.map((t) => t.id), ['2']);
        expect(bloc.state.minPriceInResults, 320000);
        expect(bloc.state.status, SearchTripsStatus.success);
      },
    );
  }
}
