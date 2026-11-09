import 'package:vexgo_app/core/localization/locale_controller.dart';
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
                              context.l10n.uiRateYourTrip,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.uiClose,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (!valid)
                        Text(
                          context
                              .l10n
                              .uiYourAccountSessionHasChangedOpenTheReview,
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
                          if (review.isEdited) Text(context.l10n.uiEdited),
                          const SizedBox(height: 8),
                          Text(
                            review.comment.isEmpty
                                ? context.l10n.uiNoWrittenReview
                                : review.comment,
                          ),
                          if (review.replyContent != null) ...[
                            const Divider(height: 28),
                            Text(
                              context.l10n.uiReplyFrom(
                                review.responderName ??
                                    context.l10n.uiOperatore2807c,
                              ),
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
                                  label: Text(context.l10n.uiEditReview),
                                ),
                              TextButton.icon(
                                onPressed: busy || uncertain || failed
                                    ? null
                                    : () =>
                                          setState(() => _confirmDelete = true),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(context.l10n.uiDeleteReview),
                              ),
                            ],
                          ),
                          if (review.isEditable == false)
                            Text(context.l10n.uiThe3DayEditingPeriodHasEnded),
                        ],
                        if (_confirmDelete) ...[
                          const Divider(),
                          Text(context.l10n.uiDeleteThisReviewAndItsReplies),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(
                                        () => _confirmDelete = false,
                                      ),
                                child: Text(context.l10n.uiKeep),
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
                                child: Text(context.l10n.uiConfirmDeletion),
                              ),
                            ],
                          ),
                        ],
                        if (form) ...[
                          if (ApiConfig.isDemoMode) ...[
                            Text(context.l10n.uiWhatDidYouLikeMost),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
                                        context.l10n.uiOnTime,
                                        context.l10n.uiCleanVehicle,
                                        context.l10n.uiSafeDriving,
                                        context.l10n.uiHelpfulStaff,
                                        context.l10n.uiGoodAmenities,
                                        context.l10n.uiConvenientPickUpDropOff,
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
                            decoration: InputDecoration(
                              labelText: context.l10n.uiDetailedReview,
                              hintText: context.l10n.uiShareYourTripExperience,
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
                              review == null
                                  ? context.l10n.uiSubmitReview
                                  : context.l10n.uiSaveChanges,
                            ),
                          ),
                          if (review != null)
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _editing = false),
                              child: Text(context.l10n.uiCancelEditing),
                            ),
                        ],
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: busy ? null : _refresh,
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.uiRefreshReview),
                            ),
                            TextButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  scrollable: true,
                                  title: Text(context.l10n.uiAboutReviews),
                                  content: Text(
                                    context
                                        .l10n
                                        .uiSubmitAReviewWithin7DaysOfDeparture,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(context.l10n.uiGotIt),
                                    ),
                                  ],
                                ),
                              ),
                              icon: const Icon(Icons.info_outline),
                              label: Text(context.l10n.uiInformation),
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
