import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import '../screens/ai_chatbot_screen.dart';

/// Entry card / tile for opening [AiChatbotScreen] from Support / Home sections
/// without adding a bottom navigation tab.
class AiChatbotEntryCard extends StatelessWidget {
  static const String routePath = '/ai-chatbot';

  final VoidCallback? onTap;
  final int? companyId;
  final bool compact;

  const AiChatbotEntryCard({
    super.key,
    this.onTap,
    this.companyId,
    this.compact = false,
  });

  void _defaultOpen(BuildContext context) {
    try {
      context.push(routePath, extra: companyId);
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AiChatbotScreen(initialCompanyId: companyId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DiscoveryColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('ai-chatbot-entry-card'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () => _defaultOpen(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DiscoveryColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const ExcludeSemantics(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: DiscoveryColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ lý AI',
                      style: DiscoveryTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hỏi đáp chính sách vé, hành lý và gợi ý chuyến xe',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: DiscoveryColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
