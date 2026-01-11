import MapKit
import SwiftUI

struct CorridorsMapView: View {
    @StateObject private var viewModel = CorridorsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingAbout = false
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
                    if corridor.polyline.count > 1 {
                        let polyline = MKPolyline(
                            coordinates: corridor.polyline,
                            count: corridor.polyline.count
                        )
                        MapPolyline(polyline)
                            .stroke(
                                color(for: severity(for: corridor.id)).opacity(0.7),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                            )
                    }
                }

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

            VStack(alignment: .leading, spacing: 8) {
                statusOverlay
                legendOverlay
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

    private var statusOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Chain Map")
                    .font(.headline)

                Button("Refresh") {
                    viewModel.manualRefresh()
                }
                .font(.caption)

                Button("About") {
                    isShowingAbout = true
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
        .sheet(isPresented: $isShowingAbout) {
            AboutDataView()
        }
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

    private var legendOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Drive Safety")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                legendItem(label: "Clear", color: color(for: .ok))
                legendItem(label: "Caution", color: color(for: .caution))
                legendItem(label: "Chains", color: color(for: .chains))
                legendItem(label: "Closed", color: color(for: .closed))
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.leading, 16)
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 14, height: 4)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AboutDataView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About the data")
                        .font(.title3)
                        .bold()

                    Text("Chain Map pulls live chain control data from Caltrans QuickMap. The app fetches the KML feed every few minutes and caches the last result on your device so it can still show something offline.")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to read the map")
                            .font(.headline)
                        Text("Colored corridor lines indicate driving safety conditions: green is clear, orange is caution, red means chains required, black means closed. Gray means no recent chain-control data was available for that corridor.")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Accuracy")
                            .font(.headline)
                        Text("Data is informational and can lag or change quickly. Always follow official guidance and roadside signage.")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Data Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CorridorsMapView()
}
