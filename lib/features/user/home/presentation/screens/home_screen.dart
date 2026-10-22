import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../widgets/featured_operators_section.dart';
import '../widgets/popular_routes_section.dart';
import '../widgets/search_form_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DiscoveryTheme(
    child: BlocProvider<HomeBloc>(
      create: (context) =>
          HomeBloc(tripRepository: context.read<TripRepository>())
            ..add(const LoadHomeDataEvent()),
      child: const _HomeScreenContent(),
    ),
  );
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DiscoveryColors.background,
    body: BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ColoredBox(
              color: DiscoveryColors.header,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_bus_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label: 'VexGo',
                          child: ExcludeSemantics(
                            child: Text.rich(
                              TextSpan(
                                children: const [
                                  TextSpan(text: 'Vex'),
                                  TextSpan(
                                    text: 'Go',
                                    style: TextStyle(
                                      color: DiscoveryColors.logoAccent,
                                    ),
                                  ),
                                ],
                              ),
                              style: DiscoveryTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Thông báo',
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => context.go('/notifications'),
                      ),
                      IconButton(
                        tooltip: 'Tài khoản và hỗ trợ',
                        icon: const Icon(
                          Icons.headset_mic_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn muốn đi đâu?',
                    style: DiscoveryTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tìm chuyến xe phù hợp cho hành trình của bạn.',
                    style: DiscoveryTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  if (state.status == HomeStatus.loading ||
                      state.status == HomeStatus.initial)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == HomeStatus.failure)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.wifi_off_outlined,
                              color: DiscoveryColors.neutral500,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa tải được dữ liệu tìm chuyến',
                              style: DiscoveryTextStyles.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kiểm tra kết nối và thử lại nhé.',
                              style: DiscoveryTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            DiscoveryButton(
                              text: 'Thử lại',
                              onPressed: () => context.read<HomeBloc>().add(
                                const LoadHomeDataEvent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SearchFormCard(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/my-tickets'),
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Tra cứu vé và xem vé của tôi'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: DiscoveryColors.primary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: DiscoveryColors.neutral200),
                      textStyle: DiscoveryTextStyles.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.popularRoutes.isNotEmpty)
            const SliverToBoxAdapter(child: PopularRoutesSection()),
          if (state.operators.isNotEmpty)
            const SliverToBoxAdapter(child: FeaturedOperatorsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    ),
  );
}
