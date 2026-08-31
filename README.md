# GPT-Analyze

A macOS SwiftUI app for analyzing GPT conversation exports.

## What's here

- `GPT_Analyze/ContentView.swift` — contains a `GPTAnalyzer` class that reads a conversation export from a file URL, deserializes the JSON, and analyzes it using Apple's `NaturalLanguage` framework. It times the run.
- `GPT_Analyze.xcodeproj` — open and build.
- `COMMERCIALIZATION_ANALYSIS.md`, `EXECUTIVE_SUMMARY.md` — generated assessments of the idea. Not documentation of the code.

## Status

Six commits, November 2025. `GPT-Analyze2` is a later restart with the same structure.

## Related

`conversation-analysis-tools` covers the same subject in Python with tests and CI.
