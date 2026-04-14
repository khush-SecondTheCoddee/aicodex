package com.example.custombrowser

import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.StyleSpan
import java.util.Locale

/**
 * A tiny custom HTML renderer (no WebView/Chromium).
 * Supported tags: h1-h3, p, br, b/strong, i/em, a.
 */
object SimpleHtmlRenderer {

    private val tagRegex = Regex("<(/?)([a-zA-Z0-9]+)([^>]*)>")
    private val hrefRegex = Regex("href\\s*=\\s*\"([^\"]+)\"", RegexOption.IGNORE_CASE)

    fun render(html: String): CharSequence {
        val out = SpannableStringBuilder()
        val boldStack = ArrayDeque<Int>()
        val italicStack = ArrayDeque<Int>()
        val linkStack = ArrayDeque<Pair<Int, String>>()

        var last = 0
        tagRegex.findAll(html).forEach { match ->
            appendDecodedText(out, html.substring(last, match.range.first))

            val closing = match.groupValues[1] == "/"
            val rawTag = match.groupValues[2].lowercase(Locale.ROOT)
            val attrs = match.groupValues[3]

            when {
                !closing && (rawTag == "h1" || rawTag == "h2" || rawTag == "h3") -> {
                    ensureBreak(out)
                    boldStack.addLast(out.length)
                }
                closing && (rawTag == "h1" || rawTag == "h2" || rawTag == "h3") -> {
                    applyStyle(boldStack, out, android.graphics.Typeface.BOLD)
                    out.append("\n\n")
                }
                !closing && (rawTag == "b" || rawTag == "strong") -> boldStack.addLast(out.length)
                closing && (rawTag == "b" || rawTag == "strong") -> applyStyle(
                    boldStack,
                    out,
                    android.graphics.Typeface.BOLD
                )
                !closing && (rawTag == "i" || rawTag == "em") -> italicStack.addLast(out.length)
                closing && (rawTag == "i" || rawTag == "em") -> applyStyle(
                    italicStack,
                    out,
                    android.graphics.Typeface.ITALIC
                )
                !closing && rawTag == "a" -> {
                    val href = hrefRegex.find(attrs)?.groupValues?.getOrNull(1).orEmpty()
                    linkStack.addLast(out.length to href)
                }
                closing && rawTag == "a" -> {
                    val (start, href) = linkStack.removeLastOrNull() ?: return@forEach
                    val end = out.length
                    if (href.isNotBlank()) {
                        out.insert(end, " [$href]")
                    }
                    out.append(' ')
                }
                !closing && rawTag == "br" -> out.append('\n')
                (closing && rawTag == "p") || (!closing && rawTag == "p") -> ensureBreak(out)
            }

            last = match.range.last + 1
        }

        if (last < html.length) {
            appendDecodedText(out, html.substring(last))
        }

        while (boldStack.isNotEmpty()) {
            applyStyle(boldStack, out, android.graphics.Typeface.BOLD)
        }
        while (italicStack.isNotEmpty()) {
            applyStyle(italicStack, out, android.graphics.Typeface.ITALIC)
        }

        return out
    }

    private fun applyStyle(stack: ArrayDeque<Int>, out: SpannableStringBuilder, typeface: Int) {
        val start = stack.removeLastOrNull() ?: return
        val end = out.length
        if (end > start) {
            out.setSpan(StyleSpan(typeface), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
    }

    private fun ensureBreak(out: SpannableStringBuilder) {
        if (out.isNotEmpty() && out.last() != '\n') {
            out.append("\n\n")
        }
    }

    private fun appendDecodedText(out: SpannableStringBuilder, text: String) {
        out.append(
            text
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace(Regex("\\s+"), " ")
        )
    }
}
