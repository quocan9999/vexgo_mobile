import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';

class TripFilterSheet extends StatefulWidget {
  final TripFilterModel initialFilter;
  final List<String> availableOperators;
  final List<String> availableVehicleTypes;
  final List<String> availableAmenities;

  const TripFilterSheet({
    super.key,
    required this.initialFilter,
    required this.availableOperators,
    required this.availableVehicleTypes,
    required this.availableAmenities,
  });

  static Future<TripFilterModel?> show(
    BuildContext context, {
    required TripFilterModel initialFilter,
    required List<String> availableOperators,
    required List<String> availableVehicleTypes,
    required List<String> availableAmenities,
  }) {
    return showModalBottomSheet<TripFilterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripFilterSheet(
        initialFilter: initialFilter,
        availableOperators: availableOperators,
        availableVehicleTypes: availableVehicleTypes,
        availableAmenities: availableAmenities,
      ),
    );
  }

  @override
  State<TripFilterSheet> createState() => _TripFilterSheetState();
}

class _TripFilterSheetState extends State<TripFilterSheet> {
  late List<TimeSlot> _selectedTimeSlots;
  late List<String> _selectedOperators;
  late List<String> _selectedVehicleTypes;
  late List<String> _selectedAmenities;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _selectedTimeSlots = List.from(widget.initialFilter.selectedTimeSlots);
    _selectedOperators = List.from(widget.initialFilter.selectedOperators);
    _selectedVehicleTypes = List.from(widget.initialFilter.selectedVehicleTypes);
    _selectedAmenities = List.from(widget.initialFilter.selectedAmenities);
    _priceRange = RangeValues(
      widget.initialFilter.minPrice,
      widget.initialFilter.maxPrice,
    );
  }

  void _reset() {
    setState(() {
      _selectedTimeSlots.clear();
      _selectedOperators.clear();
      _selectedVehicleTypes.clear();
      _selectedAmenities.clear();
      _priceRange = const RangeValues(100000, 500000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXl),
          topRight: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppDimensions.md, bottom: AppDimensions.xs),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Bộ lọc tìm kiếm',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Thiết lập lại',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Filter content scroll view
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.base),
              children: [
                // 1. Giờ xuất bến
                Text(
                  'GIỜ XUẤT BẾN',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.xs,
                  children: TimeSlot.values.map((slot) {
                    final isSelected = _selectedTimeSlots.contains(slot);
                    return FilterChip(
                      label: Text(slot.label),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      backgroundColor: AppColors.neutral50,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.neutral700,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.neutral200,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTimeSlots.add(slot);
                          } else {
                            _selectedTimeSlots.remove(slot);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppDimensions.lg),
                const Divider(),
                const SizedBox(height: AppDimensions.sm),

                // 2. Khoảng giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'KHOẢNG GIÁ',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral500,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Flexible(
                      child: Text(
                        '${CurrencyFormatter.format(_priceRange.start.round())} - ${CurrencyFormatter.format(_priceRange.end.round())}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 100000,
                  max: 500000,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.neutral200,
                  labels: RangeLabels(
                    CurrencyFormatter.formatSimple(_priceRange.start.round()),
                    CurrencyFormatter.formatSimple(_priceRange.end.round()),
                  ),
                  onChanged: (values) {
                    setState(() => _priceRange = values);
                  },
                ),

                const SizedBox(height: AppDimensions.md),
                const Divider(),
                const SizedBox(height: AppDimensions.sm),

                // 3. Nhà xe
                if (widget.availableOperators.isNotEmpty) ...[
                  Text(
                    'NHÀ XE',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  ...widget.availableOperators.map((operatorName) {
                    final isChecked = _selectedOperators.contains(operatorName);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(
                        operatorName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedOperators.add(operatorName);
                          } else {
                            _selectedOperators.remove(operatorName);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: AppDimensions.md),
                  const Divider(),
                  const SizedBox(height: AppDimensions.sm),
                ],

                // 4. Loại xe
                if (widget.availableVehicleTypes.isNotEmpty) ...[
                  Text(
                    'LOẠI XE',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  ...widget.availableVehicleTypes.map((vType) {
                    final isChecked = _selectedVehicleTypes.contains(vType);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(
                        vType,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedVehicleTypes.add(vType);
                          } else {
                            _selectedVehicleTypes.remove(vType);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: AppDimensions.md),
                  const Divider(),
                  const SizedBox(height: AppDimensions.sm),
                ],

                // 5. Tiện ích
                if (widget.availableAmenities.isNotEmpty) ...[
                  Text(
                    'TIỆN ÍCH TRÊN XE',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.xs,
                    children: widget.availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.neutral50,
                        labelStyle: AppTextStyles.bodySmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.neutral700,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.neutral200,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Apply Button
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'ÁP DỤNG BỘ LỌC',
                width: double.infinity,
                type: ButtonType.primary,
                onPressed: () {
                  final newFilter = TripFilterModel(
                    selectedTimeSlots: _selectedTimeSlots,
                    selectedOperators: _selectedOperators,
                    selectedVehicleTypes: _selectedVehicleTypes,
                    selectedAmenities: _selectedAmenities,
                    minPrice: _priceRange.start,
                    maxPrice: _priceRange.end,
                  );
                  Navigator.of(context).pop(newFilter);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
