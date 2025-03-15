//
//  GoalView.swift
//  TodoApp
//
//  Created by Chen Chen on 2025-03-11.
//
import SwiftUI

struct Todo: Identifiable {
    let id = UUID()
    var goal_id: UUID
    var title: String
    var isCompleted: Bool
}

struct Goal: Identifiable {
    let id = UUID()
    var title: String
    var todos: [Todo]
}

struct GoalListView: View {
    @State private var goals: [Goal] = [
        Goal(title: "Learn SwiftUI", todos: [
            Todo(goal_id: UUID(), title: "Read SwiftUI documentation", isCompleted: false),
            Todo(goal_id: UUID(), title: "Build a sample app", isCompleted: false)
        ]),
        Goal(title: "Exercise", todos: [
            Todo(goal_id: UUID(), title: "Go for a run", isCompleted: false),
            Todo(goal_id: UUID(), title: "Do yoga", isCompleted: false)
        ])
    ]
    
    @State private var isAddingGoal = false
    @State private var newGoalTitle = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(goals) { goal in
                    NavigationLink(destination: TodoListView(goal: binding(for: goal))) {
                        Text(goal.title)
                    }
                }
                .onDelete(perform: deleteGoal)
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingGoal) {
                VStack {
                    TextField("Enter goal title", text: $newGoalTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Add Goal") {
                        let newGoal = Goal(title: newGoalTitle, todos: [])
                        goals.append(newGoal)
                        newGoalTitle = ""
                        isAddingGoal = false
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
    
    private func binding(for goal: Goal) -> Binding<Goal> {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else {
            fatalError("Goal not found")
        }
        return $goals[index]
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
}
struct TodoListView: View {
    var goal: Goal
    
    var body: some View {
        VStack {
            List {
                ForEach(goal.todos) { todo in
                    HStack {
                        Text(todo.title)
                        Spacer()
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(todo.isCompleted ? .green : .gray)
                    }
                }
            }
            
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
