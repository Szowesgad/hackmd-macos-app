//
//  ExportManagerTests.swift
//  HackMDTests
//
//  Created on 2025-03-19
//

import XCTest
@testable import HackMD

final class ExportManagerTests: XCTestCase {
    
    func testExportFormatProperties() {
        // Test Format PDF
        let pdfFormat = ExportFormat.pdf
        XCTAssertEqual(pdfFormat.fileExtension, "pdf")
        XCTAssertEqual(pdfFormat.contentType, .pdf)
        XCTAssertEqual(pdfFormat.displayName, "PDF Document")
        
        // Test Format Markdown
        let mdFormat = ExportFormat.markdown
        XCTAssertEqual(mdFormat.fileExtension, "md")
        XCTAssertEqual(mdFormat.contentType, .plainText)
        XCTAssertEqual(mdFormat.displayName, "Markdown")
        
        // Test Format HTML
        let htmlFormat = ExportFormat.html
        XCTAssertEqual(htmlFormat.fileExtension, "html")
        XCTAssertEqual(htmlFormat.contentType, .plainText)
        XCTAssertEqual(htmlFormat.displayName, "HTML")
    }
    
    // Test dla logiki zapisywania plików
    func testExportToFile() {
        let exportManager = ExportManager.shared
        
        let expectation = self.expectation(description: "Export to file")
        
        // Mock window
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                               styleMask: .closable,
                               backing: .buffered,
                               defer: true)
        
        // Mock content
        let testContent = "# Test Document\n\nThis is a test document for export."
        let testTitle = "Test Document"
        
        // Tworzenie tymczasowej ścieżki dla pliku testowego
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryFilePath = (temporaryDirectory as NSString).appendingPathComponent("test_export.md")
        
        // Przygotowujemy test dla zapisywania pliku
        // Ze względu na naturę SavePanel nie możemy bezpośrednio testować UI, 
        // więc to jest głównie test kompilacji i podstawowej logiki
        exportManager.exportContent(content: testContent, title: testTitle, format: .markdown, from: window) { success, error in
            // W rzeczywistym teście wskaźnik sukcesu byłby false, ponieważ użytkownik nie wybierze ścieżki
            // Tutaj sprawdzamy jedynie, czy funkcja działa bez wyjątków
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}