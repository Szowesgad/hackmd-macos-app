//
//  WebViewController.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa
import WebKit
import UniformTypeIdentifiers

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate, NSMenuDelegate {
    private var webView: WKWebView!
    private var progressIndicator: NSProgressIndicator!
    private var devTools: WKWebView?
    private var devToolsWindow: NSWindow?
    private var contextMenu: NSMenu?
    
    // Adres URL do HackMD.io
    private let hackmdURL = Bundle.main.object(forInfoDictionaryKey: "HACKMD_URL") as? String ?? "https://hackmd.io"
    
    override func loadView() {
        // Tworzenie głównego widoku
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 800))
        
        setupWebView()
        setupProgressIndicator()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ładowanie strony HackMD.io
        if let url = URL(string: hackmdURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // Obserwowanie postępu ładowania strony
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            updateProgressIndicator()
        } else if keyPath == "title" {
            updateWindowTitle()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupWebView() {
        // Konfiguracja WKWebView
        let configuration = WKWebViewConfiguration()
        
        // Ustawienia WebPreferences
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Włączenie deweloperskich funkcji WebKit
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Ustawienia kontrolera użytkownika
        let userContentController = WKUserContentController()
        
        // Dodanie skryptów injekcyjnych dla funkcji deweloperskich
        injectDeveloperScripts(userContentController)
        
        // Dodanie message handlers dla komunikacji JS <-> Swift
        userContentController.add(self, name: "exportContent")
        
        configuration.userContentController = userContentController
        
        // Utworzenie i konfiguracja webView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = true
        
        // Setup context menu
        setupContextMenu()
        
        // Dodanie webView do głównego widoku
        view.addSubview(webView)
    }
    
    private func setupContextMenu() {
        // Tworzenie menu kontekstowego
        contextMenu = NSMenu(title: "HackMD Context Menu")
        contextMenu?.delegate = self
        
        // Dodanie pozycji menu
        contextMenu?.addItem(NSMenuItem(title: "Copy Markdown", action: #selector(copyMarkdown(_:)), keyEquivalent: ""))
        contextMenu?.addItem(NSMenuItem(title: "Copy HTML", action: #selector(copyHTML(_:)), keyEquivalent: ""))
        contextMenu?.addItem(NSMenuItem.separator())
        contextMenu?.addItem(NSMenuItem(title: "Export as PDF", action: #selector(exportAsPDF(_:)), keyEquivalent: ""))
        contextMenu?.addItem(NSMenuItem(title: "Export as Markdown", action: #selector(exportAsMarkdown(_:)), keyEquivalent: ""))
        contextMenu?.addItem(NSMenuItem.separator())
        contextMenu?.addItem(NSMenuItem(title: "Open in Browser", action: #selector(openInBrowser(_:)), keyEquivalent: ""))
    }
    
    private func setupProgressIndicator() {
        // Utworzenie wskaźnika postępu
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 2))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.autoresizingMask = [.width, .minYMargin]
        
        view.addSubview(progressIndicator)
    }
    
    private func injectDeveloperScripts(_ userContentController: WKUserContentController) {
        // Tutaj można dodać skrypty, które będą wstrzykiwane do strony
        let developerSettingsScript = """
        // Skrypt do wstrzyknięcia ustawień developerskich
        document.addEventListener('DOMContentLoaded', function() {
            console.log('HackMD macOS App - Dev Mode Active');
            
            // Funkcja pobierania zawartości do eksportu
            window.getMarkdownContent = function() {
                // Próba pobrania zawartości markdowna z edytora HackMD
                try {
                    // Szukanie elementu zawierającego markdown
                    const editor = document.querySelector('.CodeMirror') || 
                                 document.querySelector('.editor') || 
                                 document.querySelector('.markdown-body');
                    
                    if (editor) {
                        // Jeśli to CodeMirror, pobierz zawartość z edytora
                        if (window.CodeMirror && editor.CodeMirror) {
                            return editor.CodeMirror.getValue();
                        }
                        
                        // Jeśli to element z klasą markdown-body, pobierz innerHTML i przekonwertuj
                        if (editor.classList.contains('markdown-body')) {
                            return editor.innerHTML;
                        }
                        
                        // Próba pobrania tekstu
                        return editor.textContent || editor.innerText;
                    }
                    
                    // Fallback - zwróć tytuł dokumentu
                    return document.title;
                } catch (e) {
                    console.error('Error getting markdown content:', e);
                    return 'Error getting content: ' + e.message;
                }
            };
            
            // Funkcja pobierania nazwy dokumentu
            window.getDocumentTitle = function() {
                // Pobierz tytuł dokumentu lub domyślną nazwę
                const rawTitle = document.title || 'HackMD Document';
                // Usuń przyrostek " - HackMD" jeśli istnieje
                return rawTitle.replace(/ - HackMD$/, '');
            };
            
            // Funkcja do eksportu zawartości
            window.exportContent = function(format) {
                const content = window.getMarkdownContent();
                const title = window.getDocumentTitle();
                
                // Wyślij zawartość do Swift
                window.webkit.messageHandlers.exportContent.postMessage({
                    content: content,
                    title: title,
                    format: format
                });
            };
        });
        """
        
        let script = WKUserScript(
            source: developerSettingsScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        userContentController.addUserScript(script)
    }
    
    // MARK: - Helper Methods
    
    private func updateProgressIndicator() {
        let progress = webView.estimatedProgress
        progressIndicator.doubleValue = progress
        
        // Ukryj wskaźnik postępu, gdy strona zostanie załadowana
        if progress >= 1.0 {
            progressIndicator.isHidden = true
        } else if progressIndicator.isHidden {
            progressIndicator.isHidden = false
        }
    }
    
    private func updateWindowTitle() {
        if let title = webView.title, !title.isEmpty {
            self.view.window?.title = "HackMD - \(title)"
        } else {
            self.view.window?.title = "HackMD"
        }
    }
    
    // MARK: - Public Methods
    
    func reload() {
        webView.reload()
    }
    
    func toggleDevTools() {
        if devToolsWindow == nil {
            openDevTools()
        } else {
            closeDevTools()
        }
    }
    
    private func openDevTools() {
        // Tworzenie okna dla narzędzi developerskich
        let devToolsWindowFrame = NSRect(x: 100, y: 100, width: 800, height: 600)
        let devToolsWindow = NSWindow(
            contentRect: devToolsWindowFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        devToolsWindow.title = "Developer Tools"
        
        // Tworzenie WKWebView dla DevTools
        let devTools = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        devTools.autoresizingMask = [.width, .height]
        
        // Dodanie DevTools do okna
        devToolsWindow.contentView = devTools
        
        // Wyświetlenie DevTools
        if let inspector = webView.value(forKey: "_inspector") as? NSObject {
            if let webView = inspector.value(forKey: "webView") as? WKWebView {
                devTools.addSubview(webView)
                webView.frame = devTools.bounds
                webView.autoresizingMask = [.width, .height]
            }
        }
        
        devToolsWindow.makeKeyAndOrderFront(nil)
        
        // Zachowanie referencji
        self.devTools = devTools
        self.devToolsWindow = devToolsWindow
    }
    
    private func closeDevTools() {
        devToolsWindow?.close()
        devToolsWindow = nil
        devTools = nil
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressIndicator.isHidden = false
        progressIndicator.doubleValue = 0.0
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressIndicator.doubleValue = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.progressIndicator.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressIndicator.isHidden = true
        // Obsługa błędów ładowania strony
    }
    
    // MARK: - WKUIDelegate
    
    // Obsługa okien popup i alertów
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            // Otwieranie linków z target="_blank" w tym samym oknie
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // Obsługa menu kontekstowego
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        // Na macOS ta metoda może nie być wywoływana, zamiast tego używamy NSMenu
        completionHandler(nil)
    }
    
    // Własne menu kontekstowe
    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        // Ta metoda również może nie być wywoływana na macOS
    }
    
    // Handle menu display for macOS context menu
    func webView(_ webView: WKWebView, handleContextMenu contextMenu: WKContextMenu, forElement elementInfo: WKContextMenuElementInfo) async -> WKContextMenu {
        // Zwróć nasze własne menu kontekstowe
        return contextMenu
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
    
    deinit {
        // Usunięcie obserwatorów
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        
        // Usunięcie message handlers
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "exportContent")
    }
}

// MARK: - Export Functions

extension WebViewController {
    
    // Eksport do PDF
    @objc func exportAsPDF(_ sender: Any) {
        // Uruchom JavaScript do pobrania zawartości
        webView.evaluateJavaScript("window.exportContent('pdf')") { (_, error) in
            if let error = error {
                print("Error executing exportContent script: \(error)")
                self.showExportError(error.localizedDescription)
            }
        }
    }
    
    // Eksport do Markdown
    @objc func exportAsMarkdown(_ sender: Any) {
        // Uruchom JavaScript do pobrania zawartości
        webView.evaluateJavaScript("window.exportContent('markdown')") { (_, error) in
            if let error = error {
                print("Error executing exportContent script: \(error)")
                self.showExportError(error.localizedDescription)
            }
        }
    }
    
    // Kopiowanie Markdown
    @objc func copyMarkdown(_ sender: Any) {
        webView.evaluateJavaScript("window.getMarkdownContent()") { (result, error) in
            if let error = error {
                print("Error getting markdown content: \(error)")
            } else if let content = result as? String {
                // Kopiuj do schowka
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(content, forType: .string)
            }
        }
    }
    
    // Kopiowanie HTML
    @objc func copyHTML(_ sender: Any) {
        webView.evaluateJavaScript("document.querySelector('.markdown-body')?.innerHTML || document.body.innerHTML") { (result, error) in
            if let error = error {
                print("Error getting HTML content: \(error)")
            } else if let content = result as? String {
                // Kopiuj do schowka
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(content, forType: .html)
            }
        }
    }
    
    // Otwieranie w przeglądarce
    @objc func openInBrowser(_ sender: Any) {
        if let url = webView.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    // Zapisywanie pliku
    private func saveFile(content: String, defaultName: String, fileType: UTType, fileExtension: String) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Document"
        savePanel.nameFieldStringValue = defaultName + "." + fileExtension
        savePanel.allowedContentTypes = [fileType]
        savePanel.canCreateDirectories = true
        
        savePanel.beginSheetModal(for: self.view.window!) { (response) in
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    self.showExportError("Failed to save file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Generowanie PDF z zawartości HTML
    private func generatePDF(from html: String, title: String) {
        // Utwórz tymczasowy WKWebView do renderowania PDF
        let configuration = WKWebViewConfiguration()
        let tempWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1000), configuration: configuration)
        
        // Załaduj HTML
        tempWebView.loadHTMLString(html, baseURL: webView.url)
        
        // Poczekaj aż się załaduje
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Konfiguracja panelu zapisu
            let savePanel = NSSavePanel()
            savePanel.title = "Save PDF"
            savePanel.nameFieldStringValue = title + ".pdf"
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.canCreateDirectories = true
            
            savePanel.beginSheetModal(for: self.view.window!) { (response) in
                if response == .OK, let url = savePanel.url {
                    // Konwertuj do PDF
                    let configuration = WKPDFConfiguration()
                    tempWebView.createPDF(configuration: configuration) { (pdfData, error) in
                        if let error = error {
                            self.showExportError("Failed to generate PDF: \(error.localizedDescription)")
                        } else if let pdfData = pdfData {
                            do {
                                try pdfData.write(to: url)
                            } catch {
                                self.showExportError("Failed to save PDF: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Wyświetlanie błędu eksportu
    private func showExportError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "exportContent" {
            if let messageBody = message.body as? [String: Any],
               let content = messageBody["content"] as? String,
               let title = messageBody["title"] as? String,
               let format = messageBody["format"] as? String {
                
                // Wykonaj eksport w zależności od formatu
                switch format {
                case "pdf":
                    // Eksport do PDF
                    generatePDF(from: content, title: title)
                    
                case "markdown":
                    // Eksport do Markdown
                    saveFile(content: content, defaultName: title, fileType: UTType.plainText, fileExtension: "md")
                    
                default:
                    print("Unknown export format: \(format)")
                }
            }
        }
    }
}

// MARK: - NSMenuDelegate

extension WebViewController {
    
    // Customize menu before display
    func menuWillOpen(_ menu: NSMenu) {
        // Można tutaj dynamicznie włączać/wyłączać pozycje menu
        // w zależności od aktualnego stanu
    }
    
    // Override context menu for WKWebView
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Enable all menu items from our context menu
        return true
    }
}
