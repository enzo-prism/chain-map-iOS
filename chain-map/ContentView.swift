//
//  ContentView.swift
//  chain-map
//
//  Created by Enzo on 1/10/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CorridorsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            CorridorsMapView(viewModel: viewModel)
                .tabItem {
                    Label("Map", systemImage: AppSymbol.tabMap)
                }

            CorridorsListView(viewModel: viewModel)
                .tabItem {
                    Label("Status", systemImage: AppSymbol.tabStatus)
                }
        }
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.startPolling()
            } else {
                viewModel.stopPolling()
            }
        }
    }
}

#Preview {
    ContentView()
}
