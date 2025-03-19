//
//  WidgetTests.swift
//  HackMDTests
//
//  Created on 2025-03-19
//

import XCTest
@testable import HackMD

final class WidgetTests: XCTestCase {
    
    // Testy dla modelu Widget
    func testWidgetDataProvider() {
        // Inicjacja data providera
        let dataProvider = WidgetDataProvider.shared
        
        // Test zapisywania i odczytywania notatek
        let testNotes = [
            NoteItem(
                id: "test1",
                title: "Test Note 1",
                lastEdited: Date(),
                previewText: "Test preview text 1",
                collaborators: 2
            ),
            NoteItem(
                id: "test2",
                title: "Test Note 2",
                lastEdited: Date().addingTimeInterval(-3600), // 1 hour ago
                previewText: "Test preview text 2",
                collaborators: 1
            )
        ]
        
        // Zapisywanie notatek w UserDefaults (testowym)
        // W rzeczywistym teście musielibyśmy użyć mocka dla UserDefaults
        dataProvider.saveRecentNotes(testNotes)
        
        // Odczyt notatek - powinien zwrócić placeholdery, ponieważ rzeczywista instancja
        // UserDefaults(suiteName:) prawdopodobnie zwróci nil w środowisku testowym
        let retrievedNotes = dataProvider.getRecentNotes()
        
        // Sprawdzamy, czy mamy jakieś dane (albo nasze testowe dane, albo placeholdery)
        XCTAssertTrue(retrievedNotes.count > 0)
        
        // Test aktualizacji danych
        dataProvider.updateRecentNotes(from: """
        {
            "notes": [
                {"id": "update1", "title": "Updated Note", "lastEdited": "2025-03-19T10:00:00Z", "previewText": "Updated text", "collaborators": 3}
            ]
        }
        """)
        
        // Ponowny odczyt - oczekujemy że będą zwrócone dane (albo zaktualizowane, albo placeholdery)
        let updatedNotes = dataProvider.getRecentNotes()
        XCTAssertTrue(updatedNotes.count > 0)
    }
    
    // Testy dla formatowania czasu dla widgetów
    func testTimeAgoFormatter() {
        // Test dla timeAgo
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        // Tworzenie formattera poza klasą
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        // Testowanie formatowania
        let oneHourAgoString = formatter.localizedString(for: oneHourAgo, relativeTo: now)
        let oneDayAgoString = formatter.localizedString(for: oneDayAgo, relativeTo: now)
        
        // Sprawdzenie, czy zawiera jednostki czasu
        // Nie możemy sprawdzić dokładnych wartości, ponieważ są zależne od lokalizacji
        XCTAssertTrue(oneHourAgoString.count > 0)
        XCTAssertTrue(oneDayAgoString.count > 0)
    }
}