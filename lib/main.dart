import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/services/flacore_audio_handler.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/onboarding_screen.dart';

/// Global singleton audio handler initialized at app startup.
/// Lazily falls back to a default instance if accessed before AudioService.init (e.g. in tests).
FlaCoreAudioHandler? _audioHandler;
FlaCoreAudioHandler get audioHandler => _audioHandler ??= FlaCoreAudioHandler();
set audioHandler(FlaCoreAudioHandler handler) => _audioHandler = handler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    audioHandler = await AudioService.init(
      builder: () => FlaCoreAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.flacore.flacore.channel.audio.v2',
        androidNotificationChannelName: 'FlaCore Music Playback',
        androidNotificationChannelDescription:
            'Kontrol pemutaran musik FlaCore',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  } catch (e, st) {
    debugPrint('AudioService.init Error: $e\n$st');
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(FlaCoreApp(hasSeenOnboarding: hasSeenOnboarding));
}

class FlaCoreApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final FlaCoreAudioHandler? handler;

  const FlaCoreApp({
    super.key,
    this.hasSeenOnboarding = true,
    this.handler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(audioHandler: handler ?? audioHandler),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'FlaCore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: hasSeenOnboarding ? const MainShell() : const OnboardingScreen(),
      ),
    );
  }
}
