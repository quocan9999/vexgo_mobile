import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/features/user/app_info/presentation/screens/app_information_screen.dart';
import '../widgets/available_offers_section.dart';
import '../../../ai_chatbot/presentation/widgets/ai_chatbot_entry_card.dart';
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
                        tooltip: context.l10n.uiNotifications,
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => context.go('/notifications'),
                      ),
                      IconButton(
                        tooltip: context.l10n.uiAccountAndSupport,
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
                    context.l10n.uiWhereWouldYouLikeToGo,
                    style: DiscoveryTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.uiFindTheRightBusForYourJourney,
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
                              context.l10n.uiUnableToLoadTripSearch,
                              style: DiscoveryTextStyles.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.uiCheckYourConnectionAndTryAgain,
                              style: DiscoveryTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            DiscoveryButton(
                              text: context.l10n.uiTryAgain,
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
                ],
              ),
            ),
          ),
          if (state.operators.isNotEmpty)
            SliverToBoxAdapter(
              child: AvailableOffersSection(operators: state.operators),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(child: AiChatbotEntryCard()),
          ),
          if (state.popularRoutes.isNotEmpty)
            const SliverToBoxAdapter(child: PopularRoutesSection()),
          if (state.operators.isNotEmpty)
            const SliverToBoxAdapter(child: FeaturedOperatorsSection()),
          const SliverToBoxAdapter(child: BookingGuideSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    ),
  );
}
