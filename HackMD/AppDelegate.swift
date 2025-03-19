import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow!
    var webView: WKWebView!
    
    // Adres URL do HackMD.io
    let hackMDURL = URL(string: "https://hackmd.io")!
    
    // Ustawienia dla developera
    let isDeveloperModeEnabled = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Konfiguracja WKWebView
        let webConfiguration = WKWebViewConfiguration()
        
        // Włączenie funkcji developerskich jeśli tryb developerski jest aktywny
        if isDeveloperModeEnabled {
            webConfiguration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        }
        
        // Dodanie user agent dla lepszej obsługi
        let userAgent = "HackMD-macOS/1.0 Mozilla/5.0 (Macintosh; Intel Mac OS X \(ProcessInfo().operatingSystemVersionString)) AppleWebKit/605.1.15 Version/16.4 Safari/605.1.15"
        webConfiguration.applicationNameForUserAgent = userAgent
        
        // Utworzenie obiektu WKWebView
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Ustawienie delegata nawigacji
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Utworzenie okna
        let windowRect = NSRect(x: 0, y: 0, width: 1200, height: 800)
        mainWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Konfiguracja okna
        mainWindow.title = "HackMD"
        mainWindow.center()
        mainWindow.contentView = NSView(frame: windowRect)
        mainWindow.contentView?.addSubview(webView)
        
        // Ograniczenia AutoLayout
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: mainWindow.contentView!.topAnchor),
            webView.leadingAnchor.constraint(equalTo: mainWindow.contentView!.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: mainWindow.contentView!.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: mainWindow.contentView!.bottomAnchor)
        ])
        
        // Wyświetlenie okna
        mainWindow.makeKeyAndOrderFront(nil)
        
        // Załadowanie zawartości HackMD
        loadHackMD()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Metoda do ładowania HackMD
    func loadHackMD() {
        let request = URLRequest(url: hackMDURL)
        webView.load(request)
    }
}

// Rozszerzenie do obsługi nawigacji WebView
extension AppDelegate: WKNavigationDelegate, WKUIDelegate {
    // Obsługa ładowania strony
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        mainWindow.title = webView.title ?? "HackMD"
    }
    
    // Obsługa błędów ładowania
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let alert = NSAlert()
        alert.messageText = "Błąd ładowania HackMD"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Obsługa nowych okien
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Jeżeli HackMD próbuje otworzyć nowe okno, przekierowujemy to do głównego widoku
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // Obsługa alertów JavaScript
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
}
