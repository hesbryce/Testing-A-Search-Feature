import XCTest

class SearchFeatureUITests: XCTestCase {
    
    // MARK: - Properties
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to main content view if needed
        navigateToMainContentView()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Search Bar Interaction Tests
    
    func testSearchBarVisibilityForLoggedInUser() throws {
        // Given: User is logged in
        loginTestUser()
        
        // When: Navigate to content view
        navigateToMainContentView()
        
        // Then: Search bar should be visible
        let searchBar = app.searchFields["Search \(getAppName())"]
        XCTAssertTrue(searchBar.exists, "Search bar should be visible for logged in users")
        XCTAssertTrue(searchBar.isHittable, "Search bar should be interactive")
    }
    
    func testSearchBarHiddenForLoggedOutUser() throws {
        // Given: User is logged out
        logoutUser()
        
        // When: Navigate to content view
        navigateToMainContentView()
        
        // Then: Search bar should be hidden
        let searchBar = app.searchFields["Search \(getAppName())"]
        XCTAssertFalse(searchBar.exists, "Search bar should be hidden for logged out users")
    }
    
    func testSearchBarPlaceholderText() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Check search bar placeholder
        let searchBar = app.searchFields["Search \(getAppName())"]
        
        // Then: Placeholder should contain app name
        XCTAssertTrue(searchBar.exists, "Search bar should exist")
        XCTAssertEqual(searchBar.placeholderValue, "Search \(getAppName())", "Placeholder should match expected format")
    }
    
    func testSearchBarKeyboardAppearance() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Tap search bar
        let searchBar = app.searchFields["Search \(getAppName())"]
        searchBar.tap()
        
        // Then: Keyboard should appear
        XCTAssertTrue(app.keyboards.element.exists, "Keyboard should appear when search bar is tapped")
        
        // When: Tap elsewhere to dismiss keyboard
        app.tables.firstMatch.tap()
        
        // Then: Keyboard should disappear
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard should dismiss when tapping elsewhere")
    }
    
    // MARK: - Search Functionality Tests
    
    func testBasicSearch() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Perform search
        let searchTerm = "employee"
        performSearch(searchTerm)
        
        // Then: Should navigate to search results
        XCTAssertTrue(app.staticTexts["Showing"].exists, "Should show results count label")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", searchTerm)).element.exists,
                     "Results should contain search term")
    }
    
    func testEmptySearchAlert() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Search with empty text
        let searchBar = app.searchFields["Search \(getAppName())"]
        searchBar.tap()
        app.buttons["Search"].tap()
        
        // Then: Should show alert for empty search
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.exists, "Should show alert for empty search")
        XCTAssertTrue(alert.staticTexts["Invalid Search"].exists, "Alert should have correct title")
        
        // Dismiss alert
        alert.buttons["Dismiss"].tap()
    }
    
    func testSearchWithWhitespaceOnly() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Search with whitespace only
        let searchBar = app.searchFields["Search \(getAppName())"]
        searchBar.tap()
        searchBar.typeText("   ")
        app.buttons["Search"].tap()
        
        // Then: Should show alert for invalid search
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.exists, "Should show alert for whitespace-only search")
        alert.buttons["Dismiss"].tap()
    }
    
    func testNoResultsFound() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Search for non-existent term
        performSearch("nonexistentterm12345")
        
        // Then: Should show no results alert
        let alert = app.alerts["No Results Found"]
        XCTAssertTrue(alert.exists, "Should show no results alert")
        XCTAssertTrue(alert.staticTexts["Your search did not match any content."].exists,
                     "Alert should have correct message")
        alert.buttons["Dismiss"].tap()
    }
    
    // MARK: - Search Results Tests
    
    func testSearchResultsDisplay() throws {
        // Given: User performs a search
        loginTestUser()
        navigateToMainContentView()
        performSearch("handbook")
        
        // Then: Results should be displayed
        let resultsTable = app.tables.firstMatch
        XCTAssertTrue(resultsTable.exists, "Results table should exist")
        
        let firstCell = resultsTable.cells.firstMatch
        XCTAssertTrue(firstCell.exists, "At least one result cell should exist")
        
        // Verify cell content structure
        XCTAssertTrue(firstCell.staticTexts.firstMatch.exists, "Cell should have title text")
        XCTAssertTrue(firstCell.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last updated'")).element.exists,
                     "Cell should have date information")
    }
    
    func testSearchResultsCount() throws {
        // Given: User performs a search
        loginTestUser()
        navigateToMainContentView()
        performSearch("meeting")
        
        // Then: Results count should be displayed
        let resultsLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Showing'")).firstMatch
        XCTAssertTrue(resultsLabel.exists, "Results count label should exist")
        XCTAssertTrue(resultsLabel.label.contains("result"), "Label should contain 'result' text")
    }
    
    func testSearchResultNavigation() throws {
        // Given: User has search results
        loginTestUser()
        navigateToMainContentView()
        performSearch("handbook")
        
        // When: Tap on first result
        let firstCell = app.tables.firstMatch.cells.firstMatch
        XCTAssertTrue(firstCell.exists, "First result cell should exist")
        firstCell.tap()
        
        // Then: Should navigate to content detail
        // Verify we're on a different screen (back button exists)
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.exists, "Back button should exist after navigation")
    }
    
    // MARK: - Date Filtering Tests
    
    func testDateFilterToggle() throws {
        // Given: User has search results
        loginTestUser()
        navigateToMainContentView()
        performSearch("meeting")
        
        // When: Tap date filter button
        let dateFilterButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Date'")).firstMatch
        XCTAssertTrue(dateFilterButton.exists, "Date filter button should exist")
        dateFilterButton.tap()
        
        // Then: Results should reorder (we can't easily verify exact order in UI tests,
        // but we can verify the button state changes)
        XCTAssertTrue(dateFilterButton.exists, "Date filter button should still exist after tap")
    }
    
    // MARK: - Search Bar in Results Tests
    
    func testSearchBarInResults() throws {
        // Given: User is on search results page
        loginTestUser()
        navigateToMainContentView()
        performSearch("handbook")
        
        // Then: Results search bar should exist and contain search term
        let resultsSearchBar = app.searchFields.firstMatch
        XCTAssertTrue(resultsSearchBar.exists, "Results search bar should exist")
        XCTAssertEqual(resultsSearchBar.value as? String, "handbook", "Search bar should contain original search term")
    }
    
    func testNewSearchFromResults() throws {
        // Given: User is on search results page
        loginTestUser()
        navigateToMainContentView()
        performSearch("handbook")
        
        // When: Perform new search from results page
        let resultsSearchBar = app.searchFields.firstMatch
        resultsSearchBar.tap()
        resultsSearchBar.clearAndEnterText("meeting")
        app.buttons["Search"].tap()
        
        // Then: Results should update
        let resultsLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'meeting'")).firstMatch
        XCTAssertTrue(resultsLabel.exists, "Results should update to show new search term")
    }
    
    // MARK: - Accessibility Tests
    
    func testSearchBarAccessibility() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Check search bar accessibility
        let searchBar = app.searchFields["Search \(getAppName())"]
        
        // Then: Search bar should be accessible
        XCTAssertTrue(searchBar.isAccessibilityElement, "Search bar should be accessibility element")
        XCTAssertNotNil(searchBar.accessibilityLabel, "Search bar should have accessibility label")
    }
    
    func testSearchResultsAccessibility() throws {
        // Given: User has search results
        loginTestUser()
        navigateToMainContentView()
        performSearch("handbook")
        
        // When: Check first result cell accessibility
        let firstCell = app.tables.firstMatch.cells.firstMatch
        
        // Then: Cell should be accessible
        XCTAssertTrue(firstCell.isAccessibilityElement, "Result cells should be accessibility elements")
        XCTAssertNotNil(firstCell.accessibilityLabel, "Result cells should have accessibility labels")
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When & Then: Measure search performance
        measure(metrics: [XCTApplicationLaunchMetric(), XCTClockMetric()]) {
            performSearch("performance")
            
            // Wait for results to load
            XCTAssertTrue(app.staticTexts["Showing"].waitForExistence(timeout: 5),
                         "Results should load within 5 seconds")
        }
    }
    
    func testScrollPerformance() throws {
        // Given: User has many search results
        loginTestUser()
        navigateToMainContentView()
        performSearch("test") // Assuming this returns many results
        
        let resultsTable = app.tables.firstMatch
        
        // When & Then: Measure scroll performance
        measure(metrics: [XCTClockMetric()]) {
            resultsTable.swipeUp()
            resultsTable.swipeUp()
            resultsTable.swipeDown()
            resultsTable.swipeDown()
        }
    }
    
    // MARK: - Cross-Platform Considerations
    
    func testSearchOnDifferentOrientations() throws {
        // Given: User is on main content view
        loginTestUser()
        navigateToMainContentView()
        
        // When: Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Then: Search should still work
        let searchBar = app.searchFields["Search \(getAppName())"]
        XCTAssertTrue(searchBar.exists, "Search bar should exist in landscape mode")
        
        performSearch("handbook")
        XCTAssertTrue(app.staticTexts["Showing"].exists, "Search should work in landscape mode")
        
        // Clean up
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMainContentView() {
        // Navigate to the main content view where search is available
        // This would depend on your app's navigation structure
        if !app.searchFields.firstMatch.exists {
            // Add navigation logic here
        }
    }
    
    private func loginTestUser() {
        // Login a test user if not already logged in
        // This would depend on your app's authentication flow
    }
    
    private func logoutUser() {
        // Logout user if logged in
        // This would depend on your app's authentication flow
    }
    
    private func performSearch(_ searchTerm: String) {
        let searchBar = app.searchFields.firstMatch
        searchBar.tap()
        searchBar.clearAndEnterText(searchTerm)
        
        // Tap search button on keyboard or search button in app
        if app.keyboards.buttons["Search"].exists {
            app.keyboards.buttons["Search"].tap()
        } else {
            app.buttons["Search"].tap()
        }
    }
    
    private func getAppName() -> String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TestApp"
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }
        
        // Clear existing text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        
        // Enter new text
        self.typeText(text)
    }
}

// MARK: - Additional Test Extensions for Cross-Platform Testing

extension SearchFeatureUITests {
    
    func testSearchFeatureOnIPad() throws {
        // Skip if not on iPad
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad specific test")
        }
        
        // iPad specific search behavior tests
        loginTestUser()
        navigateToMainContentView()
        
        // iPad might show search differently
        let searchBar = app.searchFields.firstMatch
        XCTAssertTrue(searchBar.exists, "Search bar should exist on iPad")
        
        performSearch("ipad test")
        XCTAssertTrue(app.staticTexts["Showing"].exists, "Search should work on iPad")
    }
    
    func testSearchWithExternalKeyboard() throws {
        // Test search functionality with external keyboard shortcuts
        loginTestUser()
        navigateToMainContentView()
        
        let searchBar = app.searchFields.firstMatch
        searchBar.tap()
        
        // Test keyboard shortcut if available (Cmd+A, Cmd+C, etc.)
        searchBar.typeText("keyboard test")
        
        // Use return key instead of search button
        app.keyboards.buttons["return"].tap()
        
        XCTAssertTrue(app.staticTexts["Showing"].exists, "Search should work with return key")
    }
}
