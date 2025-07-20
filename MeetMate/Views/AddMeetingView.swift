import SwiftUI

struct AddMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var reminderSet = false
    @State private var reminderTime = Date()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<PersonEntity>
    @State private var selectedPerson: PersonEntity?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meeting Details")) {
                    TextField("Title", text: $title)
                    Picker("Person", selection: $selectedPerson) {
                        ForEach(people, id: \.self) { person in
                            Text(person.name ?? "").tag(person as PersonEntity?)
                        }
                    }
                    TextField("Location", text: $location)
                    TextField("Notes", text: $notes)
                }

                Section(header: Text("Reminder")) {
                    Toggle(isOn: $reminderSet) {
                        Text("Set Reminder")
                    }
                    if reminderSet {
                        DatePicker("Reminder Time", selection: $reminderTime)
                    }
                }
            }
            .navigationTitle("Add Meeting")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addMeeting()
                        dismiss()
                    }
                }
            }
        }
    }

    private func addMeeting() {
        withAnimation {
            let newMeeting = MeetingEntity(context: viewContext)
            newMeeting.id = UUID()
            newMeeting.datetime = Date()
            newMeeting.title = title
            newMeeting.location = location
            newMeeting.notes = notes
            newMeeting.reminderSet = reminderSet
            newMeeting.reminderTime = reminderTime
            newMeeting.person = selectedPerson

            if newMeeting.reminderSet {
                NotificationManager.shared.scheduleNotification(for: newMeeting)
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddMeetingView_Previews: PreviewProvider {
    static var previews: some View {
        AddMeetingView()
    }
}
