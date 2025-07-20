import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            MeetingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Meetings")
                }

            PeopleView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("People")
                }
        }
    }
}

struct MeetingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeetingEntity.datetime, ascending: true)],
        animation: .default)
    private var meetings: FetchedResults<MeetingEntity>

    enum ActiveSheet: Identifiable {
        case add, edit(MeetingEntity)
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let meeting): return meeting.objectID.uriRepresentation().absoluteString
            }
        }
    }
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        NavigationView {
            List {
                ForEach(meetings, id: \.objectID) { meeting in
                    VStack(alignment: .leading) {
                        Text(meeting.title ?? "No title")
                            .font(.headline)
                        Text(meeting.person?.name ?? "No person")
                            .font(.subheadline)
                        Text(meeting.datetime ?? Date(), style: .date)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeSheet = .edit(meeting)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            activeSheet = .edit(meeting)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete(perform: deleteMeetings)
            }
            .navigationTitle("Meetings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { activeSheet = .add }) {
                        Label("Add Meeting", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add:
                    AddMeetingView()
                case .edit(let meeting):
                    EditMeetingView(meeting: meeting)
                }
            }
        }
    }

    private func deleteMeetings(offsets: IndexSet) {
        withAnimation {
            offsets.map { meetings[$0] }.forEach { meeting in
                NotificationManager.shared.cancelNotification(for: meeting)
                viewContext.delete(meeting)
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

struct PeopleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<PersonEntity>

    @State private var showingAddPerson = false
    @State private var newName = ""
    @State private var newNotes = ""
    @State private var newTag = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(people) { person in
                    Text(person.name ?? "No name")
                }
                .onDelete(perform: deletePeople)
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddPerson = true }) {
                        Label("Add Person", systemImage: "plus")
                    }
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
                                addPerson()
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

    private func addPerson() {
        withAnimation {
            let newPerson = PersonEntity(context: viewContext)
            newPerson.id = UUID()
            newPerson.name = newName
            newPerson.notes = newNotes
            newPerson.tag = newTag

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deletePeople(offsets: IndexSet) {
        withAnimation {
            offsets.map { people[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct EditMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PersonEntity.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<PersonEntity>

    @ObservedObject var meeting: MeetingEntity

    @State private var title: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var reminderSet: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var selectedPerson: PersonEntity?

    var body: some View {
        NavigationView {
            if people.isEmpty {
                VStack(spacing: 20) {
                    Text("No people available to assign to this meeting.")
                        .font(.headline)
                        .padding()
                    Text("Please add a person in the People tab before editing meetings.")
                        .multilineTextAlignment(.center)
                    Button("Close") {
                        dismiss()
                    }
                    .padding()
                }
            } else {
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
                .navigationTitle("Edit Meeting")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveChanges()
                            dismiss()
                        }
                        .disabled(selectedPerson == nil)
                    }
                }
                .onAppear {
                    title = meeting.title ?? ""
                    location = meeting.location ?? ""
                    notes = meeting.notes ?? ""
                    reminderSet = meeting.reminderSet
                    reminderTime = meeting.reminderTime ?? Date()
                    selectedPerson = meeting.person
                    if selectedPerson == nil, let first = people.first {
                        selectedPerson = first
                    }
                }
            }
        }
    }

    private func saveChanges() {
        guard let selectedPerson = selectedPerson else { return }
        print("Saving changes to meeting: title=\(title), location=\(location), notes=\(notes), reminderSet=\(reminderSet), reminderTime=\(reminderTime), person=\(selectedPerson.name ?? "")")
        meeting.title = title
        meeting.location = location
        meeting.notes = notes
        meeting.reminderSet = reminderSet
        meeting.reminderTime = reminderTime
        meeting.person = selectedPerson
        meeting.datetime = meeting.datetime ?? Date()
        do {
            try viewContext.save()
            print("Save successful")
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Save failed: \(nsError), \(nsError.userInfo)")
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
