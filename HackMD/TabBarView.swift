//
//  TabBarView.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa

protocol TabBarViewDelegate: AnyObject {
    func tabSelected(_ tabBarView: TabBarView, tabId: String)
    func tabClosed(_ tabBarView: TabBarView, tabId: String)
    func newTabRequested(_ tabBarView: TabBarView)
}

class TabBarView: NSView {
    // Properties
    private var tabs: [TabItem] = []
    private var tabButtons: [NSButton] = []
    private var activeTabId: String?
    private var tabButtonHeight: CGFloat = 30
    
    // Add button for new tab
    private lazy var addButton: NSButton = {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 30, height: tabButtonHeight))
        button.bezelStyle = .smallSquare
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add tab")
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.toolTip = "New Tab"
        button.target = self
        button.action = #selector(addTabClicked)
        return button
    }()
    
    // Scroll view for tabs
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView(frame: bounds)
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = tabsClipView
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        return scrollView
    }()
    
    // Content view for tabs
    private lazy var tabsClipView: NSView = {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: tabButtonHeight))
        return view
    }()
    
    // Delegate
    weak var delegate: TabBarViewDelegate?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Add scroll view
        addSubview(scrollView)
        
        // Add the add button
        addSubview(addButton)
        
        // Set up constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            addButton.leadingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addButton.topAnchor.constraint(equalTo: topAnchor),
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        // Register for TabManager notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tabsDidChange),
            name: TabManager.tabsDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeTabDidChange),
            name: TabManager.activeTabDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    func updateTabs(_ tabs: [TabItem], activeTabId: String?) {
        self.tabs = tabs
        self.activeTabId = activeTabId
        layoutTabs()
    }
    
    // MARK: - Private Methods
    
    private func layoutTabs() {
        // Remove all existing tab buttons
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        
        // Create tab buttons
        var xOffset: CGFloat = 0
        
        for tab in tabs {
            let tabWidth: CGFloat = min(max(measureTabWidth(title: tab.title), 100), 200)
            let tabButton = createTabButton(tab: tab, frame: NSRect(x: xOffset, y: 0, width: tabWidth, height: tabButtonHeight))
            
            tabsClipView.addSubview(tabButton)
            tabButtons.append(tabButton)
            
            // Update xOffset for next tab
            xOffset += tabWidth
        }
        
        // Update tabsClipView width
        tabsClipView.frame.size.width = xOffset
        
        // Highlight active tab
        updateActiveTab()
    }
    
    private func createTabButton(tab: TabItem, frame: NSRect) -> NSButton {
        let button = NSButton(frame: frame)
        button.bezelStyle = .smallSquare
        button.title = tab.title
        button.isBordered = false
        button.identifier = NSUserInterfaceItemIdentifier(tab.id)
        button.target = self
        button.action = #selector(tabClicked(_:))
        
        // Add close button
        let closeButton = NSButton(frame: NSRect(x: frame.width - 25, y: (frame.height - 20) / 2, width: 20, height: 20))
        closeButton.bezelStyle = .smallSquare
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close tab")
        closeButton.imagePosition = .imageOnly
        closeButton.isBordered = false
        closeButton.identifier = NSUserInterfaceItemIdentifier("close-\(tab.id)")
        closeButton.target = self
        closeButton.action = #selector(closeTabClicked(_:))
        
        button.addSubview(closeButton)
        
        return button
    }
    
    private func updateActiveTab() {
        for button in tabButtons {
            if let id = button.identifier?.rawValue, id == activeTabId {
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor.selectedControlColor.cgColor
            } else {
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
    }
    
    private func measureTabWidth(title: String) -> CGFloat {
        let attributedString = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ])
        
        let size = attributedString.size()
        return size.width + 60 // Add padding for close button and margins
    }
    
    // MARK: - Actions
    
    @objc private func tabClicked(_ sender: NSButton) {
        if let id = sender.identifier?.rawValue {
            activeTabId = id
            delegate?.tabSelected(self, tabId: id)
        }
    }
    
    @objc private func closeTabClicked(_ sender: NSButton) {
        if let id = sender.identifier?.rawValue, id.hasPrefix("close-") {
            let tabId = id.replacingOccurrences(of: "close-", with: "")
            delegate?.tabClosed(self, tabId: tabId)
        }
    }
    
    @objc private func addTabClicked() {
        delegate?.newTabRequested(self)
    }
    
    @objc private func tabsDidChange() {
        updateTabs(TabManager.shared.getAllTabs(), activeTabId: TabManager.shared.getActiveTab()?.id)
    }
    
    @objc private func activeTabDidChange() {
        activeTabId = TabManager.shared.getActiveTab()?.id
        updateActiveTab()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}