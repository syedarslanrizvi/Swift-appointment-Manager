import Foundation
import UserNotifications
@testable import MeetMate

class MockUserNotificationCenter: UNUserNotificationCenter {
    var addRequestCalled = false
    var removePendingNotificationRequestsCalled = false

    override func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addRequestCalled = true
    }

    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequestsCalled = true
    }
}
