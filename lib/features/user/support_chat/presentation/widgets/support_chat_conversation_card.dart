import 'package:flutter/material.dart';
import '../../../../../core/design/discovery_theme.dart';
import '../../../../../data/models/support_chat_model.dart';

class SupportChatConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const SupportChatConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = switch (conversation.status) {
      'CHO_TIEP_NHAN' => (
        bg: DiscoveryColors.warningLight,
        fg: DiscoveryColors.warningDark,
        icon: Icons.hourglass_top_rounded,
      ),
      'DANG_XU_LY' => (
        bg: DiscoveryColors.primaryLight,
        fg: DiscoveryColors.primary,
        icon: Icons.support_agent_rounded,
      ),
      'DA_DONG' => (
        bg: DiscoveryColors.neutral100,
        fg: DiscoveryColors.neutral600,
        icon: Icons.check_circle_outline_rounded,
      ),
      _ => (
        bg: DiscoveryColors.neutral100,
        fg: DiscoveryColors.neutral600,
        icon: Icons.info_outline_rounded,
      ),
    };

    final previewText = conversation.preview ?? conversation.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DiscoveryColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DiscoveryColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: DiscoveryColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.companyName,
                        style: DiscoveryTextStyles.h4.copyWith(
                          color: DiscoveryColors.neutral900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusConfig.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusConfig.icon,
                              size: 12,
                              color: statusConfig.fg,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                conversation.statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'VexGoJakarta',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusConfig.fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (previewText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          previewText,
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.neutral600,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: DiscoveryColors.neutral400,
                    size: 20,
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
