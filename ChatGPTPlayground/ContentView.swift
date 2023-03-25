//
//  ContentView.swift
//  ChatGPTPlayground
//
//  Created by Kenta Matsue on 2023/03/18.
//

import SwiftUI

struct ContentView: View {
    @State private var answer = ""
    @State private var inputedText = ""
    @State private var messages: [[String: String]] = []
    
    var body: some View {
        List(messages, id: \.self) { message in
            if message["role"] == "user" {
                Section {
                    HStack {
                        Spacer()
                        Text(message["content"] ?? "")
                    }
                }
            } else {
                Section {
                    HStack {
                        Text(message["content"] ?? "")
                        Spacer()
                    }
                }
            }
        }
        ZStack {
            HStack() {
                TextField("Input your question", text: $inputedText)
                Spacer()
                Button("Request", action: request)
            }
            .padding()
        }
    }
    
    private func request() {
        messages.append(["role": "user",
                         "content": inputedText])
        messages.append(["role": "assistant",
                         "content": "考えてます…"])
        Task {
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.allHTTPHeaderFields = ["Authorization": "Bearer $OPENAI_API_KEY"]
            let body: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": messages,
                "temperature": 0.7,
            ]
            let httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = httpBody
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
                _ = messages.removeLast()
                answer = gptResponse.choices.last?.message.content ?? ""
                messages.append(["role": "assistant",
                                 "content": answer])
                inputedText = ""
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct GPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: [String: Int]
    let choices: [GPTResponseChoice]
}

struct GPTResponseChoice: Codable {
    let message: GPTResponseMessage
    let finish_reason: String
    let index: Int
}

struct GPTResponseMessage: Codable {
    let role: String
    let content: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
