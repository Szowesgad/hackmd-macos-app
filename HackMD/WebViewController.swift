//
//  WebViewController.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var progressIndicator: NSProgressIndicator!
    private var devTools: WKWebView?
    private var devToolsWindow: NSWindow?
    
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
        
        configuration.userContentController = userContentController
        
        // Utworzenie i konfiguracja webView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = true
        
        // Dodanie webView do głównego widoku
        view.addSubview(webView)
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
            // Dodatkowe ustawienia developerskie można dodać tutaj
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
    }
}
