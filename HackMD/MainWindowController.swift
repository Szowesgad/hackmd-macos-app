import Cocoa
import WebKit

class MainWindowController: NSWindowController {
    
    var webViewController: ViewController!
    var loadingViewController: LoadingViewController!
    
    // Stan ładowania aplikacji
    private var isAppReady = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Konfiguracja okna
        configureWindow()
        
        // Pokazanie ekranu ładowania
        showLoadingScreen()
    }
    
    private func configureWindow() {
        guard let window = window else { return }
        
        // Ustawienie minimalnego rozmiaru okna
        window.minSize = NSSize(width: 800, height: 600)
        
        // Tytuł okna
        window.title = "HackMD"
        
        // Dodanie przycisków do paska narzędzi
        configureToolbar()
        
        // Rejestracja obserwatorów zdarzeń
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
        
        // Rejestracja obserwatora trybu ciemnego/jasnego
        if #available(macOS 10.14, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppearanceChange(_:)),
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
        }
    }
    
    // Konfiguracja paska narzędzi
    private func configureToolbar() {
        guard let window = window else { return }
        
        // Utworzenie paska narzędzi
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        
        // Przypisanie paska narzędzi do okna
        window.toolbar = toolbar
    }
    
    // Wyświetlenie ekranu ładowania
    private func showLoadingScreen() {
        // Utworzenie kontrolera ekranu ładowania
        loadingViewController = LoadingViewController()
        
        // Ustawienie callbacku po zakończeniu ładowania
        loadingViewController.onLoadingComplete = { [weak self] in
            self?.showMainContent()
        }
        
        // Wyświetlenie ekranu ładowania
        if let window = window, let contentView = window.contentView {
            loadingViewController.view.frame = contentView.bounds
            loadingViewController.view.autoresizingMask = [.width, .height]
            contentView.addSubview(loadingViewController.view)
        }
    }
    
    // Wyświetlenie głównej zawartości aplikacji
    private func showMainContent() {
        guard let window = window, let contentView = window.contentView else { return }
        
        // Utworzenie kontrolera WebView
        webViewController = ViewController()
        
        // Usunięcie ekranu ładowania
        loadingViewController.view.removeFromSuperview()
        
        // Dodanie głównego widoku
        webViewController.view.frame = contentView.bounds
        webViewController.view.autoresizingMask = [.width, .height]
        contentView.addSubview(webViewController.view)
        
        // Ustawienie flagi gotowości aplikacji
        isAppReady = true
        
        // Aktualizacja tytułu okna
        window.title = "HackMD"
    }
    
    // Obsługa zamknięcia okna
    @objc private func handleWindowClose(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Obsługa zmiany trybu ciemnego/jasnego
    @objc private func handleAppearanceChange(_ notification: Notification) {
        // Przekazanie zdarzenia do webViewController
        webViewController?.updateAppearanceMode()
    }
    
    // Metody obsługi akcji z paska narzędzi
    @objc func handleRefresh(_ sender: Any) {
        webViewController?.loadHackMD()
    }
    
    @objc func handleHome(_ sender: Any) {
        webViewController?.loadHackMD()
    }
    
    @objc func handleShareButton(_ sender: Any) {
        guard let webView = webViewController?.webView else { return }
        
        // Pobranie adresu URL i tytułu strony
        guard let url = webView.url, let title = webView.title else { return }
        
        // Utworzenie serwisu udostępniania
        let sharingServicePicker = NSSharingServicePicker(items: [url, title])
        
        // Wyświetlenie menu udostępniania
        if let button = sender as? NSButton {
            sharingServicePicker.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc func handlePreferences(_ sender: Any) {
        // Tutaj możemy dodać wyświetlanie okna preferencji
        // To zostanie zaimplementowane w przyszłości
    }
    
    @objc func handleDeveloperTools(_ sender: Any) {
        webViewController?.showDeveloperTools()
    }
    
    @objc func handleDarkMode(_ sender: NSButton) {
        if #available(macOS 10.14, *) {
            // Przełączenie trybu ciemnego/jasnego
            let isDarkMode = sender.state == .on
            webViewController?.isDarkMode = isDarkMode
            webViewController?.injectDarkModeScript()
        }
    }
}

// Rozszerzenie do obsługi paska narzędzi
extension MainWindowController: NSToolbarDelegate {
    // Dostępne identyfikatory elementów paska narzędzi
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .home,
            .refresh,
            NSToolbarItem.Identifier.flexibleSpace,
            .share,
            NSToolbarItem.Identifier.flexibleSpace,
            .developerTools,
            .preferences
        ]
    }
    
    // Dozwolone identyfikatory elementów paska narzędzi
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .home,
            .refresh,
            .share,
            .developerTools,
            .preferences,
            .darkMode,
            NSToolbarItem.Identifier.flexibleSpace,
            NSToolbarItem.Identifier.space
        ]
    }
    
    // Tworzenie elementów paska narzędzi
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        if itemIdentifier == .home {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Strona główna"
            item.paletteLabel = "Strona główna"
            item.toolTip = "Przejdź do strony głównej HackMD"
            item.image = NSImage(named: NSImage.homeTemplateName)
            item.target = self
            item.action = #selector(handleHome(_:))
            return item
        }
        else if itemIdentifier == .refresh {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Odśwież"
            item.paletteLabel = "Odśwież"
            item.toolTip = "Odśwież stronę"
            item.image = NSImage(named: NSImage.refreshTemplateName)
            item.target = self
            item.action = #selector(handleRefresh(_:))
            return item
        }
        else if itemIdentifier == .share {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Udostępnij"
            item.paletteLabel = "Udostępnij"
            item.toolTip = "Udostępnij stronę"
            item.image = NSImage(named: NSImage.shareTemplateName)
            item.target = self
            item.action = #selector(handleShareButton(_:))
            return item
        }
        else if itemIdentifier == .preferences {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Preferencje"
            item.paletteLabel = "Preferencje"
            item.toolTip = "Ustawienia aplikacji"
            item.image = NSImage(named: NSImage.preferencesGeneralName)
            item.target = self
            item.action = #selector(handlePreferences(_:))
            return item
        }
        else if itemIdentifier == .developerTools {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Narzędzia deweloperskie"
            item.paletteLabel = "Narzędzia deweloperskie"
            item.toolTip = "Pokaż narzędzia deweloperskie"
            item.image = NSImage(named: NSImage.advancedName)
            item.target = self
            item.action = #selector(handleDeveloperTools(_:))
            return item
        }
        else if itemIdentifier == .darkMode {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Tryb ciemny"
            item.paletteLabel = "Tryb ciemny"
            item.toolTip = "Przełącz tryb ciemny/jasny"
            
            let button = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 24))
            button.bezelStyle = .roundRect
            button.setButtonType(.switch)
            button.title = ""
            button.image = NSImage(named: NSImage.colorPanelName)
            button.target = self
            button.action = #selector(handleDarkMode(_:))
            
            // Ustawienie początkowego stanu
            if #available(macOS 10.14, *) {
                let appearance = NSApp.effectiveAppearance
                let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                button.state = isDarkMode ? .on : .off
            }
            
            item.view = button
            
            return item
        }
        
        return nil
    }
}

