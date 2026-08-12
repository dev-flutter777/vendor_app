import 'package:flutter/material.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';


class AddProductTitleBar extends StatefulWidget {
  final TabController tabController;
  const AddProductTitleBar({super.key, required this.tabController});

  @override
  State<AddProductTitleBar> createState() => _AddProductTitleBarState();
}

class _AddProductTitleBarState extends State<AddProductTitleBar> with SingleTickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final productTabs = <Tab>[
      Tab(text: getTranslated('general_info', context) ?? 'General Info'),
      Tab(text: getTranslated('variation_setup', context) ?? 'Variations'),
      Tab(text: getTranslated('product_seo', context) ?? 'SEO'),
    ];

    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: TabBar(
          labelPadding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          controller: widget.tabController,
          tabs: productTabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall), // Match radiusSmall
            border: Border.all(color: Theme.of(context).primaryColor),
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
