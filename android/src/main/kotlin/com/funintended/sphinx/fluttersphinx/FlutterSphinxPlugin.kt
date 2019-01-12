package com.funintended.sphinx.fluttersphinx

import edu.cmu.pocketsphinx.SpeechRecognizer
import edu.cmu.pocketsphinx.SpeechRecognizerSetup
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterSphinxPlugin(speechRecognizer: SpeechRecognizer) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val recognizer = SpeechRecognizerSetup.defaultSetup().recognizer;
            // TODO: transcode iSPhinx swift class to Kotlin
            recognizer.decoder.log
            val channel = MethodChannel(registrar.messenger(), "flutter_sphinx")
            channel.setMethodCallHandler(FlutterSphinxPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        // TODO: implement android plugin here just like iOS
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }
}
