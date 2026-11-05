import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/repositories/shipment_repository.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import '../widgets/shipment_create_view.dart';
import '../widgets/shipment_detail_view.dart';
import '../widgets/shipment_lookup_view.dart';
import '../widgets/shipment_my_list_view.dart';
import '../widgets/shipment_uncertain_view.dart';

class ShipmentsHostScreen extends StatefulWidget {
  final ShipmentRepository? repository;
  final ShipmentRepository Function()? repositoryFactory;
  final ShipmentFlowCubit? cubit;
  final Future<List<CityModel>> Function()? citiesLoader;

  const ShipmentsHostScreen({
    super.key,
    this.repository,
    this.repositoryFactory,
    this.cubit,
    this.citiesLoader,
  });

  @override
  State<ShipmentsHostScreen> createState() => _ShipmentsHostScreenState();
}

class _ShipmentsHostScreenState extends State<ShipmentsHostScreen> {
  late ShipmentRepository _repository;
  late ShipmentFlowCubit _cubit;
  late bool _ownsCubit;
  int _selectedTabIndex = 0;
  String? _prefilledWaybillCode;
  bool _viewingDetail = false;
  bool _detailOpenedFromList = false;
  bool _uncertainLookupActive = false;
  ShipmentRecord? _lastObservedRecord;
  ShipmentStatus? _listStatusFilter;
  String _listSearchQuery = '';
  int _listPage = 1;

  ShipmentRepository _createRepository() {
    if (widget.repositoryFactory != null) {
      return widget.repositoryFactory!();
    }
    final current = _repository;
    if (current is RealShipmentRepository) {
      return RealShipmentRepository(client: current.client);
    }
    return current;
  }

