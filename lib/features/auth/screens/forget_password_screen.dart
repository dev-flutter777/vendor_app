import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:sixvalley_vendor_app/main.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/images.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_button_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_dialog_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/textfeild/custom_text_feild_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/widgets/my_dialog_widget.dart';
import 'package:sixvalley_vendor_app/features/auth/screens/otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const String _egyptDialCode = '+20';

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    Provider.of<AuthController>(context, listen: false).setCountryDialCode(_egyptDialCode);
  }

  String _localEgyptianMobile() {
    var digits = _numberController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }


  @override
  Widget build(BuildContext context) {
    final ConfigModel configModel =  Provider.of<SplashController>(context, listen: false).configModel!;

    return Scaffold(
      appBar: CustomAppBarWidget(isBackButtonExist: true,title: getTranslated('forget_password', context),),

      body: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: SingleChildScrollView(
          child: Column( crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(height: 95),

              Image.asset(Images.forgotPasswordIcon, height: 100, width: 100),

              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Text('${getTranslated('forget_password', context)}?', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
              ),

              Provider.of<SplashController>(context,listen: false).configModel!.forgotPasswordVerification == "phone"?
              Text(getTranslated('enter_phone_number_for_password_reset', context)!,
                  style: titilliumRegular.copyWith(color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeExtraSmall)):
              Text(getTranslated('enter_email_for_password_reset', context)!,
                  style: titilliumRegular.copyWith(color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Provider.of<SplashController>(context,listen: false).configModel!.forgotPasswordVerification == "phone" ?
              Consumer<AuthController>(
                builder: (context, authProvider,_) {
                  return Row(children: [
                    Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).hintColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(_egyptDialCode),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(child: CustomTextFieldWidget(
                      border: true,
                      hintText: getTranslated('number_hint', context),
                      controller: _numberController,
                      focusNode: _numberFocus,
                      isPhoneNumber: true,
                      textInputAction: TextInputAction.done,
                      textInputType: TextInputType.phone,
                    )),
                  ]);
                }
              ) :
              CustomTextFieldWidget(
                border: true,
                prefixIconImage: Images.emailIcon,
                controller: _controller,
                hintText: getTranslated('ENTER_YOUR_EMAIL', context),
                textInputAction: TextInputAction.done,
                textInputType: TextInputType.emailAddress,),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Consumer<AuthController>(
                builder: (context, authProvider, _) {
                  return !authProvider.isLoading ?
                  CustomButtonWidget( borderRadius: 10,
                    btnTxt: Provider.of<SplashController>(context,listen: false).configModel!.forgotPasswordVerification == "phone"?
                    getTranslated('send_otp', context):getTranslated('send_email', context),
                    onTap: () {
                      if(Provider.of<SplashController>(context,listen: false).configModel!.forgotPasswordVerification == "phone") {

                        final phone = _localEgyptianMobile();

                        if(_numberController.text.isEmpty) {
                          showCustomSnackBarWidget(getTranslated('PHONE_MUST_BE_REQUIRED', context), context, sanckBarType: SnackBarType.warning);
                        } else if (!RegExp(r'^1[0-25][0-9]{8}$').hasMatch(phone)) {
                          showCustomSnackBarWidget(getTranslated('input_valid_phone_number', context), context, sanckBarType: SnackBarType.warning);
                        } else {
                          final identity = '$_egyptDialCode$phone';
                          authProvider.forgotPassword(identity, true, configModel).then((value) {
                            if(value != null) {
                              if(value.isSuccess) {
                                Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(identity)));
                              } else {
                                showCustomSnackBarWidget(getTranslated('input_valid_phone_number', Get.context!), Get.context!,  sanckBarType: SnackBarType.warning);
                              }
                            }
                          });
                        }


                      } else {
                        if(_controller.text.isEmpty) {
                          showCustomSnackBarWidget(getTranslated('EMAIL_MUST_BE_REQUIRED', context), context,  sanckBarType: SnackBarType.warning);
                        }
                        else {
                          Provider.of<AuthController>(context, listen: false).forgotPassword(_controller.text, false, configModel).then((value) {
                            if(value != null && value.isSuccess) {
                              FocusScopeNode currentFocus = FocusScope.of(Get.context!);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                              _controller.clear();
                              showAnimatedDialogWidget(Get.context!, MyDialogWidget(
                                icon: Icons.send,
                                title: getTranslated('sent', Get.context!),
                                description: getTranslated('recovery_link_sent', Get.context!),
                                rotateAngle: 5.5,
                              ), dismissible: false);
                            }else if (value != null) {
                              showCustomSnackBarWidget(value.message, Get.context!,  sanckBarType: SnackBarType.success);
                            }
                          });
                        }
                      }
                    },
                  ) :
                  Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)));
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
