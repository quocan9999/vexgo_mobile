import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';

/// Renders AI assistant replies formatted in GitHub-Flavored Markdown while
/// preserving VexGo typography, selection/copy support, narrow-screen safety,
/// and strict link/image safety (never opens untrusted URLs or fetches remote
/// images from LLM output).
class AiChatbotMarkdownText extends StatelessWidget {
  final String data;
  final TextStyle baseStyle;
  final bool compact;

  const AiChatbotMarkdownText({
    super.key,
    required this.data,
    required this.baseStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = baseStyle.fontSize ?? 14.0;
    final styleSheet = MarkdownStyleSheet(
      p: baseStyle,
      pPadding: EdgeInsets.zero,
      // Keep inline styles as deltas so parent heading/bold/blockquote styles
      // are preserved when Markdown tags are nested (e.g. ## **Title**,
      // **bold *italic***, **~~strike~~**, ### [Link](url)).
      a: const TextStyle(),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      h1: baseStyle.copyWith(
        fontSize: fontSize + (compact ? 3 : 4),
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      h1Padding: const EdgeInsets.only(top: 4, bottom: 2),
      h2: baseStyle.copyWith(
        fontSize: fontSize + (compact ? 2 : 3),
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
      h2Padding: const EdgeInsets.only(top: 4, bottom: 2),
      h3: baseStyle.copyWith(
        fontSize: fontSize + (compact ? 1 : 2),
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      h3Padding: const EdgeInsets.only(top: 2, bottom: 2),
      h4: baseStyle.copyWith(
        fontSize: fontSize + 0.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      h4Padding: EdgeInsets.zero,
      h5: baseStyle.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      h5Padding: EdgeInsets.zero,
      h6: baseStyle.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: DiscoveryColors.neutral700,
        height: 1.4,
      ),
      h6Padding: EdgeInsets.zero,
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: fontSize * 0.9,
        color: DiscoveryColors.primaryDark,
        backgroundColor: DiscoveryColors.neutral100,
      ),
      codeblockPadding: EdgeInsets.all(compact ? 8 : 10),
      codeblockDecoration: BoxDecoration(
        color: DiscoveryColors.neutral100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      blockquote: baseStyle.copyWith(color: DiscoveryColors.neutral700),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: DiscoveryColors.primary, width: 3),
        ),
      ),
      blockSpacing: compact ? 6.0 : 8.0,
      listIndent: compact ? 16.0 : 20.0,
      listBullet: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: DiscoveryColors.primaryDark,
      ),
      listBulletPadding: const EdgeInsets.only(right: 6),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: DiscoveryColors.neutral200),
        ),
      ),
      tableHead: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: DiscoveryColors.neutral900,
      ),
      tableBody: baseStyle,
      tableHeadAlign: TextAlign.left,
      tablePadding: const EdgeInsets.only(bottom: 4),
      tableBorder: TableBorder.all(color: DiscoveryColors.neutral200),
      // IntrinsicColumnWidth automatically enables horizontal scrolling inside
      // flutter_markdown_plus so tables never overflow on 320dp @ 2.0x text.
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      tableHeadCellsDecoration: const BoxDecoration(
        color: DiscoveryColors.neutral100,
      ),
      tableCellsDecoration: const BoxDecoration(color: DiscoveryColors.surface),
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      shrinkWrap: true,
      fitContent: true,
      softLineBreak: true,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      styleSheet: styleSheet,
      // Intentionally ignore remote images from LLM text and render safe alt
      // text only to avoid unverified network fetches or layout breakage.
      imageBuilder: (uri, title, alt) {
        final fallback = (alt != null && alt.trim().isNotEmpty)
            ? alt.trim()
            : (title != null && title.trim().isNotEmpty ? title.trim() : '');
        if (fallback.isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(fallback, style: baseStyle);
      },
    );
  }
}
