//
//  TabManager.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa
import WebKit

class TabManager {
    // Singleton instance
    static let shared = TabManager()
    
    // Properties
    private var tabs: [TabItem] = []
    private var activeTabIndex: Int = 0
    
    // Notification name for tab changes
    static let tabsDidChangeNotification = Notification.Name("HackMDTabsDidChange")
    static let activeTabDidChangeNotification = Notification.Name("HackMDActiveTabDidChange")
    
    // Private initializer for singleton
    private init() {
        // Initialize with a default tab
        createNewTab(url: URL(string: "https://hackmd.io")!, title: "HackMD")
    }
    
    // MARK: - Public Methods
    
    // Get all tabs
    func getAllTabs() -> [TabItem] {
        return tabs
    }
    
    // Get active tab
    func getActiveTab() -> TabItem? {
        guard activeTabIndex >= 0 && activeTabIndex < tabs.count else {
            return nil
        }
        return tabs[activeTabIndex]
    }
    
    // Create a new tab
    func createNewTab(url: URL, title: String) -> TabItem {
        let tabItem = TabItem(id: UUID().uuidString, url: url, title: title)
        tabs.append(tabItem)
        
        // Set as active if it's the first tab
        if tabs.count == 1 {
            activeTabIndex = 0
        }
        
        notifyTabsChanged()
        return tabItem
    }
    
    // Close a tab
    func closeTab(id: String) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        tabs.remove(at: index)
        
        // Adjust active tab index if needed
        if activeTabIndex >= tabs.count {
            activeTabIndex = max(tabs.count - 1, 0)
        }
        
        notifyTabsChanged()
        notifyActiveTabChanged()
    }
    
    // Set active tab
    func setActiveTab(id: String) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        activeTabIndex = index
        notifyActiveTabChanged()
    }
    
    // Update tab title
    func updateTabTitle(id: String, title: String) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let tab = tabs[index]
        let updatedTab = TabItem(id: tab.id, url: tab.url, title: title)
        tabs[index] = updatedTab
        
        notifyTabsChanged()
    }
    
    // Update tab URL
    func updateTabURL(id: String, url: URL) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let tab = tabs[index]
        let updatedTab = TabItem(id: tab.id, url: url, title: tab.title)
        tabs[index] = updatedTab
        
        notifyTabsChanged()
    }
    
    // Get next tab (for cycling through tabs)
    func getNextTab() -> TabItem? {
        guard !tabs.isEmpty else {
            return nil
        }
        
        let nextIndex = (activeTabIndex + 1) % tabs.count
        activeTabIndex = nextIndex
        notifyActiveTabChanged()
        
        return tabs[nextIndex]
    }
    
    // Get previous tab (for cycling through tabs)
    func getPreviousTab() -> TabItem? {
        guard !tabs.isEmpty else {
            return nil
        }
        
        let prevIndex = (activeTabIndex - 1 + tabs.count) % tabs.count
        activeTabIndex = prevIndex
        notifyActiveTabChanged()
        
        return tabs[prevIndex]
    }
    
    // MARK: - Private Methods
    
    // Notify observers that tabs changed
    private func notifyTabsChanged() {
        NotificationCenter.default.post(name: TabManager.tabsDidChangeNotification, object: self)
    }
    
    // Notify observers that active tab changed
    private func notifyActiveTabChanged() {
        NotificationCenter.default.post(name: TabManager.activeTabDidChangeNotification, object: self)
    }
}

// Tab item model
struct TabItem {
    let id: String
    let url: URL
    let title: String
}