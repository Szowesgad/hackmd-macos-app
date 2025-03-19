//
//  ExportManager.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa
import WebKit
import UniformTypeIdentifiers

enum ExportFormat {
    case pdf
    case markdown
    case html
    
    var fileExtension: String {
        switch self {
        case .pdf:
            return "pdf"
        case .markdown:
            return "md"
        case .html:
            return "html"
        }
    }
    
    var contentType: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .markdown, .html:
            return .plainText
        }
    }
    
    var displayName: String {
        switch self {
        case .pdf:
            return "PDF Document"
        case .markdown:
            return "Markdown"
        case .html:
            return "HTML"
        }
    }
}

class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    // Główna metoda do eksportu zawartości
    func exportContent(content: String, title: String, format: ExportFormat, from window: NSWindow?, completion: @escaping (Bool, Error?) -> Void) {
        switch format {
        case .pdf:
            exportToPDF(content: content, title: title, from: window, completion: completion)
        case .markdown, .html:
            exportToFile(content: content, title: title, format: format, from: window, completion: completion)
        }
    }
    
    // Eksport do pliku tekstowego (markdown, html)
    private func exportToFile(content: String, title: String, format: ExportFormat, from window: NSWindow?, completion: @escaping (Bool, Error?) -> Void) {
        guard let window = window else {
            completion(false, nil)
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save as \(format.displayName)"
        savePanel.nameFieldStringValue = "\(title).\(format.fileExtension)"
        savePanel.allowedContentTypes = [format.contentType]
        savePanel.canCreateDirectories = true
        
        savePanel.beginSheetModal(for: window) { (response) in
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    completion(true, nil)
                } catch {
                    completion(false, error)
                }
            } else {
                completion(false, nil)
            }
        }
    }
    
    // Eksport do PDF
    private func exportToPDF(content: String, title: String, from window: NSWindow?, completion: @escaping (Bool, Error?) -> Void) {
        guard let window = window else {
            completion(false, nil)
            return
        }
        
        // Utwórz tymczasowy webview do renderowania PDF
        let configuration = WKWebViewConfiguration()
        let tempWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1100), configuration: configuration)
        
        // Dodaj kaskadowe arkusze stylów, aby poprawić wygląd PDF
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    padding: 20px;
                    max-width: 800px;
                    margin: 0 auto;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 { font-size: 2em; margin-top: 0; }
                h2 { font-size: 1.5em; }
                h3 { font-size: 1.25em; }
                a { color: #0366d6; text-decoration: none; }
                img { max-width: 100%; }
                pre, code {
                    font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, Courier, monospace;
                    background-color: #f6f8fa;
                    border-radius: 3px;
                    padding: 0.2em 0.4em;
                    font-size: 85%;
                }
                pre {
                    padding: 16px;
                    overflow: auto;
                    line-height: 1.45;
                }
                pre code {
                    background-color: transparent;
                    padding: 0;
                }
                blockquote {
                    border-left: 0.25em solid #dfe2e5;
                    padding: 0 1em;
                    color: #6a737d;
                }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin-bottom: 16px;
                }
                table th, table td {
                    padding: 6px 13px;
                    border: 1px solid #dfe2e5;
                }
                table tr:nth-child(2n) {
                    background-color: #f6f8fa;
                }
                hr {
                    height: 0.25em;
                    padding: 0;
                    margin: 24px 0;
                    background-color: #e1e4e8;
                    border: 0;
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
        
        // Załaduj HTML
        tempWebView.loadHTMLString(styledHTML, baseURL: nil)
        
        // Poczekaj aż webview załaduje zawartość (1 sekunda powinno wystarczyć)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let savePanel = NSSavePanel()
            savePanel.title = "Save as PDF"
            savePanel.nameFieldStringValue = "\(title).pdf"
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.canCreateDirectories = true
            
            savePanel.beginSheetModal(for: window) { (response) in
                if response == .OK, let url = savePanel.url {
                    // Utwórz PDF
                    let pdfConfiguration = WKPDFConfiguration()
                    tempWebView.createPDF(configuration: pdfConfiguration) { (pdfData, error) in
                        if let error = error {
                            completion(false, error)
                        } else if let pdfData = pdfData {
                            do {
                                try pdfData.write(to: url)
                                completion(true, nil)
                            } catch {
                                completion(false, error)
                            }
                        } else {
                            completion(false, NSError(domain: "ExportManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF"]))
                        }
                    }
                } else {
                    completion(false, nil)
                }
            }
        }
    }
}