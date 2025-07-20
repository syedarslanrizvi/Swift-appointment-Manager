import Foundation
import CoreData

extension PersonEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonEntity> {
        return NSFetchRequest<PersonEntity>(entityName: "PersonEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var tag: String?
    @NSManaged public var notes: String?
    @NSManaged public var meetings: NSSet?
}

// MARK: Generated accessors for meetings
extension PersonEntity {
    @objc(addMeetingsObject:)
    @NSManaged public func addToMeetings(_ value: MeetingEntity)

    @objc(removeMeetingsObject:)
    @NSManaged public func removeFromMeetings(_ value: MeetingEntity)

    @objc(addMeetings:)
    @NSManaged public func addToMeetings(_ values: NSSet)

    @objc(removeMeetings:)
    @NSManaged public func removeFromMeetings(_ values: NSSet)
}

extension PersonEntity : Identifiable {} 