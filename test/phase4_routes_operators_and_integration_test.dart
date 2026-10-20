import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/home/bloc/home_bloc.dart';
import 'package:vexgo_app/features/user/home/bloc/home_event.dart';
import 'package:vexgo_app/features/user/home/bloc/home_state.dart';

http.Response _utf8JsonResponse(dynamic body, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Dynamic Routes & Bus Companies Models', () {
    test(
      'PopularRouteModel.fromJson parses backend /routes payload correctly',
      () {
        final backendRouteJson = {
          'routeId': 101,
          'code': 'SG-DL',
          'origin': 'TP. Hồ Chí Minh',
          'destination': 'Đà Lạt',
          'durationMinutes': 480,
          'status': 'ACTIVE',
          'busCompany': {
            'busCompanyId': 1,
            'code': 'PT',
            'name': 'Phương Trang',
          },
        };

        final route = PopularRouteModel.fromJson(backendRouteJson);
        expect(route.id, equals('101'));
        expect(route.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(route.fromCityId, equals('HCM'));
        expect(route.toCityName, equals('Đà Lạt'));
        expect(route.toCityId, equals('DL'));
        expect(route.duration, equals('8 giờ'));
        expect(route.minPrice, isNull); // Backend payload has no minPrice
        expect(route.imageUrl, isNotEmpty);
      },
    );

    test(
      'OperatorModel.fromJson parses backend /bus-companies payload correctly',
      () {
        final backendBusCompanyJson = {
          'busCompanyId': 5,
          'code': 'HM',
          'name': 'Hoa Mai Limousine',
          'contactInfo': '1900 599 997',
          'status': 'HOAT_DONG',
        };

        final op = OperatorModel.fromJson(backendBusCompanyJson);
        expect(op.id, equals('5'));
        expect(op.name, equals('Hoa Mai Limousine'));
        expect(op.shortName, equals('HM'));
        expect(op.hotline, equals('1900 599 997'));
        expect(op.rating, isNull); // Backend payload has no rating
        expect(op.reviewCount, isNull); // Backend payload has no reviewCount
      },
    );
  });

  group(
    'Phase 4: Remote DataSource & Hybrid Repository for Routes & Bus Companies',
    () {
      test(
        'TripRemoteDataSourceImpl.getPopularRoutes returns mapped routes list',
        () async {
          final mockClient = MockClient((request) async {
            if (request.url.path.contains('/routes')) {
              return _utf8JsonResponse({
                'success': true,
                'data': [
                  {
                    'routeId': 1,
                    'code': 'SG-DL',
                    'origin': 'TP. Hồ Chí Minh',
                    'destination': 'Đà Lạt',
                    'durationMinutes': 420,
                    'status': 'ACTIVE',
                  },
                ],
              });
            }
            return http.Response('Not Found', 404);
          });

          final dataSource = TripRemoteDataSourceImpl(
            client: ApiClient(httpClient: mockClient),
          );

          final routes = await dataSource.getPopularRoutes();
          expect(routes.length, equals(1));
          expect(routes.first.id, equals('1'));
          expect(routes.first.fromCityName, equals('TP. Hồ Chí Minh'));
          expect(routes.first.duration, equals('7 giờ'));
        },
      );

      test(
        'TripRemoteDataSourceImpl.getBusCompanies returns mapped bus companies list',
        () async {
          final mockClient = MockClient((request) async {
            if (request.url.path.contains('/bus-companies')) {
              return _utf8JsonResponse({
                'success': true,
                'data': [
                  {
                    'busCompanyId': 9,
                    'code': 'FUTA',
                    'name': 'Phương Trang',
                    'contactInfo': '1900 6067',
                    'status': 'HOAT_DONG',
                  },
                ],
              });
            }
            return http.Response('Not Found', 404);
          });

          final dataSource = TripRemoteDataSourceImpl(
            client: ApiClient(httpClient: mockClient),
          );

          final companies = await dataSource.getBusCompanies();
          expect(companies.length, equals(1));
          expect(companies.first.id, equals('9'));
          expect(companies.first.name, equals('Phương Trang'));
          expect(companies.first.hotline, equals('1900 6067'));
        },
      );

      test(
        'HybridTripRepository returns remote routes & operators when available',
        () async {
          final mockClient = MockClient((request) async {
            if (request.url.path.contains('/routes')) {
              return _utf8JsonResponse({
                'data': [
                  {
                    'routeId': 2,
                    'origin': 'TP. Hồ Chí Minh',
                    'destination': 'Vũng Tàu',
                    'durationMinutes': 120,
                  },
                ],
              });
            }
            if (request.url.path.contains('/bus-companies')) {
              return _utf8JsonResponse({
                'data': [
                  {
                    'busCompanyId': 10,
                    'name': 'Kumho Samco',
                    'contactInfo': '028 35 112 112',
                  },
                ],
              });
            }
            return http.Response('Not Found', 404);
          });

          final repo = HybridTripRepository(
            remoteDataSource: TripRemoteDataSourceImpl(
              client: ApiClient(httpClient: mockClient),
            ),
          );

          final routes = await repo.getPopularRoutes();
          final operators = await repo.getOperators();

          expect(routes.length, equals(1));
          expect(routes.first.toCityName, equals('Vũng Tàu'));

          expect(operators.length, equals(1));
          expect(operators.first.name, equals('Kumho Samco'));
        },
      );

      test(
        'HybridTripRepository falls back to mock routes & operators when remote throws error',
        () async {
          final errorClient = MockClient((request) async {
            throw http.ClientException('Network down');
          });

          final repo = HybridTripRepository(
            remoteDataSource: TripRemoteDataSourceImpl(
              client: ApiClient(httpClient: errorClient),
            ),
          );

          final routes = await repo.getPopularRoutes();
          final operators = await repo.getOperators();

          // Graceful fallback without throwing
          expect(routes, isNotEmpty);
          expect(operators, isNotEmpty);
        },
      );

      test('HomeBloc loads seamlessly with HybridTripRepository', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/routes')) {
            return _utf8JsonResponse({
              'data': [
                {
                  'routeId': 50,
                  'origin': 'TP. Hồ Chí Minh',
                  'destination': 'Đà Lạt',
                  'durationMinutes': 480,
                },
              ],
            });
          }
          if (request.url.path.contains('/bus-companies')) {
            return _utf8JsonResponse({
              'data': [
                {
                  'busCompanyId': 1,
                  'name': 'Phương Trang Live',
                  'contactInfo': '1900 6067',
                },
              ],
            });
          }
          return http.Response('Not Found', 404);
        });

        final repo = HybridTripRepository(
          remoteDataSource: TripRemoteDataSourceImpl(
            client: ApiClient(httpClient: mockClient),
          ),
        );

        final bloc = HomeBloc(tripRepository: repo);
        bloc.add(const LoadHomeDataEvent());

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<HomeState>((state) {
              return state.status == HomeStatus.success &&
                  state.popularRoutes.length == 1 &&
                  state.popularRoutes.first.id == '50' &&
                  state.operators.length == 1 &&
                  state.operators.first.name == 'Phương Trang Live';
            }),
          ),
        );

        await bloc.close();
      });
    },
  );
}
