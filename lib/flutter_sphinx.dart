import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class FlutterSphinx {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_sphinx');
  static const EventChannel _listeningChannel =
      const EventChannel('flutter_sphinx/listen');
  static const EventChannel _stateChannel =
      const EventChannel('flutter_sphinx/state');
  Stream<SphinxState> _stateChanges;

  Stream<SphinxState> get stateChanges {
    if (_stateChanges != null) {
      return _stateChanges;
    }
    _stateChanges =
        Observable(_stateChannel.receiveBroadcastStream()).map((message) {
      print("state message: $message");
      // this comes through as a map
      final eventMap = message as Map<dynamic, dynamic>;
      final event = eventMap["event"];
      if (event == "loading") {
        return SphinxStateLoading();
      } else if (event == "loaded") {
        return SphinxStateLoaded(_methodChannel);
      } else if (event == "listening") {
        return SphinxStateListening(_methodChannel, _listeningChannel);
      } else if (event == "error") {
        return SphinxStateError(_methodChannel, eventMap["errorMessage"]);
      } else {
        throw StateError("unknown event found from Sphinx plugin");
      }
    }).startWith(SphinxStateUnloaded(_methodChannel));
    return _stateChanges;
  }
}

abstract class SphinxState {}

class SphinxStateLoading extends SphinxState {}

class SphinxStateUnloaded extends SphinxState {
  final MethodChannel _methodChannel;

  SphinxStateUnloaded(this._methodChannel);

  Future loadVocabulary(List<String> words) async {
    await _methodChannel.invokeMethod("load", words);
  }
}

class SphinxStateError extends SphinxState {
  final String errorMessage;
  final MethodChannel _methodChannel;

  SphinxStateError(this._methodChannel, this.errorMessage);

  Future reloadVocabulary(List<String> words) async {
    await _methodChannel.invokeMethod("load", words);
  }
}

class SphinxStateLoaded extends SphinxState {
  final MethodChannel _methodChannel;

  SphinxStateLoaded(this._methodChannel);

  Future startListening() async {
    await _methodChannel.invokeMethod("start");
  }
}

class SphinxStateListening extends SphinxState {
  final MethodChannel _methodChannel;
  final EventChannel _listeningChannel;
  Stream<String> _partialResultStream;

  SphinxStateListening(this._methodChannel, this._listeningChannel);

  Stream<String> partialResults() {
    if (_partialResultStream != null) {
      return _partialResultStream;
    }
    _partialResultStream =
        Observable(_listeningChannel.receiveBroadcastStream())
            .distinct()
            .where((s) => s != null && s.length > 0)
            .map<String>((message) {
      // we get a big string back of the partial results, we just need to send out the last item
      return message.split(" ").last;
    }).startWith("");
    return _partialResultStream;
  }

  Future stopListening() async {
    await _methodChannel.invokeMethod("stop");
  }
}
