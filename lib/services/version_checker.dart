import 'dart:async';

import 'package:harvest_guard/global.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class VersionChecker {
  static const String GITHUB_API_URL =
      'https://api.github.com/repos/harvestguard/HarvestGuardApp/releases/latest';

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final ValueNotifier<double> downloadProgress =
      ValueNotifier<double>(0);
  static final ValueNotifier<String> downloadSpeedText =
      ValueNotifier<String>("0 B/s");
  static final ValueNotifier<String> timeLeftText =
      ValueNotifier<String>("calculating...");
  static const int notificationId = 888;
  static const int permanentNotificationId =
      889; // NEW constant for permanent notification
  static bool _isCancelled = false;
  static bool hasChecked = false;
  static StreamController<bool>? _downloadController;

  static Future<bool> checkForUpdate(BuildContext context) async {
    print("Checking for updates...");
    try {
      // Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // String currentVersion = packageInfo.version;
      String currentVersion = '1.2702.1';

      print("Current version: $currentVersion");

      // Get latest version from GitHub
      final response = await http.get(Uri.parse(GITHUB_API_URL));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion =
            data['tag_name'].replaceAll('v', '').split('-')[0];
        String downloadUrl = data['assets'][0]['browser_download_url'];

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          showUpdateDialog(context, downloadUrl, latestVersion, data['body']);
          return true;
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }

    return false;
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

  static void showUpdateDialog(BuildContext context, String downloadUrl,
      String version, String releaseNotes,
      {bool force = false}) {
    // Show a permanent notification indicating an available update.
    if (!force) _showPermanentUpdateNotification(version);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            force ? const Text('Force update') : const Text('Update available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              force
                  ? Text('You have chosen to forcefully update the app.')
                  : Text('A new version ($version) of the app is available.'),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MarkdownBody(
                  data: releaseNotes,
                  onTapLink: (text, href, title) {
                    _onTapLink(text, href, title);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: force ? const Text('Cancel') : const Text('Remind me later'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Download package'),
            onPressed: () {
              Navigator.pop(context);
              _showProgressDialog(context);
              _downloadAndInstall(downloadUrl, install: false);
            },
          ),
          TextButton(
            child:
                force ? const Text('Force update') : const Text('Update now'),
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

  /// NEW: Show a permanent notification about the available update.
  static Future<void> _showPermanentUpdateNotification(String version) async {
    await flutterLocalNotificationsPlugin.show(
      permanentNotificationId,
      'Update Available',
      'A new version ($version) is available. Tap to update.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'update_channel',
          'App Updates',
          channelDescription: 'Notifications for app updates',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true, // Make notification persistent
          autoCancel: false, // Prevent auto-cancellation when tapped
        ),
      ),
      payload: 'update_notification',
    );
  }

  static Future<void> _downloadAndInstall(String downloadUrl,
      {bool install = true}) async {
    _downloadController = StreamController<bool>();
    DateTime startTime = DateTime.now();
    try {
      // get the last part of the download URL as the file name
      final fileName = downloadUrl.split('/').last;      
      final filePath = install
          ? '${(await getTemporaryDirectory()).path}/app-update.apk'
          : '/storage/emulated/0/Download/$fileName';
      final request =
          await http.Client().send(http.Request('GET', Uri.parse(downloadUrl)));
      final contentLength = request.contentLength ?? 0;
      final file = File(filePath);
      final sink = file.openWrite();
      int received = 0;

      print('Downloading update to: $filePath, install: $install');

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

        // Calculate elapsed time in seconds.
        final elapsed =
            DateTime.now().difference(startTime).inMilliseconds / 1000;
        if (elapsed > 0) {
          // Calculate speed in bytes per second.
          double speed = received / elapsed;
          String speedFormatted = _formatSpeed(speed);
          // Calculate remaining time.
          int secondsLeft =
              speed > 0 ? ((contentLength - received) / speed).round() : 0;
          int minutes = secondsLeft ~/ 60;
          int secs = secondsLeft % 60;
          String formattedTime =
              minutes > 0 ? "${minutes}m ${secs}s" : "${secs}s";
          downloadSpeedText.value = speedFormatted;
          timeLeftText.value = formattedTime;
        }

        // Update the download notification with progress details.
        if (!_isCancelled) {
          await flutterLocalNotificationsPlugin.show(
            notificationId,
            'Downloading Update',
            'Download in progress...\nSpeed: ${downloadSpeedText.value} - Time left: ${timeLeftText.value}',
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
        if (install) {
          if (Platform.isAndroid) {
            final hasPermission = await _checkInstallPermission();
            if (hasPermission) {
              final apkFile = File(filePath);
              if (await apkFile.exists() && await apkFile.length() > 0) {
                // hide the progress dialog
                Navigator.pop(navigatorKeyMain.currentContext!);
                _installApk(filePath);
              }
            }
          } else {
            _logError('Permission denied to install the APK. Please allow installation from unknown sources in your device settings.');
              // Show a notification to inform user about permission issue
            await _showInstallFailedNotification(
                'Permission denied. Please allow installation from unknown sources.');
          }
        } else {
          Navigator.pop(navigatorKeyMain.currentContext!);
          showDialog(
            context: navigatorKeyMain.currentContext!,
            builder: (context) => AlertDialog(
              title: const Text('Download Complete'),
              content: const Text(
                  'The update has been downloaded successfully, the file can be found in your download folder.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _logError('Error downloading update: $e');
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await _showInstallFailedNotification(
          'Download failed. Please try again later.');
    }
  }

  static Future<void> _installApk(String filePath) async {
    try {
      await InstallPlugin.installApk(filePath);
      // Show a notification that installation has started
      await flutterLocalNotificationsPlugin.show(
        notificationId + 1,
        'Installing Update',
        'Installation in progress. Please follow the on-screen instructions.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'update_channel',
            'App Updates',
            channelDescription: 'Notifications for app updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      _logError('Error installing APK: $e');
      await _showInstallFailedNotification(
          'Installation failed. Please try manually.');
    }
  }

  static Future<void> _showInstallFailedNotification(String message) async {
    await flutterLocalNotificationsPlugin.show(
      notificationId + 2,
      'Update Failed',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'update_channel',
          'App Updates',
          channelDescription: 'Notifications for app updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static void _logError(String message) {
    // Replace with your preferred logging framework
    debugPrint('[ERROR] VersionChecker: $message');
  }

  static String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec > 1024 * 1024) {
      return "${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s";
    } else if (bytesPerSec > 1024) {
      return "${(bytesPerSec / 1024).toStringAsFixed(2)} kB/s";
    } else {
      return "${bytesPerSec.toStringAsFixed(2)} B/s";
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
        } else if (details.payload == 'update_notification') {
          // Handle the tap on the permanent notification
          _handleUpdateNotificationTap();
        }
      },
    );
  }

  // New method to handle the update notification tap
  static Future<void> _handleUpdateNotificationTap() async {
    final context = navigatorKeyMain.currentContext;
    if (context == null) return;

    // Re-fetch the update information
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(GITHUB_API_URL));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion =
            data['tag_name'].replaceAll('v', '').split('-')[0];
        String downloadUrl = data['assets'][0]['browser_download_url'];

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          showUpdateDialog(context, downloadUrl, latestVersion, data['body']);
        }
      }
    } catch (e) {
      print('Error handling update notification tap: $e');
    }
  }

  // Update the _showProgressDialog function for a more elegant UI:
  static void _showProgressDialog(BuildContext context) {
    _isCancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Center(
          child: Column(
            children: [
              const Text(
                'Downloading Update',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: downloadProgress,
                builder: (context, progress, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: downloadProgress,
                builder: (context, progress, _) {
                  return Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: downloadSpeedText,
                    builder: (context, speed, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed, size: 16),
                          const SizedBox(width: 4),
                          Text(speed, style: const TextStyle(fontSize: 14)),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: timeLeftText,
                    builder: (context, time, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 16),
                          const SizedBox(width: 4),
                          Text(time, style: const TextStyle(fontSize: 14)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Hide'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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

  // NEW: Function to handle link taps from Markdown content.
  static Future<void> _onTapLink(
      String? text, String? href, String? title) async {
    if (href == null) return;
    final Uri url = Uri.parse(href);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $href');
    }
  }
}
