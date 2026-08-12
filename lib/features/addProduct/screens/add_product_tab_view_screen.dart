import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/edt_product_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/product_general_info_data_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_next_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_seo_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/widgets/add_product_tabbar_widget.dart';
import 'package:sixvalley_vendor_app/features/ai/widgets/genertate_count_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/seller_activation_ticket_screen.dart';
import 'package:sixvalley_vendor_app/features/product/domain/models/product_model.dart';
import 'package:sixvalley_vendor_app/features/seller_package/controllers/seller_package_controller.dart';
import 'package:sixvalley_vendor_app/features/seller_package/screens/seller_package_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';

class AddProductTabView extends StatefulWidget {
  final Product? product;
  final AddProductModel? addProduct;
  final EditProductModel? editProduct;
  final bool fromHome;
  const AddProductTabView({super.key, this.product, this.addProduct, this.editProduct, required this.fromHome});

  @override
  State<AddProductTabView> createState() => _AddProductTabViewState();
}

class _AddProductTabViewState extends State<AddProductTabView>  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AddProductScreenState> _firstTabKey = GlobalKey<AddProductScreenState>();
  final GlobalKey<AddProductNextScreenState> _secondTabKey = GlobalKey<AddProductNextScreenState>();

  ProductGeneralInfoData? productGeneralInfoData;
  ProductCombinedData? productCombinedData;
  bool _eligibilityChecked = false;
  bool _canAddNewProduct = true;
  String? _eligibilityReason;
  String? _eligibilityAction;

  List<Tab> _productTabs(BuildContext context) => <Tab>[
    Tab(text: getTranslated('general_info', context), icon: const Icon(Icons.info_outline)),
    Tab(text: getTranslated('variation_setup', context), icon: const Icon(Icons.color_lens_outlined)),
    Tab(text: getTranslated('product_seo', context), icon: const Icon(Icons.search)),
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.product == null) {
      // Every new-product entry point reaches this screen, so the check cannot be bypassed from another menu.
      Future.microtask(_checkNewProductEligibility);
    } else {
      _eligibilityChecked = true;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchDataFromFirstTab();
          _fetchDataFromSecondTab();
        });
      }
    });
  }


  void _fetchDataFromFirstTab() {
    ProductGeneralInfoData? latestData = _firstTabKey.currentState?.getCurrentFormData();
    setState(() {
      productGeneralInfoData = latestData;
    });
  }

  void _fetchDataFromSecondTab() {
    ProductCombinedData? data = _secondTabKey.currentState?.getCurrentFormData();
    setState(() {
      productCombinedData = data;
    });
  }

  void _navigateToTab(int index) {
    if(index ==1 ) {
      _fetchDataFromFirstTab();
    }

    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final productTabs = _productTabs(context);
    if (widget.product == null && !_eligibilityChecked) {
      return Scaffold(
        appBar: CustomAppBarWidget(centerTitle: false, title: getTranslated('add_product', context)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.product == null && !_canAddNewProduct) {
      return Scaffold(
        appBar: CustomAppBarWidget(centerTitle: false, title: getTranslated('add_product', context)),
        body: _AddProductEligibilityBlocked(
          reason: _eligibilityReason ?? (getTranslated('seller_product_package_required', context) ?? 'A seller package is required.'),
          action: _eligibilityAction,
        ),
      );
    }

    return DefaultTabController(
      length: productTabs.length,
      child: Scaffold(
        appBar: CustomAppBarWidget(
          centerTitle: false,
          title: widget.product != null ? getTranslated('update_product', context) : getTranslated('add_product', context),
          widget: GeneratesLeftCount(),
          isFilter: true,
          isAction: true,
          onBackPressed: () {
            Navigator.of(context).pop();
          },
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              height: 60,
              child: AddProductTitleBar(tabController: _tabController),
            ),
            if (widget.product == null) const _ProductReviewSteps(),

            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  AddProductScreen(product: widget.product, addProduct: widget.addProduct, fromHome: widget.fromHome, onTabChanged: _navigateToTab, key: _firstTabKey),

                  AddProductNextScreen(
                    key: _secondTabKey,
                    categoryId: productGeneralInfoData?.categoryId,
                    subCategoryId:  productGeneralInfoData?.subCategoryId,
                    subSubCategoryId: productGeneralInfoData?.subSubCategoryId,
                    brandId: productGeneralInfoData?.brandId,
                    unit: productGeneralInfoData?.unit,
                    product: widget.product,
                    addProduct: productGeneralInfoData?.addProduct,
                    title: productGeneralInfoData?.title,
                    description: productGeneralInfoData?.description,
                    onTabChanged: _navigateToTab,
                  ),

                  AddProductSeoScreen(
                    unitPrice: productCombinedData?.unitPrice,
                    tax: productCombinedData?.tax,
                    unit: productCombinedData?.unit,
                    categoryId: productCombinedData?.categoryId,
                    subCategoryId: productCombinedData?.subCategoryId,
                    subSubCategoryId: productCombinedData?.subSubCategoryId,
                    brandyId: productCombinedData?.brandId,
                    discount: productCombinedData?.discount,
                    currentStock: productCombinedData?.currentStock,
                    minimumOrderQuantity: productCombinedData?.minimumOrderQuantity,
                    shippingCost: productCombinedData?.shippingCost,
                    product: widget.product,
                    addProduct: productCombinedData?.addProduct,
                    title: productCombinedData?.title,
                    description: productCombinedData?.description,
                    onTabChanged: _navigateToTab,
                  ),
                ],
              ),
            )

          ],
        ),




      ),
    );
  }

  Future<void> _checkNewProductEligibility() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final packageController = Provider.of<SellerPackageController>(context, listen: false);
    final activationResponse = await authController.loadActivationStatus();
    if (!mounted) return;

    // Activation is the first gate. The server remains the source of truth for
    // registration status, while the package APIs provide the financial gates.
    if (activationResponse.response?.statusCode == 200 && activationResponse.response?.data is Map) {
      final data = Map<String, dynamic>.from(activationResponse.response!.data as Map);
      final eligibility = Map<String, dynamic>.from(data['eligibility'] as Map? ?? const {});
      final nextStep = eligibility['next_step']?.toString();
      if (nextStep == 'verify_phone' || nextStep == 'await_activation_ticket' || nextStep == 'await_admin_approval') {
        setState(() {
          _eligibilityReason = nextStep == 'verify_phone'
              ? (getTranslated('seller_product_phone_verification_required', context) ?? 'Verify your phone before adding products.')
              : (getTranslated('seller_product_activation_required', context) ?? 'Activate your seller account before adding products.');
          _eligibilityAction = nextStep == 'await_activation_ticket' ? 'activation_ticket' : 'back';
          _canAddNewProduct = false;
          _eligibilityChecked = true;
        });
        return;
      }
    } else if (authController.getRegistrationReference().isNotEmpty) {
      // Do not let a temporary API failure turn into a bypass of the first gate.
      setState(() {
        _eligibilityReason = getTranslated('seller_product_eligibility_unavailable', context) ?? 'We could not verify your eligibility. Please try again.';
        _eligibilityAction = null;
        _canAddNewProduct = false;
        _eligibilityChecked = true;
      });
      return;
    }

    await packageController.getOverview();
    final overview = packageController.overview;
    if (!mounted) return;

    // Existing sellers created before registration references were introduced can
    // use this compatible fallback. A missing package overview remains blocked.
    if (overview == null) {
      setState(() {
        _eligibilityReason = getTranslated('seller_product_eligibility_unavailable', context) ?? 'We could not verify your eligibility. Please try again.';
        _eligibilityAction = null;
        _canAddNewProduct = false;
        _eligibilityChecked = true;
      });
      return;
    }

    final subscription = overview.subscription.active;
    String? reason;
    String? action;
    if (subscription == null) {
      reason = getTranslated('seller_product_package_required', context) ?? 'Activate a seller package before adding products.';
      action = 'package';
    } else if (subscription.remainingProductLimit <= 0) {
      reason = getTranslated('seller_product_limit_reached', context) ?? 'Your package product limit has been reached.';
    }
    setState(() {
      _eligibilityReason = reason;
      _eligibilityAction = action;
      _canAddNewProduct = reason == null;
      _eligibilityChecked = true;
    });
  }
}

