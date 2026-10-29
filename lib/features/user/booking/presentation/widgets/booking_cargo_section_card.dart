import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class BookingCargoSectionCard extends StatefulWidget {
  final BookingCargoState cargo;
  final bool locked;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onRefresh;
  final ValueChanged<BookingCargoDraft> onUpdateDraft;
  final String scopeKey;
  final String title;
  final String? legBadge;

  const BookingCargoSectionCard({
    super.key,
    required this.cargo,
    required this.locked,
    required this.onToggleEnabled,
    required this.onRefresh,
    required this.onUpdateDraft,
    this.scopeKey = 'oneway',
    this.title = 'Gửi hàng kèm vé',
    this.legBadge,
  });

  @override
  State<BookingCargoSectionCard> createState() =>
      _BookingCargoSectionCardState();
}

class _BookingCargoSectionCardState extends State<BookingCargoSectionCard> {
  bool _isEditingItem = false;
  int? _editingIndex;

  CargoKind _kind = CargoKind.parcel;
  int? _selectedCategoryId;
  CargoService _service = CargoService.normal;

  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _weightCtrl = TextEditingController(text: '5');
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _editorError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _licensePlateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  BookingCargoDraft get _currentDraft =>
      widget.cargo.draft ?? BookingCargoDraft(items: const []);

