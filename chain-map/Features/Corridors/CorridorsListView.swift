import SwiftUI

struct CorridorsListView: View {
    @StateObject private var viewModel = CorridorsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(lastUpdatedText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if viewModel.isStale {
                            Text("Stale")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                }

                ForEach(viewModel.corridors) { corridor in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle()
                                .fill(color(for: corridor.status.severity))
                                .frame(width: 10, height: 10)
                            Text(corridor.label)
                                .font(.headline)
                        }

                        Text(corridor.status.headline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Chain Map")
            .toolbar {
                Button("Refresh") {
                    viewModel.manualRefresh()
                }
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

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else {
            return "Last updated: --"
        }

        return "Last updated: \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    private func color(for severity: CorridorSeverity) -> Color {
        switch severity {
        case .ok:
            return .green
        case .caution:
            return .orange
        case .chains:
            return .red
        case .closed:
            return .black
        case .unknown:
            return .gray
        }
    }
}

#Preview {
    CorridorsListView()
}
