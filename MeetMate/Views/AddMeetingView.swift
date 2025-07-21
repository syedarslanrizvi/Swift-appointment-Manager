import SwiftUI

struct AddMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var tag = ""
    @State private var meetingDate = Date()
    @State private var selectedColor = Color.accentColor
    @State private var reminderSet = false
    @State private var reminderTime = Date()
    @State private var reminderInterval: TimeInterval = 0
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<PersonEntity>
    @State private var selectedPerson: PersonEntity?
    @State private var showingAddPerson = false
    @State private var newName = ""
    @State private var newNotes = ""
    @State private var newTag = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meeting Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $meetingDate)
                    HStack {
                        Picker("Person", selection: $selectedPerson) {
                            ForEach(people, id: \.self) { person in
                                HStack {
                                    Text(person.name ?? "")
                                    if selectedPerson == person {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }.tag(person as PersonEntity?)
                            }
                        }
                        Button(action: { showingAddPerson = true }) {
                            Image(systemName: "plus.circle")
                        }
                        .accessibilityLabel("Add Person")
                    }
                    .accessibilityElement(children: .combine)
                    TextField("Location", text: $location)
                        .accessibility(label: Text("Location"))
                        .accessibility(value: Text(location))
                        .accessibility(hint: Text("Enter the meeting location"))
                    TextField("Notes", text: $notes)
                        .accessibility(label: Text("Notes"))
                        .accessibility(value: Text(notes))
                        .accessibility(hint: Text("Enter any meeting notes"))
                    TextField("Tag", text: $tag)
                        .accessibility(label: Text("Tag"))
                        .accessibility(value: Text(tag))
                        .accessibility(hint: Text("Enter a tag for the meeting"))
                    ColorPicker("Color", selection: $selectedColor)
                        .accessibility(label: Text("Color"))
                        .accessibility(hint: Text("Select a color for the meeting"))
                }

                Section(header: Text("Reminder")) {
                    Toggle(isOn: $reminderSet) {
                        Text("Set Reminder")
                    }
                    .accessibility(label: Text("Set Reminder"))
                    .accessibility(value: Text(reminderSet ? "On" : "Off"))
                    if reminderSet {
                        DatePicker("Reminder Time", selection: $reminderTime)
                            .accessibility(label: Text("Reminder Time"))
                            .accessibility(value: Text(reminderTime, style: .time))
                        Picker("Remind Me", selection: $reminderInterval) {
                            Text("At time of event").tag(TimeInterval(0))
                            Text("5 minutes before").tag(TimeInterval(5 * 60))
                            Text("15 minutes before").tag(TimeInterval(15 * 60))
                            Text("30 minutes before").tag(TimeInterval(30 * 60))
                            Text("1 hour before").tag(TimeInterval(60 * 60))
                            Text("2 hours before").tag(TimeInterval(2 * 60 * 60))
                        }
                        .accessibility(label: Text("Remind Me"))
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
                    .disabled(selectedPerson == nil)
                }
            }
            .onAppear {
                if selectedPerson == nil, let first = people.first {
                    selectedPerson = first
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                NavigationView {
                    Form {
                        Section(header: Text("Name")) {
                            TextField("Name", text: $newName)
                        }
                        Section(header: Text("Notes")) {
                            TextField("Notes", text: $newNotes)
                        }
                        Section(header: Text("Tag")) {
                            TextField("Tag", text: $newTag)
                        }
                    }
                    .navigationTitle("Add Person")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddPerson = false
                                newName = ""
                                newNotes = ""
                                newTag = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addPersonInline()
                                showingAddPerson = false
                                newName = ""
                                newNotes = ""
                                newTag = ""
                            }
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func addMeeting() {
        guard let selectedPerson = selectedPerson else { return }
        withAnimation {
            let newMeeting = MeetingEntity(context: viewContext)
            newMeeting.id = UUID()
            newMeeting.datetime = meetingDate
            newMeeting.title = title
            newMeeting.location = location
            newMeeting.notes = notes
            newMeeting.tag = tag
            newMeeting.color = selectedColor.toHex()
            newMeeting.reminderSet = reminderSet
            newMeeting.reminderTime = reminderTime.addingTimeInterval(-reminderInterval)
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

    private func addPersonInline() {
        withAnimation {
            let newPerson = PersonEntity(context: viewContext)
            newPerson.id = UUID()
            newPerson.name = newName
            newPerson.notes = newNotes
            newPerson.tag = newTag
            do {
                try viewContext.save()
                selectedPerson = newPerson
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }

    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: 
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: 
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: 
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AddMeetingView_Previews: PreviewProvider {
    static var previews: some View {
        AddMeetingView()
    }
}
