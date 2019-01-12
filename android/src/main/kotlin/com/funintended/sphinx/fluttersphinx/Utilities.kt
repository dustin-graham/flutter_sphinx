package com.funintended.sphinx.fluttersphinx

class SphinxUtilities {
    companion object {
        fun removePunctuation(words: String) : String {
            val punctuations = arrayOf(".",",","?","!","_","-","\\",":")
            var newWords = words
            for (punctuation in punctuations) {
                if (punctuation == "-") {
                    newWords = newWords.replace(punctuation, newValue = " ")
                } else {
                    newWords = newWords.replace(punctuation, newValue = "")
                }
            }
            return newWords.trim()
        }

        fun removePunctuationArr(words: List<String>): List<String> {
            val mutableList = words.toMutableList()
            for ((index, word) in words.withIndex()) {
                mutableList[index] = SphinxUtilities.removePunctuation(words = word)
            }
            return mutableList;
        }
    }
}