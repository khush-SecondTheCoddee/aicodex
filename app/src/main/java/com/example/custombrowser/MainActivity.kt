package com.example.custombrowser

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity() {

    private val networkPool = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val urlInput = findViewById<EditText>(R.id.urlInput)
        val goButton = findViewById<Button>(R.id.goButton)
        val statusView = findViewById<TextView>(R.id.statusView)
        val contentView = findViewById<TextView>(R.id.contentView)

        urlInput.setText("https://example.org")
        goButton.setOnClickListener {
            val input = urlInput.text?.toString().orEmpty().trim()
            val urlText = normalizeUrl(input)
            statusView.text = "Loading: $urlText"
            contentView.text = ""

            networkPool.execute {
                try {
                    val (statusCode, body) = fetch(urlText)
                    val rendered = SimpleHtmlRenderer.render(body)
                    runOnUiThread {
                        statusView.text = "HTTP $statusCode • Rendered with custom engine"
                        contentView.text = rendered
                    }
                } catch (e: Exception) {
                    runOnUiThread {
                        statusView.text = "Failed to load $urlText"
                        contentView.text = e.message ?: "Unknown error"
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        networkPool.shutdownNow()
    }

    private fun normalizeUrl(input: String): String {
        if (input.startsWith("http://") || input.startsWith("https://")) {
            return input
        }
        return "https://$input"
    }

    private fun fetch(urlText: String): Pair<Int, String> {
        val url = URL(urlText)
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            instanceFollowRedirects = true
            connectTimeout = 10_000
            readTimeout = 10_000
            setRequestProperty("User-Agent", "CustomBrowser/1.0")
        }

        val status = conn.responseCode
        val stream = if (status in 200..399) conn.inputStream else conn.errorStream
        val body = BufferedReader(InputStreamReader(stream)).use { br ->
            buildString {
                var line: String?
                while (br.readLine().also { line = it } != null) {
                    append(line).append('\n')
                }
            }
        }
        conn.disconnect()
        return status to body
    }
}
