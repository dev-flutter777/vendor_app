import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/seller_activation_ticket_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';

class SellerActivationBannerWidget extends StatefulWidget {
  const SellerActivationBannerWidget({super.key});
  @override
  State<SellerActivationBannerWidget> createState() => _SellerActivationBannerWidgetState();
}

class _SellerActivationBannerWidgetState extends State<SellerActivationBannerWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Provider.of<AuthController>(context, listen: false).loadActivationStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(builder: (_, auth, __) {
      final banner = auth.activation?['banner'];
      if (auth.activationJustApproved) {
        return Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Text(getTranslated('seller_account_activated', context) ?? '', style: const TextStyle(color: Colors.white))), IconButton(color: Colors.white, onPressed: auth.dismissActivationApprovedBanner, icon: const Icon(Icons.close))]));
      }
      if (banner == null || banner['visible'] != true) return const SizedBox.shrink();
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerActivationTicketScreen())).then((_) => auth.loadActivationStatus()),
        child: Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)), child: Text(getTranslated('seller_activation_required', context) ?? '', style: const TextStyle(color: Colors.white))),
      );
    });
  }
}
