import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
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
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<MyTicketsBloc>();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: const CustomAppBar(
            title: 'Vé của tôi',
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              // Search & Lookup Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.sm,
                  AppDimensions.base,
                  AppDimensions.sm,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => bloc.add(SearchTicketsEvent(val)),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã vé (VXG-...) hoặc SĐT tra cứu...',
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral500, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              bloc.add(const SearchTicketsEvent(''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 3 Status Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base, vertical: 8),
                child: Row(
                  children: [
                    _buildTabItem(
                      title: 'Sắp đi',
                      count: state.upcomingTickets.length,
                      isSelected: state.selectedTab == TicketStatus.upcoming,
                      onTap: () => bloc.add(const ChangeTabEvent(TicketStatus.upcoming)),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    _buildTabItem(
                      title: 'Đã đi',
                      count: state.completedTickets.length,
                      isSelected: state.selectedTab == TicketStatus.completed,
                      onTap: () => bloc.add(const ChangeTabEvent(TicketStatus.completed)),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    _buildTabItem(
                      title: 'Đã hủy',
                      count: state.cancelledTickets.length,
                      isSelected: state.selectedTab == TicketStatus.cancelled,
                      onTap: () => bloc.add(const ChangeTabEvent(TicketStatus.cancelled)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.neutral200),

              // Tickets List / Empty State
              Expanded(
                child: _buildTicketsList(context, state, bloc),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.neutral700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.neutral300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.neutral700,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    BuildContext context,
    MyTicketsState state,
    MyTicketsBloc bloc,
  ) {
    if (state.status == MyTicketsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tickets = state.filteredTickets;

    if (tickets.isEmpty) {
      return _buildEmptyState(context, state.selectedTab);
    }

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const LoadMyTicketsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.base),
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

  Widget _buildEmptyState(BuildContext context, TicketStatus status) {
    IconData icon;
    String title;
    String subtitle;
    bool showAction = false;

    switch (status) {
      case TicketStatus.upcoming:
        icon = Icons.confirmation_number_outlined;
        title = 'Chưa có chuyến xe nào sắp đi';
        subtitle = 'Khám phá ngay hàng trăm chuyến xe khách liên tỉnh chất lượng cao với giá ưu đãi!';
        showAction = true;
        break;
      case TicketStatus.completed:
        icon = Icons.history_rounded;
        title = 'Chưa có lịch sử chuyến đi';
        subtitle = 'Các chuyến xe bạn đã hoàn thành sẽ hiển thị tại đây để bạn có thể xem lại hoặc đánh giá.';
        break;
      case TicketStatus.cancelled:
        icon = Icons.cancel_presentation_rounded;
        title = 'Không có vé nào bị hủy';
        subtitle = 'Mọi giao dịch hủy vé và hoàn tiền theo chính sách nhà xe sẽ được ghi nhận tại đây.';
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutral200.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.neutral500),
            ),
            const SizedBox(height: AppDimensions.base),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(color: AppColors.neutral800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (showAction) ...[
              const SizedBox(height: AppDimensions.lg),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/search-trips'),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Tìm chuyến ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
