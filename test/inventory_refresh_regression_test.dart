import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'booking_integrity_regression_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Review: hold expiry preserves normalized inventory coordinates',
    () async {
      ApiConfig.isDemoMode = false;
      TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
      addTearDown(TokenStorage.resetStorageAdapter);
      await TokenStorage.saveTokens(accessToken: 'review-fixture-token');
      final server = fixtures.CheckoutServer();
      final bloc = await fixtures.ready(server);
      addTearDown(bloc.close);
      final before = bloc.state.seatLayout!.lowerFloor
          .map((s) => '${s.id}:${s.row}:${s.col}')
          .toList();
      server.now = server.now.add(const Duration(minutes: 11));
      await fixtures.dispatch(
        bloc,
        const TickCountdownEvent(),
        (s) => s.seatHold == null,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final after = bloc.state.seatLayout!.lowerFloor
          .map((s) => '${s.id}:${s.row}:${s.col}')
          .toList();
      expect(
        after,
        before,
        reason: 'The same API inventory must retain its layout after expiry',
      );
    },
  );
}
