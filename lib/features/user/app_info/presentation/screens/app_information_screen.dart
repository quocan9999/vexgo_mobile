import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';

Future<void> openAppInformation(BuildContext context, Widget page) =>
    Navigator.of(
      context,
      rootNavigator: true,
    ).push<void>(MaterialPageRoute(builder: (_) => page));

class AppInformationScreen extends StatelessWidget {
  const AppInformationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: TabPageHeader(
      title: context.l10n.uiAboutVexgo,
      showBackButton: true,
    ),
    body: ListView(
      children: [
        ListTile(
          minVerticalPadding: 16,
          leading: const Icon(Icons.directions_bus_outlined),
          title: Text(context.l10n.uiAboutVexgo532a39),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openAppInformation(context, const AboutVexGoScreen()),
        ),
        const Divider(height: 1, indent: 56),
        ListTile(
          minVerticalPadding: 16,
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(context.l10n.uiUserGuide),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openAppInformation(context, const BookingGuideScreen()),
        ),
      ],
    ),
  );
}

class AboutVexGoScreen extends StatelessWidget {
  const AboutVexGoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: TabPageHeader(
      title: context.l10n.uiAboutVexgo532a39,
      showBackButton: true,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.uiWithYouOnEveryJourney,
          style: DiscoveryTextStyles.h2,
        ),
        const SizedBox(height: 12),
        Text(context.l10n.uiVexgoIsAnOnlineBusBookingAppThat),
        const SizedBox(height: 24),
        Text(
          context.l10n.uiWhatCanYouDoWithVexgo,
          style: DiscoveryTextStyles.h4,
        ),
        const SizedBox(height: 12),
        Text(context.l10n.uiFindOneWayOrRoundTripsSelectSeats),
        const SizedBox(height: 24),
        Text(context.l10n.uiFaresSchedulesAndServiceConditionsAreShownFor),
      ],
    ),
  );
}

class BookingGuideScreen extends StatelessWidget {
  const BookingGuideScreen({super.key});
  static List<(String, String)> get topics => <(String, String)>[
    (
      LocaleController.strings.ui1FindATrip,
      LocaleController.strings.uiSelectYourOriginDestinationAndDepartureDateOn,
    ),
    (
      LocaleController.strings.ui2SelectSeatsAndStops,
      LocaleController.strings.uiSelectAvailableSeatsOnTheTripSSeat,
    ),
    (
      LocaleController.strings.ui3CheckPassengerDetailsAndOffers,
      LocaleController.strings.uiEnterContactDetailsToReceiveYourTicketCheck,
    ),
    (
      LocaleController.strings.ui4PayAndReceiveTickets,
      LocaleController.strings.uiUseTheBankDetailsAmountAndTransferReference,
    ),
    (
      LocaleController.strings.ui5LookUpTicketsAndReceipts,
      LocaleController.strings.uiOpenMyTicketsForTicketsLinkedToYour,
    ),
    (
      LocaleController.strings.ui6CancellationAndSupport,
      LocaleController.strings.uiOpenTicketDetailsAndCancelIfEligibleReview,
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: TabPageHeader(
      title: context.l10n.uiUserGuide,
      showBackButton: true,
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            context.l10n.uiFromFindingTripsToReceivingTicketsAndManaging,
          ),
        ),
        for (var i = 0; i < topics.length; i++)
          ExpansionTile(
            initiallyExpanded: i == 0,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Text(topics[i].$1, style: DiscoveryTextStyles.titleMedium),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(topics[i].$2)],
          ),
      ],
    ),
  );
}

class BookingGuideSection extends StatelessWidget {
  const BookingGuideSection({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.uiBookWithVexgo, style: DiscoveryTextStyles.h3),
        const SizedBox(height: 12),
        Text(
          context.l10n.ui1FindTheRightTrip2SelectSeats,
          style: TextStyle(height: 1.8),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                openAppInformation(context, const BookingGuideScreen()),
            child: Text(context.l10n.uiViewBookingGuide),
          ),
        ),
      ],
    ),
  );
}
