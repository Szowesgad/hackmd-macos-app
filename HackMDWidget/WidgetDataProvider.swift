//
//  WidgetDataProvider.swift
//  HackMDWidget
//
//  Created on 2025-03-19.
//

import Foundation

class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.szowesgad.hackmd")
    private let recentNotesKey = "recentNotes"
    
    // Singleton
    private init() {}
    
    func saveRecentNotes(_ notes: [NoteItem]) {
        let encodedData = try? JSONEncoder().encode(notes)
        userDefaults?.set(encodedData, forKey: recentNotesKey)
    }
    
    func getRecentNotes() -> [NoteItem] {
        guard let data = userDefaults?.data(forKey: recentNotesKey),
              let notes = try? JSONDecoder().decode([NoteItem].self, from: data) else {
            return NoteItem.placeholders
        }
        return notes
    }
    
    func updateRecentNotes(from webData: String) {
        // W rzeczywistej aplikacji tutaj byłoby parsowanie danych z HackMD.io
        // Dla celów demonstracyjnych używamy danych placeholderowych
        let notes = NoteItem.placeholders
        saveRecentNotes(notes)
    }
}

// Rozszerzenie struktury NoteItem o obsługę Codable
extension NoteItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case lastEdited
        case previewText
        case collaborators
    }
}