class _ProductReviewSteps extends StatelessWidget {
  const _ProductReviewSteps();

  @override
  Widget build(BuildContext context) {
    final labels = [
      getTranslated('seller_product_step_uploaded', context)!,
      getTranslated('seller_product_step_under_review', context)!,
      getTranslated('seller_product_step_published', context)!,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getTranslated('seller_product_review_steps_title', context)!, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(children: List.generate(labels.length, (index) => Expanded(child: Row(children: [
          CircleAvatar(radius: 11, backgroundColor: index == 0 ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: .35), child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.white))),
          const SizedBox(width: 4),
          Expanded(child: Text(labels[index], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
          if (index < labels.length - 1) Icon(Icons.arrow_forward, size: 14, color: Theme.of(context).hintColor),
        ])))),
      ]),
    );
  }
}

class _AddProductEligibilityBlocked extends StatelessWidget {
  final String reason;
  final String? action;

  const _AddProductEligibilityBlocked({required this.reason, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(reason, textAlign: TextAlign.center),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          if (action != null) OutlinedButton.icon(
            onPressed: () {
              if (action == 'activation_ticket') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerActivationTicketScreen()));
              } else if (action == 'package') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPackageScreen()));
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(action == 'activation_ticket' ? Icons.support_agent_outlined : Icons.inventory_2_outlined),
            label: Text(_actionLabel(context)),
          ),
        ]),
      ),
    );
  }

  String _actionLabel(BuildContext context) {
    return switch (action) {
      'activation_ticket' => getTranslated('complete_seller_activation', context) ?? 'Complete activation',
      'package' => getTranslated('go_to_seller_packages', context) ?? 'Go to packages',
      _ => getTranslated('back', context) ?? 'Back',
    };
  }
}
