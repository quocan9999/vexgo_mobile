import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/data/models/city_model.dart';

class SelectCitySheet extends StatefulWidget {
  final String title;
  final List<CityModel> cities;
  final CityModel? currentCity;

  const SelectCitySheet({
    super.key,
    required this.title,
    required this.cities,
    this.currentCity,
  });

  static Future<CityModel?> show(
    BuildContext context, {
    required String title,
    required List<CityModel> cities,
    CityModel? currentCity,
  }) {
    return showModalBottomSheet<CityModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectCitySheet(
        title: title,
        cities: cities,
        currentCity: currentCity,
      ),
    );
  }

  @override
  State<SelectCitySheet> createState() => _SelectCitySheetState();
}

class _SelectCitySheetState extends State<SelectCitySheet> {
  late TextEditingController _searchController;
  List<CityModel> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCities = widget.cities;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cities;
      } else {
        _filteredCities = widget.cities.where((city) {
          final matchName = city.name.toLowerCase().contains(query);
          final matchStation = city.stations.any(
            (s) => s.name.toLowerCase().contains(query),
          );
          return matchName || matchStation;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final popularCities = widget.cities.where((c) => c.isPopular).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              margin: const EdgeInsets.only(
                top: AppDimensions.md,
                bottom: AppDimensions.xs,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DiscoveryColors.neutral300,
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
                    widget.title,
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DiscoveryColors.neutral600,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Tìm tỉnh thành, bến xe, văn phòng...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: DiscoveryColors.neutral400,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: DiscoveryColors.neutral500,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Content List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base,
              ),
              children: [
                // Popular Cities Chips (only when search query is empty)
                if (_searchController.text.isEmpty &&
                    popularCities.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: DiscoveryColors.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        'Địa điểm phổ biến',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          color: DiscoveryColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.xs,
                    children: popularCities.map((city) {
                      final isSelected = widget.currentCity?.id == city.id;
                      return ChoiceChip(
                        label: Text(city.name),
                        selected: isSelected,
                        selectedColor: DiscoveryColors.primaryLight,
                        backgroundColor: DiscoveryColors.neutral50,
                        labelStyle: DiscoveryTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? DiscoveryColors.primary
                              : DiscoveryColors.neutral700,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? DiscoveryColors.primary
                              : DiscoveryColors.neutral200,
                        ),
                        onSelected: (_) => Navigator.of(context).pop(city),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Divider(),
                  const SizedBox(height: AppDimensions.sm),
                ],

                // All Filtered Cities
                Text(
                  'Tất cả địa điểm',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),

                if (_filteredCities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.xxl,
                    ),
                    child: Center(
                      child: Text(
                        'Không tìm thấy địa điểm phù hợp',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          color: DiscoveryColors.neutral500,
                        ),
                      ),
                    ),
                  )
                else
                  ..._filteredCities.map((city) {
                    final isSelected = widget.currentCity?.id == city.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.xs),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DiscoveryColors.primaryLight.withValues(
                                alpha: 0.5,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          padding: const EdgeInsets.all(AppDimensions.xs + 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DiscoveryColors.primary
                                : DiscoveryColors.neutral100,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: isSelected
                                ? Colors.white
                                : DiscoveryColors.neutral600,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          city.name,
                          style: DiscoveryTextStyles.titleSmall.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? DiscoveryColors.primary
                                : DiscoveryColors.neutral900,
                          ),
                        ),
                        subtitle: Text(
                          '${city.region} • ${city.stations.length} bến xe/điểm đón',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(city),
                              child: Text(
                                'Chọn',
                                style: DiscoveryTextStyles.bodySmall.copyWith(
                                  color: DiscoveryColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                        children: city.stations.map((station) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 48,
                              right: 16,
                            ),
                            title: Text(
                              station.name,
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              station.address,
                              style: DiscoveryTextStyles.caption.copyWith(
                                color: DiscoveryColors.neutral400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.of(context).pop(city),
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
