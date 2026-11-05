import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/core/widgets/empty_state.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'shipment_status_badge.dart';

class ShipmentMyListView extends StatefulWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final ShipmentStatus? initialStatus;
  final String? initialSearch;
  final void Function(ShipmentStatus? status, String search, int page)?
  onFilterChanged;
  final ValueChanged<int>? onOpenDetail;

  const ShipmentMyListView({
    super.key,
    required this.cubit,
    required this.state,
    this.initialStatus,
    this.initialSearch,
    this.onFilterChanged,
    this.onOpenDetail,
  });

  @override
  State<ShipmentMyListView> createState() => _ShipmentMyListViewState();
}

class _ShipmentMyListViewState extends State<ShipmentMyListView> {
  late final TextEditingController _searchController;
  ShipmentStatus? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    if (widget.state.myShipments == null && !widget.state.loadingMine) {
      widget.cubit.loadMine(
        page: _currentPage,
        status: _selectedStatus,
        search: _searchController.text.trim(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetch({int? page, ShipmentStatus? status, String? search}) {
    final targetPage = page ?? _currentPage;
    final targetStatus = status ?? _selectedStatus;
    final targetSearch = search ?? _searchController.text.trim();
    _currentPage = targetPage;
    widget.onFilterChanged?.call(targetStatus, targetSearch, targetPage);
    widget.cubit.loadMine(
      page: targetPage,
      status: targetStatus,
      search: targetSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageData = widget.state.myShipments;
    final records = pageData?.records ?? [];

    return Column(
      children: [
        // Search & Filter header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.base,
            AppDimensions.sm,
            AppDimensions.base,
            AppDimensions.sm,
          ),
          child: Column(
            children: [
              CustomTextField(
                controller: _searchController,
                hintText: 'Tìm kiếm theo mã vận đơn...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: DiscoveryColors.neutral500,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  onPressed: () => _fetch(page: 1),
                ),
                onChanged: (val) {
                  if (val.isEmpty) _fetch(page: 1, search: '');
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', null),
                    _buildFilterChip('Mới tạo', ShipmentStatus.created),
                    _buildFilterChip('Đã tiếp nhận', ShipmentStatus.accepted),
                    _buildFilterChip(
                      'Đang vận chuyển',
                      ShipmentStatus.inTransit,
                    ),
                    _buildFilterChip('Đã giao', ShipmentStatus.delivered),
                    _buildFilterChip('Đã hủy', ShipmentStatus.cancelled),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: DiscoveryColors.neutral200),

        // List body
        Expanded(
          child: widget.state.loadingMine
              ? const Center(child: CircularProgressIndicator())
              : widget.state.listError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: DiscoveryColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.state.listError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            color: DiscoveryColors.neutral700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Thử lại',
                          onPressed: () => _fetch(),
                          type: ButtonType.primary,
                        ),
                      ],
                    ),
                  ),
                )
              : records.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chưa có đơn gửi hàng nào',
                  message:
                      'Bạn chưa tạo đơn gửi hàng nào hoặc không có đơn phù hợp bộ lọc.',
                )
              : RefreshIndicator(
                  onRefresh: () async => _fetch(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.base),
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = records[index];
                      return _buildShipmentCard(item);
                    },
                  ),
                ),
        ),

        // Pagination bar if page data available
        if (pageData != null && pageData.totalPages > 1) ...[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Trang trước',
                  onPressed: pageData.page > 1
                      ? () => _fetch(page: pageData.page - 1)
                      : null,
                ),
                Text(
                  'Trang ${pageData.page} / ${pageData.totalPages}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DiscoveryColors.neutral700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Trang sau',
                  onPressed: pageData.page < pageData.totalPages
                      ? () => _fetch(page: pageData.page + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, ShipmentStatus? status) {
    final selected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          setState(() => _selectedStatus = status);
          _fetch(page: 1, status: status);
        },
        selectedColor: DiscoveryColors.primaryLight,
        checkmarkColor: DiscoveryColors.primary,
        labelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? DiscoveryColors.primary
              : DiscoveryColors.neutral700,
        ),
      ),
    );
  }

  Widget _buildShipmentCard(ShipmentListEntry item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onOpenDetail != null) {
              widget.onOpenDetail!(item.shipmentId);
            } else {
              widget.cubit.openDetail(item.shipmentId);
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.waybillCode,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DiscoveryColors.primaryDark,
                        ),
                        softWrap: true,
                      ),
                    ),
                    ShipmentStatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.carrier} • ${item.route}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DiscoveryColors.neutral800,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Người nhận: ${item.receiverName}',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                    Text(
                      '${item.itemsCount} kiện',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: DiscoveryColors.neutral200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDayMonthYear(item.sentAt.toLocal()),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: DiscoveryColors.neutral500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.totalFee),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
