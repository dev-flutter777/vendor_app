import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixvalley_vendor_app/helper/color_helper.dart';
import 'package:sixvalley_vendor_app/helper/price_converter.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:sixvalley_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:sixvalley_vendor_app/features/transaction/screens/transaction_screen.dart';
import 'package:sixvalley_vendor_app/features/wallet/widgets/wallet_card_widget.dart';
import 'package:sixvalley_vendor_app/features/wallet/widgets/wallet_transaction_list_view_widget.dart';
import 'package:sixvalley_vendor_app/features/wallet/widgets/withdraw_balance_widget.dart';
import 'package:sixvalley_vendor_app/features/wallet/screens/seller_balance_funding_screen.dart';
import 'package:sixvalley_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:sixvalley_vendor_app/features/wallet/domain/models/seller_balance_model.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class WalletScreen extends StatefulWidget {
  final bool fromNotification;
  const WalletScreen({super.key, this.fromNotification = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  
  @override
  void initState() {
    if(widget.fromNotification && Provider.of<ProfileController>(context, listen: false).userInfoModel == null) {
      Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletController>(context, listen: false).getSellerBalance(context);
    });

    super.initState();
  }
  final ScrollController _scrollController = ScrollController();


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {

        if(widget.fromNotification) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
            builder: (BuildContext context) => const DashboardScreen(),
          ), (route) => false);

        }else {
          if(!didPop) {
            Navigator.of(context).pop();
          }
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBarWidget(
          title: getTranslated('wallet', context),
          onBackPressed: () {
            if(widget.fromNotification) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen()));
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            Provider.of<TransactionController>(context, listen: false).getTransactionList(context,'all','','');
            Provider.of<ProfileController>(context, listen: false).getSellerInfo();
            await Provider.of<WalletController>(context, listen: false).getSellerBalance(context);
          },
          color: Theme.of(context).cardColor,
          backgroundColor: Theme.of(context).primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [

              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                child: Column(children: [
                  Consumer<ProfileController>(
                    builder: (context, seller, child) {
                      return seller.userInfoModel == null ? const SizedBox() : Column(children: [

                        seller.userInfoModel == null ? const SizedBox() : const WithdrawBalanceWidget(),

                        Consumer<WalletController>(
                          builder: (context, walletController, child) {
                            final balance = walletController.sellerBalance;
                            if (balance == null) return const SizedBox();
                            final cards = <Widget>[
                              _financialCard(context, balance.summary['sales_total'] ?? 0, 'sales_total', Colors.blue),
                              _financialCard(context, balance.summary['available'] ?? 0, 'available_balance', Colors.green),
                              _financialCard(context, balance.summary['pending'] ?? 0, 'pending_balance', Colors.orange),
                              _financialCard(context, balance.summary['operating'] ?? 0, 'operating_balance', Colors.deepPurple),
                              _financialCard(context, balance.summary['pending_withdraw'] ?? 0, 'pending_withdrawn', Colors.redAccent),
                              _financialCard(context, balance.summary['withdrawn'] ?? 0, 'withdrawn', Colors.grey),
                            ];
                            return Container(
                              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                              height: 76,
                              child: ListView(scrollDirection: Axis.horizontal, children: cards),
                            );
                          },
                        ),

                        Consumer<WalletController>(
                          builder: (context, walletController, child) {
                            final tabs = walletController.sellerBalance?.financialTabs ?? const <String, List<SellerFinancialRecord>>{};
                            return tabs.isEmpty ? const SizedBox() : _FinancialTabsCard(tabs: tabs);
                          },
                        ),

                        Consumer<WalletController>(
                          builder: (context, walletController, child) {
                            final records = walletController.sellerBalance?.records ?? const [];
                            if (records.isEmpty) return const SizedBox();
                            return Card(
                              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                              child: Padding(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(getTranslated('financial_records', context) ?? 'Financial records', style: robotoBold),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),
                                    ...records.take(5).map((record) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(record.eventType.isEmpty ? record.bucket : record.eventType),
                                      subtitle: Text(record.createdAt),
                                      trailing: Text(
                                        (record.direction == 'debit' ? '-' : '+') + record.amount.toStringAsFixed(2),
                                        style: TextStyle(color: record.direction == 'debit' ? Colors.red : Colors.green),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        Consumer<WalletController>(
                          builder: (context, walletController, child) {
                            final balance = walletController.sellerBalance;
                            if (balance == null) return const SizedBox();
                            return Card(
                              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                              child: ListTile(
                                leading: const Icon(Icons.add_card_outlined),
                                title: Text(getTranslated('operating_balance', context) ?? 'Operating balance'),
                                subtitle: Text(getTranslated('deposit_by_digital_or_manual', context) ?? 'Deposit by digital payment or manual transfer'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerBalanceFundingScreen())),
                              ),
                            );
                          },
                        ),

                        Container(
                          margin: const EdgeInsets.all(Dimensions.fontSizeSmall).copyWith(right: 0, top: Dimensions.paddingSizeDefault),
                          height: 76,
                          child: ListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            children: [

                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                  PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                  double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.withdrawn)
                                ) : 0.0)),
                                title: '${getTranslated('withdrawn', context)}',
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                              ),



                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.pendingWithdraw)
                                ) : 0.0)),
                                title: '${getTranslated('pending_withdrawn', context)}',
                                color: Theme.of(context).colorScheme.surfaceTint,
                              ),

                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                  PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                  double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.commissionGiven)
                                  ) : 0.0)),
                                title: '${getTranslated('commission_given', context)}',
                                color: ColorHelper.darken(Theme.of(context).colorScheme.tertiary, 0.1),
                              ),

                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                  PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                  double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.deliveryChargeEarned)
                                  ) : 0.0)),
                                title: '${getTranslated('delivery_charge_earned', context)}',
                                color: ColorHelper.darken(Theme.of(context).colorScheme.outline, 0.18),
                              ),

                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                  PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                  double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.collectedCash)
                                  ) : 0.0)),
                                title: '${getTranslated('collected_cash', context)}',
                                color: Theme.of(context).colorScheme.onTertiaryContainer
                              ),

                              WalletCardWidget(
                                amount: PriceConverter.showCurrencyCode(context,
                                  PriceConverter.longToShortPrice(seller.userInfoModel!.wallet != null ?
                                  double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.wallet!.totalTaxCollected)
                                  ) : 0.0)),
                                title: '${getTranslated('total_collected_tax', context)}',
                                color: Theme.of(context).colorScheme.error,
                              )
                            ],

                          ),
                        ),

                        if (seller.userInfoModel?.auctionWalletVisible == true) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Dimensions.fontSizeSmall,
                              Dimensions.paddingSizeDefault,
                              Dimensions.fontSizeSmall,
                              0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                getTranslated('auction_wallet', context)!,
                                style: robotoBold.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(Dimensions.fontSizeSmall).copyWith(right: 0, top: Dimensions.paddingSizeSmall),
                            height: 76,
                            child: ListView(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              children: [
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionTotalEarning ?? 0.0)))),
                                  title: getTranslated('auction_total_earning', context)!,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionTotalVat ?? 0.0)))),
                                  title: getTranslated('auction_total_vat', context)!,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionTotalShipping ?? 0.0)))),
                                  title: getTranslated('auction_total_shipping', context)!,
                                  color: ColorHelper.darken(Theme.of(context).colorScheme.outline, 0.18),
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionWithdrawableBalance ?? 0.0)))),
                                  title: getTranslated('auction_withdrawable_balance', context)!,
                                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionPendingWithdraw ?? 0.0)))),
                                  title: getTranslated('auction_pending_withdraw', context)!,
                                  color: Theme.of(context).colorScheme.surfaceTint,
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionTotalCommissionGiven ?? 0.0)))),
                                  title: getTranslated('auction_total_commission_given', context)!,
                                  color: ColorHelper.darken(Theme.of(context).colorScheme.tertiary, 0.1),
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionPendingCommission ?? 0.0)))),
                                  title: getTranslated('auction_pending_commission', context)!,
                                  color: ColorHelper.darken(Theme.of(context).colorScheme.tertiary, 0.2),
                                ),
                                WalletCardWidget(
                                  amount: PriceConverter.showCurrencyCode(context,
                                    PriceConverter.longToShortPrice(
                                      double.parse(PriceConverter.convertPriceWithoutSymbol(context, seller.userInfoModel!.auctionTotalPendingAmount ?? 0.0)))),
                                  title: getTranslated('auction_total_pending_amount', context)!,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                        ],

                      ]);
                    }
                  ),

                  const _TransactionTitleRowWidget(),

                  Consumer<TransactionController>(
                    builder: (context, transactionProvider, child) {
                      return  Container(
                        child: transactionProvider.transactionList !=null ? transactionProvider.transactionList!.isNotEmpty ?
                        WalletTransactionListViewWidget(transactionProvider: transactionProvider, limit: 10) : const NoDataScreen()
                          : Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
                      );
                    }
                  ),
                ]),
              ))
            ],
          ),
        ),
      ),
    );
  }
}

