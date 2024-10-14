//
//  SuffixTextField.swift
//  CostCalculatorApp
//
//  Created by Zishuo Li on 2024-09-25.
//

import SwiftUI

struct SuffixTextField: View {
    var label: String
    @Binding var text: String
    var suffix: String
    var keyboardType: UIKeyboardType = .default
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", text: $text, onEditingChanged: { editing in
                isEditing = editing
                if editing {
                    HapticFeedbackManager.shared.selectionChanged() // Add this line
                }
            })
            .keyboardType(keyboardType)
            if !suffix.isEmpty {
                Text(suffix)
                    .foregroundColor(.gray)
            }
        }
    }
}

