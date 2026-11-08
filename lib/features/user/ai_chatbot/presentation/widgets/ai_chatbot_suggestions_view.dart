import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';

class AiChatbotSuggestionsView extends StatelessWidget {
  final List<AiSuggestion> suggestions;
  final bool loading;
  final String? error;
  final bool canInteract;
  final VoidCallback onRetry;
  final ValueChanged<AiSuggestion> onSelectSuggestion;
  final ValueChanged<AiSuggestion>? onFillDraftOnly;
  final bool compact;

  const AiChatbotSuggestionsView({
    super.key,
    required this.suggestions,
    required this.loading,
    required this.error,
    required this.canInteract,
    required this.onRetry,
    required this.onSelectSuggestion,
    this.onFillDraftOnly,
    this.compact = false,
  });

  static String categoryLabel(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'POLICY' || 'CHINH_SACH' => 'Chính sách',
      'LUGGAGE' || 'HANH_LY' => 'Hành lý',
      'BOOKING' || 'DAT_VE' => 'Đặt vé',
      'TRIP' || 'CHUYEN_XE' => 'Chuyến xe',
      'PAYMENT' || 'THANH_TOAN' => 'Thanh toán',
      'REFUND' || 'HUY_VE' => 'Hủy & hoàn tiền',
      'SHIPMENT' || 'GUI_HANG' => 'Gửi hàng',
      _ => raw.trim().isEmpty ? 'Gợi ý' : raw.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ai-chatbot-welcome-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIntroCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: DiscoveryColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Câu hỏi thường gặp',
                style: DiscoveryTextStyles.titleSmall.copyWith(
                  color: DiscoveryColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          Container(
            key: const Key('ai-chatbot-suggestions-loading'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DiscoveryColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: DiscoveryColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đang tải câu hỏi gợi ý…',
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (error != null)
          Container(
            key: const Key('ai-chatbot-suggestions-error'),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: DiscoveryColors.warningDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: const Key('ai-chatbot-suggestions-retry-btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: DiscoveryColors.primary,
                      side: const BorderSide(color: DiscoveryColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            ),
          )
        else if (suggestions.isEmpty)
          Container(
            key: const Key('ai-chatbot-suggestions-empty'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DiscoveryColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chưa có câu hỏi gợi ý sẵn. Bạn có thể nhập trực tiếp câu hỏi bên dưới.',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('ai-chatbot-suggestions-reload-btn'),
                  tooltip: 'Tải lại câu hỏi gợi ý',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: DiscoveryColors.primary,
                  ),
                ),
              ],
            ),
          )
        else
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(
                key: Key('ai-chatbot-suggestion-card-$index'),
                suggestion: item,
                enabled: canInteract,
                onTap: () => onSelectSuggestion(item),
                onFillDraft: onFillDraftOnly == null
                    ? null
                    : () => onFillDraftOnly!(item),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ExcludeSemantics(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: DiscoveryColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào! Tôi là Trợ lý AI VexGo',
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hỗ trợ giải đáp chính sách vé, hành lý đi kèm, gợi ý chuyến xe và hướng dẫn quy trình đặt vé.',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trợ lý AI chỉ cung cấp thông tin tham khảo và không tự động đặt vé, thanh toán, hủy vé hay thay đổi vận đơn.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      color: DiscoveryColors.neutral700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onFillDraft;

  const _SuggestionCard({
    super.key,
    required this.suggestion,
    required this.enabled,
    required this.onTap,
    this.onFillDraft,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = AiChatbotSuggestionsView.categoryLabel(
      suggestion.category,
    );

    return Material(
      color: DiscoveryColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DiscoveryColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        badgeText,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      suggestion.question,
                      style: DiscoveryTextStyles.bodyMedium.copyWith(
                        color: DiscoveryColors.neutral900,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (suggestion.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        suggestion.description,
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onFillDraft != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Chèn câu hỏi vào ô nhập',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onFillDraft,
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: DiscoveryColors.primary,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: DiscoveryColors.primary,
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
}
