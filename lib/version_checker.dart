import 'dart:async';

import 'package:harvest_guard/global.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class VersionChecker {
  static const String GITHUB_API_URL =
      'https://api.github.com/repos/harvestguard/HarvestGuardApp/releases/latest';

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final ValueNotifier<double> downloadProgress =
      ValueNotifier<double>(0);
  static const int notificationId = 888;
  static bool _isCancelled = false;
  static bool hasChecked = false;
  static StreamController<bool>? _downloadController;

  static Future<void> checkForUpdate(BuildContext context) async {
    print("Checking for updates...");
    try {
      // Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      // String currentVersion = '0.0.1'; // For testing

      print("Current version: $currentVersion");

      // Get latest version from GitHub
      final response = await http.get(Uri.parse(GITHUB_API_URL));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion =
            data['tag_name'].replaceAll('v', '').split('-')[0];
        String downloadUrl = data['assets'][0]['browser_download_url'];

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          _showUpdateDialog(context, downloadUrl, latestVersion, data['body']);
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String downloadUrl,
      String version, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A new version ($version) of the app is available.'),
                  const SizedBox(height: 16),
                  const Text('Release Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MarkdownBody(
                      data: releaseNotes,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Remind Me Later'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Update Now'),
            onPressed: () {
              Navigator.pop(context);
              _showProgressDialog(context);
              _downloadAndInstall(downloadUrl);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(String downloadUrl) async {
    _downloadController = StreamController<bool>();
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/app-update.apk';
      final request =
          await http.Client().send(http.Request('GET', Uri.parse(downloadUrl)));
      final contentLength = request.contentLength ?? 0;
      final file = File(filePath);
      final sink = file.openWrite();
      int received = 0;

      await for (final chunk in request.stream) {
        if (_isCancelled) {
          await sink.close();
          await file.delete();
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        final progress = received / contentLength;
        downloadProgress.value = progress;

        if (!_isCancelled) {
          await flutterLocalNotificationsPlugin.show(
            notificationId,
            'Downloading Update',
            'Download in progress...',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'update_channel',
                'App Updates',
                channelDescription: 'Notifications for app updates',
                importance: Importance.high,
                priority: Priority.high,
                showProgress: true,
                maxProgress: 100,
                progress: (progress * 100).round(),
              ),
            ),
            payload: 'download_progress',
          );
        }
      }

      await sink.close();
      if (!_isCancelled) {
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        if (Platform.isAndroid) {
          final hasPermission = await _checkInstallPermission();
          if (hasPermission) {
            await OpenFile.open(filePath);
          } else {
            print('Permission denied to install the APK. Please allow installation from unknown sources in your device settings.');
          }
        }
      }
    } catch (e) {
      print('Error downloading update: $e');
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    } finally {
      _downloadController?.close();
      _downloadController = null;
    }
  }

  static Future<void> initNotifications() async {
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher_monochrome');
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == 'download_progress') {
          _showProgressDialog(navigatorKeyMain.currentContext!);
        }
      },
    );
  }

  static void _showProgressDialog(BuildContext context) {
    _isCancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Downloading Update'),
        content: ValueListenableBuilder<double>(
          valueListenable: downloadProgress,
          builder: (context, progress, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                Text('${(progress * 100).toStringAsFixed(1)}%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              _isCancelled = true;
              _downloadController?.add(true);
              _downloadController?.close();
              flutterLocalNotificationsPlugin.cancel(notificationId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  static Future<bool> _checkInstallPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (status.isDenied) {
        final result = await Permission.requestInstallPackages.request();
        if (result.isDenied) {
          return false;
        }
      }
    }
    return true;
  }
}