// Rozszerzenie dla identyfikatorów elementów paska narzędzi
extension NSToolbarItem.Identifier {
    static let home = NSToolbarItem.Identifier("HomeToolbarItem")
    static let refresh = NSToolbarItem.Identifier("RefreshToolbarItem")
    static let share = NSToolbarItem.Identifier("ShareToolbarItem")
    static let preferences = NSToolbarItem.Identifier("PreferencesToolbarItem")
    static let developerTools = NSToolbarItem.Identifier("DeveloperToolsToolbarItem")
    static let darkMode = NSToolbarItem.Identifier("DarkModeToolbarItem")
}

// Rozszerzenie dla ViewController
extension ViewController {
    // Dodajemy brakującą metodę
    func showDeveloperTools() {
        // Otworzenie narzędzi developerskich przy pomocy JavaScript
        webView.evaluateJavaScript("__ELECTRON_INSPECTOR__.showDevTools();", completionHandler: { (result, error) in
            if let error = error {
                print("Błąd przy otwieraniu narzędzi developerskich: \(error)")
                
                // Alternatywna metoda otwierania narzędzi developerskich
                let script = """
                (function() {
                    try {
                        if (typeof __ELECTRON_INSPECTOR__ !== 'undefined') {
                            __ELECTRON_INSPECTOR__.showDevTools();
                        } else if (typeof __REACT_DEVTOOLS_GLOBAL_HOOK__ !== 'undefined') {
                            __REACT_DEVTOOLS_GLOBAL_HOOK__.inject();
                        } else {
                            console.log('Narzędzia developerskie nie są dostępne');
                        }
                    } catch(e) {
                        console.error('Błąd przy próbie otwarcia narzędzi developerskich:', e);
                    }
                })();
                """
                
                self.webView.evaluateJavaScript(script, completionHandler: nil)
            }
        })
    }
    
    // Dodajemy brakującą metodę
    func loadHackMD() {
        if let hackMDURL = URL(string: "https://hackmd.io") {
            let request = URLRequest(url: hackMDURL)
            webView.load(request)
        }
    }
}
