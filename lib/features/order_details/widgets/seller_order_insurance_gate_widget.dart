import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:sixvalley_vendor_app/features/order_details/domain/models/seller_order_insurance_model.dart';
import 'package:sixvalley_vendor_app/helper/price_converter.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerOrderInsuranceGateWidget extends StatelessWidget {
  final String orderId;
  const SellerOrderInsuranceGateWidget({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsController>(builder: (context, controller, _) {
      final envelope = controller.sellerOrderInsurance;
      final insurance = envelope?.insurance;
      if (controller.insuranceLoading || insurance == null) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.shield_outlined, color: Theme.of(context).primaryColor), const SizedBox(width: 10), Expanded(child: Text(getTranslated('seller_order_insurance', context) ?? 'Seller order insurance', style: Theme.of(context).textTheme.titleLarge))]),
          const SizedBox(height: 12),
          Text(getTranslated('seller_order_details_hidden_until_insurance_paid', context) ?? 'Order details remain hidden until insurance is paid.'),
          const Divider(height: 28),
          _row(context, getTranslated('order_reference', context) ?? 'Order reference', insurance.orderReference),
          _row(context, getTranslated('insurance_amount', context) ?? 'Insurance amount', PriceConverter.convertPrice(context, insurance.amount)),
          _row(context, getTranslated('payment_deadline', context) ?? 'Payment deadline', insurance.expiresAt ?? '-'),
          _row(context, getTranslated('status', context) ?? 'Status', getTranslated(insurance.status, context) ?? insurance.status),
          if (insurance.adminNote?.isNotEmpty == true) _row(context, getTranslated('admin_note', context) ?? 'Admin note', insurance.adminNote!),
          const SizedBox(height: 16),
          if (insurance.status == 'pending_payment') ...[
            if (envelope!.paymentOptions.operatingBalance)
              _payButton(context, controller, insurance, 'operating_balance', 'pay_from_operating_balance'),
            if (envelope.paymentOptions.reusableInsuranceCredit && insurance.reusableInsuranceCredit >= insurance.amount)
              _payButton(context, controller, insurance, 'seller_order_insurance_credit', 'pay_from_reusable_insurance_credit'),
            ...envelope.paymentOptions.digitalGateways.map((gateway) => Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton(
              onPressed: controller.insuranceLoading ? null : () async {
                final redirect = await controller.paySellerOrderInsurance(orderId, gateway.id);
                if (redirect != null) await launchUrl(Uri.parse(redirect), mode: LaunchMode.externalApplication);
              }, child: Text('${getTranslated('pay_with', context) ?? 'Pay with'} ${gateway.title}'),
            ))),
            if (envelope.paymentOptions.offlinePayment && envelope.paymentOptions.offlineMethods.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton(onPressed: () => _offlineDialog(context, controller, envelope.paymentOptions.offlineMethods), child: Text(getTranslated('offline_payment', context) ?? 'Offline payment'))),
          ],
          if (insurance.status == 'pending_review') Padding(padding: const EdgeInsets.only(top: 8), child: Text(getTranslated('offline_payment_waiting_for_admin_review', context) ?? 'Payment is waiting for admin review.')),
        ]))),
      ]);
    });
  }

  Widget _row(BuildContext context, String title, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(title)), Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)))]));

  Widget _payButton(BuildContext context, OrderDetailsController controller, SellerOrderInsuranceModel insurance, String method, String label) => Padding(
    padding: const EdgeInsets.only(top: 8), child: ElevatedButton(onPressed: controller.insuranceLoading ? null : () => controller.paySellerOrderInsurance(orderId, method), child: Text(getTranslated(label, context) ?? label)),
  );

  Future<void> _offlineDialog(BuildContext context, OrderDetailsController controller, List<InsurancePaymentMethod> methods) async {
    String methodId = methods.first.id;
    XFile? proof;
    final note = TextEditingController();
    await showDialog(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text(getTranslated('offline_payment', context) ?? 'Offline payment'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: methodId, items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))).toList(), onChanged: (v) => methodId = v ?? methodId),
        TextField(controller: note, decoration: InputDecoration(labelText: getTranslated('payment_note', context) ?? 'Payment note')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () async { proof = await ImagePicker().pickImage(source: ImageSource.gallery); setState(() {}); }, child: Text(proof?.name ?? (getTranslated('select_payment_proof', context) ?? 'Select payment proof'))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(getTranslated('cancel', context) ?? 'Cancel')), ElevatedButton(onPressed: proof == null ? null : () async { final ok = await controller.submitSellerOrderInsuranceOffline(orderId, methodId, proof!.path, note.text); if (ok && dialogContext.mounted) Navigator.pop(dialogContext); }, child: Text(getTranslated('submit', context) ?? 'Submit'))],
    )));
  }
}
