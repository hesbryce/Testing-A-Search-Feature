import XCTest
import Foundation
@testable import YourApp

class SearchFunctionalityTests: XCTestCase {
    
    // MARK: - Properties
    var searchModel: SearchResultModel!
    var mockAppContent: ApplicationContent!
    var testPages: [Page]!
    
    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        super.setUp()
        searchModel = SearchResultModel()
        mockAppContent = createMockAppContent()
        testPages = createTestPages()
    }
    
    override func tearDownWithError() throws {
        searchModel = nil
        mockAppContent = nil
        testPages = nil
        super.tearDown()
    }
    
    // MARK: - Unit Tests for Search Logic
    
    func testSearchByPageTitle_ExactMatch() throws {
        // Given
        let searchTerm = "Employee Handbook"
        let expectedTitle = "Employee Handbook"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Search should return results for exact title match")
        XCTAssertEqual(results.first?.pageTitle, expectedTitle, "First result should match search term")
    }
    
    func testSearchByPageTitle_CaseInsensitive() throws {
        // Given
        let searchTerm = "employee handbook" // lowercase
        let expectedTitle = "Employee Handbook" // mixed case
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Case insensitive search should return results")
        XCTAssertEqual(results.first?.pageTitle, expectedTitle, "Should find page regardless of case")
    }
    
    func testSearchByMarkdownContent() throws {
        // Given
        let searchTerm = "quarterly meeting"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Should find pages with markdown content matching search")
        XCTAssertTrue(results.contains { $0.pageBody.localizedCaseInsensitiveContains(searchTerm) },
                     "At least one result should contain search term in body")
    }
    
    func testSearchByImageCaption() throws {
        // Given
        let searchTerm = "team photo"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Should find pages with image captions matching search")
        let hasImageMatch = results.contains { $0.imageCaption.localizedCaseInsensitiveContains(searchTerm) }
        XCTAssertTrue(hasImageMatch, "Should match image captions")
    }
    
    func testSearchByAccessibilityLabel() throws {
        // Given
        let searchTerm = "office building"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Should find pages with accessibility labels matching search")
        let hasAccessibilityMatch = results.contains { $0.imageAccessibilityLabel.localizedCaseInsensitiveContains(searchTerm) }
        XCTAssertTrue(hasAccessibilityMatch, "Should match accessibility labels")
    }
    
    func testSearchByModuleName_Email() throws {
        // Given
        let searchTerm = "support@company.com"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Should find pages with email modules matching search")
        let hasEmailMatch = results.contains { result in
            result.emailModule.contains { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
        XCTAssertTrue(hasEmailMatch, "Should match email module names")
    }
    
    func testEmptySearchTerm() throws {
        // Given
        let searchTerm = ""
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertTrue(results.isEmpty, "Empty search should return no results")
    }
    
    func testWhitespaceOnlySearchTerm() throws {
        // Given
        let searchTerm = "   \n\t   "
        
        // When
        let results = performSearch(with: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines), in: testPages)
        
        // Then
        XCTAssertTrue(results.isEmpty, "Whitespace-only search should return no results after trimming")
    }
    
    func testNoMatchesFound() throws {
        // Given
        let searchTerm = "nonexistentterm12345"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertTrue(results.isEmpty, "Search for non-existent term should return empty results")
    }
    
    // MARK: - Date Sorting Tests
    
    func testResultsSortedByDateDescending() throws {
        // Given
        let searchTerm = "meeting"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        let sortedResults = sortResultsByDate(results, ascending: false)
        
        // Then
        XCTAssertGreaterThan(sortedResults.count, 1, "Need multiple results to test sorting")
        
        let dateFormatter = ISO8601DateFormatter()
        for i in 0..<sortedResults.count - 1 {
            guard let date1 = dateFormatter.date(from: sortedResults[i].lastUpdated),
                  let date2 = dateFormatter.date(from: sortedResults[i + 1].lastUpdated) else {
                XCTFail("Invalid date format in test data")
                return
            }
            XCTAssertGreaterThanOrEqual(date1, date2, "Results should be sorted in descending order")
        }
    }
    
    func testResultsSortedByDateAscending() throws {
        // Given
        let searchTerm = "meeting"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        let sortedResults = sortResultsByDate(results, ascending: true)
        
        // Then
        XCTAssertGreaterThan(sortedResults.count, 1, "Need multiple results to test sorting")
        
        let dateFormatter = ISO8601DateFormatter()
        for i in 0..<sortedResults.count - 1 {
            guard let date1 = dateFormatter.date(from: sortedResults[i].lastUpdated),
                  let date2 = dateFormatter.date(from: sortedResults[i + 1].lastUpdated) else {
                XCTFail("Invalid date format in test data")
                return
            }
            XCTAssertLessThanOrEqual(date1, date2, "Results should be sorted in ascending order")
        }
    }
    
    // MARK: - Duplicate Prevention Tests
    
    func testNoDuplicateResults() throws {
        // Given
        let searchTerm = "duplicate" // Term that might appear in multiple components of same page
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        let uniquePageTitles = Set(results.map { $0.pageTitle })
        XCTAssertEqual(results.count, uniquePageTitles.count, "Should not have duplicate pages in results")
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformanceWithLargeDataset() throws {
        // Given
        let largeDataset = createLargeTestDataset(pageCount: 1000)
        let searchTerm = "performance"
        
        // When & Then
        measure {
            let _ = performSearch(with: searchTerm, in: largeDataset)
        }
    }
    
    func testDateSortingPerformance() throws {
        // Given
        let largeResultSet = createLargeSearchResults(count: 500)
        
        // When & Then
        measure {
            let _ = sortResultsByDate(largeResultSet, ascending: false)
        }
    }
    
    // MARK: - Edge Cases
    
    func testSearchWithSpecialCharacters() throws {
        // Given
        let searchTerm = "@#$%^&*()"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        // Should handle gracefully without crashing
        XCTAssertNotNil(results, "Search should handle special characters gracefully")
    }
    
    func testSearchWithUnicodeCharacters() throws {
        // Given
        let searchTerm = "café résumé naïve"
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertNotNil(results, "Search should handle unicode characters")
    }
    
    func testSearchWithVeryLongTerm() throws {
        // Given
        let searchTerm = String(repeating: "a", count: 1000)
        
        // When
        let results = performSearch(with: searchTerm, in: testPages)
        
        // Then
        XCTAssertNotNil(results, "Should handle very long search terms without crashing")
    }
    
    // MARK: - Helper Methods
    
    private func performSearch(with searchTerm: String, in pages: [Page]) -> [SearchResultModel.SearchedResults] {
        // Implement your actual search logic here
        // This would mirror the logic from your SearchResultsViewController
        var results: [SearchResultModel.SearchedResults] = []
        
        for page in pages {
            // Title matching
            if page.name?.localizedCaseInsensitiveContains(searchTerm) == true {
                let result = SearchResultModel.SearchedResults(
                    pageTitle: page.name ?? "",
                    pageBody: "Title matches search term",
                    lastUpdated: page.updatedAt ?? "",
                    imageAttached: ""
                )
                results.append(result)
            }
            
            // Component matching logic would go here...
        }
        
        return results
    }
    
    private func sortResultsByDate(_ results: [SearchResultModel.SearchedResults], ascending: Bool) -> [SearchResultModel.SearchedResults] {
        let dateFormatter = ISO8601DateFormatter()
        
        return results.sorted { result1, result2 in
            guard let date1 = dateFormatter.date(from: result1.lastUpdated),
                  let date2 = dateFormatter.date(from: result2.lastUpdated) else {
                return false
            }
            
            return ascending ? date1 < date2 : date1 > date2
        }
    }
    
    private func createMockAppContent() -> ApplicationContent {
        // Create mock data for testing
        return ApplicationContent()
    }
    
    private func createTestPages() -> [Page] {
        // Create test pages with various content types
        return []
    }
    
    private func createLargeTestDataset(pageCount: Int) -> [Page] {
        // Generate large dataset for performance testing
        return []
    }
    
    private func createLargeSearchResults(count: Int) -> [SearchResultModel.SearchedResults] {
        // Generate large result set for performance testing
        return []
    }
}

// MARK: - XCTAssert Extensions for Custom Validation

extension XCTestCase {
    
    func XCTAssertContainsSearchTerm(_ text: String, _ searchTerm: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(text.localizedCaseInsensitiveContains(searchTerm), 
                     "Text '\(text)' should contain search term '\(searchTerm)'", 
                     file: file, line: line)
    }
    
    func XCTAssertValidSearchResults(_ results: [SearchResultModel.SearchedResults], 
                                   for searchTerm: String, 
                                   file: StaticString = #file, 
                                   line: UInt = #line) {
        XCTAssertFalse(results.isEmpty, "Search results should not be empty", file: file, line: line)
        
        for result in results {
            let containsInTitle = result.pageTitle.localizedCaseInsensitiveContains(searchTerm)
            let containsInBody = result.pageBody.localizedCaseInsensitiveContains(searchTerm)
            
            XCTAssertTrue(containsInTitle || containsInBody, 
                         "Result '\(result.pageTitle)' should contain search term '\(searchTerm)'", 
                         file: file, line: line)
        }
    }
}
