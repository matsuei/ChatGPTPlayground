//
//  ContentView.swift
//  ChatGPTPlayground
//
//  Created by Kenta Matsue on 2023/03/18.
//

import SwiftUI

struct ContentView: View {
    @State private var answer = ""
    @State private var isLoading = false
    @State private var inputedText = ""
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                TextField("Input your question", text: $inputedText)
                Button("Request", action: request)
                Text(answer)
            }
            .padding()
            if isLoading {
                LoadingView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func request() {
        Task {
            defer {
                isLoading = false
            }
            isLoading = true
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.allHTTPHeaderFields = ["Authorization": "Bearer $OPENAI_API_KEY"]
            let body: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "user",
                    "content": inputedText],
                ],
                "temperature": 0.7,
            ]
            let httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = httpBody
            let (data, response) = try await URLSession.shared.data(for: request)
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            do {
                let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
                print(gptResponse)
                answer = gptResponse.choices.first?.message.content ?? ""
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

struct LoadingView: View {
    var body: some View {
        VStack {
            Text("Wait for gpt...")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .font(.title)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
        .background(Color.gray.opacity(0.6))
    }
}
