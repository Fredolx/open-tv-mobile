import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_tv/backend/sql.dart';
import 'package:open_tv/backend/xtream.dart';
import 'package:open_tv/memory.dart';
import 'package:open_tv/models/channel.dart';
import 'package:open_tv/error.dart';
import 'package:open_tv/models/media_type.dart';
import 'package:open_tv/player.dart';

class ChannelTile extends StatefulWidget {
  final Channel channel;
  final BuildContext parentContext;
  final Function(MediaType, int, String) updateViewMode;
  const ChannelTile(
      {super.key,
      required this.channel,
      required this.updateViewMode,
      required this.parentContext});

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

  play() async {
    if (widget.channel.mediaType == MediaType.group ||
        widget.channel.mediaType == MediaType.serie) {
      if (widget.channel.mediaType == MediaType.serie &&
          !refreshedSeries.contains(widget.channel.id)) {
        await Error.tryAsync(() async {
          await getEpisodes(widget.channel);
          refreshedSeries.add(widget.channel.id!);
        }, widget.parentContext, null, true, false);
      }
      widget.updateViewMode(
          widget.channel.mediaType,
          widget.channel.mediaType == MediaType.group
              ? widget.channel.id!
              : int.parse(widget.channel.url!),
          widget.channel.name);
    } else {
      Sql.addToHistory(widget.channel.id!);
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => Player(channel: widget.channel)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: _focusNode.hasFocus ? 8.0 : 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: widget.channel.favorite
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          focusNode: _focusNode,
          onLongPress: favorite,
          onTap: () async => await play(),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: widget.channel.image != null
                              ? CachedNetworkImage(
                                  width: 1000,
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
                        maxLines: 3,
                      ))
                ],
              )),
        ));
  }
}
