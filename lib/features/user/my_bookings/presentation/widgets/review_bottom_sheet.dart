import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';

class ReviewBottomSheet extends StatefulWidget {
  final TicketModel ticket;
  final MyTicketsBloc bloc;

  const ReviewBottomSheet({
    super.key,
    required this.ticket,
    required this.bloc,
  });

  static Future<void> show(BuildContext context, TicketModel ticket, MyTicketsBloc bloc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewBottomSheet(ticket: ticket, bloc: bloc),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _rating = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  final Set<String> _selectedTags = {'Đúng giờ', 'Xe sạch sẽ'};

  final List<String> _availableTags = [
    'Đúng giờ',
    'Xe sạch sẽ',
    'Lái xe an toàn',
    'Nhân viên nhiệt tình',
    'Tiện nghi đầy đủ',
    'Đón trả thuận tiện',
  ];

  String _getRatingLabel(int star) {
    switch (star) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
      default:
        return 'Tuyệt vời';
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.base,
        AppDimensions.base,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.base,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.base),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đánh giá chuyến đi',
                          style: AppTextStyles.h4.copyWith(fontSize: 16),
                        ),
                        Text(
                          widget.ticket.trip.operatorName,
                          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.base),

              // Stars Selection
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = star),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 40,
                              color: isFilled ? AppColors.secondary : AppColors.neutral400,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getRatingLabel(_rating),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Quick Tags (Wrap for 360dp safety)
              Text(
                'Điểm bạn hài lòng nhất',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.neutral700,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: AppColors.neutral100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.neutral200,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.base),

              // Comment text field
              Text(
                'Nhận xét chi tiết',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn về tài xế, độ êm của xe, thái độ phục vụ...',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
                    final review = ReviewModel(
                      rating: _rating,
                      comment: _commentCtrl.text.trim().isEmpty
                          ? 'Dịch vụ ${_getRatingLabel(_rating).toLowerCase()}'
                          : _commentCtrl.text.trim(),
                      tags: _selectedTags.toList(),
                      createdAt: nowStr,
                    );

                    widget.bloc.add(SubmitTicketReviewEvent(
                      ticketId: widget.ticket.id,
                      review: review,
                    ));

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Gửi đánh giá',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
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
