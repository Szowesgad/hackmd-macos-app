//
//  HistoryManager.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Foundation

class HistoryManager {
    // Singleton instance
    static let shared = HistoryManager()
    
    // Constants
    private let maxHistoryItems = 100
    private let historyKey = "noteHistory"
    
    // Properties
    private var history: [HistoryItem] = []
    private let userDefaults = UserDefaults.standard
    
    // Private initializer for singleton
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Adds a note to the history
    func addToHistory(noteId: String, title: String, url: URL) {
        // Check if the item already exists in history
        if let index = history.firstIndex(where: { $0.noteId == noteId }) {
            // Update existing item and move to front
            let item = history[index]
            history.remove(at: index)
            
            let updatedItem = HistoryItem(
                noteId: item.noteId,
                title: title,
                url: url,
                lastVisited: Date(),
                visitCount: item.visitCount + 1
            )
            
            history.insert(updatedItem, at: 0)
        } else {
            // Add new item
            let newItem = HistoryItem(
                noteId: noteId,
                title: title,
                url: url,
                lastVisited: Date(),
                visitCount: 1
            )
            
            history.insert(newItem, at: 0)
            
            // Trim history if needed
            if history.count > maxHistoryItems {
                history = Array(history.prefix(maxHistoryItems))
            }
        }
        
        // Save history
        saveHistory()
        
        // Notify listeners (widget)
        updateWidgetData()
    }
    
    /// Returns the history items
    func getHistory() -> [HistoryItem] {
        return history
    }
    
    /// Returns recently visited notes
    func getRecentNotes(limit: Int = 10) -> [HistoryItem] {
        return Array(history.prefix(limit))
    }
    
    /// Returns frequently visited notes
    func getFrequentNotes(limit: Int = 10) -> [HistoryItem] {
        let sorted = history.sorted { $0.visitCount > $1.visitCount }
        return Array(sorted.prefix(limit))
    }
    
    /// Removes an item from history
    func removeFromHistory(noteId: String) {
        history.removeAll { $0.noteId == noteId }
        saveHistory()
        updateWidgetData()
    }
    
    /// Clears the entire history
    func clearHistory() {
        history.removeAll()
        saveHistory()
        updateWidgetData()
    }
    
    // MARK: - Private Methods
    
    /// Loads history from UserDefaults
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let loadedHistory = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = loadedHistory
        }
    }
    
    /// Saves history to UserDefaults
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    /// Updates widget data with recent notes
    private func updateWidgetData() {
        // Create shared UserDefaults for widget
        let sharedDefaults = UserDefaults(suiteName: "group.com.szowesgad.hackmd")
        
        // Convert history items to widget-compatible format
        let recentNotes = history.prefix(5).map { item -> [String: Any] in
            return [
                "id": item.noteId,
                "title": item.title,
                "lastEdited": item.lastVisited,
                "previewText": "Notatka HackMD",
                "collaborators": 0
            ]
        }
        
        // Save to shared UserDefaults
        if let data = try? JSONSerialization.data(withJSONObject: recentNotes) {
            sharedDefaults?.set(data, forKey: "recentNotes")
        }
    }
}

// Model for history items
struct HistoryItem: Codable {
    let noteId: String
    let title: String
    let url: URL
    let lastVisited: Date
    let visitCount: Int
}