  double? _parseOptionalDouble(String raw) {
    final trimmed = raw.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) return double.nan;
    return parsed;
  }

  double? _parsePositiveFiniteDouble(String raw) {
    final v = _parseOptionalDouble(raw);
    if (v == null || !v.isFinite || v <= 0) return null;
    return v;
  }

  String? _validateDimensionInputs() {
    if (_kind == CargoKind.motorcycle || _kind == CargoKind.bicycle) {
      return null;
    }
    final rawDims = [
      _lengthCtrl.text.trim(),
      _widthCtrl.text.trim(),
      _heightCtrl.text.trim(),
    ];
    if (rawDims.every((s) => s.isEmpty)) return null;
    if (rawDims.any((s) => s.isEmpty)) {
      return 'Nhập đủ dài, rộng, cao; mỗi chiều phải lớn hơn 0.';
    }
    final parsedDims = rawDims
        .map((s) => double.tryParse(s.replaceAll(',', '.')))
        .toList();
    if (!parsedDims.every((v) => v != null && v.isFinite && v > 0)) {
      return 'Kích thước dài, rộng, cao phải là số hợp lệ lớn hơn 0.';
    }
    if (parsedDims[0]! > 150 || parsedDims[1]! > 80 || parsedDims[2]! > 80) {
      return 'Kích thước tối đa cho phép là 150 × 80 × 80 cm.';
    }
    return null;
  }

  double _parseWeight() {
    if (_kind == CargoKind.motorcycle) return 100;
    if (_kind == CargoKind.bicycle) return 15;
    final trimmed = _weightCtrl.text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return 0;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) return double.nan;
    return parsed;
  }

  int _parseQuantity() {
    return int.tryParse(_quantityCtrl.text.trim()) ?? 0;
  }

  CargoGroup _computeTargetGroup() {
    final parsedWeight = _parseWeight();
    final probe = CargoItemDraft(
      name: _nameCtrl.text.trim().isEmpty ? 'Hàng' : _nameCtrl.text.trim(),
      kind: _kind,
      categoryId: 1,
      quantity: _parseQuantity() > 0 ? _parseQuantity() : 1,
      weight: parsedWeight.isFinite && parsedWeight > 0 ? parsedWeight : 0,
      length: _parsePositiveFiniteDouble(_lengthCtrl.text),
      width: _parsePositiveFiniteDouble(_widthCtrl.text),
      height: _parsePositiveFiniteDouble(_heightCtrl.text),
    );
    return probe.group;
  }

  List<CargoCategory> _matchingCategories(CargoOptions options) {
    final group = _computeTargetGroup();
    return options.categories.where((c) => c.group == group).toList();
  }

  int? _resolvedCategoryId(CargoOptions options) {
    final matching = _matchingCategories(options);
    if (matching.isEmpty) return null;
    if (_selectedCategoryId != null &&
        matching.any((c) => c.id == _selectedCategoryId)) {
      return _selectedCategoryId;
    }
    return matching.first.id;
  }

  CargoItemDraft _buildCandidateItem(CargoOptions options) {
    final categoryId = _resolvedCategoryId(options) ?? 0;
    return CargoItemDraft(
      name: _nameCtrl.text.trim(),
      kind: _kind,
      categoryId: categoryId,
      quantity: _parseQuantity(),
      weight: _parseWeight(),
      length: _parseOptionalDouble(_lengthCtrl.text),
      width: _parseOptionalDouble(_widthCtrl.text),
      height: _parseOptionalDouble(_heightCtrl.text),
      service: _service,
      note: _noteCtrl.text.trim(),
      vehicleModel: _vehicleModelCtrl.text.trim(),
      licensePlate: _licensePlateCtrl.text.trim(),
    );
  }

  void _openAddItem(CargoOptions options) {
    setState(() {
      _isEditingItem = true;
      _editingIndex = null;
      _kind = CargoKind.parcel;
      _service = CargoService.normal;
      _nameCtrl.text = '';
      _quantityCtrl.text = '1';
      _weightCtrl.text = '5';
      _lengthCtrl.text = '';
      _widthCtrl.text = '';
      _heightCtrl.text = '';
      _vehicleModelCtrl.text = '';
      _licensePlateCtrl.text = '';
      _noteCtrl.text = '';
      _selectedCategoryId = null;
      _selectedCategoryId = _resolvedCategoryId(options);
      _editorError = null;
    });
  }

  void _openEditItem(int index, CargoItemDraft item, CargoOptions options) {
    setState(() {
      _isEditingItem = true;
      _editingIndex = index;
      _kind = item.kind;
      _selectedCategoryId = item.categoryId;
      _service = item.service;
      _nameCtrl.text = item.name;
      _quantityCtrl.text = '${item.quantity}';
      _weightCtrl.text = item.isVehicle
          ? '${item.payloadWeight.toInt()}'
          : _formatEditableNumber(item.weight);
      _lengthCtrl.text = item.length != null
          ? _formatEditableNumber(item.length!)
          : '';
      _widthCtrl.text = item.width != null
          ? _formatEditableNumber(item.width!)
          : '';
      _heightCtrl.text = item.height != null
          ? _formatEditableNumber(item.height!)
          : '';
      _vehicleModelCtrl.text = item.vehicleModel;
      _licensePlateCtrl.text = item.licensePlate;
      _noteCtrl.text = item.note;
      _selectedCategoryId = _resolvedCategoryId(options);
      _editorError = null;
    });
  }

  void _cancelEditor() {
    setState(() {
      _isEditingItem = false;
      _editingIndex = null;
      _editorError = null;
    });
  }

  void _saveItem(CargoOptions options) {
    final dimError = _validateDimensionInputs();
    if (dimError != null) {
      setState(() {
        _editorError = dimError;
      });
      return;
    }
    final matching = _matchingCategories(options);
    if (matching.isEmpty) {
      setState(() {
        _editorError =
            'Chuyến xe không có danh mục phù hợp cho nhóm ${_groupLabel(_computeTargetGroup())}.';
      });
      return;
    }
    final candidate = _buildCandidateItem(options);
    final itemError = candidate.validationError;
    if (itemError != null) {
      setState(() {
        _editorError = itemError;
      });
      return;
    }

    final updatedItems = List<CargoItemDraft>.from(_currentDraft.items);
    if (_editingIndex != null &&
        _editingIndex! >= 0 &&
        _editingIndex! < updatedItems.length) {
      updatedItems[_editingIndex!] = candidate;
    } else {
      updatedItems.add(candidate);
    }

    final usedInGroup = updatedItems
        .where((i) => i.group == candidate.group)
        .fold<int>(0, (sum, i) => sum + i.quantity);
    final remaining = options.capacity.slots[candidate.group]?.remaining ?? 0;
    if (usedInGroup > remaining) {
      setState(() {
        _editorError =
            'Số lượng vượt quá sức chứa còn lại ($remaining chỗ cho ${_groupLabel(candidate.group)}).';
      });
      return;
    }

    final points = options.points;
    int? senderId = _currentDraft.senderPointId;
    int? receiverId = _currentDraft.receiverPointId;
    if (points != null) {
      if (senderId == null && points.senders.length == 1) {
        senderId = points.senders.first.id;
      }
      if (receiverId == null && points.receivers.length == 1) {
        final candidateReceiver = points.receivers.first.id;
        if (candidateReceiver != senderId) {
          receiverId = candidateReceiver;
        }
      }
    }

    widget.onUpdateDraft(
      BookingCargoDraft(
        items: updatedItems,
        senderPointId: senderId,
        receiverPointId: receiverId,
      ),
    );
    setState(() {
      _isEditingItem = false;
      _editingIndex = null;
      _editorError = null;
    });
  }

  void _removeItem(int index) {
    final updatedItems = List<CargoItemDraft>.from(_currentDraft.items);
    if (index < 0 || index >= updatedItems.length) return;
    updatedItems.removeAt(index);
    widget.onUpdateDraft(
      BookingCargoDraft(
        items: updatedItems,
        senderPointId: _currentDraft.senderPointId,
        receiverPointId: _currentDraft.receiverPointId,
      ),
    );
  }

  void _selectSenderPoint(int? pointId) {
    widget.onUpdateDraft(
      BookingCargoDraft(
        items: _currentDraft.items,
        senderPointId: pointId,
        receiverPointId: _currentDraft.receiverPointId,
      ),
    );
  }

  void _selectReceiverPoint(int? pointId) {
    widget.onUpdateDraft(
      BookingCargoDraft(
        items: _currentDraft.items,
        senderPointId: _currentDraft.senderPointId,
        receiverPointId: pointId,
      ),
    );
  }

  static String _formatEditableNumber(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}';
    }
    return value.toString();
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}';
    }
    final fixed2 = value.toStringAsFixed(2);
    if (double.tryParse(fixed2) == value) {
      return fixed2.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value.toString();
  }

  static String _kindLabel(CargoKind kind) {
    switch (kind) {
      case CargoKind.parcel:
        return 'Hàng nhẹ';
      case CargoKind.bulky:
        return 'Hàng cồng kềnh';
      case CargoKind.motorcycle:
        return 'Xe máy';
      case CargoKind.bicycle:
        return 'Xe đạp';
    }
  }

  static String _groupLabel(CargoGroup group) {
    switch (group) {
      case CargoGroup.parcel:
        return 'Hàng nhẹ';
      case CargoGroup.bulky:
        return 'Hàng cồng kềnh / Xe đạp';
      case CargoGroup.motorcycle:
        return 'Xe máy';
    }
  }

  static String _serviceLabel(CargoService service) {
    switch (service) {
      case CargoService.normal:
        return 'Tiêu chuẩn';
      case CargoService.fragile:
        return 'Dễ vỡ';
      case CargoService.valuable:
        return 'Giá trị cao';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargo = widget.cargo;
    final locked = widget.locked;
    final scope = widget.scopeKey;

    return Container(
      key: Key('cargo-section-card-$scope'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cargo.enabled
              ? DiscoveryColors.primary.withValues(alpha: 0.4)
              : DiscoveryColors.neutral200,
          width: cargo.enabled ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cargo.enabled
                      ? DiscoveryColors.primaryLight
                      : DiscoveryColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: cargo.enabled
                      ? DiscoveryColors.primary
                      : DiscoveryColors.neutral600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: DiscoveryColors.neutral900,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.legBadge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DiscoveryColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.legBadge!,
                              style: const TextStyle(
                                color: DiscoveryColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Đăng ký gửi kiện hàng, xe máy hoặc xe đạp đi cùng chuyến xe',
                      style: TextStyle(
                        color: DiscoveryColors.neutral600,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                key: Key('cargo-toggle-$scope'),
                value: cargo.enabled,
                activeTrackColor: DiscoveryColors.primary,
                onChanged: locked
                    ? null
                    : (val) {
                        if (!val) {
                          _isEditingItem = false;
                          _editingIndex = null;
                          _editorError = null;
                        }
                        widget.onToggleEnabled(val);
                      },
              ),
            ],
          ),
          if (locked && cargo.enabled) ...[
            const SizedBox(height: 12),
            _buildBanner(
              key: Key('cargo-locked-banner-$scope'),
              icon: Icons.lock_outline_rounded,
              color: DiscoveryColors.info,
              text:
                  'Đơn hàng đã tạo hoặc đang xử lý. Thông tin gửi hàng đã được khóa để đảm bảo đồng bộ.',
            ),
          ],
          if (cargo.enabled) ...[
            const SizedBox(height: 12),
            _buildBanner(
              key: Key('cargo-pricing-notice-$scope'),
              icon: Icons.info_outline_rounded,
              color: DiscoveryColors.secondary,
              text:
                  'Phí gửi hàng được xác định khi tạo đơn. Thông tin người nhận được lấy theo thông tin liên hệ đặt vé và sức chứa được máy chủ xác nhận khi tạo đơn.',
            ),
            const SizedBox(height: 12),
            if (cargo.loading)
              _buildLoadingState(scope, locked)
            else if (cargo.error != null || cargo.options == null)
              _buildErrorState(
                scope,
                cargo.error ?? 'Không tải được tùy chọn gửi hàng.',
                locked,
              )
            else
              _buildLoadedOptions(scope, cargo.options!, locked),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(String scope, bool locked) {
    return Container(
      key: Key('cargo-loading-$scope'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DiscoveryColors.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đang kiểm tra dịch vụ gửi hàng, sức chứa và điểm gửi/nhận...',
                  style: TextStyle(
                    color: DiscoveryColors.neutral900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: Key('cargo-disable-btn-$scope'),
                onPressed: () => widget.onToggleEnabled(false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Bỏ gửi hàng'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String scope, String message, bool locked) {
    return Container(
      key: Key('cargo-error-$scope'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiscoveryColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DiscoveryColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: DiscoveryColors.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: DiscoveryColors.neutral900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: Key('cargo-retry-btn-$scope'),
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Thử lại'),
                ),
                TextButton.icon(
                  key: Key('cargo-disable-btn-$scope'),
                  onPressed: () => widget.onToggleEnabled(false),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Bỏ gửi hàng'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadedOptions(String scope, CargoOptions options, bool locked) {
    if (!options.capacity.acceptsShipments) {
      return Container(
        key: Key('cargo-not-accepted-$scope'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DiscoveryColors.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DiscoveryColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.block_rounded,
                  color: DiscoveryColors.warningDark,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chuyến xe không nhận gửi hàng.',
                    style: TextStyle(
                      color: DiscoveryColors.neutral900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Vui lòng tắt gửi hàng kèm vé để tiếp tục đặt vé hành khách như bình thường.',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (!locked) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: Key('cargo-disable-btn-$scope'),
                onPressed: () => widget.onToggleEnabled(false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Bỏ gửi hàng'),
              ),
            ],
          ],
        ),
      );
    }

    final points = options.points;
    final hasValidRoutePoints =
        points != null &&
        points.senders.isNotEmpty &&
        points.receivers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCapacitySection(scope, options.capacity),
        const SizedBox(height: 14),
        if (!hasValidRoutePoints)
          _buildErrorState(
            scope,
            'Chuyến xe chưa cấu hình điểm gửi/nhận hàng hợp lệ.',
            locked,
          )
        else ...[
          _buildRoutePointsSection(scope, points, locked),
          const SizedBox(height: 14),
          _buildCargoItemsSection(scope, options, locked),
        ],
        if (widget.cargo.validationError != null) ...[
          const SizedBox(height: 12),
          _buildBanner(
            key: Key('cargo-validation-error-$scope'),
            icon: Icons.warning_amber_rounded,
            color: DiscoveryColors.warningDark,
            text: widget.cargo.validationError!,
          ),
        ],
      ],
    );
  }

  Widget _buildCapacitySection(String scope, CargoCapacity capacity) {
    return Container(
      key: Key('cargo-capacity-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sức chứa gửi hàng còn lại trên chuyến',
            style: TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CargoGroup.values.map((group) {
              final remaining = capacity.slots[group]?.remaining ?? 0;
              final available = remaining > 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: available
                      ? DiscoveryColors.successLight
                      : DiscoveryColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: available
                        ? DiscoveryColors.success.withValues(alpha: 0.3)
                        : DiscoveryColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_groupLabel(group)}: còn $remaining chỗ',
                  style: TextStyle(
                    color: available
                        ? DiscoveryColors.successDark
                        : DiscoveryColors.errorDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePointsSection(
    String scope,
    CargoRoutePoints points,
    bool locked,
  ) {
    final senderId =
        points.senders.any((p) => p.id == _currentDraft.senderPointId)
        ? _currentDraft.senderPointId
        : null;
    final receiverId =
        points.receivers.any((p) => p.id == _currentDraft.receiverPointId)
        ? _currentDraft.receiverPointId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điểm gửi & nhận hàng trên tuyến',
          style: TextStyle(
            color: DiscoveryColors.neutral900,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: Key('cargo-sender-point-$scope'),
          initialValue: senderId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Điểm gửi hàng *',
            filled: true,
            fillColor: DiscoveryColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          dropdownColor: DiscoveryColors.surface,
          items: points.senders
              .map(
                (p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(
                    p.address.isNotEmpty ? '${p.name} (${p.address})' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DiscoveryColors.neutral900,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: locked ? null : _selectSenderPoint,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          key: Key('cargo-receiver-point-$scope'),
          initialValue: receiverId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Điểm nhận hàng *',
            filled: true,
            fillColor: DiscoveryColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          dropdownColor: DiscoveryColors.surface,
          items: points.receivers
              .map(
                (p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(
                    p.address.isNotEmpty ? '${p.name} (${p.address})' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DiscoveryColors.neutral900,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: locked ? null : _selectReceiverPoint,
        ),
      ],
    );
  }

  Widget _buildCargoItemsSection(
    String scope,
    CargoOptions options,
    bool locked,
  ) {
    if (options.categories.isEmpty) {
      return _buildBanner(
        key: Key('cargo-empty-categories-$scope'),
        icon: Icons.warning_amber_rounded,
        color: DiscoveryColors.error,
        text:
            'Chuyến xe chưa có danh mục hàng hóa hợp lệ. Không thể thêm kiện hàng.',
      );
    }

    final items = _currentDraft.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Danh sách kiện hàng (${items.length})',
              style: const TextStyle(
                color: DiscoveryColors.neutral900,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!locked && !_isEditingItem)
              OutlinedButton.icon(
                key: Key('cargo-add-item-btn-$scope'),
                onPressed: () => _openAddItem(options),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Thêm kiện hàng'),
              ),
          ],
        ),
        if (items.isEmpty && !_isEditingItem) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: const Text(
              'Chưa có kiện hàng nào. Nhấn "Thêm kiện hàng" để khai báo thông tin hàng gửi.',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final categoryName =
                options.categories
                    .where((c) => c.id == item.categoryId)
                    .map((c) => c.name)
                    .firstOrNull ??
                'Danh mục #${item.categoryId}';
            return _buildCargoItemTile(
              scope: scope,
              index: index,
              item: item,
              categoryName: categoryName,
              options: options,
              locked: locked,
            );
          }),
        ],
        if (_isEditingItem && !locked) ...[
          const SizedBox(height: 12),
          _buildItemEditor(scope, options),
        ],
      ],
    );
  }

  Widget _buildCargoItemTile({
    required String scope,
    required int index,
    required CargoItemDraft item,
    required String categoryName,
    required CargoOptions options,
    required bool locked,
  }) {
    final hasDimensions =
        item.length != null && item.width != null && item.height != null;
    return Container(
      key: Key('cargo-item-$scope-$index'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} × ${item.quantity}',
                      style: const TextStyle(
                        color: DiscoveryColors.neutral900,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildSmallTag(_kindLabel(item.kind)),
                        _buildSmallTag(categoryName),
                        _buildSmallTag(_serviceLabel(item.service)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!locked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('cargo-edit-item-$scope-$index'),
                      onPressed: () => _openEditItem(index, item, options),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: DiscoveryColors.primary,
                      ),
                      tooltip: 'Sửa kiện hàng',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      key: Key('cargo-delete-item-$scope-$index'),
                      onPressed: () => _removeItem(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: DiscoveryColors.error,
                      ),
                      tooltip: 'Xóa kiện hàng',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.isVehicle
                ? 'Khối lượng quy định: ${_formatNumber(item.payloadWeight)} kg/xe'
                : hasDimensions
                ? 'Khối lượng: ${_formatNumber(item.weight)} kg • Kích thước: ${_formatNumber(item.length!)}×${_formatNumber(item.width!)}×${_formatNumber(item.height!)} cm (Quy đổi: ${_formatNumber(item.effectiveWeight)} kg)'
                : 'Khối lượng: ${_formatNumber(item.weight)} kg',
            style: const TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
            ),
          ),
          if (item.isVehicle &&
              (item.vehicleModel.isNotEmpty ||
                  item.licensePlate.isNotEmpty)) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (item.vehicleModel.isNotEmpty)
                  'Dòng xe: ${item.vehicleModel}',
                if (item.licensePlate.isNotEmpty)
                  'Biển số: ${item.licensePlate}',
              ].join(' • '),
              style: const TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
              ),
            ),
          ],
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Ghi chú: ${item.note}',
              style: const TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: DiscoveryColors.neutral600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItemEditor(String scope, CargoOptions options) {
    final targetGroup = _computeTargetGroup();
    final matchingCategories = _matchingCategories(options);
    final selectedCatId = _resolvedCategoryId(options);
    final isVehicle =
        _kind == CargoKind.motorcycle || _kind == CargoKind.bicycle;

    return Container(
      key: Key('cargo-item-editor-$scope'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingIndex != null
                ? 'Chỉnh sửa kiện hàng #${_editingIndex! + 1}'
                : 'Thêm kiện hàng mới',
            style: const TextStyle(
              color: DiscoveryColors.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Phân loại kiện hàng',
            style: TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CargoKind.values.map((kind) {
              final selected = _kind == kind;
              return ChoiceChip(
                key: Key('cargo-kind-${kind.name}-$scope'),
                label: Text(_kindLabel(kind)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _kind = kind;
                    if (kind == CargoKind.motorcycle) {
                      _weightCtrl.text = '100';
                      _lengthCtrl.clear();
                      _widthCtrl.clear();
                      _heightCtrl.clear();
                    } else if (kind == CargoKind.bicycle) {
                      _weightCtrl.text = '15';
                      _lengthCtrl.clear();
                      _widthCtrl.clear();
                      _heightCtrl.clear();
                    } else if (_weightCtrl.text == '100' ||
                        _weightCtrl.text == '15') {
                      _weightCtrl.text = '5';
                    }
                    _selectedCategoryId = _resolvedCategoryId(options);
                    _editorError = null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (matchingCategories.isEmpty)
            _buildBanner(
              icon: Icons.warning_amber_rounded,
              color: DiscoveryColors.warningDark,
              text:
                  'Không có danh mục hàng cho nhóm ${_groupLabel(targetGroup)} trên chuyến này.',
            )
          else
            DropdownButtonFormField<int>(
              key: Key('cargo-category-dropdown-$scope'),
              initialValue: selectedCatId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Danh mục hàng (${_groupLabel(targetGroup)})',
                filled: true,
                fillColor: DiscoveryColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              dropdownColor: DiscoveryColors.surface,
              items: matchingCategories
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                  _editorError = null;
                });
              },
            ),
          const SizedBox(height: 10),
          TextField(
            key: Key('cargo-item-name-$scope'),
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Tên kiện hàng *',
              hintText: isVehicle
                  ? 'VD: Xe máy Honda Vision / Xe đạp thể thao'
                  : 'VD: Thùng quà, tài liệu, vali...',
              filled: true,
              fillColor: DiscoveryColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (_) {
              if (_editorError != null) {
                setState(() => _editorError = null);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('cargo-item-quantity-$scope'),
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số lượng *',
                    filled: true,
                    fillColor: DiscoveryColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setState(() => _editorError = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: Key('cargo-item-weight-$scope'),
                  controller: _weightCtrl,
                  enabled: !isVehicle,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isVehicle
                        ? 'Khối lượng cố định (kg)'
                        : 'Khối lượng (kg, ≤40) *',
                    filled: true,
                    fillColor: DiscoveryColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {
                      _selectedCategoryId = _resolvedCategoryId(options);
                      _editorError = null;
                    });
                  },
                ),
              ),
            ],
          ),
          if (!isVehicle) ...[
            const SizedBox(height: 10),
            const Text(
              'Kích thước tùy chọn (cm - tối đa 150 × 80 × 80 cm)',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('cargo-item-length-$scope'),
                    controller: _lengthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Dài (≤150)',
                      filled: true,
                      fillColor: DiscoveryColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _selectedCategoryId = _resolvedCategoryId(options);
                        _editorError = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('cargo-item-width-$scope'),
                    controller: _widthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Rộng (≤80)',
                      filled: true,
                      fillColor: DiscoveryColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _selectedCategoryId = _resolvedCategoryId(options);
                        _editorError = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('cargo-item-height-$scope'),
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cao (≤80)',
                      filled: true,
                      fillColor: DiscoveryColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _selectedCategoryId = _resolvedCategoryId(options);
                        _editorError = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_validateDimensionInputs() != null) ...[
              const SizedBox(height: 4),
              Text(
                _validateDimensionInputs()!,
                key: Key('cargo-dimension-error-$scope'),
                style: const TextStyle(
                  color: DiscoveryColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (isVehicle) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('cargo-item-vehicle-model-$scope'),
                    controller: _vehicleModelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dòng xe / Loại xe',
                      filled: true,
                      fillColor: DiscoveryColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: Key('cargo-item-license-plate-$scope'),
                    controller: _licensePlateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Biển số xe',
                      filled: true,
                      fillColor: DiscoveryColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Dịch vụ bảo quản',
            style: TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CargoService.values.map((srv) {
              return ChoiceChip(
                key: Key('cargo-service-${srv.name}-$scope'),
                label: Text(_serviceLabel(srv)),
                selected: _service == srv,
                onSelected: (_) => setState(() => _service = srv),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            key: Key('cargo-item-note-$scope'),
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Ghi chú kiện hàng (tùy chọn)',
              filled: true,
              fillColor: DiscoveryColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_editorError != null) ...[
            const SizedBox(height: 10),
            _buildBanner(
              key: Key('cargo-editor-error-$scope'),
              icon: Icons.error_outline_rounded,
              color: DiscoveryColors.error,
              text: _editorError!,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                key: Key('cargo-cancel-item-btn-$scope'),
                onPressed: _cancelEditor,
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                key: Key('cargo-save-item-btn-$scope'),
                onPressed: () => _saveItem(options),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _editingIndex != null
                      ? 'Cập nhật kiện hàng'
                      : 'Lưu kiện hàng',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    Key? key,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DiscoveryColors.neutral900,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable summary box for displaying either pre-order cargo draft info
/// or post-order verified server cargo info (`BookingModel.shippingFee`,
/// `BookingModel.shipment?.code`, `BookingModel.cargoItems`).
class BookingCargoSummaryBox extends StatelessWidget {
  final BookingFlowState? state;
  final BookingModel? booking;
  final String scopeKey;
  final String title;

  const BookingCargoSummaryBox({
    super.key,
    this.state,
    this.booking,
    this.scopeKey = 'oneway',
    this.title = 'Thông tin gửi hàng kèm vé',
  });

  static bool hasCargo({BookingFlowState? state, BookingModel? booking}) {
    final resolvedBooking = booking ?? state?.checkoutBooking;
    if (state?.cargo.enabled == true) return true;
    if (resolvedBooking == null) return false;
    return resolvedBooking.shipment != null ||
        resolvedBooking.cargoItems.isNotEmpty ||
        (resolvedBooking.shippingFee != null &&
            resolvedBooking.shippingFee! > 0);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBooking = booking ?? state?.checkoutBooking;
    final cargoState = state?.cargo;

    if (!hasCargo(state: state, booking: booking)) {
      return const SizedBox.shrink();
    }

    final shipmentCode = resolvedBooking?.shipment?.code.trim() ?? '';
    final shippingFee =
        resolvedBooking?.shippingFee ?? resolvedBooking?.shipment?.shippingFee;
    final confirmedItems = resolvedBooking?.cargoItems ?? const [];
    final draftItems = cargoState?.draft?.items ?? const [];

    String? senderName;
    String? receiverName;
    final points = cargoState?.options?.points;
    if (points != null && cargoState?.draft != null) {
      senderName = points.senders
          .where((p) => p.id == cargoState!.draft!.senderPointId)
          .map((p) => p.name)
          .firstOrNull;
      receiverName = points.receivers
          .where((p) => p.id == cargoState!.draft!.receiverPointId)
          .map((p) => p.name)
          .firstOrNull;
    }

    return Container(
      key: Key('cargo-summary-box-$scopeKey'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: DiscoveryColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: DiscoveryColors.neutral900,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shipmentCode.isNotEmpty) ...[
            _buildRow(
              'Mã vận đơn gửi hàng',
              shipmentCode,
              valueColor: DiscoveryColors.secondary,
              bold: true,
            ),
            const SizedBox(height: 4),
          ],
          _buildRow(
            'Phí gửi hàng',
            shippingFee != null
                ? CurrencyFormatter.format(shippingFee)
                : 'Phí gửi hàng được xác định khi tạo đơn',
            valueColor: shippingFee != null
                ? DiscoveryColors.neutral900
                : DiscoveryColors.warningDark,
            bold: shippingFee != null,
          ),
          if (senderName != null && receiverName != null) ...[
            const SizedBox(height: 4),
            _buildRow('Tuyến gửi hàng', '$senderName → $receiverName'),
          ],
          if (confirmedItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Kiện hàng đã xác nhận:',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...confirmedItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${item.name} × ${item.quantity}',
                  style: const TextStyle(
                    color: DiscoveryColors.neutral900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else if (draftItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Kiện hàng đăng ký gửi:',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...draftItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${item.name} × ${item.quantity}',
                  style: const TextStyle(
                    color: DiscoveryColors.neutral900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color valueColor = DiscoveryColors.neutral900,
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
