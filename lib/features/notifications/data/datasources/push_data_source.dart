import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The only class that talks to Firebase Cloud Messaging and the local
/// notifications plugin (HU-24, lessons K3 and K4).
///
/// Each citizen has a topic, `user_<id>`: the Edge Function `send-push` sends
/// there, so only that citizen's devices receive it. Where Firebase was not
/// started (web, desktop, tests) every method does nothing.
class PushDataSource {
  static const _channel = AndroidNotificationChannel(
    'vigia_alerts',
    'Avisos de VIGÍA',
    description: 'Apoyos, comentarios y reparaciones de tus reportes.',
    importance: Importance.max,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _opened = StreamController<String>.broadcast();
  bool _started = false;

  bool get _available => Firebase.apps.isNotEmpty;

  static String topicFor(String userId) => 'user_$userId';

  Future<void> subscribe(String userId) async {
    if (!_available) return;
    await _start();
    await FirebaseMessaging.instance.subscribeToTopic(topicFor(userId));
  }

  Future<void> unsubscribe(String userId) async {
    if (!_available) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic(topicFor(userId));
  }

  /// The report of the push that launched the app first, then every tap.
  Stream<String> openedReports() async* {
    if (!_available) return;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final fromPush = _incidentOf(initial?.data);
    if (fromPush != null) yield fromPush;
    final launch = await _local.getNotificationAppLaunchDetails();
    final fromLocal = launch?.didNotificationLaunchApp == true ? launch?.notificationResponse?.payload : null;
    if (fromLocal != null && fromLocal.isNotEmpty) yield fromLocal;
    yield* _opened.stream;
  }

  /// Permission (Android 13+), the channel that shows pushes on top of the
  /// screen, and the listeners. Runs once.
  Future<void> _start() async {
    if (_started) return;
    _started = true;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await _local.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) _opened.add(id);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    // With the app open Android shows nothing by itself: show it here.
    FirebaseMessaging.onMessage.listen(_show);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final id = _incidentOf(message.data);
      if (id != null) _opened.add(id);
    });
  }

  void _show(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      payload: _incidentOf(message.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  String? _incidentOf(Map<String, dynamic>? data) {
    final id = data?['incidentId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  @visibleForTesting
  Future<void> dispose() => _opened.close();
}
