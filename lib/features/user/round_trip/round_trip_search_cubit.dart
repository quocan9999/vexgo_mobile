import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'round_trip_request.dart';

class RoundTripSearchState extends Equatable {
  final RoundTripRequest? request;
  final List<TripModel> outboundTrips;
  final List<TripModel> inboundTrips;
  final bool outboundLoading;
  final bool inboundLoading;
  final String? outboundError;
  final String? inboundError;
  final TripModel? outbound;
  final TripModel? inbound;
  const RoundTripSearchState({
    this.request,
    this.outboundTrips = const [],
    this.inboundTrips = const [],
    this.outboundLoading = false,
    this.inboundLoading = false,
    this.outboundError,
    this.inboundError,
    this.outbound,
    this.inbound,
  });
  bool get canContinue =>
      request != null &&
      outbound != null &&
      inbound != null &&
      request!.acceptsPair(outbound!, inbound!);
  RoundTripSelection? get selection => canContinue
      ? RoundTripSelection(
          request: request!,
          outbound: outbound!,
          inbound: inbound!,
        )
      : null;
  @override
  List<Object?> get props => [
    request,
    outboundTrips,
    inboundTrips,
    outboundLoading,
    inboundLoading,
    outboundError,
    inboundError,
    outbound,
    inbound,
  ];
}

/// Two independent searches; old responses cannot replace a newer route/date.
class RoundTripSearchCubit extends Cubit<RoundTripSearchState> {
  final TripRepository repository;
  int _revision = 0;
  RoundTripSearchCubit(this.repository) : super(const RoundTripSearchState());

  Future<void> search(RoundTripRequest request) async {
    if (isClosed) return;
    final revision = ++_revision;
    emit(
      RoundTripSearchState(
        request: request,
        outboundLoading: true,
        inboundLoading: true,
      ),
    );
    Future<void> fetch(TripLeg leg) async {
      List<TripModel> trips = const [];
      String? error;
      try {
        final result = await repository.searchTrips(
          fromCityId: request.originFor(leg).id,
          toCityId: request.destinationFor(leg).id,
          date: RoundTripRequest.formatDate(request.dateFor(leg)),
        );
        trips = List.unmodifiable(
          result.where((trip) => request.accepts(leg, trip)),
        );
      } catch (_) {
        error =
            'Không tải được chuyến ${leg == TripLeg.outbound ? 'đi' : 'về'}. Vui lòng thử lại.';
      }
      if (isClosed || revision != _revision) return;
      final s = state;
      emit(
        RoundTripSearchState(
          request: request,
          outboundTrips: leg == TripLeg.outbound ? trips : s.outboundTrips,
          inboundTrips: leg == TripLeg.inbound ? trips : s.inboundTrips,
          outboundLoading: leg == TripLeg.outbound ? false : s.outboundLoading,
          inboundLoading: leg == TripLeg.inbound ? false : s.inboundLoading,
          outboundError: leg == TripLeg.outbound ? error : s.outboundError,
          inboundError: leg == TripLeg.inbound ? error : s.inboundError,
          outbound: s.outbound,
          inbound: s.inbound,
        ),
      );
    }

    await Future.wait([fetch(TripLeg.outbound), fetch(TripLeg.inbound)]);
  }

  bool select(TripLeg leg, TripModel trip) {
    if (isClosed) return false;
    final s = state;
    final list = leg == TripLeg.outbound ? s.outboundTrips : s.inboundTrips;
    if ((leg == TripLeg.outbound ? s.outboundLoading : s.inboundLoading) ||
        !list.contains(trip)) {
      return false;
    }
    final out = leg == TripLeg.outbound ? trip : s.outbound;
    final back = leg == TripLeg.inbound ? trip : s.inbound;
    if (out != null && back != null && !s.request!.acceptsPair(out, back)) {
      return false;
    }
    emit(
      RoundTripSearchState(
        request: s.request,
        outboundTrips: s.outboundTrips,
        inboundTrips: s.inboundTrips,
        outboundLoading: s.outboundLoading,
        inboundLoading: s.inboundLoading,
        outboundError: s.outboundError,
        inboundError: s.inboundError,
        outbound: out,
        inbound: back,
      ),
    );
    return true;
  }

  void clearSelection(TripLeg leg) {
    if (isClosed) return;
    final s = state;
    emit(
      RoundTripSearchState(
        request: s.request,
        outboundTrips: s.outboundTrips,
        inboundTrips: s.inboundTrips,
        outboundLoading: s.outboundLoading,
        inboundLoading: s.inboundLoading,
        outboundError: s.outboundError,
        inboundError: s.inboundError,
        outbound: leg == TripLeg.outbound ? null : s.outbound,
        inbound: leg == TripLeg.inbound ? null : s.inbound,
      ),
    );
  }
}
