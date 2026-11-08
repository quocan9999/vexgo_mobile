import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';

class AiChatbotExchangeItem extends StatefulWidget {
  final int exchangeIndex;
  final AiChatExchange exchange;
  final bool canInteract;
  final int? verifyingTripId;
  final ValueChanged<AiSuggestedTrip> onSelectTrip;
  final ValueChanged<String> onSelectFollowUpQuestion;
  final VoidCallback onOpenSupportChat;

  const AiChatbotExchangeItem({
    super.key,
    required this.exchangeIndex,
    required this.exchange,
    required this.canInteract,
    required this.verifyingTripId,
    required this.onSelectTrip,
    required this.onSelectFollowUpQuestion,
    required this.onOpenSupportChat,
  });

  @override
  State<AiChatbotExchangeItem> createState() => _AiChatbotExchangeItemState();
}

class _AiChatbotExchangeItemState extends State<AiChatbotExchangeItem> {
  bool _citationsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final idx = widget.exchangeIndex;
    final question = widget.exchange.question;
    final answer = widget.exchange.answer;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth < 360
        ? screenWidth - 28
        : screenWidth * 0.88;

    return Column(
      key: Key('ai-chatbot-exchange-$idx'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Question Bubble
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: Key('ai-chatbot-user-bubble-$idx'),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: DiscoveryColors.primaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(
                color: DiscoveryColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  question,
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral900,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Assistant Reply Bubble + Attachments
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: Key('ai-chatbot-assistant-bubble-$idx'),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DiscoveryColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: DiscoveryColors.neutral200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.smart_toy_outlined,
                        size: 16,
                        color: DiscoveryColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Trợ lý AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: DiscoveryColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  answer.reply,
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral900,
                    height: 1.5,
                  ),
                ),

                // Expandable Citations (Internal knowledge base sources, not web links)
                if (answer.citations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCitationsSection(idx, answer.citations),
                ],

                // Suggested Trips
                if (answer.suggestedTrips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSuggestedTripsSection(idx, answer.suggestedTrips),
                ],

                // Human Handoff CTA
                if (answer.requiresHumanHandoff) ...[
                  const SizedBox(height: 12),
                  _buildHumanHandoffCard(idx, answer.handoffReason),
                ],

                // Suggested Follow-up Questions
                if (answer.suggestedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSuggestedQuestionsSection(
                    idx,
                    answer.suggestedQuestions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCitationsSection(int idx, List<AiCitation> citations) {
    return Container(
      key: Key('ai-chatbot-citations-box-$idx'),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            toggled: _citationsExpanded,
            label: 'Nguồn tham khảo nội bộ (${citations.length})',
            child: InkWell(
              key: Key('ai-chatbot-citations-toggle-$idx'),
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  setState(() => _citationsExpanded = !_citationsExpanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 16,
                          color: DiscoveryColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nguồn tham khảo (${citations.length})',
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.neutral900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        _citationsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: DiscoveryColors.neutral700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_citationsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 12, color: DiscoveryColors.neutral200),
                  Text(
                    'Tài liệu quy định nội bộ (không phải đường dẫn web):',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...citations.asMap().entries.map((entry) {
                    final cIndex = entry.key;
                    final citation = entry.value;
                    return Container(
                      key: Key('ai-chatbot-citation-$idx-$cIndex'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DiscoveryColors.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DiscoveryColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  citation.documentCode,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: DiscoveryColors.primaryDark,
                                  ),
                                ),
                              ),
                              Text(
                                citation.title,
                                style: DiscoveryTextStyles.bodySmall.copyWith(
                                  color: DiscoveryColors.neutral900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            citation.hierarchyPath,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: DiscoveryColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTripsSection(int idx, List<AiSuggestedTrip> trips) {
    return Column(
      key: Key('ai-chatbot-trips-section-$idx'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.directions_bus_outlined,
                size: 16,
                color: DiscoveryColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Chuyến xe gợi ý (${trips.length})',
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Giá và số chỗ trống dưới đây là thông tin gợi ý; hệ thống sẽ tải lại chuyến xe từ máy chủ khi bạn chọn.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            color: DiscoveryColors.neutral600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        ...trips.asMap().entries.map((entry) {
          final tIndex = entry.key;
          final trip = entry.value;
          final isVerifying = widget.verifyingTripId == trip.tripId;
          return Container(
            key: Key('ai-chatbot-trip-card-$idx-$tIndex'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      trip.operator,
                      style: DiscoveryTextStyles.bodyMedium.copyWith(
                        color: DiscoveryColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Text(
                        'Mã: ${trip.code}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${trip.origin} → ${trip.destination}',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Ngày đi: ${_formatIsoDate(trip.departureDate)}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral700,
                      ),
                    ),
                    Text(
                      trip.arrivalTime != null
                          ? 'Giờ: ${trip.departureTime} - ${trip.arrivalTime}'
                          : 'Giờ khởi hành: ${trip.departureTime}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Loại xe: ${trip.vehicleType}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral700,
                      ),
                    ),
                    Text(
                      'Chỗ trống tham khảo: ${trip.availableSeats}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      trip.price != null
                          ? CurrencyFormatter.format(trip.price!)
                          : 'Chưa có giá',
                      key: Key('ai-chatbot-trip-price-$idx-$tIndex'),
                      style: DiscoveryTextStyles.titleSmall.copyWith(
                        color: trip.price != null
                            ? DiscoveryColors.secondaryDark
                            : DiscoveryColors.neutral600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        key: Key('ai-chatbot-trip-select-btn-$idx-$tIndex'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DiscoveryColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            (widget.canInteract &&
                                widget.verifyingTripId == null)
                            ? () => widget.onSelectTrip(trip)
                            : null,
                        icon: isVerifying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                        label: Text(
                          isVerifying
                              ? 'Đang kiểm tra chuyến…'
                              : 'Xem & chọn chuyến',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHumanHandoffCard(int idx, String? handoffReason) {
    return Container(
      key: Key('ai-chatbot-handoff-card-$idx'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DiscoveryColors.info.withValues(alpha: 0.35),
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
                  Icons.support_agent_rounded,
                  size: 18,
                  color: DiscoveryColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gợi ý trao đổi trực tiếp với nhân viên hỗ trợ',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống chỉ gợi ý chuyển tiếp và chưa tự động kết nối hay gửi nội dung cho nhân viên khi bạn chưa bấm nút bên dưới.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              color: DiscoveryColors.neutral700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              key: Key('ai-chatbot-handoff-btn-$idx'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: DiscoveryColors.primary,
                backgroundColor: DiscoveryColors.surface,
                side: const BorderSide(color: DiscoveryColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: widget.onOpenSupportChat,
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text(
                'Chat với nhân viên',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestionsSection(int idx, List<String> questions) {
    return Column(
      key: Key('ai-chatbot-followup-section-$idx'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gợi ý hỏi tiếp:',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: DiscoveryColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: questions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final question = entry.value;
            return ActionChip(
              key: Key('ai-chatbot-followup-chip-$idx-$qIndex'),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: DiscoveryColors.neutral50,
              side: const BorderSide(color: DiscoveryColors.neutral300),
              label: Text(
                question,
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: widget.canInteract
                  ? () => widget.onSelectFollowUpQuestion(question)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatIsoDate(String iso) {
    final parts = iso.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return iso;
  }
}

class AiChatbotPendingExchange extends StatelessWidget {
  final String pendingQuestion;

  const AiChatbotPendingExchange({super.key, required this.pendingQuestion});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth < 360
        ? screenWidth - 28
        : screenWidth * 0.88;

    return Column(
      key: const Key('ai-chatbot-pending-exchange'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingQuestion.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              key: const Key('ai-chatbot-pending-user-bubble'),
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DiscoveryColors.primaryLight.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: DiscoveryColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn • Đang gửi…',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pendingQuestion,
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral900,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const Key('ai-chatbot-typing-indicator'),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: DiscoveryColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DiscoveryColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Trợ lý AI đang trả lời…',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
