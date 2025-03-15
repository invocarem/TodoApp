import SwiftUI
import SwiftUI

struct TodoListView: View {
    @Binding var goal: Goal
    @State private var fetchedTodos: [Todo] = [] // Store fetched Todo objects
    @State private var isLoading = false // Track loading state
    @State private var errorMessage: String? // Store error messages
    
    
    @State private var isAddingTodo = false
    @State private var newTodoTitle = ""
    
    var body: some View {
        VStack {
            List {
                if isLoading {
                    ProgressView("Loading todos...") // Show a loading indicator
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)") // Show error message
                } else {
                    ForEach(fetchedTodos.indices, id: \.self) { index in
                        HStack {
                            Text(fetchedTodos[index].title) // Display the title of each todo
                            Spacer()
                            Picker("", selection: $fetchedTodos[index].isCompleted) {
                                Text("Not Completed").tag(false)
                                Text("Completed").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                            .onChange(of: fetchedTodos[index].isCompleted) { is_completed in
                                updateTodoCompletion(todo: fetchedTodos[index], isCompleted: is_completed)
                            }
                        }
                    }
                    
                }
            }
            .onAppear {
                fetchTodos() // Fetch todos when the view appears
            }
            .navigationTitle(goal.title)
            
            Button(action: {
                isAddingTodo = true
            }) {
                Text("Add Todo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            Button(action: {
                saveTodosAsPDF()
            }) {
                Text("Save as PDF")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $isAddingTodo) {
            VStack {
                TextField("Enter todo title", text: $newTodoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Add Todo") {
                    print("add todo")
                    let newTodo = Todo(goal_id: goal.id, title: newTodoTitle, isCompleted: false)
                    fetchedTodos.append(newTodo)
                    
                    TodoService.shared.createTodo(goalId: goal.id, title: newTodoTitle) { todo, success in
                        if todo == nil  {
                            print("Failed to save new todo.")
                        }
                    }
                    newTodoTitle = ""
                    isAddingTodo = false
                }
                .padding()
            }
            .padding()
        }
        
    }

    private func fetchTodos() {
        isLoading = true
        errorMessage = nil
        
        let dispatchGroup = DispatchGroup() // To handle multiple async requests
        var tempTodos: [Todo] = []
        dispatchGroup.enter()
        TodoService.shared.fetchTodo(for: goal.id) { todos in
            tempTodos = todos!
            dispatchGroup.leave() // End the task
        }
        
        // Notify when all tasks are complete
        dispatchGroup.notify(queue: .main) {
            isLoading = false
            print("fetch todos completed!!!")
            if tempTodos.isEmpty {
                errorMessage = "No todos found or failed to fetch todos."
            } else {
                fetchedTodos = tempTodos
            }
        }
    }
    private func updateTodoCompletion(todo: Todo, isCompleted: Bool) {
        // Update the todo completion status in your backend or local storage
        var updatedTodo = todo
        updatedTodo.isCompleted = isCompleted
        TodoService.shared.updateTodo(updatedTodo)  { todo2, error in
            if let error = error {
                        print("Failed to update todo: \(error.localizedDescription)")
                        return
                    }
                    
            if let updatedTodo = todo2 {
                        print("Todo updated successfully: \(updatedTodo.title)")
                    } else {
                        print("Failed to update todo: No data returned.")
                    }
        }
    }
    func saveTodosAsPDF() {
        let pdfData = createPDFData()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent("\(goal.title)_Todos.pdf")
        
        do {
            try pdfData.write(to: pdfURL)
            print("PDF saved to: \(pdfURL)")
        } catch {
            print("Error saving PDF: \(error)")
        }
    }
    
    func createPDFData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // A4 size
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
            var yPosition: CGFloat = 50
            
            for todo in fetchedTodos {
                let todoText = "\(todo.title) - \(todo.isCompleted ? "Completed" : "Not Completed")"
                todoText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                yPosition += 20
            }
        }
        
        return data
    }
}

/*
struct xTodoListView: View {
    @Binding var goal: Goal
    
    
    @State private var isAddingTodo = false
    @State private var newTodoTitle = ""
    
    var body: some View {
        VStack {
            List {
                ForEach($goal.todos) { $todo in
                    HStack {
                        TextField("Todo", text: $todo.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Spacer()
                        Button(action: {
                            todo.isCompleted.toggle()
                            TodoService.shared.updateTodo(todo) { updatedTodo, error in
                                if let error = error {
                                    print("Error updating todo: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? .green : .gray)
                        }
                    }
                }
                .onDelete(perform: deleteTodo)
            }
            
            Button(action: {
                isAddingTodo = true
            }) {
                Text("Add Todo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            Button(action: {
                saveTodosAsPDF()
            }) {
                Text("Save as PDF")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle(goal.title)
        .sheet(isPresented: $isAddingTodo) {
            VStack {
                TextField("Enter todo title", text: $newTodoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Add Todo") {
                    let newTodo = Todo(goal_id: goal.id, title: newTodoTitle, isCompleted: false)
                    goal.todos.append(newTodo)
                    newTodoTitle = ""
                    isAddingTodo = false
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func deleteTodo(at offsets: IndexSet) {
        goal.todos.remove(atOffsets: offsets)
    }
    
    func saveTodosAsPDF() {
        let pdfData = createPDFData()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent("\(goal.title)_Todos.pdf")
        
        do {
            try pdfData.write(to: pdfURL)
            print("PDF saved to: \(pdfURL)")
        } catch {
            print("Error saving PDF: \(error)")
        }
    }
    
    func createPDFData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // A4 size
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
            var yPosition: CGFloat = 50
            
            for todo in goal.todos {
                let todoText = "\(todo.title) - \(todo.isCompleted ? "Completed" : "Not Completed")"
                todoText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                yPosition += 20
            }
        }
        
        return data
    }
}
*/
