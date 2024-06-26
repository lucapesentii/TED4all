class Talk {
  final String title;
  final String details;
  final String mainSpeaker;
  final String url;

  Talk.fromJSON(Map<String, dynamic> jsonMap) :
    title = jsonMap['title'],
    details = jsonMap['description'],
    mainSpeaker = (jsonMap['speaker'] ?? ""),
    url = (jsonMap['url'] ?? "");
}

class RelatedVideos {
  final List<Talk> relatedVideos;

  RelatedVideos.fromJSON(Map<String, dynamic> json) :
    relatedVideos = (json['related_videos'] as List).map((i) => Talk.fromJSON(i)).toList();
}
