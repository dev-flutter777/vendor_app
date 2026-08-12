import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/notification/controllers/notification_controller.dart';
import 'package:sixvalley_vendor_app/features/product/domain/models/product_model.dart';
import 'package:sixvalley_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:sixvalley_vendor_app/features/order/controllers/order_controller.dart';
import 'package:sixvalley_vendor_app/features/product/controllers/product_controller.dart';
import 'package:sixvalley_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:sixvalley_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';
import 'package:sixvalley_vendor_app/features/home/widgets/completed_order_widget.dart';
import 'package:sixvalley_vendor_app/features/home/widgets/on_going_order_widget.dart';
import 'package:sixvalley_vendor_app/features/product/widgets/stock_out_product_widget.dart';
import 'package:sixvalley_vendor_app/features/notification/screens/notification_screen.dart';
import 'package:sixvalley_vendor_app/features/auth/widgets/seller_activation_banner_widget.dart';
import 'package:sixvalley_vendor_app/features/product/screens/most_popular_product_screen.dart';
import 'package:sixvalley_vendor_app/features/product/screens/top_selling_product_screen.dart';


class HomePageScreen extends StatefulWidget {
  final Function? callback;
  const HomePageScreen({super.key, this.callback});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final ScrollController _scrollController = ScrollController();
  Future<void> _loadData(BuildContext context, bool reload) async {
    Provider.of<ProfileController>(context, listen: false).getSellerInfo();
    if(Provider.of<OrderController>(context, listen: false).orderModel == null || reload) {
      Provider.of<OrderController>(context, listen: false).getOrderList(context,1,'all', null, reload: reload);
    }
    // This summary powers visible order-status cards, not the removed earnings screen.
    Provider.of<BankInfoController>(context, listen: false).getAnalyticsFilterData(context, 'overall');
    Provider.of<SplashController>(context,listen: false).getColorList();
    Provider.of<ProductController>(context,listen: false).getStockOutProductList(1, 'en', reload: reload);

    Provider.of<ProductController>(context,listen: false).getTopSellingProductList(1, context, 'en', reload: reload);
    // Financial, delivery, review, and seller-shipping data are admin-managed.
    // Do not request them from the vendor home screen after their UI was removed.
    Provider.of<NotificationController>(context, listen: false).getNotificationList(1);
    Provider.of<ProductController>(context, listen: false).getStockLimitStatus(context);
    Provider.of<ProductController>(context,listen: false).setShowCookie(true, notify: false);

    Provider.of<ProductController>(context,listen: false).getMostPopularProductList(1, context, 'en', reload: reload);

  }

  @override
  void initState() {
    _loadData(context, false);
    // Initialize the visible order-status filter; revenue charts remain removed.
    Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterName(context,'overall', false);
    Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterType(0, false);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    double limitedStockCardHeight = MediaQuery.of(context).size.width / 1.4;


    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.only(
      //       topRight: Radius.circular( isLtr ? Dimensions.radiusDefault : 0),
      //       topLeft: Radius.circular(isLtr ? 0 : Dimensions.radiusDefault),
      //       bottomLeft: const Radius.circular(Dimensions.radiusDefault),
      //       bottomRight: const Radius.circular(Dimensions.radiusDefault),
      //     ),
      //   ),
      //   child: const CustomAssetImageWidget(Images.tutorialFlowIcon, width: 20, height: 20),
      //   onPressed: () {
      //   }
      // ),

      body: Consumer<OrderController>(builder: (context, order, child) {
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh the visible order-status filter without restoring revenue charts.
              Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterName(context, 'overall',true);
              Provider.of<BankInfoController>(context, listen: false).setAnalyticsFilterType(0,true);
              await _loadData(context, true);
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  elevation: 0,
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  surfaceTintColor: Theme.of(context).highlightColor,
                  backgroundColor: Theme.of(context).highlightColor,
                  snap: true,
                  title: Image.asset(Images.logoWithAppName, height: 35),
                  actions: [
                    Consumer<NotificationController>(
                      builder: (context, notificationController, _) {
                        return InkWell(onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const NotificationScreen())),
                          child: Stack(
                            children: [
                              Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
                                child: Icon(CupertinoIcons.bell, color: Theme.of(context).primaryColor),
                              ),
                              Positioned(top: 5,right: 18,child: Align(alignment: Alignment.topRight,
                                child: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.error,
                                  radius: 8,child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: Builder(
                                        builder: (context) {
                                          final isAuctionEnabled = Provider.of<SplashController>(context, listen: false)
                                              .configModel?.isAuctionFeatureEnabled == true;
                                          final generalCount = notificationController.notificationModel?.newNotificationItem ?? 0;
                                          final auctionCount = isAuctionEnabled
                                              ? (notificationController.auctionNotificationModel?.newNotification ?? 0) : 0;
                                          return Text('${generalCount + auctionCount}',
                                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white),
                                          );
                                        },
                                      ),
                                    ),
                                  ),)
                                )
                              ),
                            ],
                          ),
                        );
                      }
                    )
                  ],
                ),

                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      const SellerActivationBannerWidget(),
                      OngoingOrderWidget(callback: widget.callback),

                      CompletedOrderWidget(callback: widget.callback),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Consumer<ProductController>(
                        builder: (context, prodProvider, child) {
                          List<Product> productList;
                          productList = prodProvider.stockOutProductList ?? [];
                          return productList.isNotEmpty ?
                          Container(
                            height: limitedStockCardHeight,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha:.05),
                                  spreadRadius: -3, blurRadius: 12, offset: Offset.fromDirection(0,6))],
                            ),
                            child: StockOutProductView( isHome: true)
                          ) : const SizedBox();
                        }
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      const TopSellingProductScreen(isMain: true),
                     // const SizedBox(height: Dimensions.paddingSizeSmall),

                      const MostPopularProductScreen(isMain: true),
                      // Earnings charts and delivery rankings are shown to admin only.
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                    ],
                  ),
                )
              ],
            ),
          );
        },

      ),
    );
  }
}







class TutorialFlowDialogWidget extends StatelessWidget {
  const TutorialFlowDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      color: Colors.red,
    );
  }
}
