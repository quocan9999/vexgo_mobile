import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';

class AiChatbotComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final bool canSend;
  final bool sending;
  final bool isDense;

  const AiChatbotComposer({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onSend,
    required this.canSend,
    required this.sending,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedRunes = controller.text.trim().runes.length;
    final overLimit = trimmedRunes > 2000;
    final showCounter = trimmedRunes >= 1500 || overLimit;

    return Container(
      decoration: const BoxDecoration(
        color: DiscoveryColors.surface,
        border: Border(top: BorderSide(color: DiscoveryColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, isDense ? 4 : 8, 8, isDense ? 4 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(isDense ? 18 : 22),
                        border: Border.all(
                          color: overLimit
                              ? DiscoveryColors.error
                              : DiscoveryColors.neutral200,
                        ),
                      ),
                      child: TextField(
                        key: const ValueKey('ai-chatbot-composer-input'),
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: isDense ? 2 : 5,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.newline,
                        style:
                            (isDense
                                    ? DiscoveryTextStyles.bodySmall
                                    : DiscoveryTextStyles.bodyMedium)
                                .copyWith(color: DiscoveryColors.neutral900),
                        decoration: InputDecoration(
                          labelText: context.l10n.uiQuestionForTheAiAssistant,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          hintText: context.l10n.uiAskAboutPoliciesBusTrips,
                          hintStyle: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: isDense ? 12 : 14,
                            color: DiscoveryColors.neutral500,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: isDense ? 8 : 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const ValueKey('ai-chatbot-send-btn'),
                      padding: EdgeInsets.zero,
                      tooltip: context.l10n.uiSendQuestion,
                      onPressed: canSend ? onSend : null,
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DiscoveryColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: canSend
                                  ? DiscoveryColors.primary
                                  : DiscoveryColors.neutral400,
                              size: isDense ? 20 : 24,
                            ),
                    ),
                  ),
                ],
              ),
              if (showCounter)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 6, right: 8),
                  child: Text(
                    overLimit
                        ? context.l10n.uiOverThe2000CharacterLimit2000Shorten(
                            trimmedRunes,
                          )
                        : context.l10n.ui2000Characters(trimmedRunes),
                    key: const ValueKey('ai-chatbot-char-counter'),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: overLimit
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: overLimit
                          ? DiscoveryColors.error
                          : DiscoveryColors.neutral600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
