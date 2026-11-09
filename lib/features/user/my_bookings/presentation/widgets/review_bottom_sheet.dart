import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';

class ReviewBottomSheet extends StatefulWidget {
  final TicketModel ticket;
  final MyTicketsBloc bloc;
  const ReviewBottomSheet({
    super.key,
    required this.ticket,
    required this.bloc,
  });
  static Future<void> show(
    BuildContext context,
    TicketModel ticket,
    MyTicketsBloc bloc,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReviewBottomSheet(ticket: ticket, bloc: bloc),
  );
  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  final _comment = TextEditingController();
  final _tags = <String>{};
  late final int _session, _token;
  bool _editing = false, _confirmDelete = false, _sent = false;
  int _rating = 5;
  @override
  void initState() {
    super.initState();
    _session = widget.bloc.sessionGeneration;
    _token = TokenStorage.sessionVersion;
    _editing = false;
    // The ticket snapshot lacks ownership/edit/reply metadata. Read the own endpoint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _active && !ApiConfig.isDemoMode) {
        widget.bloc.add(RefreshTicketReviewEvent(widget.ticket.id));
      }
    });
  }

  bool get _active =>
      !widget.bloc.isClosed &&
      widget.bloc.sessionGeneration == _session &&
      TokenStorage.sessionVersion == _token;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_active) widget.bloc.add(RefreshTicketReviewEvent(widget.ticket.id));
  }

  void _save(ReviewModel? current) {
    if (!_active || _comment.text.trim().length > 1000) return;
    final review = ReviewModel(
      rating: _rating,
      comment: _comment.text.trim(),
      tags: ApiConfig.isDemoMode ? _tags.toList() : const [],
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _sent = true);
    widget.bloc.add(
      current == null
          ? SubmitTicketReviewEvent(ticketId: widget.ticket.id, review: review)
          : UpdateTicketReviewEvent(ticketId: widget.ticket.id, review: review),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<void>(
    stream: TokenStorage.sessionChanges,
    builder: (_, _) => BlocConsumer<MyTicketsBloc, MyTicketsState>(
      bloc: widget.bloc,
      listener: (_, state) {
        if (_active &&
            _sent &&
            state.reviewTicketId == widget.ticket.id &&
            state.reviewStatus == TicketReviewStatus.succeeded) {
          setState(() {
            _editing = false;
            _confirmDelete = false;
            _sent = false;
          });
          _refresh();
        }
      },
      builder: (context, state) {
        final owned = state.tickets
            .where((t) => t.id == widget.ticket.id)
            .firstOrNull;
        final valid = _active && !state.requiresLogin && owned != null;
        final review = valid ? owned.review : null;
        final scoped = state.reviewTicketId == widget.ticket.id;
        final busy =
            scoped &&
            (state.reviewStatus == TicketReviewStatus.loading ||
                state.reviewStatus == TicketReviewStatus.submitting);
        final uncertain =
            widget.bloc.reviewUncertain(widget.ticket.id) ||
            scoped && state.reviewStatus == TicketReviewStatus.uncertain;
        final failed =
            scoped && state.reviewStatus == TicketReviewStatus.failed;
        final editable = review == null || review.isEditable == true;
        final form = review == null || _editing;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  (MediaQuery.sizeOf(context).height -
                          MediaQuery.viewInsetsOf(context).bottom -
                          MediaQuery.paddingOf(context).top -
                          12)
                      .clamp(0, double.infinity),
            ),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Đánh giá chuyến đi',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (!valid)
                        const Text(
                          'Phiên tài khoản đã thay đổi. Vui lòng mở lại đánh giá.',
                        )
                      else ...[
                        Text(owned.trip.operatorName),
                        const SizedBox(height: 12),
                        if (busy) const LinearProgressIndicator(),
                        if (scoped && state.reviewMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              state.reviewMessage!,
                              key: const Key('review-message'),
                            ),
                          ),
                        if (review != null && !form) ...[
                          Text(
                            '${review.rating}/5 sao',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (review.isEdited) const Text('Đã chỉnh sửa'),
                          const SizedBox(height: 8),
                          Text(
                            review.comment.isEmpty
                                ? 'Không có nội dung nhận xét.'
                                : review.comment,
                          ),
                          if (review.replyContent != null) ...[
                            const Divider(height: 28),
                            Text(
                              'Phản hồi từ ${review.responderName ?? 'nhà xe'}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(review.replyContent!),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (review.isEditable == true)
                                TextButton.icon(
                                  onPressed: busy || uncertain || failed
                                      ? null
                                      : () => setState(() {
                                          _rating = review.rating;
                                          _comment.text = review.comment;
                                          _editing = true;
                                        }),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Sửa đánh giá'),
                                ),
                              TextButton.icon(
                                onPressed: busy || uncertain || failed
                                    ? null
                                    : () =>
                                          setState(() => _confirmDelete = true),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Xóa đánh giá'),
                              ),
                            ],
                          ),
                          if (review.isEditable == false)
                            const Text('Đã hết thời hạn chỉnh sửa 3 ngày.'),
                        ],
                        if (_confirmDelete) ...[
                          const Divider(),
                          const Text('Xóa đánh giá và phản hồi kèm theo?'),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(
                                        () => _confirmDelete = false,
                                      ),
                                child: const Text('Giữ lại'),
                              ),
                              TextButton(
                                onPressed: busy || uncertain || failed
                                    ? null
                                    : () {
                                        if (!_active) return;
                                        setState(() => _sent = true);
                                        widget.bloc.add(
                                          DeleteTicketReviewEvent(
                                            widget.ticket.id,
                                          ),
                                        );
                                      },
                                child: const Text('Xác nhận xóa'),
                              ),
                            ],
                          ),
                        ],
                        if (form) ...[
                          if (ApiConfig.isDemoMode) ...[
                            const Text('Điểm bạn hài lòng nhất'),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
                                        'Đúng giờ',
                                        'Xe sạch sẽ',
                                        'Lái xe an toàn',
                                        'Nhân viên nhiệt tình',
                                        'Tiện nghi đầy đủ',
                                        'Đón trả thuận tiện',
                                      ]
                                      .map(
                                        (tag) => FilterChip(
                                          label: Text(tag),
                                          selected: _tags.contains(tag),
                                          onSelected: busy
                                              ? null
                                              : (value) => setState(() {
                                                  value
                                                      ? _tags.add(tag)
                                                      : _tags.remove(tag);
                                                }),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              5,
                              (i) => IconButton(
                                tooltip: '${i + 1} sao',
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed:
                                    busy || uncertain || failed || !editable
                                    ? null
                                    : () => setState(() => _rating = i + 1),
                                color: Colors.amber.shade700,
                                icon: Icon(
                                  i < _rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                ),
                              ),
                            ),
                          ),
                          TextField(
                            controller: _comment,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 1000,
                            enabled: !busy && !uncertain && !failed && editable,
                            decoration: const InputDecoration(
                              labelText: 'Nhận xét chi tiết',
                              hintText: 'Chia sẻ trải nghiệm chuyến đi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: busy || uncertain || failed || !editable
                                ? null
                                : () => _save(review),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: AppColors.primary,
                            ),
                            child: Text(
                              review == null ? 'Gửi đánh giá' : 'Lưu thay đổi',
                            ),
                          ),
                          if (review != null)
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _editing = false),
                              child: const Text('Hủy chỉnh sửa'),
                            ),
                        ],
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: busy ? null : _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tải lại đánh giá'),
                            ),
                            TextButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  scrollable: true,
                                  title: const Text('Về đánh giá'),
                                  content: const Text(
                                    'Gửi đánh giá trong 7 ngày kể từ khi khởi hành. Bạn có thể sửa trong 3 ngày sau khi gửi. Quyền sửa do máy chủ xác nhận. Bạn có thể xóa đánh giá của mình.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đã hiểu'),
                                    ),
                                  ],
                                ),
                              ),
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Thông tin'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
