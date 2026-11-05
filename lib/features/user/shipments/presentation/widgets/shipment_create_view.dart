import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/design/discovery_theme.dart'
    as discovery
    show DiscoveryButton, ButtonType;
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/data/adapters/city_search_adapter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/home/presentation/screens/select_city_sheet.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';

class _ItemFormData {
  final TextEditingController name = TextEditingController();
  int? categoryId;
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController weight = TextEditingController();
  final TextEditingController length = TextEditingController();
  final TextEditingController width = TextEditingController();
  final TextEditingController height = TextEditingController();
  ShipmentService service = ShipmentService.normal;
  final TextEditingController note = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
    weight.dispose();
    length.dispose();
    width.dispose();
    height.dispose();
    note.dispose();
  }

  void clear() {
    name.clear();
    categoryId = null;
    quantity.text = '1';
    weight.clear();
    length.clear();
    width.clear();
    height.clear();
    service = ShipmentService.normal;
    note.clear();
  }

  ShipmentItem toShipmentItem() {
    final qty = int.tryParse(quantity.text.trim()) ?? 1;
    final w = double.tryParse(weight.text.trim()) ?? 0.0;
    final l = double.tryParse(length.text.trim());
    final wi = double.tryParse(width.text.trim());
    final h = double.tryParse(height.text.trim());

    return ShipmentItem(
      name: name.text.trim(),
      categoryId: categoryId ?? 0,
      quantity: qty,
      weight: w,
      length: l,
      width: wi,
      height: h,
      service: service,
      note: note.text.trim(),
    );
  }
}

enum _PaymentOption { senderCounter, receiverCounter }

final MockTripRepository _defaultShipmentTripRepository = MockTripRepository();

class ShipmentCreateView extends StatefulWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final Future<List<CityModel>> Function()? citiesLoader;

  const ShipmentCreateView({
    super.key,
    required this.cubit,
    required this.state,
    this.citiesLoader,
  });

  @override
  State<ShipmentCreateView> createState() => _ShipmentCreateViewState();
}

class _ShipmentCreateViewState extends State<ShipmentCreateView> {
  // Step 1: Route search (Homepage-style city selector + date)
  List<CityModel> _cities = const [];
  bool _loadingCities = false;
  String? _citiesError;
  int _citiesLoadSeq = 0;
  CityModel? _fromCity;
  CityModel? _toCity;
  String? _localSearchError;
  DateTime _departureDate = DateTime.now().add(const Duration(days: 1));

  // Step 2: Trip selection & Points
  int? _selectedSenderPointId;
  int? _selectedReceiverPointId;

  // Step 3: Parties
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderEmailController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverCccdController = TextEditingController();

  // Step 4: Items
  final List<_ItemFormData> _items = [_ItemFormData()];

  // Step 5: Payment method
  _PaymentOption _selectedPayment = _PaymentOption.senderCounter;

