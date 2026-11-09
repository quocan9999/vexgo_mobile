import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/core/widgets/flat_filter_bar.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';
import 'package:vexgo_app/core/widgets/empty_state.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_event.dart';
import '../../bloc/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<NotificationBloc>().add(const LoadNotificationsEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationBloc>().add(const LoadNotificationsEvent());
    }
  }

  Future<void> _openNotification(NotificationModel item) async {
    if (_opening || context.read<NotificationBloc>().state.requiresLogin) {
      return;
    }
    context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(item.id));
    if (item.ticketId == null) {
      if (item.ticketCode != null || item.bookingId != null) {
        context.push('/my-tickets');
      }
      return;
    }
    _opening = true;
    final version = TokenStorage.sessionVersion;
    try {
      final ticket = await context.read<BookingRepository>().getTicketById(
        item.ticketId!,
      );
      if (!mounted ||
          version != TokenStorage.sessionVersion ||
          context.read<NotificationBloc>().state.requiresLogin) {
        return;
      }
      if (ticket == null) throw StateError('Ticket unavailable');
      await context.push('/ticket-detail', extra: ticket);
    } catch (_) {
      if (mounted &&
          version == TokenStorage.sessionVersion &&
          !context.read<NotificationBloc>().state.requiresLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.uiUnableToOpenTheTicketTryAgainIn),
          ),
        );
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedClientLabel(context, state.errorMessage!)),
          ),
        );
      },
      builder: (context, state) {
        final bloc = context.read<NotificationBloc>();
        final unreadCount = state.unreadCount;
        final list = state.filteredNotifications;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: TabPageHeader(
            title: context.l10n.uiNotifications,
            actions: [
              TabHeaderAction(
                label: context.l10n.uiMarkAllAsRead,
                icon: Icons.done_all_rounded,
                onPressed:
                    !state.requiresLogin &&
                        unreadCount > 0 &&
                        state.status != NotificationStatus.loading
                    ? () => bloc.add(const MarkAllNotificationsAsReadEvent())
                    : null,
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.hasCategories)
                FlatFilterBar(
                  selectedIndex: state.activeTabIndex,
                  onChanged: (index) =>
                      bloc.add(ChangeNotificationTabEvent(index)),
                  options: [
                    FlatFilterOption(context.l10n.uiAll, count: unreadCount),
                    FlatFilterOption(context.l10n.uiTrips),
                    FlatFilterOption(context.l10n.uiOffers),
                    FlatFilterOption(context.l10n.uiSystem),
                  ],
                ),

              // 2. Notification List
              Expanded(
                child: state.requiresLogin
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.l10n.uiSignInToViewNotifications),
                            TextButton(
                              onPressed: () => context.go('/profile'),
                              child: Text(context.l10n.uiSignIn),
                            ),
                          ],
                        ),
                      )
                    : state.status == NotificationStatus.failure
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.l10n.uiUnableToLoadNotifications),
                            TextButton(
                              onPressed: () =>
                                  bloc.add(const LoadNotificationsEvent()),
                              child: Text(context.l10n.uiTryAgain),
                            ),
                          ],
                        ),
                      )
                    : state.status == NotificationStatus.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : list.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                EmptyState(
                                  icon: Icons.notifications_off_outlined,
                                  title: context.l10n.uiNoNotificationsYet,
                                  message: context
                                      .l10n
                                      .uiThereAreNoNotificationsInThisCategoryTrip,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      bloc.add(const LoadNotificationsEvent()),
                                  child: Text(context.l10n.uiRefresh),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final completed = bloc.stream.firstWhere(
                            (s) => s.status != NotificationStatus.loading,
                          );
                          bloc.add(const LoadNotificationsEvent());
                          await completed;
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppDimensions.base),
                          itemCount: list.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppDimensions.sm),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return _NotificationItemCard(
                              item: item,
                              onTap: () => _openNotification(item),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItemCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationItemCard({required this.item, required this.onTap});

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
        case NotificationCategory.unknown:
          return Icons.notifications_outlined;
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
        case NotificationCategory.unknown:
          return AppColors.primary;
      }
    }

    final color = getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: item.isRead
              ? Colors.white
              : AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: item.isRead
                ? AppColors.neutral200
                : AppColors.primary.withValues(alpha: 0.3),
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
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: item.isRead
                                ? AppColors.neutral900
                                : AppColors.primary,
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
