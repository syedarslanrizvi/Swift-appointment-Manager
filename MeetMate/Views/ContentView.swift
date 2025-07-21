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

            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
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

    @State private var searchText = ""
    @State private var selectedTag: String?

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
    @State private var showConfetti = false

    var filteredMeetings: [MeetingEntity] {
        let filteredBySearch = meetings.filter {
            ($0.status ?? "active") == "active" &&
            (searchText.isEmpty || $0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        if let selectedTag = selectedTag {
            return filteredBySearch.filter { $0.tag == selectedTag }
        } else {
            return filteredBySearch
        }
    }

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    MotivationalQuoteView(quote: "The best way to predict the future is to create it.")
                    List {
                        ForEach(filteredMeetings, id: \.objectID) { meeting in
                            MeetingRowView(meeting: meeting, activeSheet: $activeSheet)
                        }
                        .onDelete(perform: deleteMeetings)
                    }
                    .searchable(text: $searchText)
                    .navigationTitle("Meetings")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Menu {
                                Button("All", action: { selectedTag = nil })
                                ForEach(meetings.compactMap { $0.tag }.removingDuplicates(), id: \.self) { tag in
                                    Button(tag, action: { selectedTag = tag })
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { activeSheet = .add }) {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Add Meeting")
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
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { activeSheet = .add }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.accentColor))
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel("Add Meeting")
                        .padding()
                    }
                }
            }
            if showConfetti {
                ConfettiView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showConfetti = false
                        }
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

struct MeetingRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var meeting: MeetingEntity
    @Binding var activeSheet: MeetingsView.ActiveSheet?
    @State private var showConfetti = false
    @State private var showingShareSheet = false

    var body: some View {
        HStack {
            Rectangle()
            .fill(Color.fromHex(meeting.color ?? "#FFFFFF"))
            .frame(width: 8)
            
            AvatarView(name: meeting.person?.name ?? "")
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(meeting.title ?? "No title")
                        .font(.headline)
                        .accessibility(label: Text("Meeting title: \(meeting.title ?? "No title")"))
                    Spacer()
                    if let tag = meeting.tag, !tag.isEmpty {
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.fromHex(meeting.color ?? "#FFFFFF").opacity(0.2))
                            .cornerRadius(8)
                            .accessibility(label: Text("Tag: \(tag)"))
                    }
                }
                if let notes = meeting.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .accessibility(label: Text("Notes: \(notes)"))
                }
                Text(meeting.person?.name ?? "No person")
                    .font(.subheadline)
                    .accessibility(label: Text("Person: \(meeting.person?.name ?? "No person")"))
                Text(meeting.datetime ?? Date(), style: .date)
                    .font(.caption)
                    .accessibility(label: Text("Date: \(meeting.datetime ?? Date(), style: .date)"))
            }
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
            Button {
                showingShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.gray)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteMeeting()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                completeMeeting()
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .sheet(isPresented: $showingShareSheet) {
            let meetingDetails = """
            Meeting: \(meeting.title ?? "No title")
            Date: \(meeting.datetime ?? Date())
            Location: \(meeting.location ?? "Not specified")
            """
            ShareSheet(items: [meetingDetails])
        }
    }

    private func completeMeeting() {
        withAnimation {
            meeting.status = "completed"
            do {
                try viewContext.save()
                showConfetti = true
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteMeeting() {
        withAnimation {
            NotificationManager.shared.cancelNotification(for: meeting)
            viewContext.delete(meeting)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
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
    @State private var showingFeedback = false

    var body: some View {
        NavigationView {
            List {
                ForEach(people) { person in
                    Text(person.name ?? "No name")
                        .accessibility(label: Text("Person's name: \(person.name ?? "No name")"))
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFeedback = true }) {
                        Label("Feedback", systemImage: "envelope")
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                NavigationView {
                    Form {
                        Section(header: Text("Name")) {
                            TextField("Name", text: $newName)
                                .accessibility(label: Text("Name"))
                                .accessibility(value: Text(newName))
                                .accessibility(hint: Text("Enter the person's name"))
                        }
                        Section(header: Text("Notes")) {
                            TextField("Notes", text: $newNotes)
                                .accessibility(label: Text("Notes"))
                                .accessibility(value: Text(newNotes))
                                .accessibility(hint: Text("Enter any notes for the person"))
                        }
                        Section(header: Text("Tag")) {
                            TextField("Tag", text: $newTag)
                                .accessibility(label: Text("Tag"))
                                .accessibility(value: Text(newTag))
                                .accessibility(hint: Text("Enter a tag for the person"))
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
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
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
    @State private var tag: String = ""
    @State private var selectedColor: Color = .accentColor
    @State private var reminderSet: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var reminderInterval: TimeInterval = 0
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
                        TextField("Tag", text: $tag)
                        ColorPicker("Color", selection: $selectedColor)
                    }

                    Section(header: Text("Reminder")) {
                        Toggle(isOn: $reminderSet) {
                            Text("Set Reminder")
                        }
                        if reminderSet {
                            DatePicker("Reminder Time", selection: $reminderTime)
                            Picker("Remind Me", selection: $reminderInterval) {
                                Text("At time of event").tag(TimeInterval(0))
                                Text("5 minutes before").tag(TimeInterval(5 * 60))
                                Text("15 minutes before").tag(TimeInterval(15 * 60))
                                Text("30 minutes before").tag(TimeInterval(30 * 60))
                                Text("1 hour before").tag(TimeInterval(60 * 60))
                                Text("2 hours before").tag(TimeInterval(2 * 60 * 60))
                            }
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
                    tag = meeting.tag ?? ""
                    selectedColor = Color.fromHex(meeting.color ?? "#FFFFFF")
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
        meeting.tag = tag
        meeting.color = selectedColor.toHex()
        meeting.reminderSet = reminderSet
        meeting.reminderTime = reminderTime.addingTimeInterval(-reminderInterval)
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
        Group {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.light)
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
