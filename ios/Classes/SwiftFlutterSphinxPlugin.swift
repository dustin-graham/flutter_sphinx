import Flutter
import UIKit
import iSphinx

private class SphinxListener: NSObject, FlutterStreamHandler, iSphinxDelegete {
  
  
  var isphinx: iSphinx
  
  private var eventSink: FlutterEventSink?
  
  init(withISphinx iSphinx: iSphinx, listenChannel: FlutterEventChannel) {
    self.isphinx = iSphinx
    super.init()
    self.isphinx.delegete = self
    isphinx.prepareISphinx(onPreExecute: { (config) in
      // You can add new parameter pocketshinx here
      self.isphinx.silentToDetect = 1.0
      self.isphinx.isStopAtEndOfSpeech = false
      // config.setString(key: "-parameter", value: "value")
    }) { (isSuccess) in
      if isSuccess {
        print("Preparation success!")
      }
    }
    
    listenChannel.setStreamHandler(self)
  }
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
  
  public func iSphinxDidStop(reason: String, code: Int) {
    if code == 500 { // 500 code for error
//      let errorEvent: NSDictionary = ["event": ListenEvent.error, "reason": reason]
//      self.eventSink?(errorEvent)
    } else if code == 522 { // 522 code for timed out
//      let timeoutEvent: NSDictionary = ["event": ListenEvent.timedOut, "reason": reason];
//      self.eventSink?(timeoutEvent)
    }
    print(reason)
//    let stoppedEvent: NSDictionary = ["event": ListenEvent.stopped]
//    self.eventSink?(stoppedEvent)
  }
  
  public func iSphinxFinalResult(result: String, hypArr: [String], scores: [Double]) {
//    print("Full Result : \(result)")
//    // NOTE :
//    // [x] parameter "result" : Give final response with ??? values when word out-of-vocabulary.
//    // [x] parameter "hypArr" : Give final response in original words without ??? values.
//
//    // Get score from every single word. hypArr length equal with scores length
//    for score in scores {
//      print(score)
//    }
//
//    // Get array word
//    for word in hypArr {
//      print(word)
//    }
  }
  
  public func iSphinxPartialResult(partialResult: String) {
    print(partialResult)
    self.eventSink?(partialResult)
  }
  
  public func iSphinxUnsupportedWords(words: [String]) {
    var unsupportedWords = ""
    for word in words {
      unsupportedWords += word + ", "
    }
    print("Unsupported words : \(unsupportedWords)")
  }
  
  public func iSphinxDidSpeechDetected() {
    print("Speech detected!")
  }
  
  // public methods
  func stop() {
    isphinx.stopISphinx()
  }
  
  func loadVocabulary(words: [String], completion: @escaping () -> ()) {
    isphinx.updateVocabulary(words: words, oovWords: [], completion: completion)
  }
  
  func start() {
    isphinx.startISphinx()
  }
}

public class SwiftFlutterSphinxPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let stateEventChannel = FlutterEventChannel(name: "flutter_sphinx/state", binaryMessenger: registrar.messenger())
    let listenEventChannel = FlutterEventChannel(name: "flutter_sphinx/listen", binaryMessenger: registrar.messenger())
    let channel = FlutterMethodChannel(name: "flutter_sphinx", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterSphinxPlugin(withISphinx: iSphinx(), stateChannel: stateEventChannel, listenChannel: listenEventChannel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    
  }
  
  private var eventSink: FlutterEventSink?
  private var sphinxListener: SphinxListener
  
  init(withISphinx iSphinx: iSphinx, stateChannel: FlutterEventChannel, listenChannel: FlutterEventChannel) {
    sphinxListener = SphinxListener(withISphinx: iSphinx, listenChannel: listenChannel)
    super.init()
    
    stateChannel.setStreamHandler(self)
  }
  
  func buildEvent(eventName: String) -> NSDictionary {
    let event: NSDictionary = ["event": eventName];
    return event
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "load") {
      sphinxListener.stop()
      self.eventSink?(buildEvent(eventName: "loading"))
      sphinxListener.loadVocabulary(words: call.arguments as! [String]) {
        self.eventSink?(self.buildEvent(eventName: "loaded"))
      }
    } else if (call.method == "stop") {
      sphinxListener.stop()
      self.eventSink?(buildEvent(eventName: "loaded"))
      result(nil)
    } else if (call.method == "start") {
      sphinxListener.start()
      self.eventSink?(buildEvent(eventName: "listening"))
      result(nil)
    }
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events;
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
