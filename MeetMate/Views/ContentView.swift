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

    var body: some View {
        NavigationView {
            List {
                ForEach(meetings) { meeting in
                    VStack(alignment: .leading) {
                        Text(meeting.title ?? "No title")
                            .font(.headline)
                        Text(meeting.person?.name ?? "No person")
                            .font(.subheadline)
                        Text(meeting.datetime ?? Date(), style: .date)
                            .font(.caption)
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
                    Button(action: addMeeting) {
                        Label("Add Meeting", systemImage: "plus")
                    }
                }
            }
        }
    }

    @State private var showingAddMeetingView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(meetings) { meeting in
                    Text(meeting.title ?? "No title")
                }
                .onDelete(perform: deleteMeetings)
            }
            .navigationTitle("Meetings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddMeetingView.toggle() }) {
                        Label("Add Meeting", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeetingView) {
                AddMeetingView()
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
                    Button(action: addPerson) {
                        Label("Add Person", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addPerson() {
        withAnimation {
            let newPerson = PersonEntity(context: viewContext)
            newPerson.name = "New Person"

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
