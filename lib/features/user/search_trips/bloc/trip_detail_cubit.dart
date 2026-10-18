import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';

enum TripDetailStatus { loading, loaded, failure }

class TripDetailState {
  final TripDetailStatus status;
  final TripModel? trip;
  final String? error;
  const TripDetailState(this.status, {this.trip, this.error});
}

class TripDetailCubit extends Cubit<TripDetailState> {
  final TripRepository repository;
  final String tripId;
  int _request = 0;
  TripDetailCubit({required this.repository, required this.tripId})
    : super(const TripDetailState(TripDetailStatus.loading));

  Future<void> load() async {
    if (isClosed) return;
    final request = ++_request;
    emit(const TripDetailState(TripDetailStatus.loading));
    try {
      final trip = await repository.getTripById(tripId);
      if (isClosed || request != _request) return;
      if (trip == null || trip.id != tripId) {
        throw StateError('Không tìm thấy chuyến xe.');
      }
      emit(TripDetailState(TripDetailStatus.loaded, trip: trip));
    } catch (_) {
      if (isClosed || request != _request) return;
      emit(
        const TripDetailState(
          TripDetailStatus.failure,
          error: 'Không thể tải chi tiết chuyến xe. Vui lòng thử lại.',
        ),
      );
    }
  }
}
