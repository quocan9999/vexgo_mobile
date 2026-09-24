import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class ServiceGuaranteeSection extends StatelessWidget {
  const ServiceGuaranteeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final guarantees = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Chắc chắn có chỗ 100%',
        'desc': 'Hoàn tiền 150% nếu nhà xe không giữ đúng chỗ của bạn.',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Hỗ trợ khách hàng 24/7',
        'desc': 'Tổng đài viên luôn sẵn sàng giải đáp và xử lý phát sinh trên hành trình.',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.price_check_rounded,
        'title': 'Nhiều ưu đãi & Giá minh bạch',
        'desc': 'Giá vé niêm yết rõ ràng từ nhà xe, không phụ phí ẩn.',
        'color': AppColors.success,
      },
      {
        'icon': Icons.qr_code_2_rounded,
        'title': 'Vé điện tử nhanh chóng',
        'desc': 'Lên xe chỉ với một chạm quét mã QR trên điện thoại.',
        'color': const Color(0xFF7928CA),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cam kết dịch vụ từ VexGo',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...guarantees.map((g) {
            final color = g['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Icon(g['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['title'] as String,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g['desc'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
