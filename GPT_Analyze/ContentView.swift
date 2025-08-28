import Foundation
import NaturalLanguage
import Cocoa

class GPTAnalyzer {

    func analyze(fileURL: URL) {
        do {
            let startTime = Date()
            print("Starting analysis at: \(startTime)")

            let data = try Data(contentsOf: fileURL)
            guard let conversationsData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                print("Invalid JSON format")
                return
            }

            print("File loaded and JSON parsed successfully")

            // Extract messages from the 'mapping' key with a check for NoneType
            var messages: [String] = []
            for conversation in conversationsData {
                if let mapping = conversation["mapping"] as? [String: [String: Any]] {
                    for node in mapping.values {
                        if let message = node["message"] as? [String: Any],
                           let content = message["content"] as? [String: Any],
                           let parts = content["parts"] as? [String] {
                            messages.append(contentsOf: parts)
                        }
                    }
                }
            }

            print("Messages extracted successfully")

            // Build allText from messages (already [String])
            let allText = messages.joined(separator: " ")

            print("Messages ready for tokenization")

            // Tokenize the text by words, converting to lowercase and filtering
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = allText
            var words: [String] = []
            tokenizer.enumerateTokens(in: allText.startIndex..<allText.endIndex) { tokenRange, _ in
                let word = String(allText[tokenRange]).lowercased()
                // Trim punctuation and whitespace
                let trimmedWord = word.trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
                // Only keep tokens that contain at least one letter and are not empty
                if !trimmedWord.isEmpty && trimmedWord.rangeOfCharacter(from: .letters) != nil {
                    words.append(trimmedWord)
                }
                return true
            }

            print("Text tokenized successfully")

            // Count the frequency of each word
            let wordCounts = NSCountedSet(array: words)
            let totalWords = words.count

            // Get the most common words
            let sortedWords = wordCounts.allObjects.compactMap { $0 as? String }.sorted { wordCounts.count(for: $0) > wordCounts.count(for: $1) }

            print("Word frequencies counted")

            // Display the most common words with percentages
            print("Most common words:")
            for word in sortedWords.prefix(100000) {
                let count = wordCounts.count(for: word)
                let percentage = (Double(count) / Double(totalWords)) * 100
                print("\(word): \(count) (\(String(format: "%.2f", percentage))%)")
            }

            // Sentiment analysis
            let sentimentAnalyzer = NLTagger(tagSchemes: [.sentimentScore])
            sentimentAnalyzer.string = allText
            let sentiment = sentimentAnalyzer.tag(at: allText.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue ?? "0.0"
            let overallSentiment = Double(sentiment) ?? 0.0
            print("Overall sentiment: \(overallSentiment)")

            // Save the results to a file
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let resultsFileURL = homeDirectory.appendingPathComponent("analysis_results.txt")
            let filteredResultsFileURL = homeDirectory.appendingPathComponent("analysis_results_without_stopwords.txt")
            
            var resultsText = "Most common words:\n"
            for word in sortedWords.prefix(100000) {
                let count = wordCounts.count(for: word)
                let percentage = (Double(count) / Double(totalWords)) * 100
                resultsText += "\(word): \(count) (\(String(format: "%.2f", percentage))%)\n"
            }
            resultsText += "\nOverall sentiment: \(overallSentiment)\n"
            try resultsText.write(to: resultsFileURL, atomically: true, encoding: .utf8)

            // Predefined list of stop words
            let stopWords: Set<String> = ["a", "an", "the", "and", "or", "but", "because", "as", "if", "when", "while", "of", "at", "by", "for", "with", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", "in", "out", "on", "off", "over", "under", "again", "further", "then", "once", "here", "there", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now"]

            // Remove stop words
            let filteredWords = words.filter { !stopWords.contains($0) }

            print("Stop words filtered out")

            // Count the frequency of each word (without stop words)
            let filteredWordCounts = NSCountedSet(array: filteredWords)
            let filteredTotalWords = filteredWords.count

            // Display the most common words with percentages (without stop words)
            print("Most common words (without stop words):")
            let filteredSortedWords = filteredWordCounts.allObjects.compactMap { $0 as? String }.sorted { filteredWordCounts.count(for: $0) > filteredWordCounts.count(for: $1) }
            for word in filteredSortedWords.prefix(100000) {
                let count = filteredWordCounts.count(for: word)
                let percentage = (Double(count) / Double(filteredTotalWords)) * 100
                print("\(word): \(count) (\(String(format: "%.2f", percentage))%)")
            }

            // Save the results (without stop words) to a file
            var filteredResultsText = "Most common words (without stop words):\n"
            for word in filteredSortedWords.prefix(100000) {
                let count = filteredWordCounts.count(for: word)
                let percentage = (Double(count) / Double(filteredTotalWords)) * 100
                filteredResultsText += "\(word): \(count) (\(String(format: "%.2f", percentage))%)\n"
            }
            try filteredResultsText.write(to: filteredResultsFileURL, atomically: true, encoding: .utf8)

            let endTime = Date()
            print("Analysis completed at: \(endTime)")
            print("Total analysis time: \(endTime.timeIntervalSince(startTime)) seconds")

        } catch {
            print("Error loading or parsing file: \(error)")
        }
    }
}

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a button to open the file picker
        let openButton = NSButton(title: "Open File", target: self, action: #selector(openFile))
        openButton.frame = NSRect(x: 20, y: 20, width: 100, height: 40)
        view.addSubview(openButton)
    }

    @objc func openFile() {
        let dialog = NSOpenPanel()

        dialog.title = "Choose a JSON file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["json"]

        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                let analyzer = GPTAnalyzer()
                analyzer.analyze(fileURL: result)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
}
