import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/companion_auth.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInWithTwitch extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInWithTwitch({
    super.key,
    this.onStart,
    this.onComplete,
  });

  static Future<bool> isGlobalThisSupported() async {
    if (Platform.isIOS) return true;

    final completer = Completer<bool>();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.addJavaScriptChannel("response", onMessageReceived: (message) {
      completer.complete(message.message == "true");
    });
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          controller.runJavaScript(
              "response.postMessage(typeof globalThis !== 'undefined');");
        },
      ),
    );
    const htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head><meta charset="UTF-8"></head>
      <body></body>
      </html>
      ''';
    await controller.loadHtmlString(htmlContent);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF6441A5)),
      ),
      child: Text(localizations.signInWithTwitch, 
          style: const TextStyle(
            color: Colors.white,
          )),
      onPressed: () async {
        // Skip browser check on iOS
        final isGlobalThisSupported = Platform.isIOS
            ? true
            : await SignInWithTwitch.isGlobalThisSupported();

        if (!context.mounted) return;

        if (!isGlobalThisSupported) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return const CompanionAuthWidget(
                provider: "twitch",
                isTooOld: true,
              );
            },
          );
          return;
        }

        final user = Provider.of<UserModel>(context, listen: false);
        onStart?.call();

        try {
          await FirebaseAnalytics.instance.logLogin(loginMethod: "twitch");

          final result = await FlutterWebAuth2.authenticate(
            url: url.toString(),
            callbackUrlScheme: "com.rtirl.chat",
            options: const FlutterWebAuth2Options(
              preferEphemeral: true,
            ),
          );

          final token = Uri.parse(result).queryParameters['token'];
          if (token != null) {
            await user.signIn(token);
            Timer(const Duration(seconds: 3), () => onComplete?.call());
          } else {
            onComplete?.call();
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(localizations.signInError)), // Use captured
            );
          }
        } on PlatformException catch (e) {
          onComplete?.call();
          if (e.code != "CANCELLED") {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                  content: Text('${localizations.signInError}: ${e.message}')), // Use captured
            );
          }
        } catch (e) {
          onComplete?.call();
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('${localizations.signInError}: $e')), // Use captured
          );
        }
      },
    );
  }
}