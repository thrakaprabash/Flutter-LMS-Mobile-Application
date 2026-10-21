import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

String videoTime(Duration time) {
  final seconds = time.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60) % 60;
  return '${hours > 0 ? '$hours:' : ''}${hours > 0 ? minutes.toString().padLeft(2, '0') : minutes}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Shares the lesson's controller between inline and fullscreen presentation.
/// This widget owns controls only; the lesson owns and disposes the controller.
class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({
    super.key,
    required this.controller,
    this.title = 'Lesson video',
    this.fullscreen = false,
    this.routeScope,
  });
  final VideoPlayerController controller;
  final String title;
  final bool fullscreen;
  final Widget Function(Widget child)? routeScope;
  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer>
    with WidgetsBindingObserver {
  Timer? timer;
  bool controls = true, openingFullscreen = false, resumeAfterSeek = false;
  double? scrub;
  VideoPlayerController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(onPlaybackChanged);
    scheduleHide();
  }

  @override
  void didUpdateWidget(covariant LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(onPlaybackChanged);
      controller.addListener(onPlaybackChanged);
    }
  }

  void onPlaybackChanged() {
    if (!mounted) return;
    if (!controller.value.isPlaying && !controls) {
      setState(() => controls = true);
    }
    if (controller.value.isPlaying && timer == null && controls) scheduleHide();
  }

  void scheduleHide() {
    timer?.cancel();
    timer = null;
    if (controller.value.isPlaying && scrub == null) {
      timer = Timer(const Duration(seconds: 4), () {
        timer = null;
        if (mounted && controller.value.isPlaying && scrub == null) {
          setState(() => controls = false);
        }
      });
    }
  }

  void reveal() {
    setState(() => controls = true);
    scheduleHide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller.pause();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.removeListener(onPlaybackChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> togglePlayback() async {
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
    if (mounted) reveal();
  }

  Future<void> skip(int seconds) async {
    final end = controller.value.duration.inMilliseconds;
    final target = (controller.value.position.inMilliseconds + seconds * 1000)
        .clamp(0, end);
    await controller.seekTo(Duration(milliseconds: target));
    if (mounted) reveal();
  }

  Future<void> fullscreen() async {
    if (openingFullscreen) return;
    timer?.cancel();
    setState(() => openingFullscreen = true);
    try {
      final screen = _FullscreenVideo(
        controller: controller,
        title: widget.title,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => widget.routeScope?.call(screen) ?? screen,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          openingFullscreen = false;
          controls = true;
        });
        scheduleHide();
      }
    }
  }

  Widget control({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 24,
  }) => IconButton(
    tooltip: label,
    color: Colors.white,
    iconSize: size,
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    onPressed: onPressed,
    icon: Icon(icon),
  );
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final duration = value.duration.inMilliseconds.toDouble();
      final position = (scrub ?? value.position.inMilliseconds.toDouble())
          .clamp(0.0, duration);
      final ended =
          value.duration > Duration.zero && value.position >= value.duration;
      final content = Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned.fill(
            child: Semantics(
              label: controls ? 'Hide video controls' : 'Show video controls',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => controls = !controls);
                  scheduleHide();
                },
              ),
            ),
          ),
          if (value.isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                semanticsLabel: 'Buffering video',
              ),
            ),
          if (controls)
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: widget.fullscreen,
                  bottom: widget.fullscreen,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 4,
                        child: Row(
                          children: [
                            if (widget.fullscreen)
                              control(
                                label: 'Exit fullscreen',
                                icon: Icons.arrow_back,
                                onPressed: () => Navigator.pop(context),
                              ),
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            PopupMenuButton<double>(
                              tooltip: 'Playback speed',
                              initialValue: value.playbackSpeed,
                              onOpened: () {
                                timer?.cancel();
                                timer = null;
                              },
                              onCanceled: scheduleHide,
                              onSelected: (speed) async {
                                await controller.setPlaybackSpeed(speed);
                                if (mounted) reveal();
                              },
                              itemBuilder: (_) => [
                                for (final speed in [
                                  .5,
                                  .75,
                                  1.0,
                                  1.25,
                                  1.5,
                                  2.0,
                                ])
                                  PopupMenuItem(
                                    value: speed,
                                    child: Text('${speed}x'),
                                  ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '${value.playbackSpeed}x',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            control(
                              label: 'Rewind 10 seconds',
                              icon: Icons.replay_10,
                              onPressed: () => skip(-10),
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            control(
                              label: ended
                                  ? 'Replay video'
                                  : value.isPlaying
                                  ? 'Pause video'
                                  : 'Play video',
                              icon: ended
                                  ? Icons.replay
                                  : value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              onPressed: togglePlayback,
                              size: 48,
                            ),
                            const SizedBox(width: 12),
                            control(
                              label: 'Forward 10 seconds',
                              icon: Icons.forward_10,
                              onPressed: () => skip(10),
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 4,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 28,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white38,
                                  value: position,
                                  max: duration > 0 ? duration : 1,
                                  semanticFormatterCallback: (v) =>
                                      '${videoTime(Duration(milliseconds: v.round()))} of ${videoTime(value.duration)}',
                                  onChangeStart: duration <= 0
                                      ? null
                                      : (_) {
                                          resumeAfterSeek = value.isPlaying;
                                          controller.pause();
                                          timer?.cancel();
                                          timer = null;
                                        },
                                  onChanged: duration <= 0
                                      ? null
                                      : (v) => setState(() => scrub = v),
                                  onChangeEnd: duration <= 0
                                      ? null
                                      : (v) async {
                                          await controller.seekTo(
                                            Duration(milliseconds: v.round()),
                                          );
                                          if (resumeAfterSeek) {
                                            await controller.play();
                                          }
                                          if (mounted) {
                                            setState(() => scrub = null);
                                            reveal();
                                          }
                                        },
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    '${videoTime(Duration(milliseconds: position.round()))} / ${videoTime(value.duration)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                control(
                                  label: widget.fullscreen
                                      ? 'Exit fullscreen'
                                      : 'Fullscreen',
                                  icon: widget.fullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  onPressed: widget.fullscreen
                                      ? () => Navigator.pop(context)
                                      : openingFullscreen
                                      ? null
                                      : fullscreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
      if (widget.fullscreen) return content;
      return LayoutBuilder(
        builder: (context, bounds) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: bounds.maxWidth,
            height:
                (bounds.maxWidth /
                        (value.aspectRatio > 0 ? value.aspectRatio : 16 / 9))
                    .clamp(220.0, double.infinity),
            child: content,
          ),
        ),
      );
    },
  );
}

class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({required this.controller, required this.title});
  final VideoPlayerController controller;
  final String title;
  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: LessonVideoPlayer(
      controller: widget.controller,
      title: widget.title,
      fullscreen: true,
    ),
  );
}
