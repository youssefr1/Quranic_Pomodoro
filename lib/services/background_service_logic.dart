import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationChannelId = 'pomodoro_foreground';
const String notificationChannelName = 'Pomodoro Service';
const int notificationId = 888;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelName,
    description: 'This channel is used for pomodoro timer notifications.',
    importance: Importance.low, // low importance so it doesn't pop up every second
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'قرآني بومودورو',
      initialNotificationContent: 'ابدأ جلستك الآن',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Timer logic in background
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final prefs = await SharedPreferences.getInstance();
        final endTimeStr = prefs.getString('pomodoro_end_time');
        final stateLabel = prefs.getString('pomodoro_state_label') ?? 'وقت التركيز';
        
        if (endTimeStr != null) {
          final endTime = DateTime.parse(endTimeStr);
          final remaining = endTime.difference(DateTime.now());

          if (remaining.inSeconds > 0) {
            final minutes = (remaining.inSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
            
            flutterLocalNotificationsPlugin.show(
              notificationId,
              'قرآني بومودورو - $stateLabel',
              'الوقت المتبقي: $minutes:$seconds',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  notificationChannelName,
                  icon: '@mipmap/ic_launcher',
                  ongoing: true,
                  onlyAlertOnce: true,
                ),
              ),
            );
          } else {
            // Timer Finished
            flutterLocalNotificationsPlugin.show(
              notificationId,
              'مبارك!',
              'انتهت جلسة التركيز بنجاح. حان وقت الاستراحة.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  notificationChannelName,
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            );
            prefs.remove('pomodoro_end_time');
            service.stopSelf();
          }
        }
      }
    }

    // Update foreground if needed
    service.invoke('update');
  });
}
