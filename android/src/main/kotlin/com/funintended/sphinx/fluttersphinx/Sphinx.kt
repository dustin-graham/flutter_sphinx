package com.funintended.sphinx.fluttersphinx

import edu.cmu.pocketsphinx.*
import java.io.File

interface SphinxListener {
    // 500 code for error,  522 code for timed out,  200 code for finish speech
    fun iSphinxDidStop(reason: String, code: Int)

    fun iSphinxFinalResult(result: String, hypArr: List<String>, scores: List<Double>)
    fun iSphinxPartialResult(partialResult: String)
    fun iSphinxUnsupportedWords(words: List<String>)
    fun iSphinxDidSpeechDetected()
}

class Sphinx : RecognitionListener {

    companion object {
        final val SEARCH_ID: String = "SEARCH_ID"
    }

    private lateinit var recognizer: SpeechRecognizer
    private lateinit var recognizerTemp: SpeechRecognizer
    private lateinit var config: Config
    private lateinit var nGramModel: NGramModel
    private var unSupportedWords: MutableList<String> = mutableListOf()
    private var originalWords: List<String> = emptyList()
    private var oovWords: List<String> = emptyList()
    private val arpaFile = "search.arpa" // TODO: get a file path for this search file
    private val fullDictionary = "full_dict.txt" // TODO
    private val dictPathTemp = "search-dict.txt" // TODO

    /** Enable or disable stop when iSphinx detect as silent. Default is true. */
    var isStopAtEndOfSpeech: Boolean = true
    /** Check the iSphinx isRunning. */
    private var isRunning: Boolean = false

    /** Set the delegete from your class. */
    var delegete: SphinxListener? = null

    /** Start speech recognition without timeout. */
    fun startISphinx() {
        this.isRunning = true
        recognizer.startListening("TODO")// TODO: set search name
    }

    /** Prepare iSphinx with default acoustic model and dictionary. You need to set the language model with other method. */
    fun prepareISphinx(onPreExecute: (SpeechRecognizerSetup) -> Unit,
                       onPostExecute: (Boolean) -> Unit) {
        this.unSupportedWords.clear()
        val mainSetup = setupRecognizer()
        onPreExecute(mainSetup)
        recognizer = mainSetup.recognizer
        recognizer.decoder
        val tempSetup = setupRecognizer()
        recognizer.addListener(this)
        recognizerTemp = tempSetup.recognizer
        onPostExecute(true)
    }

    private fun setupRecognizer(): SpeechRecognizerSetup {
        return SpeechRecognizerSetup.defaultSetup().apply {
            setDictionary(File(fullDictionary))
            setSampleRate(1600)
            setFloat("-vad_threshold", 3.5)
            setFloat("-lw", 6.5);
        }
    }

    private fun generateDictionary(words: List<String>) {
        var text = ""
        for (word in words) {
            val lookup = recognizerTemp.decoder.lookupWord(word.toLowerCase())
            if (lookup != null) {
                text += "${word.toLowerCase()} $lookup\n"
            } else {
                unSupportedWords.add(word)
            }
        }
        // TODO: write search dic to file at dictPathTemp path
//        try ? text.write(to: dictPathTemp!, atomically: true, encoding: .utf8)
        recognizer.decoder.loadDict(dictPathTemp, null, "dict")
        delegete?.iSphinxUnsupportedWords(unSupportedWords)
    }

    private fun generateNGramModel(words: List<String>) {
        nGramModel = NGramModel(recognizer.decoder.config, recognizer.decoder.logmath, arpaFile)
        for (word in words) {
            nGramModel.addWord(word.toLowerCase(), 1.7f)
        }
        recognizer.decoder.setLm(SEARCH_ID, nGramModel)
    }

    /** Update language model from an array string. oovWords is word disturber so if the user says a word from oovWords the hypothesis will be ???. This function will repleace old language model already set. */
    fun updateVocabulary(words: List<String>, oovWords: List<String>, completion: () -> Unit) {
        this.originalWords = words.distinct()
        this.oovWords = oovWords.distinct()
        this.originalWords = SphinxUtilities.removePunctuationArr(words = this.originalWords)
        this.oovWords = SphinxUtilities.removePunctuationArr(words = this.oovWords)
        val combinedWords: List<String> = (this.originalWords + this.oovWords).distinct()
        this.generateDictionary(combinedWords)
        this.generateNGramModel(combinedWords)
        completion()
    }

    /** Get the decoder. */
    fun getDecoder(): Decoder = recognizer.decoder

    /** Get the recognizer class. */
    fun getRecognizer(): SpeechRecognizer = recognizer

    /** Stop speech recognition. Call this function when you sure speec recognition is running. */
    fun stopISphinx() {
        this.isRunning = false
        recognizer.stop()
    }

    override fun onBeginningOfSpeech() {
        delegete?.iSphinxDidSpeechDetected()
    }

    override fun onEndOfSpeech() {
        if (isStopAtEndOfSpeech) {
            this.isRunning = false
            recognizer.stop()
        }
        delegete?.iSphinxDidStop("End of speech!", 200)
    }


    override fun onPartialResult(hyp: Hypothesis?) {
        if (hyp != null) {
            if (hyp.hypstr.isNotEmpty()) {
                delegete?.iSphinxPartialResult(hyp.hypstr)
            }
        }
    }

    override fun onResult(hyp: Hypothesis?) {
        if (hyp != null) {
            if (hyp.hypstr.isNotEmpty()) {
                val hypArr = mutableListOf<String>()
                val scores = mutableListOf<Double>()
                var hypStr: String = ""
                val segIterator = recognizer.decoder.seg().iterator()
                while (segIterator.hasNext()) {
                    val segment = segIterator.next()
                    val score = recognizer.decoder.logmath.exp(segment.prob)
                    val word = segment.word
                    if (!word.contains("<") && !word.contains(">") &&
                            !word.contains("[") && !word.contains("]")) {
                        hypStr += if (originalWords.contains(word)) {
                            segment.word + " ";
                        } else {
                            "??? ";
                        }
                        scores.add(score)
                        hypArr.add(segment.getWord())
                    }
                }
                delegete?.iSphinxFinalResult(result = hypStr.trim(), hypArr = hypArr, scores = scores)
            }
        }
    }

    override fun onError(errorDesc: Exception) {
        this.isRunning = false
        recognizer.stop()
        delegete?.iSphinxDidStop(reason = errorDesc.message ?: "", code = 500)
    }

    override fun onTimeout() {
        this.isRunning = false
        recognizer.stop()
        delegete?.iSphinxDidStop(reason = "Speech timeout!", code = 522)
    }
}
