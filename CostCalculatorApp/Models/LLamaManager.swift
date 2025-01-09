//
//  LocalLlama.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-10-16.
//

import Foundation


//class LlamaManager {
//    func runLlamaModel(prompt: String) async throws {
//        do {
//            // Initialize the model in a try-catch block
//            if let modelURL = Bundle.main.url(forResource: "qwen2.5-1.5b-instruct-q3_k_m", withExtension: "gguf") {
//                print("Model path: \(modelURL.path)")
//                let modelPath = modelURL.path
//                let model = try Model(modelPath: modelPath)
//                
//                let llama = LLama(model: model)
//                
//                // Call the infer function in an async context
//                for try await token in await llama.infer(prompt: prompt, maxTokens: 1024) {
//                    print(token, terminator: "")
//                }
//            } else {
//                print("Model file not found")
//            }
//            
//        } catch {
//            // Handle any errors here
//            print("Error occurred: \(error)")
//        }
//    }
//}

