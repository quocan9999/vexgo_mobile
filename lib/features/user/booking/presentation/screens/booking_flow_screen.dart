import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../steps/step_1_seat_selection.dart';
import '../steps/step_2_pickup_point.dart';
import '../steps/step_3_dropoff_point.dart';
import '../steps/step_4_passenger_info.dart';
import '../steps/step_5_trip_summary.dart';
import '../steps/step_6_payment.dart';
import '../widgets/booking_bottom_bar.dart';
import '../widgets/booking_stepper.dart';

class BookingFlowScreen extends StatelessWidget {
  final TripModel trip;
  final DateTime date;
  final int ticketCount;

  const BookingFlowScreen({
    super.key,
    required this.trip,
    required this.date,
    this.ticketCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingFlowBloc(
        seatRepository: MockSeatRepository(),
        bookingRepository: MockBookingRepository(),
      )..add(InitBookingFlowEvent(
          trip: trip,
          date: date,
          ticketCount: ticketCount,
        )),
      child: const _BookingFlowContent(),
    );
  }
}

class _BookingFlowContent extends StatelessWidget {
  const _BookingFlowContent();

  Future<bool> _handlePop(BuildContext context, BookingFlowState state, BookingFlowBloc bloc) async {
    if (state.step.index > 0) {
      bloc.add(const PreviousStepEvent());
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thoát khỏi đặt vé?'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi tiến trình đặt vé này không? Các vị trí ghế bạn chọn sẽ không được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tiếp tục đặt vé'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Rời khỏi', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BookingFlowBloc>();

    return BlocConsumer<BookingFlowBloc, BookingFlowState>(
      listener: (context, state) {
        if (state.status == BookingFlowStatus.success && state.createdTicket != null) {
          context.pushReplacement(
            '/booking-success',
            extra: {'ticket': state.createdTicket},
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final trip = state.trip;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _handlePop(context, state, bloc);
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
          child: Scaffold(
            appBar: CustomAppBar(
              title: state.step.title,
              subtitle: trip != null ? '${trip.operatorName} • ${trip.fromCityName} -> ${trip.toCityName}' : null,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () async {
                  final shouldPop = await _handlePop(context, state, bloc);
                  if (shouldPop && context.mounted) {
                    context.pop();
                  }
                },
              ),
            ),
            body: state.status == BookingFlowStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Top Stepper
                      BookingStepper(
                        currentStep: state.step,
                        onStepTapped: (index) => bloc.add(GoToStepEvent(index)),
                      ),

                      // Step View Container
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildCurrentStepView(state, bloc),
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: state.status == BookingFlowStatus.loading
                ? null
                : BookingBottomBar(
                    state: state,
                    onNext: () => bloc.add(const NextStepEvent()),
                    onBack: () => bloc.add(const PreviousStepEvent()),
                    onConfirmPayment: () => bloc.add(const ConfirmPaymentEvent()),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStepView(BookingFlowState state, BookingFlowBloc bloc) {
    switch (state.step) {
      case BookingStep.seatSelection:
        return Step1SeatSelection(
          key: const ValueKey('step_1_seats'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.pickupPoint:
        return Step2PickupPoint(
          key: const ValueKey('step_2_pickup'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.dropoffPoint:
        return Step3DropoffPoint(
          key: const ValueKey('step_3_dropoff'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.passengerInfo:
        return Step4PassengerInfo(
          key: const ValueKey('step_4_passenger'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.tripSummary:
        return Step5TripSummary(
          key: const ValueKey('step_5_summary'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.payment:
        return Step6Payment(
          key: const ValueKey('step_6_payment'),
          state: state,
          bloc: bloc,
        );
    }
  }
}
