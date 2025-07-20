import XCTest
import CoreData
@testable import MeetMate

class NotificationManagerTests: XCTestCase {

    var notificationManager: NotificationManager!
    var mockUserNotificationCenter: MockUserNotificationCenter!
    var viewContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        mockUserNotificationCenter = MockUserNotificationCenter()
        notificationManager = NotificationManager()
        notificationManager.userNotificationCenter = mockUserNotificationCenter

        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }

    func testScheduleNotification() {
        let meeting = MeetingEntity(context: viewContext)
        meeting.id = UUID()
        meeting.title = "Test Meeting"
        meeting.reminderSet = true
        meeting.reminderTime = Date()

        notificationManager.scheduleNotification(for: meeting)

        XCTAssertTrue(mockUserNotificationCenter.addRequestCalled)
    }

    func testCancelNotification() {
        let meeting = MeetingEntity(context: viewContext)
        meeting.id = UUID()

        notificationManager.cancelNotification(for: meeting)

        XCTAssertTrue(mockUserNotificationCenter.removePendingNotificationRequestsCalled)
    }
}

extension NotificationManager {
    @objc var userNotificationCenter: UNUserNotificationCenter {
        get { return UNUserNotificationCenter.current() }
        set { }
    }
}