Widget _financialCard(BuildContext context, double amount, String titleKey, Color color) {
  return WalletCardWidget(
    amount: PriceConverter.showCurrencyCode(context, PriceConverter.longToShortPrice(amount)),
    title: getTranslated(titleKey, context) ?? titleKey,
    color: color,
  );
}

class _FinancialTabsCard extends StatelessWidget {
  final Map<String, List<SellerFinancialRecord>> tabs;
  const _FinancialTabsCard({required this.tabs});

  @override
  Widget build(BuildContext context) {
    const keys = ['balance', 'insurance', 'shipping'];
    return DefaultTabController(
      length: keys.length,
      child: Card(
        margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: Column(children: [
          TabBar(
            isScrollable: true,
            tabs: keys.map((key) => Tab(text: '${getTranslated(key == 'insurance' ? 'order_insurance' : key, context) ?? key} (${tabs[key]?.length ?? 0})')).toList(),
          ),
          SizedBox(
            height: 230,
            child: TabBarView(children: keys.map((key) {
              final records = tabs[key] ?? const <SellerFinancialRecord>[];
              if (records.isEmpty) return Center(child: Text(getTranslated('no_data_found', context) ?? 'No data'));
              return ListView(children: records.take(10).map((record) => ListTile(
                dense: true,
                title: Text(record.eventType),
                subtitle: Text([record.referenceCode, record.shipmentReference, record.dueAt].where((value) => value.isNotEmpty).join(' • ')),
                trailing: Text('${record.direction == 'debit' ? '-' : '+'}${record.amount.toStringAsFixed(2)}', style: TextStyle(color: record.direction == 'debit' ? Colors.red : Colors.green)),
              )).toList());
            }).toList()),
          ),
        ]),
      ),
    );
  }
}


class _TransactionTitleRowWidget extends StatelessWidget {
  const _TransactionTitleRowWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeMedium, Dimensions.paddingSizeSmall, Dimensions.paddingSizeMedium, Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        Text(getTranslated('withdraw_history', context)!, style: robotoBold.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.50),
            fontSize: Dimensions.fontSizeDefault
        )),

        InkWell(
          onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionScreen())),
          child: Row(children: [
            Text(getTranslated('view_all', context)!, style: robotoBold.copyWith(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: Dimensions.fontSizeSmall,
            )),
            const SizedBox(width: Dimensions.paddingSizeVeryTiny),

            Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSecondary, size: Dimensions.paddingSize)
          ]),
        )
      ]),
    );
  }
}
