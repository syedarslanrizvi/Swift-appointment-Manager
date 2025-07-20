import XCTest

class MeetMateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddMeeting() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Add Meeting"].tap()

        let titleTextField = app.textFields["Title"]
        titleTextField.tap()
        titleTextField.typeText("Test Meeting")

        let locationTextField = app.textFields["Location"]
        locationTextField.tap()
        locationTextField.typeText("Test Location")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Test Meeting"].exists)
    }
}
