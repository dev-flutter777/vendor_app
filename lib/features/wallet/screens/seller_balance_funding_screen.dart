import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_package_overview_model.dart';
import 'package:sixvalley_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:sixvalley_vendor_app/features/wallet/domain/models/seller_balance_model.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class SellerBalanceFundingScreen extends StatefulWidget {
  const SellerBalanceFundingScreen({super.key});

  @override
  State<SellerBalanceFundingScreen> createState() => _SellerBalanceFundingScreenState();
}

class _SellerBalanceFundingScreenState extends State<SellerBalanceFundingScreen> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _informationControllers = {};
  XFile? _paymentProof;
  SellerOfflinePaymentMethod? _selectedOfflineMethod;
  String? _selectedGateway;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    for (final controller in _informationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBarWidget(title: getTranslated('operating_balance', context) ?? 'Operating balance'),
        body: Consumer<WalletController>(
        builder: (context, wallet, _) {
          final balance = wallet.sellerBalance;
          if (balance == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _balanceHeader(context, balance),
              Padding(
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: getTranslated('enter_amount', context) ?? 'Amount',
                      border: const OutlineInputBorder(),
                      helperText: _limitsText(balance),
                    ),
                    validator: (value) => _validateAmount(value, balance),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              TabBar(
                tabs: [
                  Tab(text: getTranslated('pay_online', context) ?? 'Digital payment'),
                  Tab(text: getTranslated('offline_payment', context) ?? 'Offline payment'),
                ],
                labelColor: Theme.of(context).primaryColor,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _digitalTab(context, wallet, balance),
                    _offlineTab(context, wallet, balance),
                  ],
                ),
              ),
              _depositHistory(context, balance),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _balanceHeader(BuildContext context, SellerBalanceModel balance) {
    return Card(
      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text(getTranslated('operating_balance', context) ?? 'Operating balance', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            Text((balance.summary['operating'] ?? 0).toStringAsFixed(2), style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ],
        ),
      ),
    );
  }

  Widget _digitalTab(BuildContext context, WalletController wallet, SellerBalanceModel balance) {
    if (!balance.digitalPaymentAvailable || balance.paymentGateways.isEmpty) {
      return _emptyState(context, getTranslated('no_digital_payment_method', context) ?? 'No digital payment method is currently available.');
    }
    return ListView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      children: [
        Text(getTranslated('choose_payment_gateway', context) ?? 'Choose a payment gateway', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...balance.paymentGateways.map((gateway) => Card(
          child: ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: Text(gateway.title),
            trailing: Radio<String>(
              value: gateway.keyName,
              groupValue: _selectedGateway,
              onChanged: (value) => setState(() => _selectedGateway = value),
            ),
            onTap: () => setState(() => _selectedGateway = gateway.keyName),
          ),
        )),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ElevatedButton.icon(
          onPressed: wallet.isFunding ? null : () => _startDigitalPayment(context, wallet, balance),
          icon: wallet.isFunding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.open_in_new),
          label: Text(wallet.isFunding ? (getTranslated('starting_payment', context) ?? 'Starting payment...') : (getTranslated('continue_to_payment', context) ?? 'Continue to payment')),
        ),
      ],
    );
  }

  Widget _offlineTab(BuildContext context, WalletController wallet, SellerBalanceModel balance) {
    if (!balance.offlinePaymentAvailable || balance.offlinePaymentMethods.isEmpty) {
      return _emptyState(context, getTranslated('no_offline_payment_method', context) ?? 'No offline payment method is currently available.');
    }
    final method = _selectedOfflineMethod;
    return ListView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      children: [
        DropdownButtonFormField<SellerOfflinePaymentMethod>(
          value: method,
          decoration: InputDecoration(labelText: getTranslated('transfer_method', context) ?? 'Transfer method', border: const OutlineInputBorder()),
          items: balance.offlinePaymentMethods.map((item) => DropdownMenuItem(value: item, child: Text(item.methodName))).toList(),
          onChanged: (value) => _selectOfflineMethod(value),
          validator: (value) => value == null ? (getTranslated('select_transfer_method', context) ?? 'Select a transfer method.') : null,
        ),
        if (method != null && method.methodFields.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ...method.methodFields.map((field) => Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
            child: Text(field.inputName + ': ' + field.inputData, style: titilliumRegular),
          )),
        ],
        if (method != null) ..._offlineInformationFields(method),
        OutlinedButton.icon(
          onPressed: _pickProof,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_paymentProof == null ? (getTranslated('upload_payment_proof', context) ?? 'Upload payment proof *') : _paymentProof!.name),
        ),
        TextFormField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(labelText: getTranslated('payment_note', context) ?? 'Payment note', border: const OutlineInputBorder()),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ElevatedButton.icon(
          onPressed: wallet.isFunding ? null : () => _submitOffline(context, wallet, balance),
          icon: wallet.isFunding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
          label: Text(wallet.isFunding ? (getTranslated('submitting', context) ?? 'Submitting...') : (getTranslated('submit_admin_review', context) ?? 'Submit for admin review')),
        ),
      ],
    );
  }

  List<Widget> _offlineInformationFields(SellerOfflinePaymentMethod method) {
    return method.methodInformations
        .where((field) => field.inputName.isNotEmpty && !_isProofField(field))
        .map((field) => Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: TextFormField(
        controller: _informationControllers[field.inputName],
        decoration: InputDecoration(
          labelText: field.inputName + (field.isRequired ? ' *' : ''),
          hintText: field.placeholder,
          border: const OutlineInputBorder(),
        ),
      ),
    )).toList();
  }

  Widget _depositHistory(BuildContext context, SellerBalanceModel balance) {
    if (balance.deposits.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 132,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        children: [
          Text(getTranslated('financial_records', context) ?? 'Deposit history', style: titilliumSemiBold),
          ...balance.deposits.take(3).map((deposit) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(deposit.source + ' - ' + deposit.status),
            trailing: Text(deposit.amount.toStringAsFixed(2)),
          )),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String text) => Center(
    child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), child: Text(text, textAlign: TextAlign.center)),
  );

  String? _validateAmount(String? value, SellerBalanceModel balance) {
    final amount = double.tryParse((value ?? '').trim());
    final min = double.tryParse(balance.fundingSettings['min_amount']?.toString() ?? '') ?? 0;
    final max = double.tryParse(balance.fundingSettings['max_amount']?.toString() ?? '') ?? double.infinity;
    if (amount == null || amount <= 0) return getTranslated('please_enter_amount', context) ?? 'Enter a valid amount.';
    if (amount < min) return 'Amount is below the minimum allowed.';
    if (amount > max) return 'Amount is above the maximum allowed.';
    return null;
  }

  String _limitsText(SellerBalanceModel balance) {
    final min = balance.fundingSettings['min_amount']?.toString() ?? '0';
    final max = balance.fundingSettings['max_amount']?.toString() ?? '0';
    return 'Allowed amount: ' + min + ' - ' + max;
  }

  Future<void> _startDigitalPayment(BuildContext context, WalletController wallet, SellerBalanceModel balance) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGateway == null) {
      showCustomSnackBarWidget(getTranslated('select_payment_gateway', context), context, sanckBarType: SnackBarType.warning);
      return;
    }
    final link = await wallet.payOperatingBalance(amount: _amountController.text.trim(), paymentMethod: _selectedGateway!);
    if (link == null || link.isEmpty) return;
    final opened = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showCustomSnackBarWidget(
        getTranslated('could_not_open_payment_page', context) ?? '',
        context,
        sanckBarType: SnackBarType.error,
      );
    }
  }

  Future<void> _submitOffline(BuildContext context, WalletController wallet, SellerBalanceModel balance) async {
    if (!_formKey.currentState!.validate()) return;
    final method = _selectedOfflineMethod;
    if (method == null) {
      showCustomSnackBarWidget(getTranslated('select_transfer_method', context), context, sanckBarType: SnackBarType.warning);
      return;
    }
    if (_paymentProof == null) {
      showCustomSnackBarWidget(getTranslated('payment_proof_required', context), context, sanckBarType: SnackBarType.warning);
      return;
    }
    for (final field in method.methodInformations.where((item) => item.isRequired && !_isProofField(item))) {
      if ((_informationControllers[field.inputName]?.text.trim() ?? '').isEmpty) {
        showCustomSnackBarWidget(getTranslated('complete_transfer_information', context), context, sanckBarType: SnackBarType.warning);
        return;
      }
    }
    final information = <String, String>{
      for (final entry in _informationControllers.entries) entry.key: entry.value.text.trim(),
    };
    final submitted = await wallet.submitOfflineBalancePayment(
      amount: _amountController.text.trim(),
      methodId: method.id,
      methodInformations: information,
      paymentProof: _paymentProof!,
      paymentNote: _noteController.text.trim(),
    );
    if (submitted && context.mounted) {
      showCustomSnackBarWidget(getTranslated('deposit_submitted_review', context), context, isError: false, sanckBarType: SnackBarType.success);
      Navigator.pop(context);
    }
  }

  void _selectOfflineMethod(SellerOfflinePaymentMethod? method) {
    for (final controller in _informationControllers.values) {
      controller.dispose();
    }
    _informationControllers.clear();
    if (method != null) {
      for (final field in method.methodInformations) {
        if (field.inputName.isNotEmpty && !_isProofField(field)) {
          _informationControllers[field.inputName] = TextEditingController();
        }
      }
    }
    setState(() => _selectedOfflineMethod = method);
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null && mounted) setState(() => _paymentProof = picked);
  }

  bool _isProofField(SellerOfflineMethodField field) {
    final text = (field.inputName + ' ' + field.placeholder).toLowerCase();
    return text.contains('screenshot') || text.contains('image') || text.contains('receipt') || text.contains('proof');
  }
}
