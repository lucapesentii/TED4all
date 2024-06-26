class Transcript {
  final String time;
  final String text;

  Transcript.fromJSON(Map<String, dynamic> jsonMap) :
    time = (jsonMap['time'] ?? ""),
    text = (jsonMap['text'] ?? "");
}

class TranscriptList {
  final List<Transcript> transcript;

  TranscriptList.fromJSON(Map<String, dynamic> jsonMap) :
    transcript = (jsonMap['transcript'] as List).map((i) => Transcript.fromJSON(i)).toList();
}