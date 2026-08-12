import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_button_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/textfeild/custom_pass_textfeild_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/textfeild/custom_text_feild_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/seller_registration_verification_screen.dart';
import 'package:sixvalley_vendor_app/helper/email_checker.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/main.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthController>(context, listen: false);
    auth.emptyRegistrationData();
    auth.setCountryDialCode('+20');
    auth.loadRequiredRegistrationPolicies();
  }

  void _submit(AuthController auth) {
    final phone = auth.phoneController.text.trim().replaceFirst(RegExp(r'^0'), '');
    if (!auth.registrationPoliciesLoaded) {
      showCustomSnackBarWidget(getTranslated('registration_policies_loading', context), context, sanckBarType: SnackBarType.warning);
    } else if (EmailChecker.isNotValid(auth.emailController.text.trim())) {
      showCustomSnackBarWidget(getTranslated('email_is_ot_valid', context), context, sanckBarType: SnackBarType.warning);
    } else if (!RegExp(r'^1[0-25][0-9]{8}$').hasMatch(phone)) {
      showCustomSnackBarWidget(getTranslated('phone_number_is_not_valid', context), context, sanckBarType: SnackBarType.warning);
    } else if (auth.passwordController.text.length < 8) {
      showCustomSnackBarWidget(getTranslated('password_minimum_length_is_6', context), context, sanckBarType: SnackBarType.warning);
    } else if (auth.passwordController.text != auth.confirmPasswordController.text) {
      showCustomSnackBarWidget(getTranslated('password_is_mismatch', context), context, sanckBarType: SnackBarType.warning);
    } else if (auth.isTermsAndCondition != true) {
      showCustomSnackBarWidget(getTranslated('terms_and_conditions_must_be_accepted', context), context, sanckBarType: SnackBarType.warning);
    } else {
      final model = RegisterModel(
        phone: '+20$phone',
        email: auth.emailController.text.trim(),
        password: auth.passwordController.text,
        confirmPassword: auth.confirmPasswordController.text,
        policyVersionIds: auth.requiredRegistrationPolicies
            .map((policy) => int.tryParse(policy['id'].toString()) ?? 0)
            .where((id) => id > 0)
            .toList(),
      );
      auth.registration(Get.context!, model, null).then((response) async {
        if (response.response?.statusCode == 200 && mounted) {
          final data = response.response!.data is String ? jsonDecode(response.response!.data) as Map<String, dynamic> : Map<String, dynamic>.from(response.response!.data);
          final reference = data['registration_reference'] as String?;
          if (reference == null) return;
          await auth.saveRegistrationReference(reference);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SellerRegistrationVerificationScreen(
            registrationReference: reference,
            mobileNumber: '+20$phone',
            otpRequired: data['otp']?['required'] != false,
            resendAfter: data['otp']?['resend_after'] as int? ?? 0,
            supportTicketRequired: data['eligibility']?['verification']?['support_ticket_required'] == true,
          )));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: getTranslated('create_an_account', context), isBackButtonExist: true),
      body: Consumer<AuthController>(builder: (context, auth, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(getTranslated('create_an_account', context)!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(getTranslated('email', context)!), const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomTextFieldWidget(border: true, hintText: getTranslated('email_hint', context), controller: auth.emailController, focusNode: auth.emailNode, nextNode: auth.phoneNode, textInputType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(getTranslated('phone', context)!), const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(children: [
              Container(height: 56, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(border: Border.all(color: Theme.of(context).hintColor), borderRadius: BorderRadius.circular(6)), child: const Text('+20')),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: CustomTextFieldWidget(border: true, hintText: getTranslated('mobile_hint', context), controller: auth.phoneController, focusNode: auth.phoneNode, nextNode: auth.passwordNode, isPhoneNumber: true, textInputType: TextInputType.phone, textInputAction: TextInputAction.next)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(getTranslated('new_password', context)!), const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomPasswordTextFieldWidget(border: true, hintTxt: getTranslated('enter_your_password', context), controller: auth.passwordController, focusNode: auth.passwordNode, nextNode: auth.confirmPasswordNode, textInputAction: TextInputAction.next, onChanged: (value) => auth.validPassCheck(value ?? '')),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(getTranslated('confirm_password', context)!), const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomPasswordTextFieldWidget(border: true, hintTxt: getTranslated('confirm_password', context), controller: auth.confirmPasswordController, focusNode: auth.confirmPasswordNode, textInputAction: TextInputAction.done),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: auth.isTermsAndCondition ?? false, onChanged: auth.updateTermsAndCondition, title: Text(getTranslated('agree_to_terms_privacy_and_confidentiality', context) ?? '')),
            if (auth.requiredRegistrationPolicies.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              ...auth.requiredRegistrationPolicies.map((policy) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("• ${policy['title'] ?? ''}", style: robotoRegular))),
            ],
            const SizedBox(height: Dimensions.paddingSizeLarge),
            auth.isLoading || !auth.registrationPoliciesLoaded ? const Center(child: CircularProgressIndicator()) : CustomButtonWidget(btnTxt: getTranslated('submit', context), onTap: () => _submit(auth)),
          ]),
        );
      }),
    );
  }
}
