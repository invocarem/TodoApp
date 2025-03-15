//
//  ContentView.swift
//  TodoApp
//
//  Created by Chen Chen on 2025-03-05.
//
import SwiftUI

struct ContentView: View {
    @State private var goal = Goal(
        id: UUID(uuidString: "522cf405-9581-49b4-b79b-049c99c70b9c")!,
        user_id: UUID(uuidString: "f5d94529-588c-43c6-897b-840ea20e4fad")!,
        title: "Learn SwiftUI",
        todos: [
            UUID(uuidString: "8e537e67-f643-4b4c-b0f5-5dc0ac7fc924")!,
            UUID(uuidString: "276b364f-781b-466e-b110-69ba5aefe793")!
        ]
    )

    var body: some View {
        NavigationStack {
            VStack{
                NavigationLink(destination: GoalListView(userId: $goal.user_id)) {
                    Text("Goals List")
                }
                //Spacer()
                NavigationLink(destination: TodoListView(goal: $goal))
                {
                    Text("Todos List")
                }
            }
            .padding()
        }
    }
    
}
/*
struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
    }
}
struct xGoal: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID  // If you have user management
    var name: String
    var description: String

    enum CodingKeys: String, CodingKey {
        case id = "goal_id"
        case userId = "user_id"
        case name
        case description
    }
}

struct xTodo: Identifiable, Codable, Hashable{
    let id: UUID
    let goalId: UUID
    var title: String
    var description: String
    var is_completed: Bool
    enum CodingKeys: String, CodingKey {
        case id = "todo_id"
        case goalId = "goal_id"
        case title
        case description
        case is_completed
    }
    
}

struct TodoUpdateRequest: Encodable {
    let title: String
    let description: String
    let is_completed: Bool
}

class xTodoService {
    private let baseURL = "http://192.168.1.71:3000" // Replace with your Windows IP
    private var activeTasks = [URLSessionTask]()
       
       // Add this to prevent task cancellation
       private func trackTask(_ task: URLSessionTask) {
           activeTasks.append(task)
           task.resume()
       }
    
    
    

        func fetchTodos(for goalId: UUID) async throws -> [Todo] {
            print("1. Starting fetchTodos for goalId: \(goalId)")
            
            guard let url = URL(string: "\(baseURL)/todos?goal_id=\(goalId.uuidString)") else {
                print("2. Invalid URL")
                throw URLError(.badURL)
            }
            
            print("3. URL is valid: \(url.absoluteString)")
            
            return try await withCheckedThrowingContinuation { continuation in
                print("4. Creating URLSession task")
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    // Remove task from active tasks
                    self.activeTasks.removeAll { $0 == task }
                    
                    print("5. Task completed with data: \(data != nil), error: \(error?.localizedDescription ?? "none")")
                    
                    if let error = error {
                        print("6. Network error: \(error)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let data = data else {
                        print("7. No data received")
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    do {
                        let todos = try JSONDecoder().decode([Todo].self, from: data)
                        print("8. Successfully decoded \(todos.count) todos")
                        continuation.resume(returning: todos)
                    } catch {
                        print("9. Decoding error: \(error)")
                        print("10. Raw response: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
                        continuation.resume(throwing: error)
                    }
                }
                
                print("11. Tracking task")
                trackTask(task) // Retain the task
            }
        }
    
    // Check if user exists by name
    func findUserByName(name: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/users/by-name/\(name)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        print("user: " , name)
        print(url)
        // Handle HTTP errors (e.g., 404)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(User.self, from: data)
        case 404:
            throw NSError(domain: "UserError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        default:
            throw URLError(.badServerResponse)
        }
    }
    
    func login(name: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }
    func fetchUser(userId: UUID) async throws -> User {
        guard let url = URL(string: "\(baseURL)/users/\(userId.uuidString)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
    func fetchGoalsnew(for userId: UUID) async throws -> [Goal] {
            guard let url = URL(string: "\(baseURL)/goals?user_id=\(userId.uuidString)") else {
                throw URLError(.badURL)
            }
            
            let request = URLRequest(
                url: url,
                timeoutInterval: 15
            )
            
            return try await withCheckedThrowingContinuation { continuation in
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    // Similar error handling as above
                    // ...
                }
                trackTask(task)
            }
        }
    func fetchGoals(for userId: UUID) async throws -> [Goal] {
        guard let url = URL(string: "\(baseURL)/goals?user_id=\(userId.uuidString)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Log the raw JSON response
        let jsonString = String(data: data, encoding: .utf8)
        print("Fetched Raw Goals JSON: \(jsonString ?? "Invalid data")")
        
        return try JSONDecoder().decode([Goal].self, from: data)
    }
    
    func fetchGoalsxxxx() async throws -> [Goal] {
        guard let url = URL(string: "\(baseURL)/goals") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Goal].self, from: data)
    }
    func fetchxxxTodos(for goalId: UUID) async throws -> [Todo] {
        print("1. Starting fetchTodos for goalId: \(goalId)")
        
        guard let url = URL(string: "\(baseURL)/todos?goal_id=\(goalId.uuidString)") else {
            print("2. Invalid URL")
            throw URLError(.badURL)
        }
        
        print("3. URL is valid: \(url.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            print("4. Creating URLSession task")
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                print("5. Task completed with data: \(data != nil), error: \(error?.localizedDescription ?? "none")")
                
                // Ensure the continuation is resumed exactly once
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                do {
                    let todos = try JSONDecoder().decode([Todo].self, from: data)
                    print("6. Successfully decoded \(todos.count) todos")
                    continuation.resume(returning: todos)
                } catch {
                    print("7. Decoding error: \(error)")
                    print("8. Raw response: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
                    continuation.resume(throwing: error)
                }
            }
            
            print("6. Starting task")
            task.resume()
        }
    }
    func fetchTodos0(for goalId: UUID) async throws -> [Todo] {
        print("1. Starting fetchTodos for goalId: \(goalId)")
        
        guard let url = URL(string: "\(baseURL)/todos?goal_id=\(goalId.uuidString)") else {
            print("2. Invalid URL")
            throw URLError(.badURL)
        }
        
        print("3. URL is valid: \(url.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            print("4. Creating URLSession task")
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                print("5. Task completed with data: \(data != nil), error: \(error?.localizedDescription ?? "none")")
                
                // ... rest of the completion handler
            }
            
            print("6. Tracking task")
            trackTask(task)
        }
    }
    func fetchTodos111(for goalId: UUID) async throws -> [Todo] {
        print ("fetchTodos for \(goalId)")
        guard let url = URL(string: "\(baseURL)/todos?goal_id=\(goalId.uuidString)") else {
            throw URLError(.badURL)
        }
        print("Fetching todos from: \(url.absoluteString)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Todo].self, from: data)
        
    }
    func fetchTodosNoGoalId() async throws -> [Todo] {
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
struct xTodoListView: View {
    let goalId: UUID
    @State private var todos = [Todo]()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if !todos.isEmpty {
                List(todos) { todo in
                    Text(todo.title)
                }
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
            } else {
                Text("No todos found")
            }
        }
        .navigationTitle("Todos")
        .task {
            print("Loading todos for goalId: \(goalId)")
            await loadTodos()
        }
    }
    
    private func loadTodos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            todos = try await TodoService().fetchTodos(for: goalId)
        } catch {
            errorMessage = error.localizedDescription
            print("Todo loading failed: \(error)")
        }
    }
}

struct TodoListView0: View {
    let goalId: UUID
    @State private var todos = [Todo]()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if !todos.isEmpty {
                List(todos) { todo in
                    Text(todo.title)
                }
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
            } else {
                Text("No todos found")
            }
        }
        .navigationTitle("Todos")
        .task {
            await loadTodos()
        }
    }
    
    private func loadTodos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("loading todos for goal \(goalId) ...")
            todos = try await TodoService().fetchTodos(for: goalId)
        } catch {
            errorMessage = error.localizedDescription
            print("Todo loading failed: \(error)")
        }
    }
}
struct TodoListViewOld: View {
    let goalId: UUID
    @State private var todos: [Todo] = []
    @State private var showAddTodoSheet = false
    @State private var editTodo: Todo?
    private let todoService = xTodoService()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todos) { todo in
                    HStack {
                        Image(systemName: todo.is_completed ? "checkmark.circle.fill" : "circle")
                                                .onAppear {
                                                    print("Rendering image for todo: \(todo.id)")
                                                }
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
            .onAppear {
                print("todo appeared") // Track cell rendering
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
            .task { await loadTodos() }
        }
        
    }
    private func loadTodos() async {
        do {
            print("load todos...", goalId)
            todos = try await todoService.fetchTodos(for: goalId)
        } catch {
            print("Failed to fetch todos: \(error)")
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
    
    // Remove the `deleteTodo` function
    // Keep `fetchTodos` and `toggleTodoCompletion`
}

struct AddTodoView: View {
    @Binding var todos: [Todo]
    @State private var title = ""
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss
    private let todoService = xTodoService()
    
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
    private let todoService = xTodoService()
    
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

struct UserView: View {
    let userId: UUID
    @State private var goals: [Goal] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let todoService = xTodoService()

    var body: some View {
        NavigationStack {
            // Main content container
            Group {
                if !goals.isEmpty {
                    List(goals) { goal in
                        NavigationLink(value: goal) {
                            VStack(alignment: .leading) {
                                Text(goal.name).font(.headline)
                                Text(goal.description).font(.subheadline)
                            }
                        }
                        .onAppear {
                            print("Goal cell appeared: \(goal.name)")
                        }
                    }
                } else if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                } else {
                    Text("No goals found")
                }
            }
            .navigationTitle("User Goals")
            .navigationDestination(for: Goal.self) { goal in
                TodoListView(goalId: goal.id)  // This must be INSIDE the NavigationStack
            }
        }
        .task {
            await loadGoals()
        }
    }

    private func loadGoals() async {
        isLoading = true
        defer { isLoading = false }
        do {
            print("load goals for \(userId)")
            goals = try await todoService.fetchGoals(for: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("Decoding Error: \(error)")
        }
    }
}


struct LoginView: View {
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedInUser: User?
    private let todoService = xTodoService()

    // Computed Binding for login state
    private var isLoggedIn: Binding<Bool> {
        Binding<Bool>(
            get: { loggedInUser != nil },
            set: { newValue in
                if !newValue {
                    loggedInUser = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Button("Login") {
                    Task { await login() }
                }
                .disabled(name.isEmpty)
            }
            .navigationTitle("Login")
            .navigationDestination(isPresented: isLoggedIn) {
                if let user = loggedInUser {
                    UserView(userId: user.id)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func login() async {
        
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await todoService.findUserByName(name: name)
            loggedInUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
        
        
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}


#Preview {
    LoginView()
}
*/
