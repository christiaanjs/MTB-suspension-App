//
//  BikeDesign.swift
//  MTBsuspension App
//
//  Copyright (C) 2026 Patrick Crowe Rishworth
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published
//  by the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct MTBSuspensionApp: App {
    @StateObject private var viewModel = BikeViewModel()
    @State private var showingSavePanel = false
    @State private var showingOpenPanel = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Design") {
                    viewModel.geometry = BikeGeometry()
                    viewModel.calculateKinematics()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save...") {
                    saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
    
    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "mtbsuspension")!]
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try viewModel.loadFromFile(url: url)
            } catch {
                print("Error loading file: \(error)")
            }
        }
    }
    
    private func saveFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "mtbsuspension")!]
        panel.nameFieldStringValue = "BikeDesign.mtbsuspension"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try viewModel.saveToFile(url: url)
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
}
