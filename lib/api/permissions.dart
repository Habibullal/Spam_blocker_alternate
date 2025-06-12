import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const channel = MethodChannel("com.example.spam_blocker/channel");

Future<void> changeDefaultApps() async {
  const intent = AndroidIntent(
    action: 'android.settings.MANAGE_DEFAULT_APPS_SETTINGS',
  );
  try {
    await intent.launch();
  } catch (e, st) {
    if (kDebugMode) {
      print('Error launching Default Apps Settings: $e\n$st');
    }
  }
}

Future<bool> hasPermissions() async{
  return (await channel.invokeMethod<bool>('hasRedirectionPermission') ?? false) && (await channel.invokeMethod<bool>('hasScreeningPermission')?? false);

}
