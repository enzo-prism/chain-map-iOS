import SwiftUI

struct CorridorsListView: View {
    @ObservedObject var viewModel: CorridorsViewModel
    private static let dateParser = ISO8601DateFormatter()
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(lastUpdatedText, systemImage: AppSymbol.lastUpdated)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if viewModel.isStale {
                                Label("Stale", systemImage: AppSymbol.stale)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(Color.orange)
                                    .clipShape(Capsule())
                            }
                        }

                        if let errorMessage = viewModel.lastErrorMessage {
                            Label(errorMessage, systemImage: AppSymbol.error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if viewModel.corridors.isEmpty {
                    Section {
                        Text("Loading corridor status...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.isSnowfallEnabled {
                    Section {
                        ForEach(viewModel.availableSnowfallPoints) { point in
                            SnowfallCardView(
                                point: point,
                                history: viewModel.snowfallHistory(for: point.id),
                                formatter: Self.relativeFormatter,
                                formatInches: viewModel.formatInches
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } header: {
                        Text("Snowfall (Last 7 Days)")
                    }
                }

                if !keyPathCorridors.isEmpty {
                    Section {
                        ForEach(keyPathCorridors) { corridor in
                            corridorRow(corridor, isKeyPath: true)
                        }
                    } header: {
                        Label("Key Paths", systemImage: AppSymbol.keyPaths)
                    }
                }

                if !otherCorridors.isEmpty {
                    Section {
                        ForEach(otherCorridors) { corridor in
                            corridorRow(corridor, isKeyPath: false)
                        }
                    } header: {
                        Label("All Corridors", systemImage: AppSymbol.allCorridors)
                    }
                }

                Section {
                    dataDisclaimer
                } header: {
                    Label("About the data", systemImage: AppSymbol.dataSource)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Status")
            .toolbar {
                Button {
                    viewModel.manualRefresh()
                } label: {
                    Label("Refresh", systemImage: AppSymbol.refresh)
                }
            }
        }
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else {
            return "Updated: --"
        }

        return "Updated \(Self.relativeFormatter.localizedString(for: date, relativeTo: Date()))"
    }

    private var keyPathCorridors: [CorridorSummary] {
        CorridorDefinition.keyPathIds.compactMap { id in
            viewModel.corridors.first(where: { $0.id == id })
        }
    }

    private var otherCorridors: [CorridorSummary] {
        let keyPathSet = Set(CorridorDefinition.keyPathIds)
        return viewModel.corridors.filter { !keyPathSet.contains($0.id) }
    }

    private func corridorRow(_ corridor: CorridorSummary, isKeyPath: Bool) -> some View {
        let details = Array(corridor.status.details.prefix(3))

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if isKeyPath {
                            Image(systemName: AppSymbol.keyPaths)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(corridor.label)
                            .font(.headline)
                    }

                    Text(corridor.status.headline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(severityLabel(for: corridor.status.severity), systemImage: AppSymbol.severitySymbol(for: corridor.status.severity))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color(for: corridor.status.severity).opacity(0.15))
                    .foregroundStyle(color(for: corridor.status.severity))
                    .clipShape(Capsule())
            }

            if !details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(details, id: \.self) { detail in
                        Text("- \(detail)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let snowfallSummary = viewModel.snowfallSummaryText(for: corridor.id) {
                Text(snowfallSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Label(updatedText(for: corridor), systemImage: AppSymbol.lastUpdated)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func updatedText(for corridor: CorridorSummary) -> String {
        if let date = Self.dateParser.date(from: corridor.status.lastUpdatedAt) {
            return "Updated \(Self.relativeFormatter.localizedString(for: date, relativeTo: Date()))"
        }

        if let fallback = viewModel.lastUpdatedAt {
            return "Updated \(Self.relativeFormatter.localizedString(for: fallback, relativeTo: Date()))"
        }

        return "Updated: --"
    }

    private func severityLabel(for severity: CorridorSeverity) -> String {
        switch severity {
        case .ok:
            return "Clear"
        case .caution:
            return "Caution"
        case .chains:
            return "Chains"
        case .closed:
            return "Closed"
        case .unknown:
            return "Unknown"
        }
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

    private var dataDisclaimer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chain Map pulls live chain control and lane closure data from Caltrans CWWP2 feeds. The app refreshes frequently and caches the last result on your device so it can still show something offline.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Data is informational and can lag or change quickly. Always follow official guidance and roadside signage.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct SnowfallCardView: View {
    let point: SnowfallPoint
    let history: SnowfallHistory?
    let formatter: RelativeDateTimeFormatter
    let formatInches: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(point.name)
                .font(.headline)

            if let history, !history.days.isEmpty {
                Text("Total: \(formatInches(history.total7DaysInches)) in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SnowfallBars(days: history.days)

                HStack(spacing: 8) {
                    Label(updatedText(for: history), systemImage: AppSymbol.lastUpdated)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if history.isStale {
                        Label("Stale", systemImage: AppSymbol.stale)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                Text("Estimated snowfall (model). Source: Open-Meteo.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Snowfall data unavailable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func updatedText(for history: SnowfallHistory) -> String {
        "Updated \(formatter.localizedString(for: history.updatedAt, relativeTo: Date()))"
    }
}

private struct SnowfallBars: View {
    let days: [SnowfallDay]

    var body: some View {
        let maxValue = days.map(\.snowfallInches).max() ?? 0
        let maxHeight: CGFloat = 36

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 8, height: barHeight(for: day, maxValue: maxValue, maxHeight: maxHeight))
                    .accessibilityLabel(dayAccessibilityLabel(day))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func barHeight(for day: SnowfallDay, maxValue: Double, maxHeight: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 4 }
        let ratio = day.snowfallInches / maxValue
        return max(4, maxHeight * CGFloat(ratio))
    }

    private func dayAccessibilityLabel(_ day: SnowfallDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateText = formatter.string(from: day.date)
        return "\(dateText), \(day.snowfallInches) inches"
    }
}

#Preview {
    CorridorsListView(viewModel: CorridorsViewModel())
}
