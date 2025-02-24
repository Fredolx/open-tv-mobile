import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_tv/backend/sql.dart';
import 'package:open_tv/models/channel.dart';
import 'package:open_tv/error.dart';
import 'package:open_tv/models/media_type.dart';
import 'package:open_tv/player.dart';

class ChannelTile extends StatefulWidget {
  final Channel channel;
  final Function(MediaType, int, String) updateViewMode;
  const ChannelTile(
      {super.key, required this.channel, required this.updateViewMode});

  @override
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile> {
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  favorite() async {
    if (widget.channel.mediaType == MediaType.group) return;
    await Error.tryAsyncNoLoading(() async {
      await Sql.favoriteChannel(widget.channel.id!, !widget.channel.favorite);
      setState(() {
        widget.channel.favorite = !widget.channel.favorite;
      });
    }, context);
  }

  play() {
    if (widget.channel.mediaType == MediaType.group ||
        widget.channel.mediaType == MediaType.serie) {
      widget.updateViewMode(
          widget.channel.mediaType,
          widget.channel.mediaType == MediaType.group
              ? widget.channel.id!
              : int.parse(widget.channel.url!),
          widget.channel.name);
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => Player(channel: widget.channel)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: _focusNode.hasFocus ? 8.0 : 4.0, // Highlight when focused
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: widget.channel.favorite
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          focusNode: _focusNode,
          onLongPress: favorite,
          onTap: () => play(),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: widget.channel.image != null
                              ? CachedNetworkImage(
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) =>
                                      Image.asset("assets/icon.png"),
                                  imageUrl: widget.channel.image!,
                                )
                              : Image.asset(
                                  "assets/icon.png",
                                  fit: BoxFit.contain,
                                ))),
                  const Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 8,
                      child: Text(
                        widget.channel.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ))
                ],
              )),
        ));
  }
}