  // Step 6: General note
  final TextEditingController _generalNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addCubitListeners(widget.cubit);
    _loadCities();
  }

  Future<List<CityModel>> _defaultCitiesLoader() =>
      _defaultShipmentTripRepository.getCities();

  Future<void> _loadCities() async {
    final request = ++_citiesLoadSeq;
    setState(() {
      _loadingCities = true;
      _citiesError = null;
    });
    try {
      final loader = widget.citiesLoader ?? _defaultCitiesLoader;
      final loaded = await loader();
      if (!mounted || request != _citiesLoadSeq) return;
      setState(() {
        _cities = List.unmodifiable(loaded);
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted || request != _citiesLoadSeq) return;
      setState(() {
        _loadingCities = false;
        _citiesError = 'Không thể tải danh sách tỉnh/thành phố.';
      });
    }
  }

  void _addCubitListeners(ShipmentFlowCubit cubit) {
    for (final c in [
      _senderNameController,
      _senderPhoneController,
      _senderEmailController,
      _receiverNameController,
      _receiverPhoneController,
      _receiverCccdController,
      _generalNoteController,
    ]) {
      c.addListener(cubit.invalidateQuote);
    }
    for (final item in _items) {
      _watchItem(item, cubit);
    }
  }

  void _removeCubitListeners(ShipmentFlowCubit cubit) {
    for (final c in [
      _senderNameController,
      _senderPhoneController,
      _senderEmailController,
      _receiverNameController,
      _receiverPhoneController,
      _receiverCccdController,
      _generalNoteController,
    ]) {
      c.removeListener(cubit.invalidateQuote);
    }
    for (final item in _items) {
      _unwatchItem(item, cubit);
    }
  }

  void _watchItem(_ItemFormData item, [ShipmentFlowCubit? cubit]) {
    final c = cubit ?? widget.cubit;
    for (final ctrl in [
      item.name,
      item.quantity,
      item.weight,
      item.length,
      item.width,
      item.height,
      item.note,
    ]) {
      ctrl.addListener(c.invalidateQuote);
    }
  }

  void _unwatchItem(_ItemFormData item, [ShipmentFlowCubit? cubit]) {
    final c = cubit ?? widget.cubit;
    for (final ctrl in [
      item.name,
      item.quantity,
      item.weight,
      item.length,
      item.width,
      item.height,
      item.note,
    ]) {
      ctrl.removeListener(c.invalidateQuote);
    }
  }

  void _routeInputsChanged() {
    widget.cubit.clearRouteSelection();
    widget.cubit.invalidateQuote();
    _selectedSenderPointId = null;
    _selectedReceiverPointId = null;
  }

  @override
  void didUpdateWidget(ShipmentCreateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.cubit, oldWidget.cubit)) {
      _removeCubitListeners(oldWidget.cubit);
      _clearAllForm();
      _addCubitListeners(widget.cubit);
    } else if (widget.state.phase == ShipmentCreationPhase.invalidated &&
        oldWidget.state.phase != ShipmentCreationPhase.invalidated) {
      _clearAllForm();
    }
  }

  void _clearAllForm() {
    _fromCity = null;
    _toCity = null;
    _localSearchError = null;
    _selectedSenderPointId = null;
    _selectedReceiverPointId = null;
    _senderNameController.clear();
    _senderPhoneController.clear();
    _senderEmailController.clear();
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _receiverCccdController.clear();
    for (final item in _items) {
      _unwatchItem(item);
      item.dispose();
    }
    _items.clear();
    final firstItem = _ItemFormData();
    _watchItem(firstItem);
    _items.add(firstItem);
    _generalNoteController.clear();
    _selectedPayment = _PaymentOption.senderCounter;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _removeCubitListeners(widget.cubit);
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderEmailController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverCccdController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    _generalNoteController.dispose();
    super.dispose();
  }

  Future<void> _selectFromCity() async {
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      await _loadCities();
      if (!mounted || _cities.isEmpty) return;
    }
    final picked = await SelectCitySheet.show(
      context,
      title: 'Chọn điểm đi',
      cities: _cities,
      currentCity: _fromCity,
    );
    if (picked != null && mounted) {
      setState(() {
        _fromCity = picked;
        _localSearchError = null;
      });
      _routeInputsChanged();
    }
  }

  Future<void> _selectToCity() async {
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      await _loadCities();
      if (!mounted || _cities.isEmpty) return;
    }
    final picked = await SelectCitySheet.show(
      context,
      title: 'Chọn điểm đến',
      cities: _cities,
      currentCity: _toCity,
    );
    if (picked != null && mounted) {
      setState(() {
        _toCity = picked;
        _localSearchError = null;
      });
      _routeInputsChanged();
    }
  }

  void _swapCities() {
    setState(() {
      final temp = _fromCity;
      _fromCity = _toCity;
      _toCity = temp;
      _localSearchError = null;
    });
    _routeInputsChanged();
  }

  String _resolveCityForBackend(CityModel city) {
    final byId = CitySearchAdapter.resolveBackendSearchCity(city.id);
    if (byId != city.id.trim()) return byId;
    return CitySearchAdapter.resolveBackendSearchCity(city.name);
  }

  void _onSearchTrips() {
    if (widget.state.searching) return;
    if (_fromCity == null || _toCity == null) {
      const msg = 'Vui lòng chọn điểm đi và điểm đến.';
      setState(() => _localSearchError = msg);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(msg)));
      return;
    }
    final searchFrom = _resolveCityForBackend(_fromCity!);
    final searchTo = _resolveCityForBackend(_toCity!);
    if (_fromCity!.id == _toCity!.id || searchFrom == searchTo) {
      const msg = 'Điểm đi và điểm đến không được trùng nhau.';
      setState(() => _localSearchError = msg);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(msg)));
      return;
    }
    setState(() => _localSearchError = null);
    final formattedDate =
        '${_departureDate.day.toString().padLeft(2, '0')}-'
        '${_departureDate.month.toString().padLeft(2, '0')}-'
        '${_departureDate.year.toString().padLeft(4, '0')}';

    widget.cubit.searchRoutes(
      from: searchFrom,
      to: searchTo,
      date: formattedDate,
    );
  }

  void _onSelectTrip(int routeId) {
    setState(() {
      _selectedSenderPointId = null;
      _selectedReceiverPointId = null;
    });
    widget.cubit.selectRoute(routeId);
  }

  void _onAddItem() {
    widget.cubit.invalidateQuote();
    setState(() {
      final item = _ItemFormData();
      _watchItem(item);
      _items.add(item);
    });
  }

  void _onRemoveItem(int index) {
    if (_items.length <= 1) return;
    widget.cubit.invalidateQuote();
    setState(() {
      final removed = _items.removeAt(index);
      _unwatchItem(removed);
      removed.dispose();
    });
  }

  Future<void> _onSubmit() async {
    final selectedRouteId = widget.state.selectedRouteId;
    if (selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tuyến và nhà xe trước khi tạo đơn.'),
        ),
      );
      return;
    }

    final (payer, method) = switch (_selectedPayment) {
      _PaymentOption.senderCounter => (
        ShipmentPayer.sender,
        ShipmentPaymentMethod.counter,
      ),
      _PaymentOption.receiverCounter => (
        ShipmentPayer.receiver,
        ShipmentPaymentMethod.counter,
      ),
    };

    final shipmentItems = _items.map((i) => i.toShipmentItem()).toList();

    final draft = ShipmentDraft(
      routeId: selectedRouteId,
      sendDate: widget.state.sendDate,
      senderPointId: _selectedSenderPointId ?? 0,
      receiverPointId: _selectedReceiverPointId ?? 0,
      senderName: _senderNameController.text.trim(),
      senderPhone: _senderPhoneController.text.trim(),
      senderEmail: _senderEmailController.text.trim(),
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
      receiverCccd: _receiverCccdController.text.trim(),
      items: shipmentItems,
      payer: payer,
      paymentMethod: method,
      note: _generalNoteController.text.trim(),
    );

    if (widget.cubit.hasCurrentQuoteFor(draft)) {
      await widget.cubit.create();
    } else {
      widget.cubit.updateDraft(draft);
      await widget.cubit.refreshQuote();
      // Quote first; a second tap explicitly confirms the displayed price.
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldErrors = widget.state.fieldErrors;
    final options = widget.state.options;
    final points = options;
    final categories = options?.categories ?? const [];
    final isInvalidated =
        widget.state.phase == ShipmentCreationPhase.invalidated;

    return AbsorbPointer(
      absorbing:
          isInvalidated ||
          widget.state.quoting ||
          widget.state.phase == ShipmentCreationPhase.submitting,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.base,
          AppDimensions.base,
          AppDimensions.base,
          AppDimensions.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isInvalidated)
              Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.base),
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: DiscoveryColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: DiscoveryColors.warning),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: DiscoveryColors.warningDark,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phiên làm việc đã thay đổi. Vui lòng đóng và mở lại tính năng.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.neutral900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // STEP 1: Route Search Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: DiscoveryColors.neutral200),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingCities) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral100,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đang tải danh sách tỉnh/thành phố...',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: DiscoveryColors.neutral600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_citiesError != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.errorLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(
                          color: DiscoveryColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: DiscoveryColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _citiesError!,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: DiscoveryColors.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadCities,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_cities.isEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.warningLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(color: DiscoveryColors.warning),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: DiscoveryColors.warningDark,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Chưa có danh sách tỉnh/thành phố khả dụng.',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: DiscoveryColors.neutral800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadCities,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Homepage-style City Selector Box + Swap Button
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Column(
                        children: [
                          _buildCitySelectorRow(
                            key: const Key('shipment_from_city_selector'),
                            icon: Icons.trip_origin_rounded,
                            iconColor: DiscoveryColors.primary,
                            label: 'Điểm đi',
                            city: _fromCity,
                            onTap: _selectFromCity,
                          ),
                          const Divider(
                            height: 1,
                            indent: 36,
                            endIndent: 48,
                            color: DiscoveryColors.neutral200,
                          ),
                          _buildCitySelectorRow(
                            key: const Key('shipment_to_city_selector'),
                            icon: Icons.location_on_rounded,
                            iconColor: DiscoveryColors.secondary,
                            label: 'Điểm đến',
                            city: _toCity,
                            onTap: _selectToCity,
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        child: Semantics(
                          button: true,
                          label: 'Đổi chiều điểm đi và điểm đến',
                          child: Tooltip(
                            message: 'Đổi chiều điểm đi và điểm đến',
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              shadowColor: const Color(0x30000000),
                              child: InkWell(
                                key: const Key('shipment_swap_cities_button'),
                                onTap: _swapCities,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: DiscoveryColors.neutral200,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.swap_vert_rounded,
                                    color: DiscoveryColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  const Divider(height: 1, color: DiscoveryColors.neutral200),
                  const SizedBox(height: AppDimensions.base),
                  // Date Row
                  Material(
                    color: DiscoveryColors.neutral50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: InkWell(
                      key: const Key('shipment_send_date_selector'),
                      onTap: () async {
                        final owner = widget.cubit;
                        final session = TokenStorage.sessionVersion;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _departureDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 60),
                          ),
                        );
                        if (!mounted ||
                            !identical(widget.cubit, owner) ||
                            owner.isClosed ||
                            session != TokenStorage.sessionVersion ||
                            owner.state.phase !=
                                ShipmentCreationPhase.editing) {
                          return;
                        }
                        if (picked != null) {
                          setState(() => _departureDate = picked);
                          _routeInputsChanged();
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: DiscoveryColors.neutral200),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: DiscoveryColors.primary,
                            ),
                            const SizedBox(width: AppDimensions.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày gửi',
                                    style: DiscoveryTextStyles.caption.copyWith(
                                      color: DiscoveryColors.neutral500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatFullDate(
                                      _departureDate,
                                    ),
                                    style: DiscoveryTextStyles.titleSmall
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.base),
                  discovery.DiscoveryButton(
                    key: const Key('shipment_search_button'),
                    text: 'Tìm tuyến gửi hàng',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    width: double.infinity,
                    height: 50,
                    isLoading: widget.state.searching,
                    onPressed: _onSearchTrips,
                    type: discovery.ButtonType.secondary,
                  ),
                  if (_localSearchError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _localSearchError!,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: DiscoveryColors.error,
                        ),
                      ),
                    ),
                  ],
                  if (widget.state.searchError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.state.searchError!,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: DiscoveryColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Found Trips List
            if (widget.state.routes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn tuyến và nhà xe (${widget.state.routes.length} nhà xe tìm thấy):',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    if (fieldErrors.containsKey('routeId'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          fieldErrors['routeId']!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: DiscoveryColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...widget.state.routes.map((trip) {
                      final isSelected =
                          widget.state.selectedRouteId == trip.id;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DiscoveryColors.primaryLight
                              : DiscoveryColors.neutral50,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? DiscoveryColors.primary
                                : DiscoveryColors.neutral200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onSelectTrip(trip.id),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? DiscoveryColors.primary
                                        : DiscoveryColors.neutral400,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.carrier,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? DiscoveryColors.primaryDark
                                                : DiscoveryColors.neutral900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          trip.minimumEstimatedFee == null
                                              ? 'Chưa có cước tham khảo'
                                              : 'Cước từ ${CurrencyFormatter.format(trip.minimumEstimatedFee!)}',
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 12,
                                            color: DiscoveryColors.neutral600,
                                          ),
                                        ),
                                        Text(
                                          '${trip.origin} → ${trip.destination}',
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 12,
                                            color: DiscoveryColors.neutral600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Trip capacity / options loading
            if (widget.state.loadingOptions) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Đang tải cấu hình nhận hàng của tuyến...'),
                    ],
                  ),
                ),
              ),
            ],

            // Options error
            if (widget.state.optionsError != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: DiscoveryColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: DiscoveryColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: DiscoveryColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.state.optionsError!,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.errorDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // STEP 2: Points Selection & Cargo Capacity
            if (options != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Điểm gửi và điểm nhận hàng',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lưu ý: Điểm giao nhận hàng độc lập có thể khác điểm đón trả khách.',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sender point selector
                    const Text(
                      'Chọn điểm gửi hàng *',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DiscoveryColors.neutral800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSenderPointId,
                      isExpanded: true,
                      hint: const Text('Chọn văn phòng/bến gửi hàng'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                      ),
                      items: (points?.senders ?? []).map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.address})',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        widget.cubit.invalidateQuote();
                        setState(() => _selectedSenderPointId = val);
                      },
                    ),
                    if (fieldErrors.containsKey('senderPointId'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          fieldErrors['senderPointId']!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: DiscoveryColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Receiver point selector
                    const Text(
                      'Chọn điểm nhận hàng *',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DiscoveryColors.neutral800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedReceiverPointId,
                      isExpanded: true,
                      hint: const Text('Chọn văn phòng/bến nhận hàng'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                      ),
                      items: (points?.receivers ?? []).map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.address})',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        widget.cubit.invalidateQuote();
                        setState(() => _selectedReceiverPointId = val);
                      },
                    ),
                    if (fieldErrors.containsKey('receiverPointId'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          fieldErrors['receiverPointId']!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: DiscoveryColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // STEP 3: Sender & Receiver Information
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Thông tin người gửi & người nhận',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NGƯỜI GỬI',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      label: 'Họ và tên người gửi *',
                      hintText: 'Nhập đầy đủ họ tên',
                      controller: _senderNameController,
                    ),
                    if (fieldErrors.containsKey('sender.fullName'))
                      _errorText(fieldErrors['sender.fullName']!),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Số điện thoại người gửi *',
                      hintText: 'VD: 0901234567',
                      controller: _senderPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    if (fieldErrors.containsKey('sender.phoneNumber'))
                      _errorText(fieldErrors['sender.phoneNumber']!),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Email người gửi (tùy chọn)',
                      hintText: 'VD: email@example.com',
                      controller: _senderEmailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (fieldErrors.containsKey('sender.email'))
                      _errorText(fieldErrors['sender.email']!),

                    const Divider(
                      height: 24,
                      color: DiscoveryColors.neutral200,
                    ),
                    const Text(
                      'NGƯỜI NHẬN',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.secondaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      label: 'Họ và tên người nhận *',
                      hintText: 'Nhập đầy đủ họ tên người nhận',
                      controller: _receiverNameController,
                    ),
                    if (fieldErrors.containsKey('receiver.fullName'))
                      _errorText(fieldErrors['receiver.fullName']!),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Số điện thoại người nhận *',
                      hintText: 'VD: 0907654321',
                      controller: _receiverPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    if (fieldErrors.containsKey('receiver.phoneNumber'))
                      _errorText(fieldErrors['receiver.phoneNumber']!),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'CCCD người nhận (tùy chọn - 12 số)',
                      hintText: 'Nhập 12 chữ số nếu có',
                      controller: _receiverCccdController,
                      keyboardType: TextInputType.number,
                    ),
                    if (fieldErrors.containsKey('receiver.cccd'))
                      _errorText(fieldErrors['receiver.cccd']!),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // STEP 4: Items List
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '4. Danh sách kiện hàng',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral900,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _onAddItem,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm kiện'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                    if (fieldErrors.containsKey('items'))
                      _errorText(fieldErrors['items']!),
                    const SizedBox(height: 6),
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return _buildItemCard(idx, item, categories, fieldErrors);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // STEP 5: Payment method & Payer
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '5. Người thanh toán & Phương thức',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentRadioTile(
                      title: 'Người gửi trả tại bến',
                      subtitle: 'Thanh toán tiền mặt khi gửi hàng',
                      value: _PaymentOption.senderCounter,
                      enabled: true,
                    ),
                    _buildPaymentRadioTile(
                      title: 'Người nhận trả tại bến',
                      subtitle: 'Thanh toán tiền mặt khi nhận hàng',
                      value: _PaymentOption.receiverCounter,
                      enabled: true,
                    ),

                    if (fieldErrors.containsKey('paymentMethod'))
                      _errorText(fieldErrors['paymentMethod']!),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // STEP 6: General Note
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '6. Ghi chú chung (tùy chọn)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText:
                          'Nhập ghi chú hoặc yêu cầu bàn giao cho nhà xe...',
                      controller: _generalNoteController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quote feedback / summary / errors right above the submit CTA
              if (widget.state.quoting) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Đang tính cước tạm tính...',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: DiscoveryColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.state.quoteError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: DiscoveryColors.error),
                  ),
                  child: Text(
                    widget.state.quoteError!,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.errorDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (fieldErrors['quote'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: DiscoveryColors.error),
                  ),
                  child: Text(
                    fieldErrors['quote']!,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.errorDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.state.quote != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: DiscoveryColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CƯỚC DỰ TÍNH',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              widget.state.quote!.totalFee,
                            ),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DiscoveryColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cước dự tính: ${CurrencyFormatter.format(widget.state.quote!.totalFee)}. Cước được chốt sau cân đo tại bến.',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Server create error banner
              if (widget.state.createError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: DiscoveryColors.error),
                  ),
                  child: Text(
                    widget.state.createError!,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.errorDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // STEP 7: Submit CTA Button
              CustomButton(
                text: widget.state.quote == null
                    ? 'Báo cước'
                    : 'Tạo đơn gửi hàng',
                isLoading:
                    widget.state.phase == ShipmentCreationPhase.submitting,
                onPressed:
                    widget.state.phase == ShipmentCreationPhase.submitting
                    ? null
                    : _onSubmit,
                type: ButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          color: DiscoveryColors.error,
        ),
      ),
    );
  }

  Widget _buildItemCard(
    int index,
    _ItemFormData item,
    List<CargoCategory> categories,
    Map<String, String> fieldErrors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Kiện #${index + 1}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.primary,
                  ),
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  tooltip: 'Xóa kiện hàng',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _onRemoveItem(index),
                ),
            ],
          ),
          const SizedBox(height: 6),
          CustomTextField(
            label: 'Tên hàng hóa *',
            hintText: 'VD: Thùng trái cây, Tài liệu...',
            controller: item.name,
          ),
          if (fieldErrors.containsKey('items.$index.name'))
            _errorText(fieldErrors['items.$index.name']!),
          const SizedBox(height: 8),

          // Category dropdown
          const Text(
            'Loại hàng hóa *',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DiscoveryColors.neutral800,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            initialValue: item.categoryId,
            isExpanded: true,
            hint: const Text('Chọn loại hàng'),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            items: categories.map((c) {
              return DropdownMenuItem<int>(
                value: c.id,
                child: Text(c.name, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              widget.cubit.invalidateQuote();
              widget.cubit.invalidateQuote();
              setState(() => item.categoryId = val);
            },
          ),
          if (fieldErrors.containsKey('items.$index.categoryId'))
            _errorText(fieldErrors['items.$index.categoryId']!),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Số lượng *',
                      hintText: '1',
                      controller: item.quantity,
                      keyboardType: TextInputType.number,
                    ),
                    if (fieldErrors.containsKey('items.$index.quantity'))
                      _errorText(fieldErrors['items.$index.quantity']!),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Khối lượng (kg/kiện) *',
                      hintText: 'VD: 5',
                      controller: item.weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    if (fieldErrors.containsKey('items.$index.weight'))
                      _errorText(fieldErrors['items.$index.weight']!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dimensions (cm) optional: L, W, H
          const Text(
            'Kích thước (cm - tùy chọn: Dài x Rộng x Cao)',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DiscoveryColors.neutral700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: 'Dài',
                  controller: item.length,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomTextField(
                  hintText: 'Rộng',
                  controller: item.width,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomTextField(
                  hintText: 'Cao',
                  controller: item.height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          if (fieldErrors.containsKey('items.$index.dimensions'))
            _errorText(fieldErrors['items.$index.dimensions']!),
          const SizedBox(height: 8),

          // Service type dropdown
          const Text(
            'Loại dịch vụ',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DiscoveryColors.neutral700,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<ShipmentService>(
            initialValue: item.service,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: ShipmentService.normal,
                child: Text(
                  'Tiêu chuẩn (NORMAL)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              DropdownMenuItem(
                value: ShipmentService.fragile,
                child: Text('Dễ vỡ (FRAGILE)', style: TextStyle(fontSize: 13)),
              ),
              DropdownMenuItem(
                value: ShipmentService.valuable,
                child: Text(
                  'Giá trị cao (VALUABLE)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
            onChanged: (val) {
              widget.cubit.invalidateQuote();
              if (val != null) setState(() => item.service = val);
            },
          ),
          const SizedBox(height: 8),

          CustomTextField(
            label: 'Ghi chú kiện hàng (tùy chọn)',
            hintText: 'VD: Hàng nhẹ, cần che mưa...',
            controller: item.note,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadioTile({
    required String title,
    required String subtitle,
    required _PaymentOption value,
    required bool enabled,
  }) {
    final isSelected = _selectedPayment == value;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? DiscoveryColors.primaryLight
            : DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isSelected
              ? DiscoveryColors.primary
              : DiscoveryColors.neutral200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  widget.cubit.invalidateQuote();
                  setState(() => _selectedPayment = value);
                }
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: !enabled
                      ? DiscoveryColors.neutral400
                      : isSelected
                      ? DiscoveryColors.primary
                      : DiscoveryColors.neutral500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !enabled
                              ? DiscoveryColors.neutral400
                              : DiscoveryColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: !enabled
                              ? DiscoveryColors.error
                              : DiscoveryColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitySelectorRow({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String label,
    required CityModel? city,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Padding(
                    // Keep text and region clear of the floating swap button.
                    padding: const EdgeInsets.only(right: 52),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final showRegion =
                            city != null &&
                            city.region.isNotEmpty &&
                            constraints.maxWidth >= 200 &&
                            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: DiscoveryTextStyles.caption.copyWith(
                                      color: DiscoveryColors.neutral500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    city?.name ?? 'Chọn tỉnh/thành phố',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: DiscoveryTextStyles.titleMedium
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: city != null
                                              ? DiscoveryColors.neutral900
                                              : DiscoveryColors.neutral400,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (showRegion) ...[
                              const SizedBox(width: 6),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.36,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DiscoveryColors.neutral100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  city.region,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
