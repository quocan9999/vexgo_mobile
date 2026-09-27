import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class PromoBannersSection extends StatelessWidget {
  const PromoBannersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final banners = [
      {
        'tag': 'ƯU ĐÃI THÀNH VIÊN MỚI',
        'title': 'Giảm ngay 20% cho chuyến xe đầu tiên',
        'subtitle': 'Nhập mã HELLOVEXGO • Tối đa 60.000đ',
        'gradient': [const Color(0xFF0060C4), const Color(0xFF003B7A)],
        'icon': Icons.card_giftcard_rounded,
      },
      {
        'tag': 'HOT DEAL TUẦN NÀY',
        'title': 'Tuyến Sài Gòn - Đà Lạt giảm 50.000đ',
        'subtitle': 'Áp dụng cho nhà xe Phương Trang & Thành Bưởi',
        'gradient': [const Color(0xFFFF6F00), const Color(0xFFD84315)],
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'tag': 'BẢO HIỂM CHUYẾN ĐI',
        'title': 'Cam kết giữ chỗ 100% an tâm',
        'subtitle': 'Đền bù gấp rưỡi nếu nhà xe không có chỗ',
        'gradient': [const Color(0xFF0F9D58), const Color(0xFF0B6F3E)],
        'icon': Icons.verified_user_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ưu đãi nổi bật',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Xem tất cả',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            itemCount: banners.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, index) {
              final item = banners[index];
              final gradientColors = item['gradient'] as List<Color>;

              return Container(
                width: 290,
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                            ),
                            child: Text(
                              item['tag'] as String,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Icon(
                          item['icon'] as IconData,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 22,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
