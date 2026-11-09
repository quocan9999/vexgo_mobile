import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/repositories/public_promotion_repository.dart';

class AvailableOffersSection extends StatefulWidget {
  final List<OperatorModel> operators;
  final PublicPromotionRepository? repository;
  final bool preview;
  final String? initialCompanyId;
  const AvailableOffersSection({
    super.key,
    required this.operators,
    this.repository,
    this.preview = true,
    this.initialCompanyId,
  });
  @override
  State<AvailableOffersSection> createState() => _AvailableOffersSectionState();
}

class _AvailableOffersSectionState extends State<AvailableOffersSection> {
  late final PublicPromotionRepository _repository =
      widget.repository ?? PublicPromotionRepository();
  String? _companyId;
  Future<List<PublicPromotion>>? _future;
  List<OperatorModel> get _companies =>
      widget.operators.where((o) => (int.tryParse(o.id) ?? 0) > 0).toList();
  @override
  void initState() {
    super.initState();
    _syncCompany();
  }

  @override
  void didUpdateWidget(AvailableOffersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCompany();
  }

  void _syncCompany() {
    final companies = _companies;
    if (companies.isEmpty) {
      _companyId = null;
      _future = null;
      return;
    }
    if (_companyId != null && companies.any((o) => o.id == _companyId)) return;
    _companyId = companies.any((o) => o.id == widget.initialCompanyId)
        ? widget.initialCompanyId
        : companies.first.id;
    _future = _repository.getAvailable(int.parse(_companyId!));
  }

  void _load(String id) => setState(() {
    _companyId = id;
    _future = _repository.getAvailable(int.parse(id));
  });

  @override
  Widget build(BuildContext context) {
    final companies = _companies;
    if (companies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.uiOperatorOffers,
                  style: DiscoveryTextStyles.h3,
                ),
              ),
              IconButton(
                tooltip: context.l10n.uiRefreshOffers,
                onPressed: () => _load(_companyId!),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (companies.length == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(companies.first.name),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(_companyId),
              initialValue: _companyId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.uiBusOperator,
                border: UnderlineInputBorder(),
              ),
              items: [
                for (final company in companies)
                  DropdownMenuItem(
                    value: company.id,
                    child: Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) _load(id);
              },
            ),
          const SizedBox(height: 12),
          FutureBuilder<List<PublicPromotion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.uiUnableToLoadThisOperatorSOffers),
                    TextButton(
                      onPressed: () => _load(_companyId!),
                      child: Text(context.l10n.uiRetryOffers),
                    ),
                  ],
                );
              }
              final offers = snapshot.data ?? const [];
              if (offers.isEmpty) {
                return Text(
                  context.l10n.uiThereAreNoCurrentOffersForThisOperator,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final offer
                      in (widget.preview ? offers.take(2) : offers))
                    _OfferDetails(
                      offer: offer,
                      key: ValueKey('$_companyId:${offer.code}'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.uiEligibilityIsCheckedAgainWhenYouBook,
                    style: DiscoveryTextStyles.caption,
                  ),
                  if (widget.preview && offers.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.white,
                                  appBar: TabPageHeader(
                                    title: context.l10n.uiOperatorOffers,
                                    showBackButton: true,
                                  ),
                                  body: SingleChildScrollView(
                                    child: AvailableOffersSection(
                                      operators: companies,
                                      initialCompanyId: _companyId,
                                      repository: _repository,
                                      preview: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        child: Text(
                          context.l10n.uiViewAllOffers(offers.length),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OfferDetails extends StatelessWidget {
  final PublicPromotion offer;
  const _OfferDetails({super.key, required this.offer});
  String _date(String value) {
    final p = value.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : value;
  }

  @override
  Widget build(BuildContext context) {
    final discount = offer.discountType == 'PHAN_TRAM'
        ? '${offer.discountValue.toStringAsFixed(offer.discountValue % 1 == 0 ? 0 : 2)}%'
        : CurrencyFormatter.format(offer.discountValue);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DiscoveryColors.neutral200)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(offer.name, style: DiscoveryTextStyles.titleMedium),
        subtitle: Text(context.l10n.uiSaveCode(discount, offer.code)),
        children: [
          if (offer.minimumTicketAmount != null &&
              offer.minimumTicketAmount! > 0)
            Text(
              context.l10n.uiMinimumFare(
                CurrencyFormatter.format(offer.minimumTicketAmount),
              ),
            ),
          if (offer.maxDiscount != null)
            Text(
              context.l10n.uiMaximumDiscount(
                CurrencyFormatter.format(offer.maxDiscount),
              ),
            ),
          Text(
            context.l10n.uiValid(_date(offer.startsOn), _date(offer.endsOn)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(context.l10n.uiCopyCode30ae06(offer.code)),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: offer.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.uiOfferCodeCopied)),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
