import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Local-only playback of an imported glass media file. This widget never
/// uploads media, initiates capture, or sends a BLE write.
class EbolaMediaPreview extends StatefulWidget {
  const EbolaMediaPreview({super.key, required this.file, required this.isVideo});
  final File file;
  final bool isVideo;

  @override
  State<EbolaMediaPreview> createState() => _EbolaMediaPreviewState();
}

class _EbolaMediaPreviewState extends State<EbolaMediaPreview> {
  VideoPlayerController? _player;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _loadVideo();
  }

  Future<void> _loadVideo() async {
    final controller = VideoPlayerController.file(widget.file);
    _player = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error =
          'This file cannot be decoded by the phone video player: ${error.runtimeType}');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _player;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isVideo ? 'Glass Video' : 'Glass Photo'),
          backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isVideo
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
                if (_error == null && (controller == null || !controller.value.isInitialized))
                  const CircularProgressIndicator(),
                if (_error == null && controller != null && controller.value.isInitialized) ...[
                  AspectRatio(aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      if (controller.value.isPlaying) {
                        await controller.pause();
                      } else {
                        await controller.play();
                      }
                      if (mounted) setState(() {});
                    },
                    icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(controller.value.isPlaying ? 'Pause' : 'Play'),
                  ),
                ],
              ])
            : Image.file(widget.file, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('Photo file could not be decoded')),
      )),
    );
  }
}
