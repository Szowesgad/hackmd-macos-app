//
//  PreferencesWindowController.swift
//  HackMD
//
//  Created on March 19, 2025
//

import Cocoa

/**
 * PreferencesWindowController manages the application preferences window
 * allowing users to customize their HackMD experience.
 */
class PreferencesWindowController: NSWindowController {
    
    // MARK: - Properties
    
    static let shared = PreferencesWindowController()
    
    // MARK: - Initialization
    
    private override init(window: NSWindow?) {
        // Create the preferences window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        
        // Configure the window content
        window.contentViewController = PreferencesViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    /**
     * Shows the preferences window and brings it to front
     */
    func showPreferences() {
        if window?.isVisible == false {
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/**
 * PreferencesViewController manages the content of the preferences window
 * with multiple tabs for different settings categories.
 */
class PreferencesViewController: NSViewController {
    
    // MARK: - Properties
    
    private let tabView = NSTabView()
    private let generalTab = NSTabViewItem(identifier: "general")
    private let appearanceTab = NSTabViewItem(identifier: "appearance")
    private let advancedTab = NSTabViewItem(identifier: "advanced")
    
    // MARK: - Lifecycle
    
    override func loadView() {
        // Create the main view
        let view = NSView()
        self.view = view
        
        // Configure tabs
        generalTab.label = "General"
        generalTab.view = createGeneralTabView()
        
        appearanceTab.label = "Appearance"
        appearanceTab.view = createAppearanceTabView()
        
        advancedTab.label = "Advanced"
        advancedTab.view = createAdvancedTabView()
        
        // Add tabs to tab view
        tabView.addTabViewItem(generalTab)
        tabView.addTabViewItem(appearanceTab)
        tabView.addTabViewItem(advancedTab)
        
        // Configure tab view
        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Tab View Creation Methods
    
    /**
     * Creates the content view for the General tab
     */
    private func createGeneralTabView() -> NSView {
        let container = NSView()
        
        // 1. Start with HackMD option
        let startupLabel = createLabel("Start with HackMD:")
        startupLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(startupLabel)
        
        let startupPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        startupPopup.translatesAutoresizingMaskIntoConstraints = false
        startupPopup.addItems(withTitles: ["Home Page", "Last Opened Note", "New Note"])
        container.addSubview(startupPopup)
        
        // 2. Default editor mode
        let editorModeLabel = createLabel("Default editor mode:")
        editorModeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(editorModeLabel)
        
        let editorModePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        editorModePopup.translatesAutoresizingMaskIntoConstraints = false
        editorModePopup.addItems(withTitles: ["Edit", "Both", "View"])
        container.addSubview(editorModePopup)
        
        // 3. Auto save option
        let autoSaveCheckbox = NSButton(checkboxWithTitle: "Enable auto-save", target: nil, action: nil)
        autoSaveCheckbox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(autoSaveCheckbox)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            startupLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            startupLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            startupPopup.topAnchor.constraint(equalTo: startupLabel.topAnchor),
            startupPopup.leadingAnchor.constraint(equalTo: startupLabel.trailingAnchor, constant: 10),
            startupPopup.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            
            editorModeLabel.topAnchor.constraint(equalTo: startupLabel.bottomAnchor, constant: 20),
            editorModeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            editorModePopup.topAnchor.constraint(equalTo: editorModeLabel.topAnchor),
            editorModePopup.leadingAnchor.constraint(equalTo: editorModeLabel.trailingAnchor, constant: 10),
            editorModePopup.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            
            autoSaveCheckbox.topAnchor.constraint(equalTo: editorModeLabel.bottomAnchor, constant: 20),
            autoSaveCheckbox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
        ])
        
        return container
    }
    
    /**
     * Creates the content view for the Appearance tab
     */
    private func createAppearanceTabView() -> NSView {
        let container = NSView()
        
        // 1. Theme selection
        let themeLabel = createLabel("Theme:")
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(themeLabel)
        
        let themePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        themePopup.translatesAutoresizingMaskIntoConstraints = false
        themePopup.addItems(withTitles: ["System Default", "Light", "Dark"])
        container.addSubview(themePopup)
        
        // 2. Font size
        let fontSizeLabel = createLabel("Font size:")
        fontSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(fontSizeLabel)
        
        let fontSizeStepper = NSStepper()
        fontSizeStepper.translatesAutoresizingMaskIntoConstraints = false
        fontSizeStepper.minValue = 9
        fontSizeStepper.maxValue = 24
        fontSizeStepper.increment = 1
        fontSizeStepper.valueWraps = false
        fontSizeStepper.intValue = 14
        container.addSubview(fontSizeStepper)
        
        let fontSizeTextField = NSTextField()
        fontSizeTextField.translatesAutoresizingMaskIntoConstraints = false
        fontSizeTextField.stringValue = "14"
        fontSizeTextField.isEditable = true
        fontSizeTextField.isBordered = true
        fontSizeTextField.alignment = .right
        container.addSubview(fontSizeTextField)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            themeLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            themeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            themePopup.topAnchor.constraint(equalTo: themeLabel.topAnchor),
            themePopup.leadingAnchor.constraint(equalTo: themeLabel.trailingAnchor, constant: 10),
            themePopup.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            
            fontSizeLabel.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 20),
            fontSizeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            fontSizeTextField.topAnchor.constraint(equalTo: fontSizeLabel.topAnchor),
            fontSizeTextField.leadingAnchor.constraint(equalTo: fontSizeLabel.trailingAnchor, constant: 10),
            fontSizeTextField.widthAnchor.constraint(equalToConstant: 40),
            
            fontSizeStepper.topAnchor.constraint(equalTo: fontSizeLabel.topAnchor),
            fontSizeStepper.leadingAnchor.constraint(equalTo: fontSizeTextField.trailingAnchor, constant: 5),
        ])
        
        return container
    }
    
