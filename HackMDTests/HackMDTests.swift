//
//  HackMDTests.swift
//  HackMDTests
//
//  Created on 2025-03-19
//

import XCTest
@testable import HackMD

final class HackMDTests: XCTestCase {
    
    // MARK: - TabManager Tests
    
    func testTabManager() {
        // Inicjalizacja
        let tabManager = TabManager.shared
        
        // Test tworzenia nowego tabu
        let url = URL(string: "https://hackmd.io/test")!
        let tab = tabManager.createNewTab(url: url, title: "Test Tab")
        
        // Sprawdzenie czy tab został utworzony
        XCTAssertEqual(tab.url, url)
        XCTAssertEqual(tab.title, "Test Tab")
        
        // Sprawdzenie czy tab jest na liście
        let tabs = tabManager.getAllTabs()
        XCTAssertTrue(tabs.contains { $0.id == tab.id })
        
        // Test aktywnego tabu
        tabManager.setActiveTab(id: tab.id)
        let activeTab = tabManager.getActiveTab()
        XCTAssertEqual(activeTab?.id, tab.id)
        
        // Test aktualizacji tytułu
        tabManager.updateTabTitle(id: tab.id, title: "Updated Title")
        let updatedTabs = tabManager.getAllTabs()
        let updatedTab = updatedTabs.first { $0.id == tab.id }
        XCTAssertEqual(updatedTab?.title, "Updated Title")
        
        // Test aktualizacji URL
        let newURL = URL(string: "https://hackmd.io/updated")!
        tabManager.updateTabURL(id: tab.id, url: newURL)
        let tabs2 = tabManager.getAllTabs()
        let updatedTab2 = tabs2.first { $0.id == tab.id }
        XCTAssertEqual(updatedTab2?.url, newURL)
        
        // Test nawigacji po tabach
        let tab2 = tabManager.createNewTab(url: URL(string: "https://hackmd.io/test2")!, title: "Test Tab 2")
        tabManager.setActiveTab(id: tab.id)
        
        let nextTab = tabManager.getNextTab()
        XCTAssertEqual(nextTab?.id, tab2.id)
        
        let prevTab = tabManager.getPreviousTab()
        XCTAssertEqual(prevTab?.id, tab.id)
    }
    
    // MARK: - HistoryManager Tests
    
    func testHistoryManager() {
        // Inicjalizacja
        let historyManager = HistoryManager.shared
        
        // Najpierw czyścimy historię do testów
        historyManager.clearHistory()
        
        // Sprawdzenie czy historia jest pusta
        let emptyHistory = historyManager.getHistory()
        XCTAssertTrue(emptyHistory.isEmpty)
        
        // Dodanie elementu do historii
        let url = URL(string: "https://hackmd.io/test")!
        historyManager.addToHistory(noteId: "test123", title: "Test Note", url: url)
        
        // Sprawdzenie czy element został dodany
        let history = historyManager.getHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.noteId, "test123")
        XCTAssertEqual(history.first?.title, "Test Note")
        XCTAssertEqual(history.first?.url, url)
        
        // Test aktualizacji istniejącego elementu
        historyManager.addToHistory(noteId: "test123", title: "Updated Note", url: url)
        let updatedHistory = historyManager.getHistory()
        XCTAssertEqual(updatedHistory.count, 1) // nadal tylko jeden element
        XCTAssertEqual(updatedHistory.first?.title, "Updated Note")
        XCTAssertEqual(updatedHistory.first?.visitCount, 2) // zwiększony licznik odwiedzin
        
        // Dodanie drugiego elementu
        let url2 = URL(string: "https://hackmd.io/test2")!
        historyManager.addToHistory(noteId: "test456", title: "Test Note 2", url: url2)
        
        // Test pobrania ostatnich notatek
        let recentNotes = historyManager.getRecentNotes(limit: 2)
        XCTAssertEqual(recentNotes.count, 2)
        XCTAssertEqual(recentNotes.first?.noteId, "test456") // najnowszy element powinien być pierwszy
        
        // Test usunięcia elementu
        historyManager.removeFromHistory(noteId: "test123")
        let historyAfterRemoval = historyManager.getHistory()
        XCTAssertEqual(historyAfterRemoval.count, 1)
        XCTAssertEqual(historyAfterRemoval.first?.noteId, "test456")
        
        // Test czyszczenia historii
        historyManager.clearHistory()
        let clearedHistory = historyManager.getHistory()
        XCTAssertTrue(clearedHistory.isEmpty)
    }
    
    // MARK: - NotificationManager Tests
    
    func testNotificationManager() {
        // Inicjalizacja
        let notificationManager = NotificationManager.shared
        
        // Sprawdzenie typów powiadomień i kategorii
        XCTAssertEqual(NotificationManager.NotificationType.noteUpdate.category, NotificationManager.Category.noteUpdate)
        XCTAssertEqual(NotificationManager.NotificationType.collaboration.category, NotificationManager.Category.collaboration)
        XCTAssertEqual(NotificationManager.NotificationType.comment.category, NotificationManager.Category.comment)
        XCTAssertEqual(NotificationManager.NotificationType.mention.category, NotificationManager.Category.mention)
        XCTAssertEqual(NotificationManager.NotificationType.reminder.category, NotificationManager.Category.reminder)
        
        // Test ustawień powiadomień
        let reminderType = NotificationManager.NotificationType.reminder
        let originalValue = reminderType.isEnabled
        
        // Zmiana wartości
        reminderType.isEnabled = !originalValue
        XCTAssertEqual(reminderType.isEnabled, !originalValue)
        
        // Przywrócenie oryginalnej wartości
        reminderType.isEnabled = originalValue
    }
}