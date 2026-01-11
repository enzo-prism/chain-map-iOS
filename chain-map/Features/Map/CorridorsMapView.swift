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
                ForEach(CorridorMapLocation.all) { location in
                    Annotation(location.label, coordinate: location.coordinate, anchor: .bottom) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(color(for: severity(for: location.id)))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                )

                            Text(location.shortLabel)
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

private struct CorridorMapLocation: Identifiable {
    let id: String
    let label: String
    let shortLabel: String
    let coordinate: CLLocationCoordinate2D

    static let all: [CorridorMapLocation] = [
        CorridorMapLocation(
            id: "i80-donner",
            label: "I-80 (Donner Summit)",
            shortLabel: "I-80",
            coordinate: CLLocationCoordinate2D(latitude: 39.3206, longitude: -120.3327)
        ),
        CorridorMapLocation(
            id: "us50-echo",
            label: "US-50 (Echo Summit)",
            shortLabel: "US-50",
            coordinate: CLLocationCoordinate2D(latitude: 38.8154, longitude: -120.0414)
        ),
        CorridorMapLocation(
            id: "ca88-carson",
            label: "CA-88 (Carson Pass)",
            shortLabel: "CA-88",
            coordinate: CLLocationCoordinate2D(latitude: 38.7056, longitude: -119.9880)
        ),
        CorridorMapLocation(
            id: "ca89-tahoe",
            label: "CA-89 (Tahoe Basin)",
            shortLabel: "CA-89",
            coordinate: CLLocationCoordinate2D(latitude: 38.9619, longitude: -120.0860)
        ),
        CorridorMapLocation(
            id: "ca28-laketahoe",
            label: "CA-28 (Lake Tahoe)",
            shortLabel: "CA-28",
            coordinate: CLLocationCoordinate2D(latitude: 39.1686, longitude: -120.1429)
        ),
        CorridorMapLocation(
            id: "ca267-kings",
            label: "CA-267 (Truckee to Kings Beach)",
            shortLabel: "CA-267",
            coordinate: CLLocationCoordinate2D(latitude: 39.3312, longitude: -120.1701)
        ),
        CorridorMapLocation(
            id: "nv431-mtrose",
            label: "NV-431 (Mt Rose Hwy)",
            shortLabel: "NV-431",
            coordinate: CLLocationCoordinate2D(latitude: 39.3293, longitude: -119.8854)
        ),
        CorridorMapLocation(
            id: "us395-reno",
            label: "US-395 (Reno/Sierra)",
            shortLabel: "US-395",
            coordinate: CLLocationCoordinate2D(latitude: 39.5296, longitude: -119.8138)
        ),
        CorridorMapLocation(
            id: "nv28-laketahoe",
            label: "NV-28 (Lake Tahoe)",
            shortLabel: "NV-28",
            coordinate: CLLocationCoordinate2D(latitude: 39.2405, longitude: -119.9433)
        ),
        CorridorMapLocation(
            id: "nv267-brockway",
            label: "NV-267 (Brockway Summit)",
            shortLabel: "NV-267",
            coordinate: CLLocationCoordinate2D(latitude: 39.3115, longitude: -119.9596)
        ),
        CorridorMapLocation(
            id: "sr207-kingsbury",
            label: "SR-207 (Kingsbury Grade)",
            shortLabel: "SR-207",
            coordinate: CLLocationCoordinate2D(latitude: 38.9341, longitude: -119.8804)
        )
    ]
}

#Preview {
    CorridorsMapView()
}
