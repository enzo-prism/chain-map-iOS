import MapKit
import SwiftUI

struct CorridorsMapView: View {
    @StateObject private var viewModel = CorridorsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.3, longitude: -120.7),
            span: MKCoordinateSpan(latitudeDelta: 3.5, longitudeDelta: 4.5)
        )
    )

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                ForEach(CorridorDefinition.all) { corridor in
                    Annotation(corridor.label, coordinate: corridor.coordinate, anchor: .bottom) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(color(for: severity(for: corridor.id)))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                )

                            Text(corridor.shortLabel)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)

            statusOverlay
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

    private var statusOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Chain Map")
                    .font(.headline)

                Button("Refresh") {
                    viewModel.manualRefresh()
                }
                .font(.caption)
            }

            Text(lastUpdatedText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if viewModel.isStale {
                Text("Stale data")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.leading, 16)
        .padding(.top, 12)
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else {
            return "Last updated: --"
        }

        return "Last updated: \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    private func severity(for corridorId: String) -> CorridorSeverity {
        viewModel.corridors.first(where: { $0.id == corridorId })?.status.severity ?? .unknown
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
    CorridorsMapView()
}
