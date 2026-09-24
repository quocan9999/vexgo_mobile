import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';

class PopularRoutesSection extends StatelessWidget {
  const PopularRoutesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) =>
          prev.popularRoutes != curr.popularRoutes || prev.status != curr.status,
      builder: (context, state) {
        final routes = state.popularRoutes;
        if (routes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tuyến đường phổ biến',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Tất cả',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
                itemCount: routes.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return _PopularRouteCard(route: route);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PopularRouteCard extends StatelessWidget {
  final PopularRouteModel route;

  const _PopularRouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final homeBloc = context.read<HomeBloc>();
        final state = homeBloc.state;

        final fromCity = state.cities.firstWhere(
          (c) => c.id == route.fromCityId,
          orElse: () => state.departureCity!,
        );
        final toCity = state.cities.firstWhere(
          (c) => c.id == route.toCityId,
          orElse: () => state.destinationCity!,
        );

        homeBloc.add(SelectDepartureCityEvent(fromCity));
        homeBloc.add(SelectDestinationCityEvent(toCity));

        context.push(
          '/search-trips',
          extra: {
            'fromCity': fromCity,
            'toCity': toCity,
            'date': state.departureDate,
            'ticketCount': state.ticketCount,
          },
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with duration badge
            Stack(
              children: [
                Image.network(
                  route.imageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 110,
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(Icons.landscape_rounded, color: AppColors.primary, size: 36),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          route.duration,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Route Details
            Padding(
              padding: const EdgeInsets.all(AppDimensions.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.fromCityName} - ${route.toCityName}',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Khoảng cách: ${route.distance}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs + 2),
                  Row(
                    children: [
                      Text(
                        'Từ ',
                        style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                      ),
                      Flexible(
                        child: Text(
                          CurrencyFormatter.format(route.minPrice),
                          style: AppTextStyles.price.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
