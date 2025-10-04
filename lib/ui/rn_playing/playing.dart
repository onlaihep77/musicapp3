import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/model/song.dart';
import 'audio_player_manager.dart';
import 'dart:async';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.playingSong, required this.songs});

  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(songs: songs, playingSong: playingSong);
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimController;
  late AudioPlayerManager _audioPlayerManager;

  late int _selectedItemIndex;
  late Song _song;

  double _currentAnimationPosition = 0.0;
  bool _isShuffle = false;
  late LoopMode _loopMode;
  final Set<String> _likedSongIds = {}; // các bài đã tim

  String get _songKey => _song.id ?? _song.source; // fallback nếu chưa có id

  PlayerState? _ps;
  late final StreamSubscription<PlayerState> _playerSub;

  @override
  void initState() {
    super.initState();

    _song = widget.playingSong;

    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _audioPlayerManager = AudioPlayerManager();

    // nạp bài đầu tiên
    if (_audioPlayerManager.songUrl != _song.source) {
      _audioPlayerManager.updateSongUrl(_song.source);
      _audioPlayerManager.prepare(isNewSong: true);
    } else {
      _audioPlayerManager.prepare(isNewSong: false);
    }

    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _loopMode = LoopMode.off;

    // ----- NEW: lắng nghe trạng thái player và điều khiển animation ở đây
    _playerSub = _audioPlayerManager.player.playerStateStream.listen((
      playerState,
    ) {
      _ps = playerState;
      if (!mounted) return;

      final processing = playerState.processingState;
      final playing = playerState.playing;

      if (processing == ProcessingState.loading ||
          processing == ProcessingState.buffering) {
        _pauseRotationAnim();
      } else if (processing == ProcessingState.completed) {
        _stopRotationAnim();
        _resetRotationAnim();
      } else if (playing) {
        _playRotationAnim();
      } else {
        _pauseRotationAnim();
      }

      // cập nhật icon nút play/pause
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playerSub.cancel();
    _imageAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64;
    final radius = (screenWidth - delta) / 2;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_song.album),
              const SizedBox(height: 16),
              const Text('_ ___ _'),
              const SizedBox(height: 30),
              RotationTransition(
                key: ValueKey(_song.source),
                turns: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_imageAnimController),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/nct.jpg',
                    image: _song.image,
                    width: screenWidth - delta,
                    height: screenWidth - delta,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/nct.jpg',
                        width: screenWidth - delta,
                        height: screenWidth - delta,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 64, bottom: 16),
                child: SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Column(
                        children: [
                          Text(_song.title),
                          const SizedBox(height: 8),
                          Text(
                            _song.artist,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.color,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          final k = _songKey;
                          setState(() {
                            if (_likedSongIds.contains(k)) {
                              _likedSongIds.remove(k);
                            } else {
                              _likedSongIds.add(k);
                            }
                          });
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: _likedSongIds.contains(_songKey)
                              ? const Icon(
                                  Icons.favorite,
                                  key: ValueKey('fav_on'),
                                )
                              : const Icon(
                                  Icons.favorite_border,
                                  key: ValueKey('fav_off'),
                                ),
                        ),
                        color: _likedSongIds.contains(_songKey)
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 34,
                  left: 26,
                  right: 26,
                  bottom: 18,
                ),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 34,
                  left: 26,
                  right: 26,
                  bottom: 18,
                ),
                child: _mediaButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers

  Widget _mediaButtons() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: _toggleShuffle,
            icon: Icons.shuffle,
            color: _isShuffle ? Colors.deepPurple : Colors.grey,
            size: 24,
          ),
          MediaButtonControl(
            function: _setPrevSong,
            icon: Icons.skip_previous,
            color: Colors.deepPurple,
            size: 36,
          ),
          _playButton(), // không điều khiển anim trong build
          MediaButtonControl(
            function: _setNextSong,
            icon: Icons.skip_next,
            color: Colors.deepPurple,
            size: 36,
          ),
          MediaButtonControl(
            function: _cycleRepeat,
            icon: _repeatingIcon(),
            color: _loopMode == LoopMode.off ? Colors.grey : Colors.deepPurple,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _playButton() {
    final processing = _ps?.processingState;
    final playing = _ps?.playing ?? false;

    if (processing == ProcessingState.loading ||
        processing == ProcessingState.buffering) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(),
      );
    } else if (!playing) {
      return MediaButtonControl(
        function: () => _audioPlayerManager.player.play(),
        icon: Icons.play_arrow,
        color: null,
        size: 48,
      );
    } else if (processing != ProcessingState.completed) {
      return MediaButtonControl(
        function: () => _audioPlayerManager.player.pause(),
        icon: Icons.pause,
        color: null,
        size: 48,
      );
    } else {
      return MediaButtonControl(
        function: () {
          _audioPlayerManager.player.seek(Duration.zero);
          // listener sẽ tự reset/khởi động anim nếu cần
        },
        icon: Icons.replay,
        color: null,
        size: 48,
      );
    }
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 4.8,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey,
          progressBarColor: Colors.purple,
          bufferedBarColor: Colors.blueGrey,
          thumbColor: Colors.deepPurple,
          thumbRadius: 9.9,
        );
      },
    );
  }

  // ---------- Controls

  void _toggleShuffle() {
    setState(() => _isShuffle = !_isShuffle);
  }

  void _cycleRepeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    _audioPlayerManager.player.setLoopMode(_loopMode);
    setState(() {});
  }

  IconData _repeatingIcon() {
    return switch (_loopMode) {
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat_on,
      _ => Icons.repeat,
    };
  }

  Future<void> _setNextSong() async {
    final wasPlaying = _ps?.playing ?? false;

    if (_isShuffle) {
      _selectedItemIndex = Random().nextInt(widget.songs.length);
    } else if (_selectedItemIndex < widget.songs.length - 1) {
      _selectedItemIndex++;
    } else if (_loopMode == LoopMode.all) {
      _selectedItemIndex = 0;
    }

    _applySongChange(widget.songs[_selectedItemIndex], wasPlaying);
  }

  Future<void> _setPrevSong() async {
    final wasPlaying = _ps?.playing ?? false;

    if (_isShuffle) {
      _selectedItemIndex = Random().nextInt(widget.songs.length);
    } else if (_selectedItemIndex > 0) {
      _selectedItemIndex--;
    } else if (_loopMode == LoopMode.all) {
      _selectedItemIndex = widget.songs.length - 1;
    }

    _applySongChange(widget.songs[_selectedItemIndex], wasPlaying);
  }

  void _applySongChange(Song nextSong, bool wasPlaying) {
    _resetRotationAnim(); // đặt lại góc quay ngay khi đổi ảnh

    // nạp URL mới
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _audioPlayerManager.prepare(isNewSong: true);

    setState(() {
      _song = nextSong;
    });

    if (wasPlaying) {
      // tiếp tục phát nếu trước đó đang phát
      _audioPlayerManager.player.play();
    }
  }

  // ---------- Animation helpers

  void _playRotationAnim() {
    _imageAnimController.forward(from: _currentAnimationPosition);
    _imageAnimController.repeat();
  }

  void _pauseRotationAnim() {
    _imageAnimController.stop();
    _currentAnimationPosition = _imageAnimController.value;
  }

  void _stopRotationAnim() {
    _imageAnimController.stop();
  }

  void _resetRotationAnim() {
    _currentAnimationPosition = 0.0;
    _imageAnimController.value = _currentAnimationPosition;
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}


