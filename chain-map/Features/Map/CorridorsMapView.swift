import MapKit
import SwiftUI

struct CorridorsMapView: View {
    @ObservedObject var viewModel: CorridorsViewModel
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
    }

    private var statusOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Chain Map")
                    .font(.headline)

                Button {
                    viewModel.manualRefresh()
                } label: {
                    Label("Refresh", systemImage: AppSymbol.refresh)
                }
                .font(.caption)

                Button {
                    isShowingAbout = true
                } label: {
                    Label("About", systemImage: AppSymbol.about)
                }
                .font(.caption)
            }

            Label(lastUpdatedText, systemImage: AppSymbol.lastUpdated)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if viewModel.isStale {
                Label("Stale data", systemImage: AppSymbol.stale)
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
                legendItem(label: "Clear", symbol: AppSymbol.severitySymbol(for: .ok), color: color(for: .ok))
                legendItem(label: "Caution", symbol: AppSymbol.severitySymbol(for: .caution), color: color(for: .caution))
                legendItem(label: "Chains", symbol: AppSymbol.severitySymbol(for: .chains), color: color(for: .chains))
                legendItem(label: "Closed", symbol: AppSymbol.severitySymbol(for: .closed), color: color(for: .closed))
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.leading, 16)
    }

    private func legendItem(label: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption2)
                .foregroundStyle(color)
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
                    Label("About the data", systemImage: AppSymbol.dataSource)
                        .font(.title3.weight(.semibold))

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
    CorridorsMapView(viewModel: CorridorsViewModel())
}
