import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flacore/main.dart';
import 'package:flacore/core/constants/api_constants.dart';
import 'package:flacore/core/utils/formatters.dart';
import 'package:flacore/data/models/song_model.dart';
import 'package:flacore/data/services/api_service.dart';
import 'package:flacore/data/services/artist_image_service.dart';
import 'package:flacore/data/services/lyrics_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flacore/providers/library_provider.dart';
import 'package:flacore/providers/player_provider.dart';
import 'package:flacore/ui/screens/artist_detail_screen.dart';
import 'package:flacore/ui/screens/now_playing_screen.dart';
import 'package:flacore/ui/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FlaCoreApp smoke test renders MainShell with FlaCore header',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlaCoreApp());
    expect(find.text('FlaCore'), findsOneWidget);
  });

  testWidgets('FlaCoreApp shows OnboardingScreen when hasSeenOnboarding is false',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlaCoreApp(hasSeenOnboarding: false));
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Age Of'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('OnboardingScreen Get Started saves preference',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'server_api_url': 'https://flacore.example.com',
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LibraryProvider()),
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_onboarding'), isTrue);
  });

  group('Formatters tests', () {
    test('formatDuration converts seconds to mm:ss correctly', () {
      expect(formatDuration(0), '00:00');
      expect(formatDuration(59), '00:59');
      expect(formatDuration(60), '01:00');
      expect(formatDuration(75), '01:15');
      expect(formatDuration(3665), '61:05');
    });

    test('formatAudioQuality handles Hi-Res vs Lossless CD correctly', () {
      expect(
        formatAudioQuality(16, 44100),
        'Lossless CD • 16-bit / 44.1 kHz',
      );
      expect(
        formatAudioQuality(24, 44100),
        'Hi-Res Lossless • 24-bit / 44.1 kHz',
      );
      expect(
        formatAudioQuality(16, 48000),
        'Hi-Res Lossless • 16-bit / 48.0 kHz',
      );
      expect(
        formatAudioQuality(24, 96000),
        'Hi-Res Lossless • 24-bit / 96.0 kHz',
      );
    });
  });

  group('Song Model tests', () {
    setUp(() {
      ApiConstants.setBaseUrl('https://flacore.example.com');
    });

    test('Song.fromJson parses all fields and computed properties properly', () {
      final json = {
        'id': 'test-uuid-1',
        'title': 'All Night',
        'artist': 'IVE, Saweetie',
        'album': 'All Night Single',
        'duration': 198,
        'bit_depth': 24,
        'sample_rate': 96000,
        'bitrate': 3154,
        'file_path': '/music/All Night.flac',
        'has_cover': true,
        'created_at': '2026-10-26T05:52:00.000Z',
      };

      final song = Song.fromJson(json);

      expect(song.id, 'test-uuid-1');
      expect(song.title, 'All Night');
      expect(song.artist, 'IVE, Saweetie');
      expect(song.album, 'All Night Single');
      expect(song.duration, 198);
      expect(song.bitDepth, 24);
      expect(song.sampleRate, 96000);
      expect(song.bitrate, 3154);
      expect(song.filePath, '/music/All Night.flac');
      expect(song.hasCover, true);
      expect(song.createdAt, DateTime.parse('2026-10-26T05:52:00.000Z'));

      // Check artistList separation
      expect(song.artistList, ['IVE', 'Saweetie']);

      // Check isHiRes getter (24-bit / 96kHz)
      expect(song.isHiRes, isTrue);

      // Check URL and label helpers
      expect(song.streamUrl, '${ApiConstants.baseUrl}/api/stream/test-uuid-1');
      expect(song.coverUrl, '${ApiConstants.baseUrl}/api/songs/test-uuid-1/cover');
      expect(song.formattedDuration, '03:18');
      expect(song.audioQualityLabel, 'Hi-Res Lossless • 24-bit / 96.0 kHz');
    });

    test('Song.isHiRes returns false for standard 16-bit 44.1kHz', () {
      final json = {
        'id': 'test-uuid-2',
        'title': 'Standard Song',
        'artist': 'NewJeans',
        'album': 'Album A',
        'duration': 150,
        'bit_depth': 16,
        'sample_rate': 44100,
        'bitrate': 915,
        'file_path': '/music/song.flac',
        'has_cover': false,
      };

      final song = Song.fromJson(json);
      expect(song.artistList, ['NewJeans']);
      expect(song.isHiRes, isFalse);
      expect(song.audioQualityLabel, 'Lossless CD • 16-bit / 44.1 kHz');
    });
  });

  group('ApiService tests', () {
    test('fetchSongs returns parsed songs list on 200', () async {
      final mockData = [
        {
          'id': '1',
          'title': 'Whiplash',
          'artist': 'aespa',
          'album': 'Whiplash',
          'duration': 183,
          'bit_depth': 16,
          'sample_rate': 44100,
          'bitrate': 1057,
          'file_path': '/opt/music/whiplash.flac',
          'has_cover': true,
        }
      ];

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), ApiConstants.songsEndpoint);
        return http.Response(jsonEncode(mockData), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final api = ApiService(client: mockClient);
      final songs = await api.fetchSongs();

      expect(songs.length, 1);
      expect(songs.first.title, 'Whiplash');
      expect(songs.first.artist, 'aespa');
    });

    test('triggerScan returns true on 200/202', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), ApiConstants.scanEndpoint);
        return http.Response(
          jsonEncode({'status': 'scan initiated'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(client: mockClient);
      final success = await api.triggerScan();

      expect(success, isTrue);
    });
  });

  group('LibraryProvider tests', () {
    late List<Song> sampleSongs;

    setUp(() {
      sampleSongs = [
        const Song(
          id: '1',
          title: 'Supernova',
          artist: 'aespa',
          album: 'Supernova',
          duration: 179,
          bitDepth: 24,
          sampleRate: 96000,
          bitrate: 3034,
          filePath: '/path/1',
          hasCover: true,
        ),
        const Song(
          id: '2',
          title: 'All Night',
          artist: 'IVE, Saweetie',
          album: 'All Night Single',
          duration: 198,
          bitDepth: 24,
          sampleRate: 96000,
          bitrate: 3154,
          filePath: '/path/2',
          hasCover: true,
        ),
        const Song(
          id: '3',
          title: 'Armageddon',
          artist: 'aespa',
          album: 'Armageddon',
          duration: 197,
          bitDepth: 24,
          sampleRate: 96000,
          bitrate: 3100,
          filePath: '/path/3',
          hasCover: true,
        ),
        const Song(
          id: '4',
          title: 'Super Shy',
          artist: 'NewJeans',
          album: 'Get Up',
          duration: 155,
          bitDepth: 16,
          sampleRate: 44100,
          bitrate: 915,
          filePath: '/path/4',
          hasCover: true,
        ),
      ];
    });

    test('artistsMap groups and sorts artists A-Z and songs A-Z', () async {
      final mockClient = MockClient((request) async {
        final jsonList = sampleSongs.map((s) => s.toJson()).toList();
        return http.Response(jsonEncode(jsonList), 200);
      });

      final provider = LibraryProvider(apiService: ApiService(client: mockClient));
      await provider.loadSongs();

      final map = provider.artistsMap;

      // Artists should be sorted A-Z: 'aespa', 'IVE', 'NewJeans', 'Saweetie'
      expect(map.keys.toList(), ['aespa', 'IVE', 'NewJeans', 'Saweetie']);

      // Collaboration song 'All Night' should appear in BOTH 'IVE' and 'Saweetie'
      expect(map['IVE']!.map((s) => s.title).toList(), ['All Night']);
      expect(map['Saweetie']!.map((s) => s.title).toList(), ['All Night']);

      // aespa songs should be sorted A-Z by title: 'Armageddon', 'Supernova'
      expect(
        map['aespa']!.map((s) => s.title).toList(),
        ['Armageddon', 'Supernova'],
      );
    });

    test('searchQuery filters songs and artists properly', () async {
      final mockClient = MockClient((request) async {
        final jsonList = sampleSongs.map((s) => s.toJson()).toList();
        return http.Response(jsonEncode(jsonList), 200);
      });

      final provider = LibraryProvider(apiService: ApiService(client: mockClient));
      await provider.loadSongs();

      // Search for 'super'
      provider.setSearchQuery('super');

      // filteredSongs should match 'Supernova' and 'Super Shy'
      final filteredSongs = provider.filteredSongs;
      expect(filteredSongs.length, 2);
      expect(
        filteredSongs.map((s) => s.title).toSet(),
        {'Supernova', 'Super Shy'},
      );

      // filteredArtists should contain 'aespa' and 'NewJeans'
      final filteredArtists = provider.filteredArtists;
      expect(filteredArtists.containsKey('aespa'), isTrue);
      expect(filteredArtists.containsKey('NewJeans'), isTrue);
      expect(filteredArtists.containsKey('IVE'), isFalse);
    });
  });

  group('PlayerProvider tests', () {
    test('initial state is correct', () {
      final playerProvider = PlayerProvider();

      expect(playerProvider.currentSong, isNull);
      expect(playerProvider.hasCurrentSong, isFalse);
      expect(playerProvider.playlist, isEmpty);
      expect(playerProvider.currentIndex, -1);
      expect(playerProvider.isPlaying, isFalse);
      expect(playerProvider.position, Duration.zero);
      expect(playerProvider.duration, Duration.zero);
      expect(playerProvider.isBuffering, isFalse);
      expect(playerProvider.progress, 0.0);
      expect(playerProvider.hasNext, isFalse);
      expect(playerProvider.hasPrevious, isFalse);

      playerProvider.dispose();
    });
  });

  group('ArtistDetailScreen tests', () {
    testWidgets('renders artist header, Play All button, and tracks list',
        (WidgetTester tester) async {
      const sampleSongs = [
        Song(
          id: 'test-1',
          title: 'Supernova',
          artist: 'aespa',
          album: 'Supernova',
          duration: 179,
          bitDepth: 24,
          sampleRate: 96000,
          bitrate: 3034,
          filePath: '/opt/music/supernova.flac',
          hasCover: false,
        ),
        Song(
          id: 'test-2',
          title: 'Whiplash',
          artist: 'aespa',
          album: 'Whiplash',
          duration: 183,
          bitDepth: 16,
          sampleRate: 44100,
          bitrate: 1057,
          filePath: '/opt/music/whiplash.flac',
          hasCover: false,
        ),
      ];

      await tester.pumpWidget(
        const FlaCoreApp(),
      );

      // Verify FlaCoreApp renders
      expect(find.text('FlaCore'), findsWidgets);

      // Pump ArtistDetailScreen wrapped in PlayerProvider and MaterialApp
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(),
          child: const MaterialApp(
            home: ArtistDetailScreen(
              artistName: 'aespa',
              songs: sampleSongs,
            ),
          ),
        ),
      );

      expect(find.text('aespa'), findsWidgets);
      expect(find.text('Supernova'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });

  group('NowPlayingScreen tests', () {
    testWidgets('renders empty state when no song is active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(),
          child: const MaterialApp(
            home: NowPlayingScreen(),
          ),
        ),
      );

      expect(find.text('No track loaded'), findsOneWidget);
    });
  });

  group('LyricsService tests', () {
    test('sanitizeTitle strips parentheses, brackets, and album suffixes', () {
      expect(
        LyricsService.sanitizeTitle('Supernova (feat. Someone)'),
        'Supernova',
      );
      expect(
        LyricsService.sanitizeTitle('Whiplash [Official Audio]'),
        'Whiplash',
      );
      expect(
        LyricsService.sanitizeTitle("Armageddon - The 1st Album 'Armageddon'"),
        'Armageddon',
      );
      expect(
        LyricsService.sanitizeTitle('Drama (Remix) - Single'),
        'Drama',
      );
    });

    test('sanitizeArtist extracts primary artist correctly', () {
      expect(LyricsService.sanitizeArtist('IVE, Saweetie'), 'IVE');
      expect(
        LyricsService.sanitizeArtist('LE SSERAFIM, ILLIT, Kep1er'),
        'LE SSERAFIM',
      );
      expect(LyricsService.sanitizeArtist('aespa feat. NAVIS'), 'aespa');
      expect(LyricsService.sanitizeArtist('NewJeans ft. Jon Batiste'), 'NewJeans');
    });

    test('parseLrc correctly parses timestamps and sorts chronologically', () {
      const sampleLrc = '''
[ti:Supernova]
[ar:aespa]
[00:14.25]I'm like some kind of Supernova
[00:04.10]Drop
[00:20.500]Body bang
''';
      final lyrics = LyricsService.parseLrc(sampleLrc);

      expect(lyrics.length, 3);
      // Chronological order: 00:04.10, 00:14.25, 00:20.500
      expect(lyrics[0].text, 'Drop');
      expect(lyrics[0].timestamp, const Duration(seconds: 4, milliseconds: 100));

      expect(lyrics[1].text, "I'm like some kind of Supernova");
      expect(lyrics[1].timestamp, const Duration(seconds: 14, milliseconds: 250));

      expect(lyrics[2].text, 'Body bang');
      expect(lyrics[2].timestamp, const Duration(seconds: 20, milliseconds: 500));
    });

    test('fetchLyrics returns parsed lyrics on 200 and null on 404/error', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['track_name'] == 'Supernova') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'trackName': 'Supernova',
              'artistName': 'aespa',
              'syncedLyrics': '[00:05.00]Ah oh ay\n[00:10.00]Nu na',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = LyricsService(client: mockClient);

      final found = await service.fetchLyrics('Supernova', 'aespa');
      expect(found, isNotNull);
      expect(found!.length, 2);
      expect(found.first.text, 'Ah oh ay');

      final notFound = await service.fetchLyrics('Unknown Song', 'Unknown Artist');
      expect(notFound, isNull);
    });
  });

  group('PlayerProvider Lyrics tests', () {
    test('initial lyrics state and toggleLyricsView work properly', () {
      final provider = PlayerProvider();

      expect(provider.currentLyrics, isNull);
      expect(provider.currentLyricIndex, -1);
      expect(provider.showLyrics, isFalse);
      expect(provider.isLoadingLyrics, isFalse);

      provider.toggleLyricsView();
      expect(provider.showLyrics, isTrue);

      provider.toggleLyricsView();
      expect(provider.showLyrics, isFalse);

      provider.dispose();
    });
  });

  group('ArtistImageService Deezer API tests', () {
    setUp(() {
      ArtistImageService.clearMemoryCache();
    });

    test('returns cached URL from SharedPreferences without network request', () async {
      SharedPreferences.setMockInitialValues({
        'artist_img_v4_daftpunk': 'https://cached.deezer.com/daftpunk.jpg',
      });

      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('Daft Punk');

      expect(url, 'https://cached.deezer.com/daftpunk.jpg');
      expect(requestMade, isFalse);
    });

    test('fetches from Deezer API, caches result, and returns picture_big or picture_medium', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'api.deezer.com');
        expect(request.url.path, '/search/artist');
        expect(request.url.queryParameters['q'], 'IU');
        expect(request.url.queryParameters['limit'], '15');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 12345,
                'name': 'IU',
                'nb_fan': 1500000,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/medium.jpg',
                'picture_big': 'https://e-cdns-images.dzcdn.net/big.jpg',
              }
            ],
            'total': 1,
          }),
          200,
        );
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('IU');

      expect(url, 'https://e-cdns-images.dzcdn.net/big.jpg');

      // Verify SharedPreferences cache was written with v4 prefix and clean name
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('artist_img_v4_iu'), 'https://e-cdns-images.dzcdn.net/big.jpg');
    });

    test('does NOT match partial name substring (IVE vs Ivete Sangalo case)', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'IVE');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 999,
                'name': 'Ivete Sangalo',
                'nb_fan': 2200000, // Massive fan count, but NOT an exact normalized match
                'picture_big': 'https://e-cdns-images.dzcdn.net/ivete.jpg',
              },
              {
                'id': 888,
                'name': 'IVE',
                'nb_fan': 350000,
                'picture_big': 'https://e-cdns-images.dzcdn.net/ive_official.jpg',
              },
            ],
            'total': 2,
          }),
          200,
        );
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('IVE');

      // Must strictly pick IVE, never Ivete Sangalo
      expect(url, 'https://e-cdns-images.dzcdn.net/ive_official.jpg');
    });

    test('prioritizes official artist with highest fan count when normalized names match (Jung Kook case)', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'Jung Kook');
        expect(request.url.queryParameters['limit'], '15');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 101,
                'name': 'Jung Kook',
                'nb_fan': 7511,
                'picture_big': 'https://e-cdns-images.dzcdn.net/jungkook_low.jpg',
              },
              {
                'id': 102,
                'name': 'Jungkook',
                'nb_fan': 474240,
                'picture_big': 'https://e-cdns-images.dzcdn.net/jungkook_official.jpg',
              },
              {
                'id': 103,
                'name': 'Jung Kook Cover Band',
                'nb_fan': 42,
                'picture_big': 'https://e-cdns-images.dzcdn.net/cover.jpg',
              },
            ],
            'total': 3,
          }),
          200,
        );
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('Jung Kook');

      // Must select the official profile with 474,240 fans despite spacing variation
      expect(url, 'https://e-cdns-images.dzcdn.net/jungkook_official.jpg');
    });

    test('selects exact name match with highest nb_fan over obscure artist or partial match', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'BTS');
        expect(request.url.queryParameters['limit'], '15');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 101,
                'name': 'BTS Official Club',
                'nb_fan': 50000,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/bts_club.jpg',
              },
              {
                'id': 102,
                'name': 'BTS',
                'nb_fan': 12,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/bts_obscure.jpg',
              },
              {
                'id': 103,
                'name': 'bts',
                'nb_fan': 4500000,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/bts_real.jpg',
              },
              {
                'id': 104,
                'name': 'BTS Band',
                'nb_fan': 200,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/bts_band.jpg',
              },
            ],
            'total': 4,
          }),
          200,
        );
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('BTS');

      // Should choose the match with highest nb_fan (4,500,000)
      expect(url, 'https://e-cdns-images.dzcdn.net/bts_real.jpg');
    });

    test('selects candidate with highest nb_fan when no exact match exists', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 201,
                'name': 'Zico Chain',
                'nb_fan': 150,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/zico_small.jpg',
              },
              {
                'id': 202,
                'name': 'ZICO (지코)',
                'nb_fan': 890000,
                'picture_medium': 'https://e-cdns-images.dzcdn.net/zico_popular.jpg',
              },
            ],
            'total': 2,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('ZICO (Block B)');

      expect(url, 'https://e-cdns-images.dzcdn.net/zico_popular.jpg');
    });

    test('returns null when Deezer artist data is empty', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': [], 'total': 0}), 200);
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('NonexistentArtistXYZ');

      expect(url, isNull);
    });

    test('returns null on network failure/offline state', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final service = ArtistImageService(client: mockClient);
      final url = await service.getArtistImageUrl('NewJeans');

      expect(url, isNull);
    });

    test('returns null for blank artist name', () async {
      final service = ArtistImageService();
      final url = await service.getArtistImageUrl('   ');
      expect(url, isNull);
    });
  });
}



