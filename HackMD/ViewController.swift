import Cocoa
import WebKit

class ViewController: NSViewController {
    
    @IBOutlet weak var webViewContainer: NSView!
    var webView: WKWebView!
    var progressIndicator: NSProgressIndicator!
    var isDarkMode: Bool = false
    
    // Adres URL do HackMD.io
    let hackMDURL = URL(string: "https://hackmd.io")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sprawdzenie aktualnego trybu (ciemny/jasny)
        updateAppearanceMode()
        
        // Konfiguracja WebView
        setupWebView()
        
        // Dodanie wskaźnika ładowania
        setupProgressIndicator()
        
        // Dodanie obserwatora zmian motywu systemu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppearanceMode),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Dodanie obserwatora dla obsługi preferencji
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesChanged(_:)),
            name: NSNotification.Name("PreferencesChanged"),
            object: nil
        )
    }
    
    // Konfiguracja WebView
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Włączenie funkcji developerskich
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Włączenie JavaScript
        configuration.preferences.javaScriptEnabled = true
        
        // Ustawienia dla pełnoekranowego trybu wideo
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Dodanie user agent dla lepszej obsługi
        let userAgent = "HackMD-macOS/1.0 Mozilla/5.0 (Macintosh; Intel Mac OS X \(ProcessInfo().operatingSystemVersionString)) AppleWebKit/605.1.15 Version/16.4 Safari/605.1.15"
        configuration.applicationNameForUserAgent = userAgent
        
        // Utworzenie WebView
        webView = WKWebView(frame: webViewContainer.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Ustawienie CallBack dla obserwowania postępu ładowania
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        // Dodanie WebView do kontenera
        webViewContainer.addSubview(webView)
        
        // Załadowanie HackMD
        loadHackMD()
    }
    
    // Konfiguracja wskaźnika postępu
    private func setupProgressIndicator() {
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 2))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.value = 0.0
        progressIndicator.autoresizingMask = [.width]
        view.addSubview(progressIndicator)
    }
    
    // Ładowanie HackMD
    private func loadHackMD() {
        let request = URLRequest(url: hackMDURL)
        webView.load(request)
    }
    
    // Aktualizacja trybu ciemnego/jasnego
    @objc func updateAppearanceMode() {
        if #available(macOS 10.14, *) {
            let appearance = NSApp.effectiveAppearance
            isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            
            // Po załadowaniu strony wstrzykujemy skrypt do zmiany trybu
            if webView.isLoading == false {
                injectDarkModeScript()
            }
        }
    }
    
    // Wstrzyknięcie skryptu do zmiany trybu
    private func injectDarkModeScript() {
        let script = """
        (() => {
            try {
                const isDark = \(isDarkMode ? "true" : "false");
                // Sprawdzenie czy HackMD ma API z trybem ciemnym
                if (typeof window.hackmd !== 'undefined' && typeof window.hackmd.themeManager !== 'undefined') {
                    window.hackmd.themeManager.setTheme(isDark ? 'dark' : 'light');
                } else {
                    // Alternatywna metoda przy użyciu lokalnego przechowywania
                    localStorage.setItem('nightMode', isDark ? 'true' : 'false');
                    
                    // Próba manualnego przełączenia klasy dla body
                    if (isDark) {
                        document.body.classList.add('night-mode');
                    } else {
                        document.body.classList.remove('night-mode');
                    }
                    
                    // Odświeżenie widoku
                    location.reload();
                }
            } catch (e) {
                console.error('Błąd przy zmianie motywu:', e);
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Błąd wstrzykiwania skryptu trybu ciemnego: \(error)")
            }
        }
    }
    
    // Obserwacja zmian preferencji
    @objc private func handlePreferencesChanged(_ notification: Notification) {
        // Tutaj można dodać obsługę zmiany preferencji
        // np. aktualizację ustawień WebView
    }
    
    // Obserwacja postępu ładowania
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressIndicator.doubleValue = webView.estimatedProgress
            
            // Ukryj pasek postępu po zakończeniu ładowania
            if webView.estimatedProgress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.progressIndicator.isHidden = true
                }
            } else {
                progressIndicator.isHidden = false
            }
        }
    }
    
    deinit {
        // Usunięcie obserwatorów
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        NotificationCenter.default.removeObserver(self)
    }
}

// Rozszerzenie do obsługi WKWebView
extension ViewController: WKNavigationDelegate, WKUIDelegate {
    // Obsługa końca ładowania strony
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.title = webView.title ?? "HackMD"
        
        // Wstrzyknięcie skryptu trybu ciemnego
        injectDarkModeScript()
    }
    
    // Obsługa błędów ładowania
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressIndicator.isHidden = true
        
        // Pokaż komunikat o błędzie
        let alert = NSAlert()
        alert.messageText = "Błąd ładowania HackMD"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Spróbuj ponownie")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            loadHackMD()
        }
    }
    
    // Obsługa nowych okien
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Jeśli HackMD próbuje otworzyć nowe okno
        if navigationAction.targetFrame == nil {
            // Sprawdź czy URL jest zewnętrzny
            if let url = navigationAction.request.url, !url.absoluteString.contains("hackmd.io") {
                // Otwórz w domyślnej przeglądarce
                NSWorkspace.shared.open(url)
            } else {
                // W przeciwnym razie załaduj w bieżącym WebView
                webView.load(navigationAction.request)
            }
        }
        return nil
    }
    
    // Obsługa dialogów JavaScript
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    // Obsługa potwierdzeń JavaScript
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Anuluj")
        
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
    
    // Obsługa promptów JavaScript
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "HackMD"
        alert.informativeText = prompt
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Anuluj")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField
        
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn ? textField.stringValue : nil)
    }
}
