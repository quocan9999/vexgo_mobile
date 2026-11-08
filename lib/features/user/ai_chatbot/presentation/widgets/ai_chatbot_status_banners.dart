import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';

class AiChatbotUncertainBanner extends StatelessWidget {
  final String? message;
  final bool hasKnownSession;
  final bool loadingHistory;
  final VoidCallback onReadHistory;
  final VoidCallback onNewConversationKeepDraft;
  final VoidCallback onNewConversationClearDraft;

  const AiChatbotUncertainBanner({
    super.key,
    required this.message,
    required this.hasKnownSession,
    required this.loadingHistory,
    required this.onReadHistory,
    required this.onNewConversationKeepDraft,
    required this.onNewConversationClearDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('ai-chatbot-uncertain-banner'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DiscoveryColors.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DiscoveryColors.warning.withValues(alpha: 0.45),
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
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: DiscoveryColors.warningDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message ??
                        'Chưa xác định được câu hỏi đã xử lý hay chưa. Giữ lại bản nháp; không gửi lại tự động.',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral900,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasKnownSession
                  ? 'Bạn có thể kiểm tra các phản hồi đã lưu của phiên hiện tại trước, hoặc chủ động bắt đầu hội thoại mới. Lưu ý: câu hỏi vừa gửi có thể đã được máy chủ tiếp nhận.'
                  : 'Do phản hồi đầu tiên bị gián đoạn trước khi nhận mã phiên nên chưa thể đối chiếu lịch sử trên máy chủ. Bạn có thể bắt đầu hội thoại mới và giữ lại câu hỏi nháp.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                color: DiscoveryColors.neutral700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasKnownSession)
                  OutlinedButton.icon(
                    key: const Key('ai-chatbot-uncertain-history-btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: DiscoveryColors.primaryDark,
                      backgroundColor: DiscoveryColors.surface,
                      side: const BorderSide(color: DiscoveryColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: loadingHistory ? null : onReadHistory,
                    icon: loadingHistory
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DiscoveryColors.primary,
                            ),
                          )
                        : const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Kiểm tra phản hồi đã lưu'),
                  ),
                ElevatedButton.icon(
                  key: const Key('ai-chatbot-uncertain-new-keep-btn'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: DiscoveryColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onNewConversationKeepDraft,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Hội thoại mới (Giữ nháp)'),
                ),
                TextButton(
                  key: const Key('ai-chatbot-uncertain-new-clear-btn'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: DiscoveryColors.neutral700,
                  ),
                  onPressed: onNewConversationClearDraft,
                  child: const Text('Hội thoại mới (Xóa nháp)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AiChatbotErrorBanner extends StatelessWidget {
  final String error;

  const AiChatbotErrorBanner({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('ai-chatbot-error-banner'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DiscoveryColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DiscoveryColors.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: DiscoveryColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.errorDark,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiChatbotHistoryCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final AiChatHistory? snapshot;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSupportChat;

  const AiChatbotHistoryCard({
    super.key,
    required this.loading,
    required this.error,
    required this.snapshot,
    required this.onRefresh,
    required this.onOpenSupportChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ai-chatbot-history-card'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.history_edu_outlined,
                  size: 18,
                  color: DiscoveryColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bản ghi phản hồi từ máy chủ (Chỉ đọc)',
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    color: DiscoveryColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('ai-chatbot-history-refresh-btn'),
                tooltip: 'Tải lại phản hồi đã lưu',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DiscoveryColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: DiscoveryColors.primary,
                      ),
              ),
            ],
          ),
          Text(
            'Bản ghi chỉ đọc từ máy chủ (hiển thị các tin nhắn đã lưu của phiên này); không tự thay thế hội thoại trên máy hoặc tự mở khóa câu hỏi đang gián đoạn.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              color: DiscoveryColors.neutral600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (loading && snapshot == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Đang tải lịch sử phản hồi…'),
            )
          else if (error != null)
            Container(
              key: const Key('ai-chatbot-history-error'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                error!,
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.errorDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (snapshot != null) ...[
            if (snapshot!.messages.isEmpty)
              Text(
                'Chưa có phản hồi nào được lưu trong phiên này.',
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral700,
                ),
              )
            else
              ...snapshot!.messages.asMap().entries.map((entry) {
                final mIdx = entry.key;
                final msg = entry.value;
                return Container(
                  key: Key('ai-chatbot-history-msg-$mIdx'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DiscoveryColors.neutral200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            msg.role == 'ASSISTANT'
                                ? 'Trợ lý AI'
                                : msg.role == 'USER'
                                ? 'Người dùng'
                                : 'Hệ thống',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.primaryDark,
                            ),
                          ),
                          Text(
                            _formatClock(msg.createdAt),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: DiscoveryColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        msg.content,
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral900,
                          height: 1.4,
                        ),
                      ),
                      if (msg.citations.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Nguồn: ${msg.citations.map((c) => '${c.documentCode} (${c.title})').join('; ')}',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: DiscoveryColors.neutral600,
                          ),
                        ),
                      ],
                      if (msg.suggestedTrips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...msg.suggestedTrips.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• ${t.operator} (${t.code}): ${t.origin} → ${t.destination} • ${t.departureTime} • ${t.price != null ? CurrencyFormatter.format(t.price!) : 'Chưa có giá'}',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                color: DiscoveryColors.neutral700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (msg.requiresHumanHandoff) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: DiscoveryColors.primary,
                            ),
                            onPressed: onOpenSupportChat,
                            icon: const Icon(
                              Icons.support_agent_rounded,
                              size: 16,
                            ),
                            label: const Text('Chat với nhân viên'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  String _formatClock(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
