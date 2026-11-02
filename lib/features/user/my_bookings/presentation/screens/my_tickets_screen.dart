import 'package:vexgo_app/core/widgets/flat_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_ticket_lookup_panel.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_summary_card.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MyTicketsBloc>();
    if (bloc.state.status == MyTicketsStatus.initial) {
      bloc.add(const LoadMyTicketsEvent());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyTicketsBloc, MyTicketsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: DiscoveryColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.successMessage!,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: DiscoveryColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Multi-account / logout / reset query safety
        if (state.requiresLogin && _searchCtrl.text.isNotEmpty) {
          _searchCtrl.clear();
        }
        if (state.searchQuery.isEmpty && _searchCtrl.text.isNotEmpty) {
          _searchCtrl.clear();
        }
      },
      builder: (context, state) {
        final bloc = context.read<MyTicketsBloc>();
        return Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: TabPageHeader(
            title: 'Vé của tôi',
            actions: [
              if (!ApiConfig.isDemoMode)
                IconButton(
                  tooltip: 'Tra cứu chứng từ thanh toán',
                  icon: const Icon(Icons.receipt_long_outlined),
                  onPressed: () => context.push('/booking-receipt'),
                ),
            ],
          ),
          body: state.requiresLogin
              ? _buildGuestView(context, state, bloc)
              : Column(
                  children: [
                    _buildTabsBar(context, state, bloc),
                    Expanded(
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverToBoxAdapter(
                            child: _buildSearchBar(context, bloc),
                          ),
                        ],
                        body: _buildTicketsList(context, state, bloc),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildGuestView(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    return Column(
      children: [
        Expanded(
          child: GuestTicketLookupPanel(key: ValueKey(bloc.sessionGeneration)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.base,
            vertical: 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.go('/profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DiscoveryColors.primary,
                side: const BorderSide(
                  color: DiscoveryColors.primary,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Đăng nhập để xem tất cả vé',
                style: DiscoveryTextStyles.button.copyWith(
                  color: DiscoveryColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, MyTicketsBloc bloc) {
    return Container(
      color: DiscoveryColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.sm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => bloc.add(SearchTicketsEvent(val)),
        style: DiscoveryTextStyles.bodyMedium.copyWith(
          color: DiscoveryColors.neutral900,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập mã vé (VXG-...) hoặc SĐT tra cứu...',
          hintStyle: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.neutral400,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DiscoveryColors.neutral500,
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    _searchCtrl.clear();
                    bloc.add(const SearchTicketsEvent(''));
                  },
                )
              : null,
          filled: true,
          fillColor: DiscoveryColors.neutral100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabsBar(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    const statuses = [
      TicketStatus.upcoming,
      TicketStatus.completed,
      TicketStatus.cancelled,
    ];
    return FlatFilterBar(
      selectedIndex: statuses.indexOf(state.selectedTab),
      onChanged: (index) => bloc.add(ChangeTabEvent(statuses[index])),
      options: [
        FlatFilterOption(
          'Sắp đi',
          count: state.upcomingTickets.length,
          key: const Key('tab-upcoming'),
        ),
        FlatFilterOption(
          'Đã đi',
          count: state.completedTickets.length,
          key: const Key('tab-completed'),
        ),
        FlatFilterOption(
          'Đã hủy',
          count: state.cancelledTickets.length,
          key: const Key('tab-cancelled'),
        ),
      ],
    );
  }

  Widget _buildTicketsList(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    if (state.status == MyTicketsStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: DiscoveryColors.primary),
      );
    }

    if (state.status == MyTicketsStatus.error) {
      return _buildErrorState(context, state, bloc);
    }

    final tickets = state.filteredTickets;

    if (tickets.isEmpty) {
      if (state.searchQuery.trim().isNotEmpty) {
        return _buildSearchEmptyState(context, state, bloc);
      }
      return _buildTabEmptyState(context, state.selectedTab, bloc);
    }

    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () async {
        final completed = bloc.stream.firstWhere(
          (s) => s.status != MyTicketsStatus.loading,
        );
        bloc.add(const LoadMyTicketsEvent());
        await completed.timeout(
          const Duration(seconds: 5),
          onTimeout: () => bloc.state,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.base,
          AppDimensions.base,
          AppDimensions.base,
          24,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TicketSummaryCard(
            ticket: ticket,
            onTap: () {
              context.push('/ticket-detail', extra: ticket);
            },
            onCancel: () {
              CancelTicketSheet.show(context, ticket, bloc);
            },
            onReview: () {
              ReviewBottomSheet.show(context, ticket, bloc);
            },
            onRebook: () {
              context.go('/search-trips');
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () async {
        bloc.add(const LoadMyTicketsEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: DiscoveryColors.error,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.base),
                    Text(
                      'Không thể tải danh sách vé',
                      style: DiscoveryTextStyles.h4.copyWith(
                        color: DiscoveryColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.errorMessage ??
                          'Đã xảy ra lỗi trong quá trình tải dữ liệu. Vui lòng thử lại.',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => bloc.add(const LoadMyTicketsEvent()),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DiscoveryColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () async {
        bloc.add(const LoadMyTicketsEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: DiscoveryColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.base),
                    Text(
                      'Không tìm thấy vé phù hợp',
                      style: DiscoveryTextStyles.h4.copyWith(
                        color: DiscoveryColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Không có vé nào khớp với từ khóa "${state.searchQuery.trim()}". Vui lòng kiểm tra lại mã vé, số điện thoại hoặc lộ trình.',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _searchCtrl.clear();
                          bloc.add(const SearchTicketsEvent(''));
                        },
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        label: const Text('Xóa bộ lọc tìm kiếm'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DiscoveryColors.primary,
                          side: const BorderSide(
                            color: DiscoveryColors.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabEmptyState(
    BuildContext context,
    TicketStatus status,
    MyTicketsBloc bloc,
  ) {
    IconData icon;
    String title;
    String subtitle;
    bool showAction = false;

    switch (status) {
      case TicketStatus.upcoming:
        icon = Icons.confirmation_number_outlined;
        title = 'Chưa có chuyến xe nào sắp đi';
        subtitle =
            'Khám phá ngay hàng trăm chuyến xe khách liên tỉnh chất lượng cao với giá ưu đãi!';
        showAction = true;
        break;
      case TicketStatus.completed:
        icon = Icons.history_rounded;
        title = 'Chưa có lịch sử chuyến đi';
        subtitle =
            'Các chuyến xe bạn đã hoàn thành sẽ hiển thị tại đây để bạn có thể xem lại hoặc đánh giá.';
        break;
      case TicketStatus.cancelled:
        icon = Icons.cancel_presentation_rounded;
        title = 'Không có vé nào bị hủy';
        subtitle =
            'Mọi giao dịch hủy vé và hoàn tiền theo chính sách nhà xe sẽ được ghi nhận tại đây.';
        break;
    }

    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () async {
        bloc.add(const LoadMyTicketsEvent());
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 46,
                        color: DiscoveryColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.base),
                    Text(
                      title,
                      style: DiscoveryTextStyles.h4.copyWith(
                        color: DiscoveryColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showAction) ...[
                      const SizedBox(height: AppDimensions.lg),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/search-trips'),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Tìm chuyến ngay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DiscoveryColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.md),
                    TextButton.icon(
                      onPressed: () => bloc.add(const LoadMyTicketsEvent()),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Tải lại'),
                      style: TextButton.styleFrom(
                        foregroundColor: DiscoveryColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
