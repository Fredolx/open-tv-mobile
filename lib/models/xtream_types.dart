class XtreamStream {
  final String? streamId;
  final String? name;
  final String? categoryId;
  final String? streamIcon;
  final String? seriesId;
  final String? cover;
  final String? containerExtension;

  XtreamStream({
    this.streamId,
    this.name,
    this.categoryId,
    this.streamIcon,
    this.seriesId,
    this.cover,
    this.containerExtension,
  });

  factory XtreamStream.fromJson(Map<String, dynamic> json) {
    return XtreamStream(
      streamId: json['stream_id']?.toString(),
      name: json['name'],
      categoryId: json['category_id']?.toString(),
      streamIcon: json['stream_icon'],
      seriesId: json['series_id']?.toString(),
      cover: json['cover'],
      containerExtension: json['container_extension'],
    );
  }
}

class XtreamSeries {
  final List<XtreamEpisode> episodes;

  XtreamSeries({required this.episodes});

  factory XtreamSeries.fromJson(Map<String, dynamic> json) {
    List<XtreamEpisode> episodesList = [];
    json["episodes"].forEach((season, episodesListForSeason) {
      episodesList.addAll((episodesListForSeason as List)
          .map((episodeJson) => XtreamEpisode.fromJson(episodeJson)));
    });
    return XtreamSeries(episodes: episodesList);
  }
}

class XtreamEpisode {
  final String id;
  final String title;
  final String containerExtension;
  final String episodeNum;
  final String season;
  final XtreamEpisodeInfo? info;

  XtreamEpisode({
    required this.id,
    required this.title,
    required this.containerExtension,
    required this.episodeNum,
    required this.season,
    required this.info,
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> json) {
    return XtreamEpisode(
        id: json['id'].toString(),
        title: json['title'],
        containerExtension: json['container_extension'],
        episodeNum: json['episode_num'].toString(),
        season: json['season'].toString(),
        info: (json['info'] is Map)
            ? XtreamEpisodeInfo.fromJson(json['info'])
            : null);
  }
}

class XtreamEpisodeInfo {
  final String? movieImage;

  XtreamEpisodeInfo({this.movieImage});

  factory XtreamEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return XtreamEpisodeInfo(
      movieImage: json['movie_image'],
    );
  }
}

class XtreamCategory {
  final String categoryId;
  final String categoryName;

  XtreamCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'],
    );
  }
}

class XtreamEPG {
  final List<XtreamEPGItem> epgListings;

  XtreamEPG({required this.epgListings});

  factory XtreamEPG.fromJson(Map<String, dynamic> json) {
    return XtreamEPG(
      epgListings: (json['epg_listings'] as List)
          .map((e) => XtreamEPGItem.fromJson(e))
          .toList(),
    );
  }
}

class XtreamEPGItem {
  final String id;
  final String title;
  final String description;
  final String startTimestamp;
  final String stopTimestamp;

  XtreamEPGItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTimestamp,
    required this.stopTimestamp,
  });

  factory XtreamEPGItem.fromJson(Map<String, dynamic> json) {
    return XtreamEPGItem(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      startTimestamp: json['start_timestamp'],
      stopTimestamp: json['stop_timestamp'],
    );
  }
}
