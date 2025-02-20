import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:open_tv/models/channel.dart';
import 'package:open_tv/models/media_type.dart';
import 'package:video_player/video_player.dart';

class Player extends StatefulWidget {
  final Channel channel;
  const Player({super.key, required this.channel});
  @override
  State<StatefulWidget> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.channel.url!))
          ..initialize().then((_) {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Chewie(
          controller: ChewieController(
            videoPlayerController: _controller,
            fullScreenByDefault: true,
            allowedScreenSleep: false,
            looping: true,
            isLive: widget.channel.mediaType == MediaType.livestream,
            allowPlaybackSpeedChanging: false,
            playbackSpeeds: [1],
            autoPlay: true,
          ),
        ));
  }
}
