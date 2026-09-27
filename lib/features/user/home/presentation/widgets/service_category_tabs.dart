import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/models/service_type.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';

class ServiceCategoryTabs extends StatelessWidget {
  const ServiceCategoryTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) => prev.selectedService != curr.selectedService,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ServiceType.values.map((service) {
              final isSelected = state.selectedService == service;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      if (service == ServiceType.ticketLookup) {
                        context.push('/my-tickets');
                        return;
                      }
                      if (service == ServiceType.cargo) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dịch vụ Gửi hàng hóa theo xe khách liên tỉnh sẽ sớm ra mắt theo đề cương!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      context.read<HomeBloc>().add(ChangeServiceTypeEvent(service));
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.sm + 2,
                        horizontal: AppDimensions.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                service.icon,
                                size: 22,
                                color: isSelected ? AppColors.primary : Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (!service.isAvailable)
                            Positioned(
                              top: -8,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Sắp có',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
