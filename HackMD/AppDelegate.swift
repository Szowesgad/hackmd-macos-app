//
//  AppDelegate.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    var webViewController: WebViewController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Kod do wykonania przed zamknięciem aplikacji
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Setup Methods
    
    private func setupMainWindow() {
        // Tworzenie głównego kontrolera widoku
        let viewController = WebViewController()
        webViewController = viewController
        
        // Tworzenie okna
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "HackMD"
        window.center()
        window.contentViewController = viewController
        window.setFrameAutosaveName("Main Window")
        window.makeKeyAndOrderFront(nil)
        
        // Zachowanie referencji do okna
        mainWindow = window
        
        // Sprawdzenie czy aplikacja powinna uruchamiać się w trybie ciemnym
        applyAppearanceSettingIfNeeded()
        
        // Obsługa zmian trybu ciemnego/jasnego
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyAppearanceSettingIfNeeded),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    @objc private func applyAppearanceSettingIfNeeded() {
        // Automatyczne dostosowanie do ustawień systemowych
        if let window = mainWindow {
            window.appearance = NSApp.effectiveAppearance
        }
    }
    
    // MARK: - Menu Actions
    
    @IBAction func openPreferences(_ sender: Any) {
        // Kod do otwarcia okna preferencji
    }
    
    @IBAction func reloadPage(_ sender: Any) {
        webViewController?.reload()
    }
    
    @IBAction func toggleDeveloperTools(_ sender: Any) {
        webViewController?.toggleDevTools()
    }
}
