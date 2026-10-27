import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../data/models/song_model.dart';
import '../data/services/api_service.dart';

/// Provider for managing song library state, fetching data, and organizing catalogs.
class LibraryProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Song> _allSongs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  LibraryProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ===========================================================================
  // Getters
  // ===========================================================================

  /// Unmodifiable view of all songs in catalog
  List<Song> get allSongs => UnmodifiableListView(_allSongs);

  /// True while loading or scanning
  bool get isLoading => _isLoading;

  /// Error message if fetch/scan fails
  String? get errorMessage => _errorMessage;

  /// Current search keyword
  String get searchQuery => _searchQuery;

  /// Total count of songs in catalog
  int get totalSongsCount => _allSongs.length;

  /// Groups songs by individual artist from `artistList`.
  /// - Artist names are sorted alphabetically (A-Z, case-insensitive).
  /// - Song titles under each artist are sorted alphabetically (A-Z, case-insensitive).
  Map<String, List<Song>> get artistsMap {
    final Map<String, List<Song>> grouped = {};

    for (final song in _allSongs) {
      // Use toSet() to prevent duplicate listing if artist name is repeated
      final uniqueArtists = song.artistList.toSet();
      for (final artist in uniqueArtists) {
        final cleanArtist = artist.trim();
        if (cleanArtist.isEmpty) continue;

        grouped.putIfAbsent(cleanArtist, () => <Song>[]).add(song);
      }
    }

    // Sort songs inside each artist group by title (A-Z)
    for (final songs in grouped.values) {
      songs.sort((a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    // Sort artist keys alphabetically (A-Z)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final sortedResult = <String, List<Song>>{};
    for (final key in sortedKeys) {
      sortedResult[key] = grouped[key]!;
    }

    return sortedResult;
  }

  /// Filtered list of songs matching `searchQuery` (across title, artist, or album).
  List<Song> get filteredSongs {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _allSongs;

    return _allSongs.where((song) {
      final titleMatch = song.title.toLowerCase().contains(query);
      final artistMatch = song.artist.toLowerCase().contains(query);
      final albumMatch = song.album.toLowerCase().contains(query);
      return titleMatch || artistMatch || albumMatch;
    }).toList();
  }

  /// Filtered map of artists matching `searchQuery`.
  /// Matches artist name directly or includes the artist if any of their songs match.
  Map<String, List<Song>> get filteredArtists {
    final query = _searchQuery.trim().toLowerCase();
    final allArtists = artistsMap;
    if (query.isEmpty) return allArtists;

    final Map<String, List<Song>> result = {};

    for (final entry in allArtists.entries) {
      final artistMatches = entry.key.toLowerCase().contains(query);

      if (artistMatches) {
        // If artist name matches, keep all songs for this artist
        result[entry.key] = entry.value;
      } else {
        // Otherwise keep only the songs that match title or album
        final matchingSongs = entry.value.where((song) {
          return song.title.toLowerCase().contains(query) ||
              song.album.toLowerCase().contains(query);
        }).toList();

        if (matchingSongs.isNotEmpty) {
          result[entry.key] = matchingSongs;
        }
      }
    }

    return result;
  }

  // ===========================================================================
  // Actions
  // ===========================================================================

  /// Updates the active search query and notifies listeners.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Clears the current search query.
  void clearSearch() {
    setSearchQuery('');
  }

  /// Loads the song catalog from API.
  Future<void> loadSongs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final songs = await _apiService.fetchSongs();
      _allSongs = songs;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers a library scan on the backend, then refreshes the catalog.
  Future<bool> refreshScan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.triggerScan();
      if (success) {
        // Reload catalog to reflect updated library
        final songs = await _apiService.fetchSongs();
        _allSongs = songs;
        _errorMessage = null;
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
