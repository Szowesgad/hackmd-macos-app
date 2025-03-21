import Cocoa
import WebKit
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var mainWindow: NSWindow!
    var webView: WKWebView!
    
    // HackMD.io URL
    let hackMDURL = URL(string: "https://hackmd.io")!
    
    // Developer settings
    let isDeveloperModeEnabled = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup the menu
        setupApplicationMenu()
        
        // Request notification permissions
        setupNotifications()
        
        // Register URL scheme handler
        registerURLSchemeHandler()
        
        // Check for updates in background (will be silent unless an update is available)
        checkForUpdates(inBackground: true)
        
        // Configure WKWebView
        let webConfiguration = WKWebViewConfiguration()
        
        // Enable developer features if developer mode is active
        if isDeveloperModeEnabled {
            webConfiguration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        }
        
        // Add user agent for better handling
        let userAgent = "HackMD-macOS/1.0 Mozilla/5.0 (Macintosh; Intel Mac OS X \(ProcessInfo().operatingSystemVersionString)) AppleWebKit/605.1.15 Version/16.4 Safari/605.1.15"
        webConfiguration.applicationNameForUserAgent = userAgent
        
        // Create WKWebView object
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set navigation delegate
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Create window
        let windowRect = NSRect(x: 0, y: 0, width: 1200, height: 800)
        mainWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Configure window
        mainWindow.title = "HackMD"
        mainWindow.center()
        mainWindow.contentView = NSView(frame: windowRect)
        mainWindow.contentView?.addSubview(webView)
        
        // AutoLayout constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: mainWindow.contentView!.topAnchor),
            webView.leadingAnchor.constraint(equalTo: mainWindow.contentView!.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: mainWindow.contentView!.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: mainWindow.contentView!.bottomAnchor)
        ])
        
        // Show window
        mainWindow.makeKeyAndOrderFront(nil)
        
        // Load HackMD content
        loadHackMD()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Method to load HackMD
    func loadHackMD() {
        let request = URLRequest(url: hackMDURL)
        webView.load(request)
    }
    
    // MARK: - Menu Setup
    
    /**
     * Sets up the application menu bar
     */
    private func setupApplicationMenu() {
        // Get the main menu
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        // Application menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "HackMD", action: nil, keyEquivalent: "")
        appMenuItem.submenu = appMenu
        
        // About item
        let aboutItem = NSMenuItem(title: "About HackMD", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        
        // Check for updates item
        let checkForUpdatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u")
        checkForUpdatesItem.target = self
        appMenu.addItem(checkForUpdatesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Preferences item
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(preferencesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Services menu
        let servicesMenu = NSMenu()
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Hide, hide others, show all
        let hideItem = NSMenuItem(title: "Hide HackMD", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hideItem.target = NSApp
        appMenu.addItem(hideItem)
        
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        hideOthersItem.target = NSApp
        appMenu.addItem(hideOthersItem)
        
        let showAllItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        showAllItem.target = NSApp
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit HackMD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)
        
        mainMenu.addItem(appMenuItem)
        
        // File menu
        let fileMenu = NSMenu(title: "File")
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileMenuItem.submenu = fileMenu
        
        let newNoteItem = NSMenuItem(title: "New Note", action: #selector(newNote), keyEquivalent: "n")
        newNoteItem.target = self
        fileMenu.addItem(newNoteItem)
        
        fileMenu.addItem(NSMenuItem.separator())
        
        // Export submenu
        let exportMenu = NSMenu(title: "Export")
        let exportMenuItem = NSMenuItem(title: "Export", action: nil, keyEquivalent: "")
        exportMenuItem.submenu = exportMenu
        
        let exportPDFItem = NSMenuItem(title: "Export as PDF", action: #selector(exportAsPDF), keyEquivalent: "p")
        exportPDFItem.keyEquivalentModifierMask = [.command, .option]
        exportPDFItem.target = self
        exportMenu.addItem(exportPDFItem)
        
        let exportMarkdownItem = NSMenuItem(title: "Export as Markdown", action: #selector(exportAsMarkdown), keyEquivalent: "m")
        exportMarkdownItem.keyEquivalentModifierMask = [.command, .option]
        exportMarkdownItem.target = self
        exportMenu.addItem(exportMarkdownItem)
        
        fileMenu.addItem(exportMenuItem)
        
        mainMenu.addItem(fileMenuItem)
        
        // Edit menu
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        
        // Standard edit menu items
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector("undo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector("redo:"), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: Selector("cut:"), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: Selector("copy:"), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: Selector("paste:"), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: Selector("selectAll:"), keyEquivalent: "a"))
        
        mainMenu.addItem(editMenuItem)
        
        // View menu
        let viewMenu = NSMenu(title: "View")
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        
        // Toggle Developer Tools
        let toggleDevToolsItem = NSMenuItem(title: "Toggle Developer Tools", action: #selector(toggleDeveloperTools), keyEquivalent: "i")
        toggleDevToolsItem.keyEquivalentModifierMask = [.command, .option]
        toggleDevToolsItem.target = self
        viewMenu.addItem(toggleDevToolsItem)
        
        // Reload Page
        let reloadItem = NSMenuItem(title: "Reload Page", action: #selector(reloadPage), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)
        
        mainMenu.addItem(viewMenuItem)
        
        // Window menu
        let windowMenu = NSMenu(title: "Window")
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        
        NSApp.windowsMenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        // Help menu
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        
        let helpItem = NSMenuItem(title: "HackMD Help", action: #selector(showHelp), keyEquivalent: "?")
        helpItem.target = self
        helpMenu.addItem(helpItem)
        
        NSApp.helpMenu = helpMenu
        mainMenu.addItem(helpMenuItem)
    }
    
    // MARK: - Notification Setup
    
    /**
     * Sets up the notification system
     */
    private func setupNotifications() {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        NotificationManager.shared.requestPermissionsIfNeeded { granted in
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Always show banner and play sound when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification response when user clicks on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract information from the notification
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification categories
        switch response.notification.request.content.categoryIdentifier {
        case NotificationManager.Category.noteUpdate.rawValue:
            if let noteId = userInfo["noteId"] as? String {
                // Open specific note
                openNote(noteId: noteId)
            }
            
        case NotificationManager.Category.collaboration.rawValue:
            if let noteId = userInfo["noteId"] as? String {
                // Open specific note
                openNote(noteId: noteId)
            }
            
        case NotificationManager.Category.reminder.rawValue:
            if let noteId = userInfo["noteId"] as? String {
                // Open specific note
                openNote(noteId: noteId)
            }
            
        case NotificationManager.Category.mention.rawValue:
            if let noteId = userInfo["noteId"] as? String {
                // Open specific note
                if response.actionIdentifier == "REPLY_MENTION" {
                    // Open note and focus on reply box
                    openNoteAndReply(noteId: noteId)
                } else {
                    openNote(noteId: noteId)
                }
            }
            
        case NotificationManager.Category.comment.rawValue:
            if let noteId = userInfo["noteId"] as? String, 
               let commentId = userInfo["commentId"] as? String {
                if response.actionIdentifier == "REPLY_COMMENT" {
                    // Open note and focus on reply box
                    openNoteAndReplyToComment(noteId: noteId, commentId: commentId)
                } else {
                    // Simply open the note at the comment location
                    openNoteAtComment(noteId: noteId, commentId: commentId)
                }
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    // Open a note and scroll to the comment location
    private func openNoteAtComment(noteId: String, commentId: String) {
        if let noteURL = URL(string: "https://hackmd.io/\(noteId)#comment-\(commentId)") {
            webView.load(URLRequest(url: noteURL))
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // Open a note and focus on the reply interface
    private func openNoteAndReply(noteId: String) {
        openNote(noteId: noteId)
        
        // Wait for page to load then focus on reply box
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.webView.evaluateJavaScript("""
                if (document.querySelector('.reply-box')) {
                    document.querySelector('.reply-box').focus();
                }
            """, completionHandler: nil)
        }
    }
    
    // Open a note and focus on the reply interface for a specific comment
    private func openNoteAndReplyToComment(noteId: String, commentId: String) {
        openNoteAtComment(noteId: noteId, commentId: commentId)
        
        // Wait for page to load then focus on reply box
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.webView.evaluateJavaScript("""
                if (document.querySelector('#comment-\(commentId) .reply-button')) {
                    document.querySelector('#comment-\(commentId) .reply-button').click();
                }
            """, completionHandler: nil)
        }
    }
    
    // MARK: - Menu Actions
    
    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    @objc func showPreferences() {
        PreferencesWindowController.shared.showPreferences()
    }
    
    @objc func newNote() {
        // Navigate to new note URL
        if let newNoteURL = URL(string: "https://hackmd.io/new") {
            webView.load(URLRequest(url: newNoteURL))
        }
    }
    
    @objc func toggleDeveloperTools() {
        // Toggle developer tools if enabled
        if isDeveloperModeEnabled {
            webView.evaluateJavaScript("__toggleDevTools()", completionHandler: nil)
        }
    }
    
    @objc func reloadPage() {
        webView.reload()
    }
    
    @objc func showHelp() {
        // Open HackMD help page
        if let helpURL = URL(string: "https://hackmd.io/c/tutorials") {
            NSWorkspace.shared.open(helpURL)
        }
    }
    
    @objc func exportAsPDF() {
        // Get the current WebViewController
        if let mainWindowController = NSApp.windows.first?.windowController as? MainWindowController,
           let webViewController = mainWindowController.contentViewController as? WebViewController {
            webViewController.exportAsPDF(nil)
        }
    }
    
    @objc func exportAsMarkdown() {
        // Get the current WebViewController
        if let mainWindowController = NSApp.windows.first?.windowController as? MainWindowController,
           let webViewController = mainWindowController.contentViewController as? WebViewController {
            webViewController.exportAsMarkdown(nil)
        }
    }
    
    @objc func checkForUpdates(_ sender: Any? = nil) {
        SparkleManager.shared.checkForUpdates()
    }
    
    func checkForUpdates(inBackground: Bool = false) {
        if inBackground {
            SparkleManager.shared.checkForUpdatesInBackground()
        } else {
            SparkleManager.shared.checkForUpdates()
        }
    }
    
    // MARK: - URL Scheme Handling
    
    private func registerURLSchemeHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        
        handleURL(url)
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "hackmd" else { return }
        
        // Bring the app to the foreground
        NSApp.activate(ignoringOtherApps: true)
        
        if url.host == "note", let noteId = url.path.replacingOccurrences(of: "/", with: "").isEmpty ? nil : url.path.replacingOccurrences(of: "/", with: "") {
            // Handle note/[id] URLs
            openNote(noteId: noteId)
        } else if url.host == "widget" {
            // Handle widget/open URLs
            if url.path.contains("open") {
                // Show main window
                mainWindow.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Opens a specific note by ID
     */
    private func openNote(noteId: String) {
        if let noteURL = URL(string: "https://hackmd.io/\(noteId)") {
            if webView.url?.absoluteString.contains(noteId) == true {
                // Note is already open, just focus the window
                mainWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                // Load the note
                webView.load(URLRequest(url: noteURL))
                mainWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

// Extension for WebView navigation handling
extension AppDelegate: WKNavigationDelegate, WKUIDelegate {
    // Handle page loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        mainWindow.title = webView.title ?? "HackMD"
    }
    
    // Handle loading errors
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error Loading HackMD"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Handle new windows
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // If HackMD tries to open a new window, redirect to main view
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // Handle JavaScript alerts
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
