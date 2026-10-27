import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/song_model.dart';
import '../../data/services/artist_image_service.dart';
import '../../providers/library_provider.dart';
import 'artist_detail_screen.dart';

/// Artists Screen displaying a clean, minimalist 2-column porcelain grid of artists.
class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final artistsMap = library.artistsMap;
    final artistNames = artistsMap.keys.toList();

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AppBackground(
        child: Stack(
          children: [
            // 1. 2-Column Porcelain Grid of Artists (Passes smoothly behind floating header)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  if (library.isLoading && artistNames.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E232E),
                      ),
                    );
                  }

                  if (artistNames.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.group_off_rounded,
                            size: 52,
                            color: Color(0xFF8C93A3),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No artists found in catalog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E232E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => library.loadSongs(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh Catalog'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RepaintBoundary(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none, // Prevents abrupt hard-edge cutoff
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: topPadding + 64.0, // Space so first row begins cleanly below floating title
                        bottom: 120.0, // Prevents bottom items from being obscured by floating nav bar
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 24.0,
                      ),
                      itemCount: artistNames.length,
                      itemBuilder: (context, index) {
                        final name = artistNames[index];
                        final songs = artistsMap[name] ?? [];

                        // Find first song that has cover art
                        final coverSong = songs.cast<Song?>().firstWhere(
                              (s) => s != null && s.hasCover,
                              orElse: () => songs.isNotEmpty ? songs.first : null,
                            );

                        return _ArtistGridItem(
                          artistName: name,
                          songsCount: songs.length,
                          coverUrl: coverSong?.hasCover == true ? coverSong?.coverUrl : null,
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    ArtistDetailScreen(
                                  artistName: name,
                                  songs: songs,
                                ),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutCubic;
                                  final tween = Tween(begin: begin, end: end).chain(
                                    CurveTween(curve: curve),
                                  );
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // 2. Soft Gradient Fade Overlay for smooth transition as cards scroll up
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: topPadding + 76.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xF2F4F7FB),
                        Color(0xB2F4F7FB),
                        Color(0x00F4F7FB),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Floating "Artists" Header Text (Float smoothly above scrollable content)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(28.0, 16.0, 24.0, 8.0),
                  child: Text(
                    'Artists',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E232E),
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimalist flat artist grid item (No thick white box card, no arrow icon)
class _ArtistGridItem extends StatelessWidget {
  final String artistName;
  final int songsCount;
  final String? coverUrl;
  final VoidCallback onTap;

  const _ArtistGridItem({
    required this.artistName,
    required this.songsCount,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Large Circular Artist Avatar (110px diameter with soft circular shadow)
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF1F5),
              border: Border.all(
                color: Colors.white,
                width: 2.0, // Crisp white outline enhancing depth
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  offset: Offset(0, 8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: Color(0xFFFFFFFF),
                  offset: Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: _ArtistAvatar(
                artistName: artistName,
                fallbackCoverUrl: coverUrl,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Bold Artist Name (15px, centered, maxLines 1 with ellipsis)
          Text(
            artistName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E232E),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // 3. Track Counter (12px, centered, #8C93A3)
          Text(
            '$songsCount ${songsCount == 1 ? 'Track' : 'Tracks'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8C93A3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular artist avatar displaying official Deezer profile photo with fallback to song cover
class _ArtistAvatar extends StatefulWidget {
  final String artistName;
  final String? fallbackCoverUrl;

  const _ArtistAvatar({
    required this.artistName,
    required this.fallbackCoverUrl,
  });

  @override
  State<_ArtistAvatar> createState() => _ArtistAvatarState();
}

class _ArtistAvatarState extends State<_ArtistAvatar> {
  String? _artistImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchArtistImage();
  }

  @override
  void didUpdateWidget(covariant _ArtistAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName) {
      _fetchArtistImage();
    }
  }

  Future<void> _fetchArtistImage() async {
    final url = await ArtistImageService.instance.getArtistImageUrl(widget.artistName);
    if (mounted) {
      setState(() {
        _artistImageUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artistImageUrl != null && _artistImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _artistImageUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 250,
        memCacheHeight: 250,
        fadeInDuration: const Duration(milliseconds: 350),
        placeholder: (context, url) => _buildFallback(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    if (widget.fallbackCoverUrl != null && widget.fallbackCoverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.fallbackCoverUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 250,
        memCacheHeight: 250,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => Container(
          color: const Color(0xFFE2E6EF),
        ),
        errorWidget: (context, url, error) => _avatarPlaceholder(),
      );
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: const Color(0xFFE4E8F0),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 48,
          color: Color(0xFF8C93A0),
        ),
      ),
    );
  }
}
