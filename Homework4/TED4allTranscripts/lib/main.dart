import 'package:flutter/material.dart';
import 'talk_repository.dart';
import 'models/talk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.title = 'MyTEDx'
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<TranscriptList>> _talks;
  int page = 1;
  bool init = true;

  String formatMilliseconds(String millisecondsStr) {
    // Converti la stringa in un numero intero
    int milliseconds = int.parse(millisecondsStr);
  
    // Crea una durata utilizzando i millisecondi
    Duration duration = Duration(milliseconds: milliseconds);
  
    // Estrai i minuti e i secondi
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
  
    // Formatta i minuti e i secondi come stringa
    String formattedTime = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  
    return formattedTime;
  }

  @override
  void initState() {
    super.initState();
    _talks = initEmptyList();
    init = true;
  }

  void _getTalksById() async {
    setState(() {
      init = false;
      _talks = getTalksById(_controller.text, page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My TedX App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TED4all'),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: (init)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(hintText: 'Enter ID of your favorite talk'),
                    ),
                    ElevatedButton(
                      child: const Text('Search by ID'),
                      onPressed: () {
                        page = 1;
                        _getTalksById();
                      },
                    ),
                  ],
                )
              : FutureBuilder<List<TranscriptList>>(
                  future: _talks,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<Transcript> allTalks = snapshot.data!.expand((rv) => rv.transcript).toList();
                      return Scaffold(
                          appBar: AppBar(
                            title: Text("#${_controller.text}"),
                          ),
                          body: ListView.builder(
                            itemCount: allTalks.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                child: ListTile(
                                    title: Text(formatMilliseconds((allTalks[index].time))),
                                    subtitle: Text(allTalks[index].text)),
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(allTalks[index].text))),
                              );
                            },
                          ),
                          floatingActionButtonLocation:
                              FloatingActionButtonLocation.centerDocked,
                          floatingActionButton: FloatingActionButton(
                            child: const Icon(Icons.arrow_drop_down),
                            onPressed: () {
                              if (snapshot.data!.length >= 6) {
                                page = page + 1;
                                _getTalksById();
                              }
                            },
                          ),
                          bottomNavigationBar: BottomAppBar(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.home),
                                  onPressed: () {
                                    setState(() {
                                      init = true;
                                      page = 1;
                                      _controller.text = "";
                                    });
                                  },
                                )
                              ],
                            ),
                          ));
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }

                    return const CircularProgressIndicator();
                  },
                ),
        ),
      ),
    );
  }
}