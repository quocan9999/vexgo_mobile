import 'package:flutter/material.dart';
import '../../../../../core/design/discovery_theme.dart';
import '../../../../../data/models/support_chat_model.dart';

class SupportChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;
  final bool isSystem;
  final bool canSend;
  final VoidCallback? onRetry;

  const SupportChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.isSystem,
    this.canSend = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DiscoveryColors.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DiscoveryColors.neutral200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                message.content,
                textAlign: TextAlign.center,
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontFamily: 'VexGoJakarta',
                  fontSize: 10,
                  color: DiscoveryColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeStr = _formatTime(message.createdAt);
    final deliveryText = switch (message.delivery) {
      ChatDelivery.sending => 'Đang gửi…',
      ChatDelivery.failed => 'Chưa xác nhận gửi',
      ChatDelivery.sent => message.read ? 'Đã đọc' : 'Đã gửi',
    };

    final isFailed = isOwn && message.delivery == ChatDelivery.failed;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn ? DiscoveryColors.primaryLight : DiscoveryColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
          border: Border.all(
            color: isOwn
                ? DiscoveryColors.primary.withValues(alpha: 0.2)
                : DiscoveryColors.neutral200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOwn) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    size: 13,
                    color: DiscoveryColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Nhân viên hỗ trợ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'VexGoJakarta',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DiscoveryColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            SelectableText(
              message.type == 'HINH_ANH'
                  ? '[Hình ảnh] ${message.content}'
                  : message.content,
              style: DiscoveryTextStyles.bodyMedium.copyWith(
                color: DiscoveryColors.neutral900,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  '$timeStr${isOwn ? ' • $deliveryText' : ''}',
                  style: TextStyle(
                    fontFamily: 'VexGoJakarta',
                    fontSize: 10,
                    fontWeight: isOwn && message.read
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isFailed
                        ? DiscoveryColors.error
                        : DiscoveryColors.neutral600,
                  ),
                ),
                if (isOwn) ...[
                  if (message.delivery == ChatDelivery.sending)
                    const SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.2,
                        color: DiscoveryColors.neutral500,
                      ),
                    )
                  else if (message.delivery == ChatDelivery.sent)
                    Icon(
                      message.read
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: message.read
                          ? DiscoveryColors.primary
                          : DiscoveryColors.neutral500,
                    )
                  else if (isFailed)
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 12,
                      color: DiscoveryColors.error,
                    ),
                ],
              ],
            ),
            if (isFailed) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  foregroundColor: DiscoveryColors.error,
                ),
                onPressed: canSend ? onRetry : null,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text(
                  'Thử gửi lại',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
