//
//  MeetingEntity+CoreDataProperties.swift
//  MeetMate
//
//  Created by Your Name on 2024-07-21.
//
//

import Foundation
import CoreData
import SwiftUI

extension MeetingEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeetingEntity> {
        return NSFetchRequest<MeetingEntity>(entityName: "MeetingEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var datetime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    @NSManaged public var reminderSet: Bool
    @NSManaged public var reminderTime: Date?
    @NSManaged public var tag: String?
    @NSManaged public var title: String?
    @NSManaged public var status: String?
    @NSManaged public var person: PersonEntity?

}

extension MeetingEntity : Identifiable {

} 