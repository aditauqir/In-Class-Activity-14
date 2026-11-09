import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../fcm_service.dart';

class FcmBanner extends StatefulWidget {
  const FcmBanner({super.key});

  @override
  State<FcmBanner> createState() => _FcmBannerState();
}

class _FcmBannerState extends State<FcmBanner> {
  final FCMService _fcmService = FCMService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _assets = {
    'default': 'assets/images/fall_banner.jpg',
    'promo': 'assets/images/fall_banner.jpg',
    'fall': 'assets/images/fall_banner.jpg',
  };

  String _statusText = 'New promotion';
  String _imagePath = 'assets/images/fall_banner.jpg';
  String? _storageImageUrl;
  String _feedback = 'Waiting for a cloud message';
  String _lastHandler = 'None yet';
  String _lastMessageId = 'None yet';
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeMessaging());
    unawaited(_checkAndSyncStorageBanner());
  }

  void _report(String text) {
    debugPrint(text);
    if (mounted) setState(() => _feedback = text); }

  Future<void> _checkAndSyncStorageBanner() async {
    try {
      final storageRef = _storage.ref('banners/fall_banner.jpg');
      final url = await storageRef.getDownloadURL();
      if (mounted) {
        setState(() {
          _storageImageUrl = url;
        });
      }
    } catch (e) {
      debugPrint('Firebase Storage notice: $e (using local asset fallback)');
    }
  }

  Future<void> _initializeMessaging() async {
    try {
      await _fcmService.initialize(
        onData: (message, source) => unawaited(_handleMessage(message, source)),
        onStatus: _report,
      );
    } on FirebaseException catch (error, stack) {
      debugPrint('Firebase error: $error\n$stack');
      _report('Messaging error (${error.code}): ${error.message}');
    } on StateError catch (error, stack) {
      debugPrint('Messaging setup error: $error\n$stack');
      _report(error.message.toString()); }
  }

  Future<void> _handleMessage(RemoteMessage message, String source) async {
    if (!mounted) return;
    setState(() {
      _lastHandler = source;
      _lastMessageId = message.messageId ?? '(no ID)';
      _messageCount += 1;
    });

    final action = message.data['action'];
    final assetKey = message.data['asset'];
    final storagePath = message.data['storage_path'];
    final directUrl = message.data['image_url'];

    String? resolvedNetworkUrl = directUrl;
    if (storagePath != null && storagePath.toString().isNotEmpty) {
      try {
        final ref = _storage.ref(storagePath.toString());
        resolvedNetworkUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Firebase Storage error for $storagePath: $e');
      }
    }

    final path = _assets[assetKey];
    if (action != 'update_ui' || (path == null && resolvedNetworkUrl == null)) {
      _report('Rejected payload: use action=update_ui and '
          'asset=default or asset=promo, or valid storage_path. Previous content preserved.');
      return; }

    setState(() {
      _statusText = message.notification?.title ?? 'New promotion';
      if (path != null) _imagePath = path;
      _storageImageUrl = resolvedNetworkUrl;
      _feedback = 'Applied payload\n${message.messageId ?? "(no ID)"}';
    });
  }

  @override
  void dispose() {
    unawaited(_fcmService.dispose().catchError(
      (Object error, StackTrace stack) {
        debugPrint('FCM cleanup error: $error\n$stack'); },
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Text(
            _statusText,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Image spans the entire phone width with Firebase Storage & local asset fallback
        if (_storageImageUrl != null && _storageImageUrl!.isNotEmpty)
          Image.network(
            _storageImageUrl!,
            height: 125,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Image.asset(
              _imagePath,
              height: 125,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Image.asset(
            _imagePath,
            height: 125,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                height: 125,
                color: Colors.amber.shade100,
                alignment: Alignment.center,
                child: Text('Fall Banner', style: GoogleFonts.outfit()),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last handler: $_lastHandler',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                'Messages handled this launch: $_messageCount',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                'Last message ID:\n$_lastMessageId',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                _feedback,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _feedback.startsWith('Rejected')
                      ? Colors.red.shade700
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
