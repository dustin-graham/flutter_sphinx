import 'package:flutter/material.dart';
import 'package:flutter_sphinx/flutter_sphinx.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sphinx = FlutterSphinx();
  final List<String> _vocabulary = const [
    "groovy",
    "doctor",
    "is",
    "very",
    "neat"
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: StreamBuilder<SphinxState>(
            stream: _sphinx.stateChanges,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                final state = snapshot.data;
                if (state is SphinxStateLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is SphinxStateUnloaded) {
                  return Center(
                    child: RaisedButton(
                      onPressed: () {
                        state.loadVocabulary(_vocabulary);
                      },
                      child: Text("Load Vocabulary"),
                    ),
                  );
                } else if (state is SphinxStateLoaded) {
                  return Center(
                    child: RaisedButton(
                      onPressed: () {
                        state.startListening();
                      },
                      child: Text("Start Listening"),
                    ),
                  );
                } else if (state is SphinxStateListening) {
                  return StreamBuilder<String>(
                    stream: state.partialResults(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(snapshot.data),
                              RaisedButton(
                                onPressed: () {
                                  state.stopListening();
                                },
                                child: Text("Stop Listening"),
                              ),
                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text("error while listening"),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  );
                } else if (state is SphinxStateError) {
                  return Center(
                    child: RaisedButton(
                      onPressed: () {
                        state.reloadVocabulary(_vocabulary);
                      },
                      child: Text("Reload Vocabulary"),
                    ),
                  );
                } else {
                  throw StateError("unknown sphinx state");
                }
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          )),
    );
  }
}
