import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uaepass_api/model/uaepass_user_token_model.dart';
import 'package:uaepass_api/uaepass/constant.dart';
import 'package:uaepass_api/service/memory_service.dart';
import 'package:uaepass_api/model/uaepass_user_profile_model.dart';
import 'package:uaepass_api/uaepass/uaepass_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The [UaePassAPI] class provides methods to facilitate authentication
/// with UAE Pass, a digital identity solution provided by the United Arab Emirates government.
class UaePassAPI {
  final String _clientId;
  final String _callbackUrl;
  final String _clientSecrete;
  final String _language;
  final String _serviceProviderEnglishName;
  final String _serviceProviderArabicName;
  final bool _isProduction;
  final bool _blockSOP1;

  /// Constructs a new instance of the [UaePassAPI] class.
  ///
  /// [clientId]: The client ID provided by UAE Pass.
  /// [redirectUri]: The URI to which the user should be redirected after authentication.
  /// [clientSecrete]: The client secret provided by UAE Pass.
  /// [appScheme]: The scheme used by the Flutter application.
  /// [isProduction]: Indicates whether the app is running in production mode.
  /// [language]: Language parameter to be sent to render English or Arabic login pages of UAEPASS (English page : en Arabic page : ar).
  UaePassAPI({
    required String clientId,
    required String callbackUrl,
    required String clientSecrete,
    String serviceProviderEnglishName = 'Service Provider',
    String serviceProviderArabicName = 'مزود الخدمة',
    required bool isProduction,
    bool blockSOP1 = false,
    String language = 'en',
  })  : _isProduction = isProduction,
        _clientSecrete = clientSecrete,
        _callbackUrl = callbackUrl,
        _clientId = clientId,
        _language = language,
        _serviceProviderEnglishName = serviceProviderEnglishName,
        _serviceProviderArabicName = serviceProviderArabicName,
        _blockSOP1 = blockSOP1;

  /// Generates the URL required to initiate the UAE Pass authentication process.
  ///
  /// Returns a [String] representing the constructed URL.
  Future<String> _getURL() async {
    // Determine the appropriate authentication context based on whether the UAE Pass app is installed.
    String acr = Const.uaePassMobileACR;
    String acrWeb = Const.uaePassWebACR;

    bool withApp = await canLaunchUrlString('${Const.uaePassScheme(_isProduction)}digitalid-users-ids');
    if (!withApp) {
      acr = acrWeb;
    }

    // Construct the URL with necessary parameters.
    String url = "${Const.baseUrl(_isProduction)}/idshub/authorize?"
        "response_type=code"
        "&client_id=$_clientId"
        "&scope=urn:uae:digitalid:profile:general"
        "&state=HnlHOJTkTb66Y5H"
        "&redirect_uri=$_callbackUrl"
        "&ui_locales=${_language}"
        "&acr_values=$acr";

    return url;
  }

  /// Initiates the UAE Pass authentication process.
  ///
  /// [context]: The [BuildContext] to navigate to the authentication view.
  ///
  /// Returns a [String] representing the authentication code obtained during the process.
  Future<String?> signIn(BuildContext context) async {
    await MemoryService.instance.initialize();
    String url = await _getURL();
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
      return MemoryService.instance.accessCode;
    }
    return MemoryService.instance.accessCode;
  }

  /// Exchanges the authorization code for an access token.
  ///
  /// [code]: The authorization code obtained during the authentication process.
  ///
  /// Returns a [String] representing the access token.
  Future<String?> getAccessToken(String code) async {
    try {
      const String url = "/idshub/token";

      var data = {'redirect_uri': _callbackUrl, 'client_id': _clientId, 'client_secret': _clientSecrete, 'grant_type': 'authorization_code', 'code': code};

      final response = await http.post(
        Uri.parse(Const.baseUrl(_isProduction) + url),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        return UAEPASSUserToken.fromJson(jsonDecode(response.body)).accessToken;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    return null;
  }

  /// Get profile information
  ///
  /// [token]: The authorization token obtained during the authentication process.
  ///
  /// Returns a [UAEPASSUserProfile] representing the profile info.
  Future<UAEPASSUserProfile?> getUserProfile(String token, {required context}) async {
    try {
      const String url = "/idshub/userinfo";

      final response = await http.get(
        Uri.parse(Const.baseUrl(_isProduction) + url),
        headers: <String, String>{'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final profile = UAEPASSUserProfile.fromJson(jsonDecode(response.body));

        if (_blockSOP1 && profile.userType == 'SOP2') {
          debugPrint('UAEPASS >> UNAUTHORISED >> ${profile.userType} ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _language == 'ar'
                    ? 'أنت غير مؤهل للوصول إلى هذه الخدمة. إما أن حسابك لم تتم ترقيته أو لديك حساب زائر. يرجى الاتصال بـ $_serviceProviderArabicName لتتمكن من الوصول إلى الخدمة.'
                    : 'You are not eligible to access this service. Your account is either not upgraded or you have a visitor account. Please contact $_serviceProviderEnglishName to access the services.',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );

          return null;
        }
        return profile;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    return null;
  }

  /// Initiates logout.
  ///
  /// [context]: The [BuildContext] to navigate to the authentication view.
  ///
  Future logout(BuildContext context) async {
    String url = "${Const.baseUrl(_isProduction)}/idshub/logout?redirect_uri=$_callbackUrl";

    if (context.mounted) {
      return await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
    }

    return null;
  }
}
