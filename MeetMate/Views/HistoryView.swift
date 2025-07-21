import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeetingEntity.datetime, ascending: false)],
        predicate: NSPredicate(format: "status == %@", "completed"),
        animation: .default)
    private var meetings: FetchedResults<MeetingEntity>
    
    @State private var selectedDate: Date?
    
    var body: some View {
        NavigationView {
            VStack {
                CalendarView(meetings: meetings.map { $0 }, selectedDate: $selectedDate)
                
                if let selectedDate = selectedDate {
                    List {
                        ForEach(meetings.filter { Calendar.current.isDate($0.datetime ?? Date(), inSameDayAs: selectedDate) }) { meeting in
                            MeetingRowView(meeting: meeting, activeSheet: .constant(nil))
                        }
                    }
                } else {
                    List {
                        ForEach(meetings) { meeting in
                            MeetingRowView(meeting: meeting, activeSheet: .constant(nil))
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct CalendarView: View {
    let meetings: [MeetingEntity]
    @Binding var selectedDate: Date?
    
    var body: some View {
        DatePicker(
            "Select Date",
            selection: Binding(
                get: { selectedDate ?? Date() },
                set: { selectedDate = $0 }
            ),
            displayedComponents: .date
        )
        .datePickerStyle(GraphicalDatePickerStyle())
        .padding()
    }
} 