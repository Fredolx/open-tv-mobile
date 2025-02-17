import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_tv/backend/sql.dart';
import 'package:open_tv/bottom_nav.dart';
import 'package:open_tv/channel_tile.dart';
import 'package:open_tv/models/channel.dart';
import 'package:open_tv/models/filters.dart';
import 'package:open_tv/models/media_type.dart';
import 'package:open_tv/models/view_type.dart';
import 'package:open_tv/error.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Timer? _debounce;
  Filters filters = Filters(
      sourceIds: [],
      mediaTypes: [MediaType.livestream, MediaType.movie, MediaType.serie],
      viewType: ViewType.all,
      page: 1,
      useKeywords: false);
  bool reachedMax = false;
  final int pageSize = 36;
  List<Channel> channels = [];
  bool searchMode = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    final sources = await Sql.getEnabledSourcesMinimal();
    filters.sourceIds = sources.map((x) => x.id).toList();
    await load();
  }

  Future<void> loadMore() async {
    filters.page++;
    load(true);
  }

  toggleSearch() {
    setState(() {
      searchMode = !searchMode;
    });
    if (searchMode) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => FocusScope.of(context).requestFocus(_focusNode));
    } else {
      filters.query = null;
      searchController.clear();
      reload();
    }
  }

  Future<void> load([bool more = false]) async {
    Error.tryAsyncNoLoading(() async {
      List<Channel> channels = await Sql.search(filters);
      if (!more) {
        setState(() {
          this.channels = channels;
        });
      } else {
        setState(() {
          this.channels.addAll(channels);
        });
      }
      reachedMax = channels.length < pageSize;
    }, context);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  reload() {
    filters.page = 1;
    load(false);
  }

  void navbarChanged(ViewType view) {
    filters.viewType = view;
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
          Offstage(
              offstage: !searchMode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: Colors.white, // Background color
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                      controller: searchController,
                      focusNode: _focusNode,
                      onChanged: (query) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 500), () {
                          filters.query = query;
                          load(false);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                            onPressed: () {
                              filters.useKeywords = !filters.useKeywords;
                              reload();
                            },
                            icon: Icon(filters.useKeywords
                                ? Icons.label
                                : Icons.label_outline)),
                        filled: true,
                        fillColor:
                            Colors.grey[200], // Light background for contrast
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    )),
                    const SizedBox(width: 10),
                    SizedBox(
                        width: 40,
                        child: IconButton(
                            onPressed: toggleSearch,
                            icon: const Icon(Icons.close, color: Colors.black)))
                  ],
                ),
              )),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = 150;
                double cardHeight = 60;
                int crossAxisCount = (constraints.maxWidth / cardWidth)
                    .floor()
                    .clamp(1, 4)
                    .toInt();
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ChannelTile(
                      channel: channel,
                    );
                  },
                );
              },
            ),
          ))
        ]),
        bottomNavigationBar: BottomNav(
          updateViewMode: navbarChanged,
        ),
        floatingActionButton: Visibility(
          visible: !searchMode,
          child: FloatingActionButton(
            onPressed: toggleSearch,
            tooltip: 'Search',
            child: const Icon(Icons.search),
          ),
        ));
  }
}
