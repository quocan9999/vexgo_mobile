import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../widgets/featured_operators_section.dart';
import '../widgets/popular_routes_section.dart';
import '../widgets/promo_banners_section.dart';
import '../widgets/search_form_card.dart';
import '../widgets/service_category_tabs.dart';
import '../widgets/service_guarantee_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        tripRepository: context.read<TripRepository>(),
      )..add(const LoadHomeDataEvent()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == HomeStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    state.errorMessage ?? 'Đã có lỗi xảy ra',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.base),
                  ElevatedButton(
                    onPressed: () => context.read<HomeBloc>().add(const LoadHomeDataEvent()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Blue Gradient & Service Category Tabs
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.radiusXl),
                      bottomRight: Radius.circular(AppDimensions.radiusXl),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.base,
                        AppDimensions.sm,
                        AppDimensions.base,
                        AppDimensions.base,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top App Bar Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppDimensions.xs + 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                    ),
                                    child: const Icon(
                                      Icons.directions_bus_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.sm),
                                  Text(
                                    'VexGo',
                                    style: AppTextStyles.h2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => context.push('/notifications'),
                                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                    tooltip: 'Thông báo',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hotline Hỗ trợ VexGo'),
                                          content: const Text('Tổng đài hỗ trợ đặt vé: 1900 8888 (24/7)'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Đóng'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
                                    tooltip: 'Hotline',
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDimensions.xs),

                          // Slogan & Guarantee
                          Text(
                            'Đặt vé xe khách trực tuyến',
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cam kết giữ chỗ 100% • Hàng triệu hành khách tin dùng',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),

                          const SizedBox(height: AppDimensions.md),

                          // Dịch vụ hệ sinh thái xe khách (Vé xe khách, Gửi hàng hóa, Tra cứu vé)
                          const ServiceCategoryTabs(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Form Card (Positioned cleanly, 100% visible with full borders and shadow)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.base,
                    AppDimensions.md,
                    AppDimensions.base,
                    0,
                  ),
                  child: SearchFormCard(),
                ),

                const SizedBox(height: AppDimensions.base),

                // Promo Banners Section
                const PromoBannersSection(),

                const SizedBox(height: AppDimensions.xl),

                // Popular Routes Section
                const PopularRoutesSection(),

                const SizedBox(height: AppDimensions.xl),

                // Featured Operators Section
                const FeaturedOperatorsSection(),

                const SizedBox(height: AppDimensions.xl),

                // Service Guarantee Section
                const ServiceGuaranteeSection(),

                const SizedBox(height: AppDimensions.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