    /**
     * Creates the content view for the Advanced tab
     */
    private func createAdvancedTabView() -> NSView {
        let container = NSView()
        
        // 1. Developer options
        let developerOptionsLabel = createLabel("Developer Options")
        developerOptionsLabel.font = NSFont.boldSystemFont(ofSize: 14)
        developerOptionsLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(developerOptionsLabel)
        
        let enableDevToolsCheckbox = NSButton(checkboxWithTitle: "Enable Developer Tools", target: nil, action: nil)
        enableDevToolsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(enableDevToolsCheckbox)
        
        let enableLoggingCheckbox = NSButton(checkboxWithTitle: "Enable Debug Logging", target: nil, action: nil)
        enableLoggingCheckbox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(enableLoggingCheckbox)
        
        // 2. Export settings
        let exportButton = NSButton(title: "Export Settings", target: nil, action: nil)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.bezelStyle = .rounded
        container.addSubview(exportButton)
        
        let importButton = NSButton(title: "Import Settings", target: nil, action: nil)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        importButton.bezelStyle = .rounded
        container.addSubview(importButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            developerOptionsLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            developerOptionsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            enableDevToolsCheckbox.topAnchor.constraint(equalTo: developerOptionsLabel.bottomAnchor, constant: 10),
            enableDevToolsCheckbox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            enableLoggingCheckbox.topAnchor.constraint(equalTo: enableDevToolsCheckbox.bottomAnchor, constant: 10),
            enableLoggingCheckbox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            exportButton.topAnchor.constraint(equalTo: enableLoggingCheckbox.bottomAnchor, constant: 30),
            exportButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            
            importButton.topAnchor.constraint(equalTo: exportButton.topAnchor),
            importButton.leadingAnchor.constraint(equalTo: exportButton.trailingAnchor, constant: 10),
        ])
        
        return container
    }
    
    // MARK: - Helper Methods
    
    /**
     * Creates a standard label with the given text
     */
    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .right
        return label
    }
}
