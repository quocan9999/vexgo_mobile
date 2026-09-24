import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/core/widgets/empty_state.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_event.dart';
import '../../bloc/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final bloc = context.read<NotificationBloc>();
        final unreadCount = state.unreadCount;
        final list = state.filteredNotifications;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Thông báo',
            automaticallyImplyLeading: Navigator.of(context).canPop(),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => bloc.add(const MarkAllNotificationsAsReadEvent()),
                  child: Text(
                    'Đọc tất cả',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // 1. Category Tabs
              Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral200),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base, vertical: 6),
                  children: [
                    _buildTab(context, title: 'Tất cả', count: unreadCount, index: 0, activeIndex: state.activeTabIndex),
                    const SizedBox(width: AppDimensions.xs),
                    _buildTab(context, title: 'Chuyến đi', index: 1, activeIndex: state.activeTabIndex),
                    const SizedBox(width: AppDimensions.xs),
                    _buildTab(context, title: 'Ưu đãi', index: 2, activeIndex: state.activeTabIndex),
                    const SizedBox(width: AppDimensions.xs),
                    _buildTab(context, title: 'Hệ thống', index: 3, activeIndex: state.activeTabIndex),
                  ],
                ),
              ),

              // 2. Notification List
              Expanded(
                child: state.status == NotificationStatus.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : list.isEmpty
                        ? EmptyState(
                            icon: Icons.notifications_off_outlined,
                            title: 'Chưa có thông báo nào',
                            message: 'Bạn chưa có thông báo trong mục này. Các cập nhật chuyến đi và ưu đãi sẽ xuất hiện tại đây.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppDimensions.base),
                            itemCount: list.length,
                            separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.sm),
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return _NotificationItemCard(
                                item: item,
                                onTap: () {
                                  bloc.add(MarkNotificationAsReadEvent(item.id));
                                  if (item.ticketCode != null) {
                                    context.push('/my-tickets');
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String title,
    int? count,
    required int index,
    required int activeIndex,
  }) {
    final isSelected = index == activeIndex;

    return InkWell(
      onTap: () => context.read<NotificationBloc>().add(ChangeNotificationTabEvent(index)),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.neutral700,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationItemCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      switch (item.category) {
        case NotificationCategory.trip:
          return Icons.directions_bus_rounded;
        case NotificationCategory.promo:
          return Icons.card_giftcard_rounded;
        case NotificationCategory.system:
          return Icons.info_outline_rounded;
      }
    }

    Color getColor() {
      switch (item.category) {
        case NotificationCategory.trip:
          return AppColors.primary;
        case NotificationCategory.promo:
          return AppColors.secondary;
        case NotificationCategory.system:
          return const Color(0xFF0F9D58);
      }
    }

    final color = getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: item.isRead ? AppColors.neutral200 : AppColors.primary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), color: color, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: item.isRead ? AppColors.neutral900 : AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.formatFullDate(item.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral400,
                      fontSize: 11,
                    ),
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
