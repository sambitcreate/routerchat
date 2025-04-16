//
//  ContentView.swift
//  Router Chat AI
//
//  Created by Sambit Biswas on 4/14/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorTheme) private var theme

    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Message.self, inMemory: true)
        .colorTheme(.light)
}