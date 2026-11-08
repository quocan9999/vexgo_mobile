import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/repositories/ai_chatbot_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';
import 'package:vexgo_app/features/user/ai_chatbot/presentation/screens/ai_chatbot_screen.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

class _Trips implements TripRepository {
  @override
  Future<List<CityModel>> getCities() async => [];
  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => [];
  @override
  Future<List<OperatorModel>> getOperators() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ai implements AiChatbotRepository {
  int loads = 0;
  @override
  Future<List<AiSuggestion>> suggestions() async {
    loads++;
    return const [
      AiSuggestion('qa', 'POLICY', 'Câu hỏi QA từ API', 'Gợi ý kiểm thử'),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'actual app routes: Home and Account open AI; root back and company scope work',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
      addTearDown(TokenStorage.resetStorageAdapter);
      final ai = _Ai();
      final auth = AuthBloc(authRepository: FakeAuthRepository());
      addTearDown(auth.close);
      AppRoutes.router.go(AppRoutes.home);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AiChatbotRepository>.value(value: ai),
            RepositoryProvider<TripRepository>.value(value: _Trips()),
          ],
          child: BlocProvider<AuthBloc>.value(
            value: auth,
            child: MaterialApp.router(routerConfig: AppRoutes.router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const Key('ai-chatbot-entry-card'));
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(AiChatbotScreen), findsOneWidget);
      expect(find.text('Câu hỏi QA từ API'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      await tester.tap(find.byKey(const Key('ai-chatbot-back-btn')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trợ lý AI'));
      await tester.pumpAndSettle();
      expect(find.byType(AiChatbotScreen), findsOneWidget);
      expect(ai.loads, 2);
      AppRoutes.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      AppRoutes.router.push(AppRoutes.aiChatbot, extra: 3);
      await tester.pumpAndSettle();
      expect(find.text('Đang lọc theo nhà xe #3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
