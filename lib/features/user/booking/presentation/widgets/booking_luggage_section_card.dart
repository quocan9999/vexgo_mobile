import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/luggage_policy.dart';
import 'package:vexgo_app/data/repositories/luggage_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';

/// Card khai báo "Hành lý đi kèm" trong luồng đặt vé (Step 4 & Step 5, một chiều & khứ hồi).
///
/// Phân tách rõ:
/// 1. Hành lý xách tay miễn phí ([CarryOnBag]): lưu tại client, đối chiếu theo
///    `policy.freeWeightPerPassengerKg` và tối đa 1 kiện/hành khách.
/// 2. Hành lý ký gửi ([CheckedLuggageItem]): chọn gói `S / M / L / XL` hoặc
///    phương tiện đặc biệt (`Xe đạp` / `Xe máy`), chọn điểm gửi/nhận từ
///    `options.cargo.points`, hiển thị rõ `referenceFee` là **phí tham khảo**
///    và đồng bộ sang `BookingFlowBloc` khi hợp lệ.
class BookingLuggageSectionCard extends StatefulWidget {
  final LuggageCubit cubit;

  /// Internal full-page declaration content; booking screens use the summary.
  final bool editorMode;
  final bool locked;
  final String scopeKey;
  final String title;
  final String? legBadge;
  final String? seatChangeNotice;
  final VoidCallback? onDismissSeatChangeNotice;
  final Future<void> Function(BookingCargoDraft? draft)? onSyncBookingCargo;

  const BookingLuggageSectionCard({
    super.key,
    required this.cubit,
    this.editorMode = false,
    required this.locked,
    this.scopeKey = 'oneway',
    this.title = 'Hành lý đi kèm',
    this.legBadge,
    this.seatChangeNotice,
    this.onDismissSeatChangeNotice,
    this.onSyncBookingCargo,
  });

  @override
  State<BookingLuggageSectionCard> createState() =>
      _BookingLuggageSectionCardState();
}

class _BookingLuggageSectionCardState extends State<BookingLuggageSectionCard> {
  final ValueNotifier<int> _managerRevision = ValueNotifier(0);
  bool _managerOpen = false;
  GlobalKey<_BookingLuggageSectionCardState> _editorKey = GlobalKey();

