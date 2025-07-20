import Foundation
import CoreData

extension MeetingEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeetingEntity> {
        return NSFetchRequest<MeetingEntity>(entityName: "MeetingEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var datetime: Date?
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    @NSManaged public var reminderSet: Bool
    @NSManaged public var reminderTime: Date?
    @NSManaged public var person: PersonEntity?
}

extension MeetingEntity : Identifiable {} 