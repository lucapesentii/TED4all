import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/talk.dart';

Future<List<RelatedVideos>> initEmptyList() async {
  // Decode an empty JSON array
  List<dynamic> list = jsonDecode("[]");
  // Map the list to a list of RelatedVideos objects
  List<RelatedVideos> relatedVideosList = list.map((model) => RelatedVideos.fromJSON(model)).toList();
  return relatedVideosList;
}

Future<List<RelatedVideos>> getTalksById(String id, int page) async {
  var url = Uri.parse('https://0ef9izcch7.execute-api.us-east-1.amazonaws.com/default/Get_Watch_Next_by_Id');

  final http.Response response = await http.post(url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, Object>{
      'id': id,
      'page': page,
      'doc_per_page': 6
    }),
  );
  if (response.statusCode == 200) {
    Iterable list = json.decode(response.body);
    var talks = list.map((model) => RelatedVideos.fromJSON(model)).toList();
    return talks;
  } else {
    throw Exception('Failed to load talks');
  }
      
}