  @override
  void didUpdateWidget(covariant BookingLuggageSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cubit, widget.cubit)) {
      _editorKey = GlobalKey();
    }
    if (_managerOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _managerRevision.value++;
      });
    }
  }

  bool get _hasUnsavedInput => _isEditingCarryOn || _isEditingChecked;

  Future<void> _openManager() async {
    if (_managerOpen || widget.cubit.isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _managerOpen = true;
    if (widget.cubit.state.phase == LuggagePhase.idle) {
      unawaited(widget.cubit.load());
    }
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => ValueListenableBuilder<int>(
            valueListenable: _managerRevision,
            builder: (_, revision, _) {
              if (!mounted) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Hành lý đi kèm')),
                  body: const Center(child: Text('Phiên đặt vé đã kết thúc.')),
                );
              }
              final current = widget;
              return BlocBuilder<LuggageCubit, LuggageState>(
                bloc: current.cubit,
                builder: (_, state) => PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;
                    final unsaved =
                        _editorKey.currentState?._hasUnsavedInput ?? false;
                    if (unsaved) {
                      final discard = await showDialog<bool>(
                        context: routeContext,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Bỏ phần đang nhập?'),
                          content: const Text(
                            'Mục chưa lưu sẽ bị bỏ. Các kiện đã lưu vẫn được giữ nguyên.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Nhập tiếp'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Bỏ phần đang nhập'),
                            ),
                          ],
                        ),
                      );
                      if (discard != true) return;
                    }
                    if (routeContext.mounted) Navigator.of(routeContext).pop();
                  },
                  child: Scaffold(
                    key: Key('luggage-manager-${current.scopeKey}'),
                    appBar: AppBar(
                      backgroundColor: DiscoveryColors.header,
                      foregroundColor: Colors.white,
                      title: Text(
                        current.legBadge == null
                            ? 'Hành lý đi kèm'
                            : 'Hành lý · ${current.legBadge}',
                      ),
                      actions: [
                        _infoButton(
                          'Cước phí dự tính',
                          'Cước được dự tính theo gói của nhà xe và có thể thay đổi sau khi kiểm tra vật phẩm. Thanh toán tại bến khi giao vật phẩm, không cộng vào tiền vé thanh toán trực tuyến.',
                          'luggage-manager-info-${current.scopeKey}',
                        ),
                      ],
                    ),
                    body: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: BookingLuggageSectionCard(
                          key: _editorKey,
                          editorMode: true,
                          cubit: current.cubit,
                          locked: current.locked,
                          scopeKey: current.scopeKey,
                          legBadge: current.legBadge,
                          onSyncBookingCargo: current.onSyncBookingCargo,
                        ),
                      ),
                    ),
                    bottomNavigationBar: SafeArea(
                      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: FilledButton(
                        key: Key('luggage-manager-done-${current.scopeKey}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: DiscoveryColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (current.locked) {
                            Navigator.of(routeContext).pop();
                            return;
                          }
                          final editor = _editorKey.currentState;
                          if (editor?._hasUnsavedInput ?? false) {
                            ScaffoldMessenger.of(routeContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lưu hoặc hủy mục đang nhập trước khi hoàn tất.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!current.locked &&
                              current.cubit.validationError != null &&
                              state.phase != LuggagePhase.idle) {
                            ScaffoldMessenger.of(routeContext).showSnackBar(
                              SnackBar(
                                content: Text(current.cubit.validationError!),
                              ),
                            );
                            return;
                          }
                          Navigator.of(routeContext).pop();
                        },
                        child: Text(current.locked ? 'Đóng' : 'Xong'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } finally {
      _managerOpen = false;
      if (!mounted) _managerRevision.dispose();
    }
  }

  Widget _infoButton(
    String title,
    String description,
    String key,
  ) => IconButton(
    key: Key(key),
    tooltip: title,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    icon: const Icon(Icons.info_outline_rounded, size: 20),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(description),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Đã hiểu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _descriptionInfo(String title, String description, String key) => Row(
    children: [
      Expanded(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      _infoButton(title, description, key),
    ],
  );

  Widget _buildSummary(LuggageState state) {
    final scope = widget.scopeKey;
    final selection = state.selection;
    final canShowSelection = state.phase != LuggagePhase.revoked;
    final hasItems =
        canShowSelection &&
        (selection.checked.isNotEmpty || selection.carryOn.isNotEmpty);
    final fee = widget.cubit.referenceFee;
    return Container(
      key: Key('luggage-section-card-$scope'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.luggage_outlined,
                color: DiscoveryColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.legBadge == null
                      ? widget.title
                      : '${widget.title} · ${widget.legBadge}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _infoButton(
                'Thông tin hành lý',
                'Hành lý xách tay được miễn phí trong hạn mức nhà xe. Thêm kiện ký gửi hoặc phương tiện để xem cước dự tính. Các lựa chọn được quản lý riêng theo từng chặng.',
                'luggage-info-$scope',
              ),
            ],
          ),
          if (state.phase != LuggagePhase.revoked)
            _descriptionInfo(
              state.options == null
                  ? 'Hạn mức xách tay theo nhà xe'
                  : 'Xách tay miễn phí ≤ ${_formatNumber(state.options!.policy.freeWeightPerPassengerKg)} kg/khách',
              'Mỗi hành khách được mang một kiện xách tay trong hạn mức. Kiện vượt hạn mức cần kiểm tra điều kiện ký gửi. Hạn mức áp dụng theo chuyến đang chọn.',
              'luggage-allowance-info-$scope',
            ),
          if (hasItems) ...[
            for (final bag in selection.carryOn)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Xách tay · ${bag.quantity} kiện · ${_formatNumber(bag.weightKg)} kg/kiện',
                ),
              ),
            for (final item in selection.checked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item.cargo.name} × ${item.cargo.quantity} · '
                  '${item.packageCode == null ? 'Phương tiện' : 'Gói ${item.packageCode}'} · '
                  '${_formatNumber(item.cargo.payloadWeight)} kg/kiện',
                ),
              ),
            if (selection.checked.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  const Text(
                    'Cước phí dự tính',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    fee == null
                        ? 'Cần kiểm tra lại'
                        : CurrencyFormatter.format(fee),
                    style: const TextStyle(
                      color: DiscoveryColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (widget.seatChangeNotice != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.seatChangeNotice!,
                key: Key('luggage-seat-change-notice-$scope'),
              ),
            ),
          if (state.phase == LuggagePhase.revoked)
            const Text('Phiên đã thay đổi. Vui lòng mở lại đặt vé.')
          else if (!widget.locked) ...[
            if (state.phase != LuggagePhase.idle &&
                widget.cubit.validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.cubit.validationError!,
                  style: const TextStyle(color: DiscoveryColors.error),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('luggage-open-btn-$scope'),
                onPressed: _openManager,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: Icon(hasItems ? Icons.edit_outlined : Icons.add),
                label: Text(hasItems ? 'Sửa hành lý' : 'Thêm hành lý ký gửi'),
              ),
            ),
          ] else
            TextButton(
              onPressed: _openManager,
              child: const Text('Xem hành lý'),
            ),
        ],
      ),
    );
  }

  // --- Carry-on editor state ---
  bool _isEditingCarryOn = false;
  int? _editingCarryOnIndex;
  final TextEditingController _carryOnWeightCtrl = TextEditingController(
    text: '5',
  );
  final TextEditingController _carryOnQtyCtrl = TextEditingController(
    text: '1',
  );
  String? _carryOnEditorError;

  // --- Checked luggage editor state ---
  bool _isEditingChecked = false;
  int? _editingCheckedIndex;
  CarryOnBag? _convertingCarryOn;
  bool _editorIsVehicle = false;
  String _selectedPackageCode = 'S';
  CargoKind _vehicleKind = CargoKind.bicycle;
  LuggageMotorcycleTariff _motorcycleTariff = LuggageMotorcycleTariff.wave;
  int? _selectedCategoryId;
  CargoService _service = CargoService.normal;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _weightCtrl = TextEditingController(text: '5');
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _vehicleModelCtrl = TextEditingController();
  final TextEditingController _licensePlateCtrl = TextEditingController();
  String? _checkedEditorError;

  @override
  void dispose() {
    if (_managerOpen) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _managerRevision.value++,
      );
    } else {
      _managerRevision.dispose();
    }
    _carryOnWeightCtrl.dispose();
    _carryOnQtyCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _noteCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _licensePlateCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  double? _parseDecimal(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _syncIfReady() {
    final callback = widget.onSyncBookingCargo;
    if (callback == null) return;
    final cubit = widget.cubit;
    if (cubit.state.phase == LuggagePhase.idle) {
      unawaited(callback(null));
      return;
    }
    if (cubit.state.phase == LuggagePhase.ready &&
        cubit.policyIsFresh &&
        cubit.validationError == null) {
      try {
        final draft = cubit.exportForBooking(
          expectedTripId: cubit.tripId,
          expectedPassengerCount: cubit.passengerCount,
        );
        unawaited(callback(draft));
      } catch (_) {
        // Keep current state when export fails validation guards.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Carry-on actions
  // ---------------------------------------------------------------------------
  void _openAddCarryOn(LuggagePolicy policy) {
    final defaultWeight = math.min(5.0, policy.freeWeightPerPassengerKg);
    setState(() {
      _isEditingCarryOn = true;
      _editingCarryOnIndex = null;
      _carryOnWeightCtrl.text = _formatNumber(
        defaultWeight > 0 ? defaultWeight : 1,
      );
      _carryOnQtyCtrl.text = '1';
      _carryOnEditorError = null;
    });
  }

  void _openEditCarryOn(int index, CarryOnBag bag) {
    setState(() {
      _isEditingCarryOn = true;
      _editingCarryOnIndex = index;
      _carryOnWeightCtrl.text = _formatNumber(bag.weightKg);
      _carryOnQtyCtrl.text = bag.quantity.toString();
      _carryOnEditorError = null;
    });
  }

  void _cancelCarryOnEditor() {
    setState(() {
      _isEditingCarryOn = false;
      _editingCarryOnIndex = null;
      _carryOnEditorError = null;
    });
  }

  String? _computeCarryOnDraftError(LuggagePolicy policy) {
    final weight = _parseDecimal(_carryOnWeightCtrl.text);
    final qty = int.tryParse(_carryOnQtyCtrl.text.trim());
    if (weight == null || !weight.isFinite || weight <= 0) {
      return 'Nhập khối lượng xách tay hợp lệ (> 0 kg).';
    }
    if (qty == null || qty < 1) {
      return 'Số kiện xách tay phải từ 1 trở lên.';
    }
    if (weight > policy.freeWeightPerPassengerKg) {
      return 'Hành lý xách tay vượt hạn mức miễn phí (${_formatNumber(policy.freeWeightPerPassengerKg)} kg/kiện); hãy chuyển sang hành lý ký gửi.';
    }
    final existing = widget.cubit.state.selection.carryOn;
    var otherBags = 0;
    for (var i = 0; i < existing.length; i++) {
      if (i != _editingCarryOnIndex) {
        otherBags += existing[i].quantity;
      }
    }
    if (otherBags + qty > widget.cubit.passengerCount) {
      return 'Mỗi hành khách được khai báo tối đa một kiện xách tay miễn phí (tối đa ${widget.cubit.passengerCount} kiện). Hãy chuyển kiện vượt sang hành lý ký gửi.';
    }
    return null;
  }

  void _saveCarryOn(LuggagePolicy policy) {
    // Validate against the saved selection before adding the draft to it.
    final draftError = _computeCarryOnDraftError(policy);
    if (draftError != null) {
      setState(() => _carryOnEditorError = draftError);
      return;
    }
    final weight = _parseDecimal(_carryOnWeightCtrl.text)!;
    final qty = int.parse(_carryOnQtyCtrl.text.trim());

    final current = List<CarryOnBag>.from(widget.cubit.state.selection.carryOn);
    if (_editingCarryOnIndex != null &&
        _editingCarryOnIndex! >= 0 &&
        _editingCarryOnIndex! < current.length) {
      current.removeAt(_editingCarryOnIndex!);
    }

    final bag = CarryOnBag(weightKg: weight, quantity: qty);
    // Keep the edited entry in place so subsequent edits target the same bag.
    if (_editingCarryOnIndex != null) {
      current.insert(_editingCarryOnIndex!.clamp(0, current.length), bag);
    } else {
      current.add(bag);
    }

    final currentSel = widget.cubit.state.selection;
    final nextSel = LuggageSelection(
      carryOn: current,
      checked: currentSel.checked,
      senderPointId: currentSel.senderPointId,
      receiverPointId: currentSel.receiverPointId,
    );
    widget.cubit.select(nextSel);

    setState(() {
      _isEditingCarryOn = false;
      _editingCarryOnIndex = null;
      _carryOnEditorError = null;
    });
    _syncIfReady();
  }

  void _removeCarryOn(int index) {
    final current = List<CarryOnBag>.from(widget.cubit.state.selection.carryOn);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    final sel = widget.cubit.state.selection;
    widget.cubit.select(
      LuggageSelection(
        carryOn: current,
        checked: sel.checked,
        senderPointId: sel.senderPointId,
        receiverPointId: sel.receiverPointId,
      ),
    );
    setState(() {
      if (_editingCarryOnIndex == index) {
        _isEditingCarryOn = false;
        _editingCarryOnIndex = null;
        _carryOnEditorError = null;
      }
    });
    _syncIfReady();
  }

  void _convertCarryOnToChecked({
    required LuggagePolicy policy,
    required CargoOptions cargoOptions,
    double? weightKg,
    int? removeCarryOnIndex,
  }) {
    final resolvedWeight =
        weightKg ?? _parseDecimal(_carryOnWeightCtrl.text) ?? 5.0;
    final sourceIndex = removeCarryOnIndex ?? _editingCarryOnIndex;
    final bags = widget.cubit.state.selection.carryOn;
    final source =
        sourceIndex != null && sourceIndex >= 0 && sourceIndex < bags.length
        ? bags[sourceIndex]
        : null;
    final quantity = removeCarryOnIndex != null
        ? source?.quantity ?? 1
        : int.tryParse(_carryOnQtyCtrl.text.trim()) ?? 1;
    final matchingPack =
        policy.packages
            .where((p) => p.maxWeightKg >= resolvedWeight)
            .firstOrNull ??
        policy.packages.last;
    setState(() {
      _isEditingCarryOn = false;
      _editingCarryOnIndex = null;
      _carryOnEditorError = null;
      _isEditingChecked = true;
      _editingCheckedIndex = null;
      _editorIsVehicle = false;
      _selectedPackageCode = matchingPack.code;
      _nameCtrl.text = 'Hành lý ký gửi';
      _convertingCarryOn = source;
      _qtyCtrl.text = quantity.toString();
      _weightCtrl.text = _formatNumber(resolvedWeight);
      _lengthCtrl.clear();
      _widthCtrl.clear();
      _heightCtrl.clear();
      _noteCtrl.clear();
      _service = CargoService.normal;
      _selectedCategoryId = _resolveCategoryId(cargoOptions);
      _checkedEditorError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Checked luggage & vehicle actions
  // ---------------------------------------------------------------------------
  CargoGroup _targetCargoGroup() {
    if (_editorIsVehicle) {
      return _vehicleKind == CargoKind.motorcycle
          ? CargoGroup.motorcycle
          : CargoGroup.bulky;
    }
    final weight = _parseDecimal(_weightCtrl.text) ?? 0;
    final l = _parseDecimal(_lengthCtrl.text);
    final w = _parseDecimal(_widthCtrl.text);
    final h = _parseDecimal(_heightCtrl.text);
    final draft = CargoItemDraft(
      name: 'probe',
      kind: CargoKind.parcel,
      categoryId: 1,
      weight: weight > 0 ? weight : 1,
      length: (l != null && l > 0) ? l : null,
      width: (w != null && w > 0) ? w : null,
      height: (h != null && h > 0) ? h : null,
    );
    return draft.effectiveWeight >= 20 ? CargoGroup.bulky : CargoGroup.parcel;
  }

  int? _resolveCategoryId(CargoOptions options) {
    final group = _targetCargoGroup();
    final matching = options.categories.where((c) => c.group == group).toList();
    if (matching.isEmpty) return options.categories.firstOrNull?.id;
    if (_selectedCategoryId != null &&
        matching.any((c) => c.id == _selectedCategoryId)) {
      return _selectedCategoryId;
    }
    return matching.first.id;
  }

  void _openAddPackageItem(LuggagePolicy policy, CargoOptions options) {
    final firstPack = policy.packages.first;
    setState(() {
      _convertingCarryOn = null;
      _isEditingChecked = true;
      _editingCheckedIndex = null;
      _editorIsVehicle = false;
      _selectedPackageCode = firstPack.code;
      _nameCtrl.clear();
      _qtyCtrl.text = '1';
      _weightCtrl.text = _formatNumber(math.min(5, firstPack.maxWeightKg));
      _lengthCtrl.clear();
      _widthCtrl.clear();
      _heightCtrl.clear();
      _noteCtrl.clear();
      _service = CargoService.normal;
      _selectedCategoryId = null;
      _selectedCategoryId = _resolveCategoryId(options);
      _checkedEditorError = null;
    });
  }

  void _openAddVehicleItem(CargoOptions options) {
    setState(() {
      _convertingCarryOn = null;
      _isEditingChecked = true;
      _editingCheckedIndex = null;
      _editorIsVehicle = true;
      _vehicleKind = CargoKind.bicycle;
      _motorcycleTariff = LuggageMotorcycleTariff.wave;
      _nameCtrl.text = 'Xe đạp đi kèm';
      _qtyCtrl.text = '1';
      _weightCtrl.text = '15';
      _lengthCtrl.clear();
      _widthCtrl.clear();
      _heightCtrl.clear();
      _vehicleModelCtrl.clear();
      _licensePlateCtrl.clear();
      _noteCtrl.clear();
      _service = CargoService.normal;
      _selectedCategoryId = null;
      _selectedCategoryId = _resolveCategoryId(options);
      _checkedEditorError = null;
    });
  }

  void _openEditCheckedItem(
    int index,
    CheckedLuggageItem item,
    CargoOptions options,
  ) {
    final cargo = item.cargo;
    setState(() {
      _convertingCarryOn = null;
      _isEditingChecked = true;
      _editingCheckedIndex = index;
      _editorIsVehicle = cargo.isVehicle;
      if (cargo.isVehicle) {
        _vehicleKind = cargo.kind;
        _motorcycleTariff = item.motorcycleTariff;
      } else {
        _selectedPackageCode = item.packageCode ?? 'S';
      }
      _nameCtrl.text = cargo.name;
      _qtyCtrl.text = cargo.quantity.toString();
      _weightCtrl.text = _formatNumber(cargo.payloadWeight);
      _lengthCtrl.text = cargo.length != null
          ? _formatNumber(cargo.length!)
          : '';
      _widthCtrl.text = cargo.width != null ? _formatNumber(cargo.width!) : '';
      _heightCtrl.text = cargo.height != null
          ? _formatNumber(cargo.height!)
          : '';
      _vehicleModelCtrl.text = cargo.vehicleModel;
      _licensePlateCtrl.text = cargo.licensePlate;
      _noteCtrl.text = cargo.note;
      _service = cargo.service;
      _selectedCategoryId = cargo.categoryId;
      _selectedCategoryId = _resolveCategoryId(options);
      _checkedEditorError = null;
    });
  }

  void _cancelCheckedEditor() {
    setState(() {
      _convertingCarryOn = null;
      _isEditingChecked = false;
      _editingCheckedIndex = null;
      _checkedEditorError = null;
    });
  }

  String? _validateDimensionTexts() {
    if (_editorIsVehicle) return null;
    final raw = [
      _lengthCtrl.text.trim(),
      _widthCtrl.text.trim(),
      _heightCtrl.text.trim(),
    ];
    if (raw.every((s) => s.isEmpty)) return null;
    if (raw.any((s) => s.isEmpty)) {
      return 'Nhập đủ cả 3 chiều Dài, Rộng, Cao (hoặc để trống cả 3).';
    }
    final parsed = raw.map(_parseDecimal).toList();
    if (parsed.any((v) => v == null || !v.isFinite || v <= 0)) {
      return 'Kích thước Dài, Rộng, Cao phải là số hợp lệ lớn hơn 0.';
    }
    return null;
  }

  CheckedLuggageItem? _buildCandidateCheckedItem(CargoOptions options) {
    final dimError = _validateDimensionTexts();
    if (dimError != null) return null;
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 1) return null;

    final categoryId = _resolveCategoryId(options) ?? 0;
    if (_editorIsVehicle) {
      final draft = CargoItemDraft(
        name: _nameCtrl.text.trim(),
        kind: _vehicleKind,
        categoryId: categoryId,
        quantity: qty,
        weight: _vehicleKind == CargoKind.motorcycle ? 100 : 15,
        service: _service,
        note: _noteCtrl.text.trim(),
        vehicleModel: _vehicleModelCtrl.text.trim(),
        licensePlate: _licensePlateCtrl.text.trim(),
      );
      return CheckedLuggageItem(
        cargo: draft,
        packageCode: null,
        motorcycleTariff: _motorcycleTariff,
      );
    }

    final weight = _parseDecimal(_weightCtrl.text);
    if (weight == null || !weight.isFinite || weight <= 0) return null;
    final l = _parseDecimal(_lengthCtrl.text);
    final w = _parseDecimal(_widthCtrl.text);
    final h = _parseDecimal(_heightCtrl.text);

    // Category returned by the API determines normal luggage capacity;
    // heavy suitcases must not become explicit bulky goods solely by weight.
    const resolvedKind = CargoKind.parcel;
    const group = CargoGroup.parcel;
    final matchedCatId =
        options.categories.where((c) => c.group == group).firstOrNull?.id ??
        categoryId;

    return CheckedLuggageItem(
      cargo: CargoItemDraft(
        name: _nameCtrl.text.trim(),
        kind: resolvedKind,
        categoryId: matchedCatId,
        quantity: qty,
        weight: weight,
        length: l,
        width: w,
        height: h,
        service: _service,
        note: _noteCtrl.text.trim(),
      ),
      packageCode: _selectedPackageCode,
    );
  }

  String? _computeLiveCheckedEditorError(
    LuggagePolicy policy,
    CargoOptions options,
  ) {
    final dimError = _validateDimensionTexts();
    if (dimError != null) return dimError;
    if (!_editorIsVehicle) {
      final weight = _parseDecimal(_weightCtrl.text);
      if (_weightCtrl.text.trim().isNotEmpty &&
          (weight == null || !weight.isFinite || weight <= 0)) {
        return 'Khối lượng hàng phải là số hợp lệ lớn hơn 0.';
      }
      if (weight != null && weight > 0) {
        final l = _parseDecimal(_lengthCtrl.text);
        final w = _parseDecimal(_widthCtrl.text);
        final h = _parseDecimal(_heightCtrl.text);
        final probe = CheckedLuggageItem(
          cargo: CargoItemDraft(
            name: _nameCtrl.text.trim().isEmpty
                ? 'Kiện hành lý'
                : _nameCtrl.text.trim(),
            kind: CargoKind.parcel,
            categoryId: _resolveCategoryId(options) ?? 1,
            quantity: int.tryParse(_qtyCtrl.text.trim()) ?? 1,
            weight: weight,
            length: l,
            width: w,
            height: h,
            service: _service,
          ),
          packageCode: _selectedPackageCode,
        );
        final packError = probe.validate(policy);
        if (packError != null) return packError;
      }
    }
    return null;
  }

  void _saveCheckedItem(LuggagePolicy policy, CargoOptions options) {
    final dimError = _validateDimensionTexts();
    if (dimError != null) {
      setState(() => _checkedEditorError = dimError);
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _checkedEditorError = 'Vui lòng nhập tên kiện hành lý.');
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 1) {
      setState(() => _checkedEditorError = 'Số lượng phải là số nguyên ≥ 1.');
      return;
    }
    final candidate = _buildCandidateCheckedItem(options);
    if (candidate == null) {
      setState(
        () => _checkedEditorError =
            'Vui lòng kiểm tra lại khối lượng và kích thước kiện hành lý.',
      );
      return;
    }
    final itemError = candidate.validate(policy);
    if (itemError != null) {
      setState(() => _checkedEditorError = itemError);
      return;
    }

    final current = List<CheckedLuggageItem>.from(
      widget.cubit.state.selection.checked,
    );
    if (_editingCheckedIndex != null &&
        _editingCheckedIndex! >= 0 &&
        _editingCheckedIndex! < current.length) {
      current[_editingCheckedIndex!] = candidate;
    } else {
      current.add(candidate);
    }

    final sel = widget.cubit.state.selection;
    final carryOn = List<CarryOnBag>.from(sel.carryOn);
    final source = _convertingCarryOn;
    if (source != null && !carryOn.remove(source)) {
      setState(
        () => _checkedEditorError =
            'Kiện xách tay đã thay đổi. Vui lòng mở lại thao tác chuyển ký gửi.',
      );
      return;
    }
    widget.cubit.select(
      LuggageSelection(
        carryOn: carryOn,
        checked: current,
        senderPointId: sel.senderPointId,
        receiverPointId: sel.receiverPointId,
      ),
    );
    setState(() {
      _convertingCarryOn = null;
      _isEditingChecked = false;
      _editingCheckedIndex = null;
      _checkedEditorError = null;
    });
    _syncIfReady();
  }

  void _removeCheckedItem(int index) {
    final current = List<CheckedLuggageItem>.from(
      widget.cubit.state.selection.checked,
    );
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    final sel = widget.cubit.state.selection;
    widget.cubit.select(
      LuggageSelection(
        carryOn: sel.carryOn,
        checked: current,
        senderPointId: sel.senderPointId,
        receiverPointId: sel.receiverPointId,
      ),
    );
    setState(() {
      if (_editingCheckedIndex == index) {
        _isEditingChecked = false;
        _editingCheckedIndex = null;
        _checkedEditorError = null;
      }
    });
    _syncIfReady();
  }

  void _selectSenderPoint(int? id) {
    final sel = widget.cubit.state.selection;
    widget.cubit.select(
      LuggageSelection(
        carryOn: sel.carryOn,
        checked: sel.checked,
        senderPointId: id,
        receiverPointId: sel.receiverPointId,
      ),
    );
    _syncIfReady();
  }

  void _selectReceiverPoint(int? id) {
    final sel = widget.cubit.state.selection;
    widget.cubit.select(
      LuggageSelection(
        carryOn: sel.carryOn,
        checked: sel.checked,
        senderPointId: sel.senderPointId,
        receiverPointId: id,
      ),
    );
    _syncIfReady();
  }

  void _handleSkip() {
    setState(() {
      _convertingCarryOn = null;
      _isEditingCarryOn = false;
      _editingCarryOnIndex = null;
      _carryOnEditorError = null;
      _isEditingChecked = false;
      _editingCheckedIndex = null;
      _checkedEditorError = null;
    });
    widget.cubit.skip();
    _syncIfReady();
  }

  // ---------------------------------------------------------------------------
  // Build UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scope = widget.scopeKey;
    final locked = widget.locked;

    return BlocBuilder<LuggageCubit, LuggageState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (!widget.editorMode) return _buildSummary(state);
        return Container(
          key: Key('luggage-section-card-$scope'),
          padding: widget.editorMode
              ? EdgeInsets.zero
              : const EdgeInsets.all(16),
          decoration: widget.editorMode
              ? null
              : BoxDecoration(
                  color: DiscoveryColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: state.phase != LuggagePhase.idle
                        ? DiscoveryColors.primary.withValues(alpha: 0.45)
                        : DiscoveryColors.neutral200,
                    width: state.phase != LuggagePhase.idle ? 1.4 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.editorMode) _buildHeader(scope, state, locked),
              if (widget.seatChangeNotice != null &&
                  widget.seatChangeNotice!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildBanner(
                  key: Key('luggage-seat-change-notice-$scope'),
                  icon: Icons.people_outline_rounded,
                  color: DiscoveryColors.warningDark,
                  text: widget.seatChangeNotice!,
                  trailing: widget.onDismissSeatChangeNotice != null
                      ? IconButton(
                          key: Key('luggage-dismiss-seat-notice-$scope'),
                          onPressed: widget.onDismissSeatChangeNotice,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          tooltip: 'Đóng thông báo',
                        )
                      : null,
                ),
              ],
              if (locked && state.phase != LuggagePhase.idle) ...[
                const SizedBox(height: 12),
                _buildBanner(
                  key: Key('luggage-locked-banner-$scope'),
                  icon: Icons.lock_outline_rounded,
                  color: DiscoveryColors.info,
                  text:
                      'Đơn hàng đã tạo hoặc đang xử lý. Thông tin hành lý đi kèm đã được khóa để đảm bảo đồng bộ.',
                ),
              ],
              if (state.phase == LuggagePhase.revoked) ...[
                const SizedBox(height: 12),
                _buildBanner(
                  key: Key('luggage-revoked-banner-$scope'),
                  icon: Icons.lock_reset_rounded,
                  color: DiscoveryColors.error,
                  text:
                      'Phiên đăng nhập đã thay đổi. Vui lòng mở lại đặt vé để khai báo hành lý.',
                ),
              ] else if (state.phase == LuggagePhase.idle) ...[
                const SizedBox(height: 10),
                _buildIdleSection(scope, locked),
              ] else if (state.phase == LuggagePhase.loading) ...[
                const SizedBox(height: 12),
                _buildLoadingSection(scope, locked),
              ] else if (state.phase == LuggagePhase.failure) ...[
                const SizedBox(height: 12),
                _buildFailureSection(scope, state, locked),
              ] else if (state.phase == LuggagePhase.ready &&
                  state.options != null) ...[
                const SizedBox(height: 12),
                _buildReadySection(scope, state, state.options!, locked),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String scope, LuggageState state, bool locked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DiscoveryColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.luggage_rounded,
            color: DiscoveryColors.primary,
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
              Text('${widget.cubit.passengerCount} hành khách'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdleSection(String scope, bool locked) {
    return Container(
      key: Key('luggage-idle-$scope'),
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
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: DiscoveryColors.success,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đang chọn: Không thêm hành lý ký gửi (chỉ đặt vé hành khách).',
                  style: TextStyle(
                    color: DiscoveryColors.neutral800,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('luggage-open-btn-$scope'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: DiscoveryColors.primary,
                  side: const BorderSide(color: DiscoveryColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => widget.cubit.load(),
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text(
                  'Xem chính sách & Khai báo hành lý đi kèm',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String scope, bool locked) {
    return Container(
      key: Key('luggage-loading-$scope'),
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
                  'Đang tải chính sách hành lý của nhà xe và sức chứa trên chuyến...',
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
                key: Key('luggage-skip-btn-$scope'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _handleSkip,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Không thêm hành lý ký gửi'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFailureSection(String scope, LuggageState state, bool locked) {
    final hasExistingItems =
        state.selection.checked.isNotEmpty ||
        state.selection.carryOn.isNotEmpty;
    return Container(
      key: Key('luggage-error-$scope'),
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
                  state.error ?? 'Không tải được chính sách hành lý.',
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
          if (hasExistingItems) ...[
            const SizedBox(height: 8),
            Text(
              'Hành lý đã chọn (${state.selection.checked.length} mục ký gửi, ${state.selection.carryOn.length} mục xách tay) vẫn được giữ nguyên. Hãy thử tải lại chính sách hoặc chọn "Không thêm hành lý ký gửi" nếu chỉ muốn đặt vé.',
              key: Key('luggage-preserved-items-notice-$scope'),
              style: const TextStyle(
                color: DiscoveryColors.neutral700,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (!locked) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: Key('luggage-retry-btn-$scope'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => widget.cubit.load(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Thử lại'),
                ),
                TextButton.icon(
                  key: Key('luggage-skip-btn-$scope'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _handleSkip,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Không thêm hành lý ký gửi'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadySection(
    String scope,
    LuggageState state,
    LuggageOptions options,
    bool locked,
  ) {
    final policy = options.policy;
    final cargoOptions = options.cargo;
    final isFresh = widget.cubit.policyIsFresh;
    final validationError = widget.cubit.validationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stale policy warning (> 5 minutes)
        if (!isFresh) ...[
          Container(
            key: Key('luggage-stale-banner-$scope'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DiscoveryColors.warning.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: DiscoveryColors.warningDark,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chính sách hành lý đã quá hạn 5 phút. Vui lòng tải lại để tiếp tục.',
                        style: TextStyle(
                          color: DiscoveryColors.neutral900,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!locked) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: Key('luggage-reload-policy-btn-$scope'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => widget.cubit.load(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tải lại chính sách'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 1. Free Carry-On Section
        ExpansionTile(
          key: Key('luggage-carryon-disclosure-$scope'),
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Xách tay · miễn phí ≤ ${_formatNumber(policy.freeWeightPerPassengerKg)} kg/khách',
          ),
          children: [
            _buildCarryOnSection(scope, policy, cargoOptions, state, locked),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Checked Luggage & Special Vehicles Section
        _buildCheckedSection(scope, policy, cargoOptions, state, locked),

        // 3. Reference Fee & Server Pricing Notice
        if (state.selection.checked.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildReferenceFeeBox(scope, policy),
        ],

        // 4. Overall Validation Error
        if (validationError != null) ...[
          const SizedBox(height: 12),
          _buildBanner(
            key: Key('luggage-validation-error-$scope'),
            icon: Icons.warning_amber_rounded,
            color: DiscoveryColors.error,
            text: validationError,
          ),
        ],

        // 5. Explicit Skip ("Không thêm hành lý ký gửi")
        if (!locked) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('luggage-skip-btn-$scope'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: DiscoveryColors.neutral700,
              ),
              onPressed: _handleSkip,
              icon: const Icon(Icons.not_interested_rounded, size: 16),
              label: const Text('Không thêm hành lý ký gửi'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCarryOnSection(
    String scope,
    LuggagePolicy policy,
    CargoOptions cargoOptions,
    LuggageState state,
    bool locked,
  ) {
    final bags = state.selection.carryOn;
    final totalBags = bags.fold<int>(0, (sum, b) => sum + b.quantity);
    final maxPassengers = widget.cubit.passengerCount;
    final freeKg = policy.freeWeightPerPassengerKg;

    return Container(
      key: Key('luggage-carryon-section-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.backpack_outlined,
                    size: 18,
                    color: DiscoveryColors.primary,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      '1. Hành lý xách tay miễn phí',
                      style: TextStyle(
                        color: DiscoveryColors.neutral900,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                key: Key('luggage-free-allowance-badge-$scope'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DiscoveryColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Miễn phí ≤ ${_formatNumber(freeKg)} kg/kiện • Tối đa $maxPassengers kiện',
                  style: const TextStyle(
                    color: DiscoveryColors.successDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _descriptionInfo(
            'Quy định xách tay',
            'Mỗi hành khách được khai báo một kiện xách tay trong hạn mức. Kiện vượt hạn mức có thể chuyển sang ký gửi khi chuyến xe còn nhận.',
            'luggage-carryon-info-$scope',
          ),
          if (bags.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(bags.length, (i) {
              final bag = bags[i];
              final isOverweight = bag.weightKg > freeKg;
              return Container(
                key: Key('luggage-carryon-item-$scope-$i'),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DiscoveryColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOverweight
                        ? DiscoveryColors.error
                        : DiscoveryColors.neutral200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kiện xách tay #${i + 1}: ${_formatNumber(bag.weightKg)} kg × ${bag.quantity} kiện',
                            style: const TextStyle(
                              color: DiscoveryColors.neutral900,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!locked) ...[
                          IconButton(
                            key: Key('luggage-carryon-edit-$scope-$i'),
                            onPressed: () => _openEditCarryOn(i, bag),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: DiscoveryColors.primary,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Sửa kiện xách tay',
                          ),
                          IconButton(
                            key: Key('luggage-carryon-delete-$scope-$i'),
                            onPressed: () => _removeCarryOn(i),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: DiscoveryColors.error,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Xóa kiện xách tay',
                          ),
                        ],
                      ],
                    ),
                    if (isOverweight || totalBags > maxPassengers) ...[
                      const SizedBox(height: 4),
                      Text(
                        isOverweight
                            ? 'Vượt hạn mức miễn phí (${_formatNumber(freeKg)} kg/kiện). Hãy chuyển sang hành lý ký gửi.'
                            : 'Tổng số kiện xách tay ($totalBags) vượt quá số hành khách ($maxPassengers). Hãy chuyển sang hành lý ký gửi.',
                        style: const TextStyle(
                          color: DiscoveryColors.error,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!locked &&
                          cargoOptions.capacity.acceptsShipments) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          key: Key('luggage-carryon-move-checked-$scope-$i'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: DiscoveryColors.secondary,
                          ),
                          onPressed: () => _convertCarryOnToChecked(
                            policy: policy,
                            cargoOptions: cargoOptions,
                            weightKg: bag.weightKg,
                            removeCarryOnIndex: i,
                          ),
                          icon: const Icon(Icons.luggage_rounded, size: 16),
                          label: const Text('Chuyển sang hành lý ký gửi'),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            }),
          ],
          if (_isEditingCarryOn && !locked) ...[
            const SizedBox(height: 10),
            _buildCarryOnEditor(scope, policy, cargoOptions),
          ] else if (!locked) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: Key('luggage-carryon-add-btn-$scope'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => _openAddCarryOn(policy),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Khai báo kiện xách tay'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarryOnEditor(
    String scope,
    LuggagePolicy policy,
    CargoOptions cargoOptions,
  ) {
    final liveError = _carryOnEditorError ?? _computeCarryOnDraftError(policy);
    return Container(
      key: Key('luggage-carryon-editor-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingCarryOnIndex != null
                ? 'Chỉnh sửa kiện xách tay #${_editingCarryOnIndex! + 1}'
                : 'Khai báo kiện xách tay miễn phí',
            style: const TextStyle(
              color: DiscoveryColors.neutral900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 260;
              final weightField = TextField(
                key: Key('luggage-carryon-weight-input-$scope'),
                controller: _carryOnWeightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Khối lượng (kg, ≤${_formatNumber(policy.freeWeightPerPassengerKg)}) *',
                  filled: true,
                  fillColor: DiscoveryColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() => _carryOnEditorError = null),
              );
              final qtyField = TextField(
                key: Key('luggage-carryon-qty-input-$scope'),
                controller: _carryOnQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số kiện (≤${widget.cubit.passengerCount}) *',
                  filled: true,
                  fillColor: DiscoveryColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() => _carryOnEditorError = null),
              );
              if (stack) {
                return Column(
                  children: [weightField, const SizedBox(height: 8), qtyField],
                );
              }
              return Row(
                children: [
                  Expanded(child: weightField),
                  const SizedBox(width: 10),
                  Expanded(child: qtyField),
                ],
              );
            },
          ),
          if (liveError != null) ...[
            const SizedBox(height: 8),
            _buildBanner(
              key: Key('luggage-carryon-error-$scope'),
              icon: Icons.error_outline_rounded,
              color: DiscoveryColors.error,
              text: liveError,
            ),
            if (cargoOptions.capacity.acceptsShipments) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: Key('luggage-carryon-convert-btn-$scope'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: DiscoveryColors.secondary,
                ),
                onPressed: () => _convertCarryOnToChecked(
                  policy: policy,
                  cargoOptions: cargoOptions,
                ),
                icon: const Icon(Icons.luggage_rounded, size: 16),
                label: const Text('Chuyển sang hành lý ký gửi'),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                key: Key('luggage-carryon-cancel-btn-$scope'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _cancelCarryOnEditor,
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                key: Key('luggage-carryon-save-btn-$scope'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _saveCarryOn(policy),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Lưu kiện xách tay'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedSection(
    String scope,
    LuggagePolicy policy,
    CargoOptions cargoOptions,
    LuggageState state,
    bool locked,
  ) {
    if (!cargoOptions.capacity.acceptsShipments) {
      return Container(
        key: Key('luggage-checked-not-accepted-$scope'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DiscoveryColors.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DiscoveryColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.block_rounded,
                  color: DiscoveryColors.warningDark,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chuyến xe không nhận hành lý ký gửi.',
                    style: TextStyle(
                      color: DiscoveryColors.neutral900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Bạn vẫn có thể mang hành lý xách tay miễn phí đúng hạn mức hoặc bấm "Không thêm hành lý ký gửi" để tiếp tục đặt vé.',
              style: TextStyle(
                color: DiscoveryColors.neutral600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final points = cargoOptions.points;
    final hasValidRoutePoints =
        points != null &&
        points.senders.isNotEmpty &&
        points.receivers.isNotEmpty;
    final checkedItems = state.selection.checked;

    return Container(
      key: Key('luggage-checked-section-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _descriptionInfo(
            'Hành lý ký gửi',
            'Số lượng và loại hành lý phụ thuộc sức chứa còn lại của chuyến xe. Hệ thống sẽ kiểm tra khi bạn chọn hành lý.',
            'luggage-capacity-info-$scope',
          ),
          const SizedBox(height: 8),
          if (!hasValidRoutePoints)
            _buildBanner(
              key: Key('luggage-missing-points-$scope'),
              icon: Icons.error_outline_rounded,
              color: DiscoveryColors.error,
              text:
                  'Chuyến xe chưa cấu hình điểm gửi/nhận hành lý ký gửi hợp lệ.',
            )
          else ...[
            _buildRoutePointsSelector(scope, points, state.selection, locked),
            const SizedBox(height: 12),
            if (checkedItems.isNotEmpty) ...[
              Text(
                'Danh sách hành lý ký gửi (${checkedItems.length})',
                style: const TextStyle(
                  color: DiscoveryColors.neutral900,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(checkedItems.length, (index) {
                return _buildCheckedItemTile(
                  scope: scope,
                  index: index,
                  item: checkedItems[index],
                  policy: policy,
                  options: cargoOptions,
                  locked: locked,
                );
              }),
              const SizedBox(height: 8),
            ],
            if (_isEditingChecked && !locked)
              _buildCheckedEditor(scope, policy, cargoOptions)
            else if (!locked)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('luggage-add-checked-btn-$scope'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _openAddPackageItem(policy, cargoOptions),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Kiện hành lý'),
                  ),
                  OutlinedButton.icon(
                    key: Key('luggage-add-vehicle-btn-$scope'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _openAddVehicleItem(cargoOptions),
                    icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                    label: const Text('Xe đạp / Xe máy'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutePointsSelector(
    String scope,
    CargoRoutePoints points,
    LuggageSelection selection,
    bool locked,
  ) {
    final senderId = points.senders.any((p) => p.id == selection.senderPointId)
        ? selection.senderPointId
        : null;
    final receiverId =
        points.receivers.any((p) => p.id == selection.receiverPointId)
        ? selection.receiverPointId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điểm gửi & nhận hành lý ký gửi trên tuyến',
          style: TextStyle(
            color: DiscoveryColors.neutral900,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          key: Key('luggage-sender-point-$scope'),
          initialValue: senderId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Điểm gửi hành lý *',
            filled: true,
            fillColor: DiscoveryColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: Key('luggage-receiver-point-$scope'),
          initialValue: receiverId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Điểm nhận hành lý *',
            filled: true,
            fillColor: DiscoveryColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildCheckedItemTile({
    required String scope,
    required int index,
    required CheckedLuggageItem item,
    required LuggagePolicy policy,
    required CargoOptions options,
    required bool locked,
  }) {
    final cargo = item.cargo;
    final itemError = item.validate(policy);
    int? itemRefFee;
    if (itemError == null) {
      try {
        itemRefFee = item.referenceFee(policy);
      } catch (_) {}
    }
    final hasDimensions =
        cargo.length != null && cargo.width != null && cargo.height != null;

    return Container(
      key: Key('luggage-checked-item-$scope-$index'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: itemError != null
              ? DiscoveryColors.error
              : DiscoveryColors.neutral200,
        ),
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
                      '${cargo.name} × ${cargo.quantity}',
                      style: const TextStyle(
                        color: DiscoveryColors.neutral900,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(
                          cargo.isVehicle
                              ? (cargo.kind == CargoKind.bicycle
                                    ? 'Xe đạp'
                                    : 'Xe máy (${_tariffLabel(item.motorcycleTariff)})')
                              : 'Gói ${item.packageCode ?? "?"}',
                        ),
                        if (cargo.service != CargoService.normal)
                          _buildTag(_serviceLabel(cargo.service)),
                        if (itemRefFee != null)
                          _buildTag(
                            'Dự tính ${CurrencyFormatter.format(itemRefFee)}',
                            highlight: true,
                          ),
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
                      key: Key('luggage-checked-edit-$scope-$index'),
                      onPressed: () =>
                          _openEditCheckedItem(index, item, options),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: DiscoveryColors.primary,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: 'Sửa hành lý ký gửi',
                    ),
                    IconButton(
                      key: Key('luggage-checked-delete-$scope-$index'),
                      onPressed: () => _removeCheckedItem(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: DiscoveryColors.error,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: 'Xóa hành lý ký gửi',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cargo.isVehicle
                ? 'Khối lượng quy định: ${_formatNumber(cargo.payloadWeight)} kg/xe'
                : hasDimensions
                ? 'Khối lượng: ${_formatNumber(cargo.weight)} kg • Kích thước: ${_formatNumber(cargo.length!)}×${_formatNumber(cargo.width!)}×${_formatNumber(cargo.height!)} cm (Hiệu dụng: ${_formatNumber(cargo.effectiveWeight)} kg)'
                : 'Khối lượng: ${_formatNumber(cargo.weight)} kg',
            style: const TextStyle(
              color: DiscoveryColors.neutral600,
              fontSize: 12,
            ),
          ),
          if (itemError != null) ...[
            const SizedBox(height: 6),
            Text(
              itemError,
              key: Key('luggage-checked-item-error-$scope-$index'),
              style: const TextStyle(
                color: DiscoveryColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckedEditor(
    String scope,
    LuggagePolicy policy,
    CargoOptions options,
  ) {
    final liveError =
        _checkedEditorError ?? _computeLiveCheckedEditorError(policy, options);

    return Container(
      key: Key('luggage-checked-editor-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingCheckedIndex != null
                ? 'Chỉnh sửa mục ký gửi #${_editingCheckedIndex! + 1}'
                : (_editorIsVehicle
                      ? 'Thêm phương tiện gửi kèm'
                      : 'Thêm kiện hành lý ký gửi'),
            style: const TextStyle(
              color: DiscoveryColors.neutral900,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (!_editorIsVehicle) ...[
            const Text(
              'Chọn gói hành lý (S / M / L / XL):',
              style: TextStyle(
                color: DiscoveryColors.neutral700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: policy.packages.map((pack) {
                final selected = _selectedPackageCode == pack.code;
                return Semantics(
                  selected: selected,
                  child: ListTile(
                    key: Key('luggage-pack-chip-${pack.code}-$scope'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    minVerticalPadding: 8,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? DiscoveryColors.primary
                          : DiscoveryColors.neutral500,
                    ),
                    title: Text(
                      'Gói ${pack.code} · ≤ ${_formatNumber(pack.maxWeightKg)} kg',
                    ),
                    subtitle: Text(
                      '${_formatNumber(pack.lengthCm)} × ${_formatNumber(pack.widthCm)} × ${_formatNumber(pack.heightCm)} cm\n'
                      'Dự tính ${CurrencyFormatter.format(pack.referenceFee)}',
                    ),
                    selected: selected,
                    selectedTileColor: DiscoveryColors.primaryLight,
                    onTap: () => setState(() {
                      _selectedPackageCode = pack.code;
                      _checkedEditorError = null;
                    }),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const Text(
              'Loại phương tiện đi kèm:',
              style: TextStyle(
                color: DiscoveryColors.neutral700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: Key('luggage-vehicle-kind-bicycle-$scope'),
                  label: Text(
                    'Xe đạp (${CurrencyFormatter.format(policy.vehicleFees["bicycle"] ?? 0)})',
                  ),
                  selected: _vehicleKind == CargoKind.bicycle,
                  onSelected: (_) {
                    setState(() {
                      _vehicleKind = CargoKind.bicycle;
                      _weightCtrl.text = '15';
                      _selectedCategoryId = _resolveCategoryId(options);
                      _checkedEditorError = null;
                    });
                  },
                ),
                ChoiceChip(
                  key: Key('luggage-vehicle-kind-motorcycle-$scope'),
                  label: const Text('Xe máy'),
                  selected: _vehicleKind == CargoKind.motorcycle,
                  onSelected: (_) {
                    setState(() {
                      _vehicleKind = CargoKind.motorcycle;
                      _weightCtrl.text = '100';
                      _selectedCategoryId = _resolveCategoryId(options);
                      _checkedEditorError = null;
                    });
                  },
                ),
              ],
            ),
            if (_vehicleKind == CargoKind.motorcycle) ...[
              const SizedBox(height: 8),
              const Text(
                'Phân nhóm xe máy (Phí tham khảo):',
                style: TextStyle(
                  color: DiscoveryColors.neutral700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LuggageMotorcycleTariff.values.map((t) {
                  final feeKey = switch (t) {
                    LuggageMotorcycleTariff.wave => 'motorcycleWave',
                    LuggageMotorcycleTariff.scooter => 'motorcycleScooter',
                    LuggageMotorcycleTariff.big => 'motorcycleBig',
                  };
                  final fee = policy.vehicleFees[feeKey] ?? 0;
                  return ChoiceChip(
                    key: Key('luggage-motorcycle-tariff-${t.name}-$scope'),
                    label: Text(
                      '${_tariffLabel(t)} (${CurrencyFormatter.format(fee)})',
                    ),
                    selected: _motorcycleTariff == t,
                    onSelected: (_) => setState(() => _motorcycleTariff = t),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 10),
          TextField(
            key: Key('luggage-checked-name-$scope'),
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: _editorIsVehicle
                  ? 'Tên phương tiện *'
                  : 'Tên kiện hành lý *',
              hintText: _editorIsVehicle
                  ? 'VD: Xe máy Honda Vision / Xe đạp Giant'
                  : 'VD: Vali hành lý, thùng quà...',
              filled: true,
              fillColor: DiscoveryColors.neutral50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (_) => setState(() => _checkedEditorError = null),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 260;
              final qtyField = TextField(
                key: Key('luggage-checked-qty-$scope'),
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số lượng *',
                  filled: true,
                  fillColor: DiscoveryColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() => _checkedEditorError = null),
              );
              final weightField = TextField(
                key: Key('luggage-checked-weight-$scope'),
                controller: _weightCtrl,
                enabled: !_editorIsVehicle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _editorIsVehicle
                      ? 'Khối lượng quy định (kg)'
                      : 'Khối lượng (kg) *',
                  filled: true,
                  fillColor: DiscoveryColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) {
                  setState(() {
                    _selectedCategoryId = _resolveCategoryId(options);
                    _checkedEditorError = null;
                  });
                },
              );
              if (stack) {
                return Column(
                  children: [qtyField, const SizedBox(height: 8), weightField],
                );
              }
              return Row(
                children: [
                  Expanded(child: qtyField),
                  const SizedBox(width: 10),
                  Expanded(child: weightField),
                ],
              );
            },
          ),
          if (!_editorIsVehicle) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              key: Key('luggage-dimensions-disclosure-$scope'),
              tilePadding: EdgeInsets.zero,
              initiallyExpanded:
                  _lengthCtrl.text.isNotEmpty ||
                  _widthCtrl.text.isNotEmpty ||
                  _heightCtrl.text.isNotEmpty,
              title: Row(
                children: [
                  const Expanded(child: Text('Kích thước chi tiết')),
                  _infoButton(
                    'Kích thước và khối lượng quy đổi',
                    'Nhập số đo thực tế theo cm. Khối lượng quy đổi = Dài × Rộng × Cao / 5.000, làm tròn một chữ số thập phân. Khối lượng tính cước là số lớn hơn giữa cân nặng và khối lượng quy đổi. Không dùng kích thước tối đa của gói thay cho số đo thực tế.',
                    'luggage-dimensions-info-$scope',
                  ),
                ],
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 280;
                    final lField = TextField(
                      key: Key('luggage-checked-length-$scope'),
                      controller: _lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Dài (cm)',
                        filled: true,
                        fillColor: DiscoveryColors.neutral50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _checkedEditorError = null),
                    );
                    final wField = TextField(
                      key: Key('luggage-checked-width-$scope'),
                      controller: _widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Rộng (cm)',
                        filled: true,
                        fillColor: DiscoveryColors.neutral50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _checkedEditorError = null),
                    );
                    final hField = TextField(
                      key: Key('luggage-checked-height-$scope'),
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cao (cm)',
                        filled: true,
                        fillColor: DiscoveryColors.neutral50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _checkedEditorError = null),
                    );
                    if (stack) {
                      return Column(
                        children: [
                          lField,
                          const SizedBox(height: 8),
                          wField,
                          const SizedBox(height: 8),
                          hField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: lField),
                        const SizedBox(width: 8),
                        Expanded(child: wField),
                        const SizedBox(width: 8),
                        Expanded(child: hField),
                      ],
                    );
                  },
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 260;
                final modelField = TextField(
                  key: Key('luggage-vehicle-model-$scope'),
                  controller: _vehicleModelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dòng xe / Loại xe',
                    filled: true,
                    fillColor: DiscoveryColors.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                final plateField = TextField(
                  key: Key('luggage-license-plate-$scope'),
                  controller: _licensePlateCtrl,
                  decoration: InputDecoration(
                    labelText: 'Biển số xe',
                    filled: true,
                    fillColor: DiscoveryColors.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                if (stack) {
                  return Column(
                    children: [
                      modelField,
                      const SizedBox(height: 8),
                      plateField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: modelField),
                    const SizedBox(width: 10),
                    Expanded(child: plateField),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          ExpansionTile(
            key: Key('luggage-options-disclosure-$scope'),
            tilePadding: EdgeInsets.zero,
            initiallyExpanded:
                _service != CargoService.normal || _noteCtrl.text.isNotEmpty,
            title: const Text('Bảo quản và ghi chú'),
            children: [
              _descriptionInfo(
                'Dịch vụ bảo quản',
                'Chọn dịch vụ phù hợp nếu kiện dễ vỡ hoặc có giá trị. Phụ phí hiển thị theo chính sách nhà xe.',
                'luggage-service-info-$scope',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CargoService.values.map((srv) {
                  final surcharge = srv == CargoService.normal
                      ? 0
                      : (policy.serviceFees[srv.name] ?? 0);
                  final label = surcharge > 0
                      ? '${_serviceLabel(srv)} (+${CurrencyFormatter.format(surcharge)})'
                      : _serviceLabel(srv);
                  return ChoiceChip(
                    key: Key('luggage-checked-service-${srv.name}-$scope'),
                    label: Text(label),
                    selected: _service == srv,
                    onSelected: (_) => setState(() => _service = srv),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                key: Key('luggage-checked-note-$scope'),
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  filled: true,
                  fillColor: DiscoveryColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (liveError != null) ...[
            const SizedBox(height: 10),
            _buildBanner(
              key: Key('luggage-checked-editor-error-$scope'),
              icon: Icons.error_outline_rounded,
              color: DiscoveryColors.error,
              text: liveError,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                key: Key('luggage-checked-cancel-btn-$scope'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _cancelCheckedEditor,
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                key: Key('luggage-checked-save-btn-$scope'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _saveCheckedItem(policy, options),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _editingCheckedIndex != null
                      ? 'Cập nhật mục ký gửi'
                      : 'Lưu mục ký gửi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceFeeBox(String scope, LuggagePolicy policy) {
    final refFee = widget.cubit.referenceFee;
    return Container(
      key: Key('luggage-reference-fee-box-$scope'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.secondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DiscoveryColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Cước phí dự tính',
                style: TextStyle(
                  color: DiscoveryColors.neutral900,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                refFee != null
                    ? CurrencyFormatter.format(refFee)
                    : 'Đang kiểm tra điều kiện gói',
                key: Key('luggage-reference-fee-value-$scope'),
                style: const TextStyle(
                  color: DiscoveryColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          _infoButton(
            'Cước phí dự tính',
            'Đây là cước dự tính theo gói của nhà xe. Thanh toán tại bến khi giao vật phẩm, không cộng vào tiền vé thanh toán trực tuyến.',
            'luggage-fee-info-$scope',
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? DiscoveryColors.secondaryLight
            : DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? DiscoveryColors.secondary.withValues(alpha: 0.3)
              : DiscoveryColors.neutral200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlight
              ? DiscoveryColors.secondary
              : DiscoveryColors.neutral700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _serviceLabel(CargoService srv) => switch (srv) {
    CargoService.normal => 'Tiêu chuẩn',
    CargoService.fragile => 'Hàng dễ vỡ',
    CargoService.valuable => 'Hàng giá trị cao',
  };

  String _tariffLabel(LuggageMotorcycleTariff t) => switch (t) {
    LuggageMotorcycleTariff.wave => 'Xe số',
    LuggageMotorcycleTariff.scooter => 'Xe tay ga',
    LuggageMotorcycleTariff.big => 'Xe phân khối lớn',
  };

  Widget _buildBanner({
    Key? key,
    required IconData icon,
    required Color color,
    required String text,
    Widget? trailing,
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
          Icon(icon, size: 18, color: color),
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
          ?trailing,
        ],
      ),
    );
  }
}
