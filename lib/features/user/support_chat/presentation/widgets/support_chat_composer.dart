import 'package:flutter/material.dart';
import '../../../../../core/design/discovery_theme.dart';

class SupportChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final bool isEnabled;
  final bool isDense;
  final FocusNode? focusNode;

  const SupportChatComposer({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    this.isEnabled = true,
    this.isDense = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, isDense ? 2 : 8, 8, isDense ? 2 : 8),
      decoration: const BoxDecoration(
        color: DiscoveryColors.surface,
        border: Border(top: BorderSide(color: DiscoveryColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DiscoveryColors.neutral50,
                borderRadius: BorderRadius.circular(isDense ? 18 : 22),
                border: Border.all(color: DiscoveryColors.neutral200),
              ),
              child: TextField(
                key: const ValueKey('chat-composer'),
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: isDense ? 2 : 5,
                maxLength: 2000,
                enabled: isEnabled,
                onChanged: onChanged,
                style:
                    (isDense
                            ? DiscoveryTextStyles.bodySmall
                            : DiscoveryTextStyles.bodyMedium)
                        .copyWith(color: DiscoveryColors.neutral900),
                decoration: InputDecoration(
                  hintText: 'Nhắn tin cho nhà xe…',
                  hintStyle: TextStyle(
                    fontFamily: 'VexGoJakarta',
                    fontSize: isDense ? 12 : 14,
                    color: DiscoveryColors.neutral500,
                  ),
                  counterText: '',
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: isDense ? 6 : 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Gửi tin nhắn',
              icon: Icon(
                Icons.send_rounded,
                color: DiscoveryColors.primary,
                size: isDense ? 20 : 24,
              ),
              onPressed: isEnabled ? onSend : null,
            ),
          ),
        ],
      ),
    );
  }
}