  void _startNewCreationFlow() {
    if (_cubit.state.phase == ShipmentCreationPhase.submitting ||
        _cubit.state.phase == ShipmentCreationPhase.uncertain) {
      return;
    }
    if (_ownsCubit) {
      _cubit.close();
    }
    _repository = _createRepository();
    _cubit = ShipmentFlowCubit(repository: _repository);
    _ownsCubit = true;
    _lastObservedRecord = null;
  }

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repositoryFactory?.call() ??
        widget.repository ??
        RealShipmentRepository();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else {
      _cubit = ShipmentFlowCubit(repository: _repository);
      _ownsCubit = true;
    }
    if (_cubit.state.record != null &&
        _cubit.state.phase == ShipmentCreationPhase.created) {
      _viewingDetail = true;
      _lastObservedRecord = _cubit.state.record;
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  Future<bool> _handlePopConfirmation(ShipmentCreationPhase phase) async {
    if (_uncertainLookupActive) {
      setState(() => _uncertainLookupActive = false);
      return false;
    }

    if (_viewingDetail) {
      setState(() {
        _viewingDetail = false;
        if (_detailOpenedFromList) {
          _detailOpenedFromList = false;
        } else {
          _detailOpenedFromList = false;
          _selectedTabIndex = 0;
          if (phase == ShipmentCreationPhase.created) {
            _startNewCreationFlow();
          }
        }
      });
      return false;
    }

    if (phase == ShipmentCreationPhase.submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang xử lý tạo đơn, vui lòng đợi trong giây lát...'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    if (phase == ShipmentCreationPhase.uncertain) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Cảnh báo đơn hàng chưa xác minh'),
          content: const Text(
            'Kết quả tạo đơn chưa được máy chủ xác nhận. Bạn có chắc muốn rời khỏi màn hình này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text(
                'Rời khỏi',
                style: TextStyle(color: DiscoveryColors.error),
              ),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShipmentFlowCubit>.value(
      value: _cubit,
      child: BlocConsumer<ShipmentFlowCubit, ShipmentFlowState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state.phase == ShipmentCreationPhase.invalidated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Phiên làm việc đã thay đổi. Dữ liệu đã được làm mới.',
                ),
                backgroundColor: DiscoveryColors.warningDark,
              ),
            );
            if (_ownsCubit) {
              _cubit.close();
              _repository = _createRepository();
              _cubit = ShipmentFlowCubit(repository: _repository);
            }
            setState(() {
              _viewingDetail = false;
              _detailOpenedFromList = false;
              _uncertainLookupActive = false;
              _selectedTabIndex = 0;
              _lastObservedRecord = null;
              _listStatusFilter = null;
              _listSearchQuery = '';
              _listPage = 1;
            });
          } else if (state.phase == ShipmentCreationPhase.created &&
              state.record != null &&
              state.record != _lastObservedRecord) {
            _lastObservedRecord = state.record;
            setState(() {
              _viewingDetail = true;
              _uncertainLookupActive = false;
            });
          } else if (state.phase == ShipmentCreationPhase.uncertain) {
            if (_viewingDetail) {
              setState(() {
                _viewingDetail = false;
                _detailOpenedFromList = false;
              });
            }
          }
        },
        builder: (context, state) {
          final isAuth =
              context.watch<AuthBloc?>()?.state.isAuthenticated ?? false;
          final tabs = ['Tạo đơn', 'Tra cứu', if (isAuth) 'Đơn của tôi'];

          // Clamp selected tab index if auth status changed
          final safeIndex = _selectedTabIndex >= tabs.length
              ? 0
              : _selectedTabIndex;

          final showDetail =
              _viewingDetail && (state.record != null || state.refreshing);

          final showTabs =
              !showDetail &&
              (!_uncertainLookupActive &&
                  state.phase != ShipmentCreationPhase.uncertain);

          final canPopRoute = Navigator.of(context).canPop();
          final showBackInHeader =
              showDetail ||
              _uncertainLookupActive ||
              state.phase == ShipmentCreationPhase.uncertain ||
              canPopRoute;

          return PopScope(
            canPop:
                state.phase != ShipmentCreationPhase.submitting &&
                state.phase != ShipmentCreationPhase.uncertain &&
                !_viewingDetail &&
                !_uncertainLookupActive,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final canLeave = await _handlePopConfirmation(state.phase);
              if (canLeave &&
                  context.mounted &&
                  Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: DiscoveryColors.background,
              appBar: TabPageHeader(
                title: showDetail
                    ? 'Chi tiết vận đơn'
                    : (state.phase == ShipmentCreationPhase.uncertain &&
                          !_uncertainLookupActive)
                    ? 'Kết quả tạo đơn'
                    : _uncertainLookupActive
                    ? 'Tra cứu vận đơn'
                    : 'Gửi hàng',
                showBackButton: showBackInHeader,
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // Top tabs
                    if (showTabs) ...[
                      Container(
                        color: Colors.white,
                        child: Row(
                          children: tabs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final title = entry.value;
                            final isSelected = safeIndex == idx;
                            return Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (idx == 0 &&
                                        _cubit.state.phase ==
                                            ShipmentCreationPhase.created) {
                                      _startNewCreationFlow();
                                    }
                                    _selectedTabIndex = idx;
                                  });
                                  if (title == 'Đơn của tôi' &&
                                      state.myShipments == null &&
                                      !state.loadingMine) {
                                    _cubit.loadMine(
                                      page: _listPage,
                                      status: _listStatusFilter,
                                      search: _listSearchQuery,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isSelected
                                            ? DiscoveryColors.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? DiscoveryColors.primary
                                          : DiscoveryColors.neutral600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: DiscoveryColors.neutral200,
                      ),
                    ],

                    // Main View Content
                    Expanded(
                      child: showDetail
                          ? ShipmentDetailView(
                              cubit: _cubit,
                              state: state,
                              onNewShipment: () {
                                setState(() {
                                  _startNewCreationFlow();
                                  _viewingDetail = false;
                                  _detailOpenedFromList = false;
                                  _uncertainLookupActive = false;
                                  _selectedTabIndex = 0;
                                  _prefilledWaybillCode = null;
                                });
                              },
                              onGoToList: isAuth
                                  ? () {
                                      setState(() {
                                        _viewingDetail = false;
                                        _detailOpenedFromList = false;
                                        _uncertainLookupActive = false;
                                        _selectedTabIndex =
                                            2; // My shipments tab
                                      });
                                      _cubit.loadMine(
                                        page: _listPage,
                                        status: _listStatusFilter,
                                        search: _listSearchQuery,
                                      );
                                    }
                                  : null,
                            )
                          : state.phase == ShipmentCreationPhase.uncertain &&
                                !_uncertainLookupActive
                          ? ShipmentUncertainView(
                              cubit: _cubit,
                              state: state,
                              isAuthenticated: isAuth,
                              onNavigateToLookup: (code) {
                                setState(() {
                                  _prefilledWaybillCode = code;
                                  _uncertainLookupActive = true;
                                });
                              },
                            )
                          : (_uncertainLookupActive || safeIndex == 1)
                          ? ShipmentLookupView(
                              key: ObjectKey(_cubit),
                              cubit: _cubit,
                              state: state,
                              initialWaybillCode: _prefilledWaybillCode,
                            )
                          : safeIndex == 0
                          ? ShipmentCreateView(
                              key: ObjectKey(_cubit),
                              cubit: _cubit,
                              state: state,
                              citiesLoader: widget.citiesLoader,
                            )
                          : ShipmentMyListView(
                              key: ObjectKey(_cubit),
                              cubit: _cubit,
                              state: state,
                              initialStatus: _listStatusFilter,
                              initialSearch: _listSearchQuery,
                              onFilterChanged: (status, search, page) {
                                _listStatusFilter = status;
                                _listSearchQuery = search;
                                _listPage = page;
                              },
                              onOpenDetail: (shipmentId) {
                                setState(() {
                                  _detailOpenedFromList = true;
                                  _viewingDetail = true;
                                });
                                _cubit.openDetail(shipmentId);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
