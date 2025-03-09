//
//  ContentView.swift
//  TodoApp
//
//  Created by Chen Chen on 2025-03-05.
//
import SwiftUI

struct Todo: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var is_completed: Bool
}
struct TodoUpdateRequest: Encodable {
    let title: String
    let description: String
    let is_completed: Bool
}
class TodoService {
    private let baseURL = "http://192.168.1.71:3000/todos" // Replace with your Windows IP

    func fetchTodos() async throws -> [Todo] {
        guard let url = URL(string: baseURL) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Todo].self, from: data)
    }

    func createTodo(title: String, description: String) async throws -> Todo {
        guard let url = URL(string: baseURL) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["title": title, "description": description]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Todo.self, from: data)
    }
    func updateTodo(id: UUID, title: String, description: String, isCompleted: Bool) async throws {
            guard let url = URL(string: "\(baseURL)/\(id.uuidString)") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = TodoUpdateRequest(title: title, description: description, is_completed: isCompleted)
            print("this is a test!!!")
            print(title, description, isCompleted)
            request.httpBody = try JSONEncoder().encode(body)
            _ = try await URLSession.shared.data(for: request)
        }
    
    
    // Toggle completion status
    func toggleTodoCompletionxxx(id: UUID, isCompleted: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/\(id.uuidString)") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["is_completed": isCompleted]
        request.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: request)
    }
}

struct TodoListView: View {
    @State private var todos: [Todo] = []
    @State private var showAddTodoSheet = false
    @State private var editTodo: Todo?
    private let todoService = TodoService()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todos) { todo in
                    HStack {
                        // Toggle Button
                        Button {
                            Task { await toggleTodoCompletion(todo) }
                        } label: {
                            Image(systemName: todo.is_completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.is_completed ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                        
                        // Todo Text (Non-Tappable)
                        VStack(alignment: .leading) {
                            Text(todo.title)
                                .font(.headline)
                                .strikethrough(todo.is_completed)
                            Text(todo.description)
                                .font(.subheadline)
                                .strikethrough(todo.is_completed)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                        
                        // Edit Button
                        Button {
                            editTodo = todo
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle()) // Define tap area
                    .onTapGesture {} // Block taps on the entire row
                    
                }
                
            }
            
            .navigationTitle("Todos")
            .toolbar {
                Button(action: { showAddTodoSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddTodoSheet) {
                AddTodoView(todos: $todos)
            }
            .sheet(item: $editTodo) { todo in
                EditTodoView(todo: Binding(
                    get: {
                        // Fetch the latest todo from the array using the ID
                        todos.first(where: { $0.id == todo.id }) ?? todo
                    },
                    set: { newValue in
                        if let index = todos.firstIndex(where: { $0.id == newValue.id }) {
                            todos[index] = newValue
                        }
                    }
                ))
            }
            .task { await fetchTodos() }
        }
    }
    
    // Toggle completion status
    private func toggleTodoCompletion(_ todo: Todo) async {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        do {
            // In toggleTodoCompletion
            try await todoService.updateTodo(
                id: todo.id,
                title: todo.title,          // Existing title
                description: todo.description, // Existing description
                isCompleted: !todo.is_completed // Toggled value
            )
            
            todos[index].is_completed.toggle() // Update local state
        } catch {
            print("Error updating todo: \(error)")
        }
    }
    private func fetchTodos() async {
        do {
            todos = try await todoService.fetchTodos()
        } catch {
            print("Error fetching todos: \(error)")
        }
    }
    // Remove the `deleteTodo` function
    // Keep `fetchTodos` and `toggleTodoCompletion`
}

struct AddTodoView: View {
    @Binding var todos: [Todo]
    @State private var title = ""
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss
    private let todoService = TodoService()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
                Button("Add Todo") {
                    Task { await addTodo() }
                }
            }
            .navigationTitle("New Todo")
        }
    }
    
    private func addTodo() async {
        do {
            let newTodo = try await todoService.createTodo(title: title, description: description)
            todos.append(newTodo)
            dismiss()
        } catch {
            print("Error adding todo: \(error)")
        }
    }
}
struct EditTodoView: View {
    @Binding var todo: Todo
    @Environment(\.dismiss) private var dismiss
    private let todoService = TodoService()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $todo.title)
                TextField("Description", text: $todo.description)
                
                Button("Save Changes") {
                    Task { await saveChanges() }
                }
            }
            .navigationTitle("Edit Todo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveChanges() async {
        do {
            
            print("Saving changes - Title: \(todo.title), Description: \(todo.description)")
            try await todoService.updateTodo(
                id: todo.id,
                title: todo.title,
                description: todo.description,
                isCompleted: todo.is_completed
            )
            dismiss()
        } catch {
            print("Error updating todo: \(error)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
    }
}


#Preview {
    TodoListView()
}
