import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_lms/features/student/learning/widgets/lesson_video_player.dart';

class TestVideoController extends VideoPlayerController {
  TestVideoController()
    : super.networkUrl(Uri.parse('https://example.com/video.mp4')) {
    value = const VideoPlayerValue(
      duration: Duration(minutes: 2),
      size: Size(640, 360),
      isInitialized: true,
    );
  }
  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
  }
}

void main() {
  test('elapsed time supports minutes and hours', () {
    expect(videoTime(const Duration(seconds: 65)), '1:05');
    expect(videoTime(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });
  testWidgets('play, pause, bounded skip and seek preserve playback intent', (
    tester,
  ) async {
    final controller = TestVideoController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LessonVideoPlayer(controller: controller)),
      ),
    );
    await tester.tap(find.byTooltip('Play video'));
    await tester.pump();
    expect(controller.value.isPlaying, isTrue);
    await tester.tap(find.byTooltip('Pause video'));
    await tester.pump();
    expect(controller.value.isPlaying, isFalse);
    await tester.tap(find.byTooltip('Rewind 10 seconds'));
    expect(controller.value.position, Duration.zero);
    await tester.tap(find.byTooltip('Forward 10 seconds'));
    expect(controller.value.position, const Duration(seconds: 10));
    await controller.seekTo(const Duration(seconds: 119));
    await tester.pump();
    await tester.tap(find.byTooltip('Forward 10 seconds'));
    expect(controller.value.position, const Duration(minutes: 2));
    await tester.pump();
    await tester.tap(find.byTooltip('Replay video'));
    await tester.pump();
    expect(controller.value.position, Duration.zero);
    expect(controller.value.isPlaying, isTrue);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(30000);
    slider.onChanged!(30000);
    slider.onChangeEnd!(30000);
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 30));
    expect(controller.value.isPlaying, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.dispose();
  });
  testWidgets('fullscreen shares position and speed and returns to inline', (
    tester,
  ) async {
    final controller = TestVideoController();
    await controller.seekTo(const Duration(seconds: 35));
    await controller.setPlaybackSpeed(1.5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LessonVideoPlayer(controller: controller)),
      ),
    );
    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Exit fullscreen'), findsNWidgets(2));
    expect(controller.value.position, const Duration(seconds: 35));
    expect(controller.value.playbackSpeed, 1.5);
    await tester.tap(find.byTooltip('Exit fullscreen').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Fullscreen'), findsOneWidget);
    expect(controller.value.position, const Duration(seconds: 35));
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.dispose();
  });
}
