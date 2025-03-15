//
//  TodoService.swift
//  TodoApp
//
//  Created by Chen Chen on 2025-03-11.
//

import Foundation
struct Todo: Identifiable, Decodable {
    let id: UUID
    var goal_id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), goal_id: UUID = UUID(), title:String, isCompleted:Bool = false) {
        self.id = id
        self.goal_id = goal_id
        self.title = title
        self.isCompleted = isCompleted
        
    }
    enum CodingKeys: String, CodingKey {
        case id
        case goal_id
        case title
        case isCompleted = "is_completed"
    }
}

class TodoService {
    static let shared = TodoService() // Singleton instance

    private let baseURL = URL(string: "http://192.168.1.71:3000")!

    // Fetch a single Todo by its UUID
    func fetchTodo(for goalId: UUID, completion: @escaping ([Todo]?) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/todos" // Add the path component
        components.queryItems = [URLQueryItem(name: "goal_id", value: goalId.uuidString)]
        let url = components.url!
        //let url = baseURL.appendingPathComponent("todos/\(todoId.uuidString)")
        print("Fetching todo from URL: \(url)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching todo: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received for todo")
                completion(nil)
                return
            }

            // Debug: Print raw JSON data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON data for todo: \(jsonString)")
            }

            // Decode the JSON data
            do {
                // Try to decode an array of Todo objects
                let todos = try JSONDecoder().decode([Todo].self, from: data)
                completion(todos)
            } catch {
                print("Decoding error for todo: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - Create a Todo
    func createTodo(goalId: UUID, title: String, completion: @escaping (Todo?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("todos")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["goal_id": goalId.uuidString, "title": title]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        print(request, goalId.uuidString, body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let todo = try JSONDecoder().decode(Todo.self, from: data)
                completion(todo, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Update a Todo
    func updateTodo(_ todo: Todo, completion: @escaping (Todo?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("todos/\(todo.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("update todo goal_id: \(todo.goal_id), id: \(todo.id), is_completed: \(todo.isCompleted)")
        
        let body: [String: Any] = ["title": todo.title, "is_completed": todo.isCompleted]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let updatedTodo = try JSONDecoder().decode(Todo.self, from: data)
                completion(updatedTodo, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
}
class TodoServiceold {
    private let baseURL = URL(string: "http://192.168.1.71:3000")!
    
    // MARK: - Fetch Goals
    func fetchGoals(for userId: UUID, completion: @escaping ([Goal]?, Error?) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/goals" // Add the path component
        components.queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]
        let url = components.url!
        print("1. Starting fetchGoals for userId: \(userId)")
        print("2. URL: \(url)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("3. Network error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("3. No data received")
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            // Debug: Print raw JSON data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("4. Raw JSON data: \(jsonString)")
            }
            
            do {
                let goals = try JSONDecoder().decode([Goal].self, from: data)
                print("5. Successfully decoded \(goals.count) goals")
                completion(goals, nil)
            } catch {
                print("5. Decoding error: \(error)")
                completion(nil, error)
            }
        }.resume()
    }
    func fetchTodo(for todoId: UUID, completion: @escaping (Todo?) -> Void) {
        let url = URL(string: "http://192.168.1.71:3000/todos/\(todoId.uuidString)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching todo: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received for todo")
                completion(nil)
                return
            }

            do {
                let todo = try JSONDecoder().decode(Todo.self, from: data)
                completion(todo)
            } catch {
                print("Decoding error for todo: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    
    // MARK: - Fetch Todos for a Goal
    func fetchTodos(for goalId: UUID, completion: @escaping ([Todo]?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("goals/\(goalId)/todos")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let todos = try JSONDecoder().decode([Todo].self, from: data)
                completion(todos, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Create a Goal
    func createGoal(title: String, completion: @escaping (Goal?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("goals")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["title": title]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let goal = try JSONDecoder().decode(Goal.self, from: data)
                completion(goal, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Create a Todo
    func createTodo(goalId: UUID, title: String, completion: @escaping (Todo?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("todos")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("create todo url: \(url)")
        let body: [String: Any] = ["goal_id": goalId.uuidString, "title": title, "isCompleted": false]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let todo = try JSONDecoder().decode(Todo.self, from: data)
                completion(todo, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Update a Goal
    func updateGoal(_ goal: Goal, completion: @escaping (Goal?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("goals/\(goal.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["title": goal.title]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let updatedGoal = try JSONDecoder().decode(Goal.self, from: data)
                completion(updatedGoal, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Update a Todo
    func updateTodo(_ todo: Todo, completion: @escaping (Todo?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("todos/\(todo.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("update todo goal_id: \(todo.goal_id), id: \(todo.id), is_completed: \(todo.isCompleted)")
        let body: [String: Any] = ["title": todo.title, "is_completed": todo.isCompleted]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: -1, userInfo: nil))
                return
            }
            
            do {
                let updatedTodo = try JSONDecoder().decode(Todo.self, from: data)
                completion(updatedTodo, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // MARK: - Delete a Goal
    func deleteGoal(_ goalId: UUID, completion: @escaping (Error?) -> Void) {
        let url = baseURL.appendingPathComponent("goals/\(goalId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            completion(error)
        }.resume()
    }
    
    // MARK: - Delete a Todo
    func deleteTodo(_ todoId: UUID, completion: @escaping (Error?) -> Void) {
        let url = baseURL.appendingPathComponent("todos/\(todoId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            completion(error)
        }.resume()
    }
}
