import Foundation
import SwiftUI

// The seven arcade games use independent preference domains. These are
// personal-best records, not a cross-game numerical ranking: scoring systems
// differ between cabinets.
private struct ArcadeScoreSpec: Identifiable {
    let id: String
    let title: String
    let bundleID: String
    let scoreKey: String
    let initialsKey: String?
    let accent: Color

    static let games: [ArcadeScoreSpec] = [
        .init(id: "drift", title: "VECTOR DRIFT",
              bundleID: "io.vectordrift.prototype",
              scoreKey: "highScore", initialsKey: "vectorDriftHighScoreInitials.v1",
              accent: .cyan),
        .init(id: "siege", title: "VECTOR SIEGE",
              bundleID: "io.vectorsiege.game",
              scoreKey: "VectorSiegeHighScore", initialsKey: nil,
              accent: .green),
        .init(id: "vortex", title: "VECTOR VORTEX",
              bundleID: "io.vectorvortex.game",
              scoreKey: "vectorVortex.highscore.v1", initialsKey: nil,
              accent: .pink),
        .init(id: "swarm", title: "VECTOR SWARM",
              bundleID: "io.vectorswarm.game",
              scoreKey: "VectorSwarm.High.v1", initialsKey: nil,
              accent: .purple),
        .init(id: "barrage", title: "VECTOR BARRAGE",
              bundleID: "io.vectorbarrage.game",
              scoreKey: "VectorBarrage.highScore.v1",
              initialsKey: "VectorBarrage.highScoreInitials.v1",
              accent: .orange),
        .init(id: "soar", title: "VECTOR SOAR",
              bundleID: "io.vectorsoar.game",
              scoreKey: "VectorSoar.HighScore", initialsKey: nil,
              accent: .cyan),
        .init(id: "aces", title: "VECTOR ACES",
              bundleID: "io.vectoraces.game",
              scoreKey: "VectorAces.HighScore.v1", initialsKey: nil,
              accent: .yellow)
    ]
}

private struct ArcadeScore: Identifiable {
    let id: String
    let title: String
    let score: Int?
    let initials: String?
    let accent: Color
}

@MainActor
private final class ArcadeHighScoreStore: ObservableObject {
    @Published private(set) var entries: [ArcadeScore] = []
    @Published private(set) var checkedAt: Date?

    func refresh() {
        entries = ArcadeScoreSpec.games.map { spec in
            // UserDefaults(suiteName:) addresses the other app's preference
            // domain in a non-sandboxed macOS launcher. No file modification,
            // network fetch, or permissions escalation is involved.
            let defaults = UserDefaults(suiteName: spec.bundleID)
            let stored = defaults?.object(forKey: spec.scoreKey)
            let score = (stored as? NSNumber)?.intValue
            let rawInitials = spec.initialsKey.flatMap { defaults?.string(forKey: $0) }
            let initials = rawInitials.flatMap { value -> String? in
                let sanitized = String(value.uppercased().filter { $0.isLetter }.prefix(3))
                return sanitized.isEmpty || sanitized == "---" ? nil : sanitized
            }
            return ArcadeScore(id: spec.id, title: spec.title,
                               score: score.flatMap { $0 > 0 ? $0 : nil },
                               initials: initials, accent: spec.accent)
        }
        checkedAt = Date()
    }
}

struct FunCityHighScoresView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ArcadeHighScoreStore()

    private let amber = Color(red: 1.0, green: 0.67, blue: 0.27)
    private let background = Color(red: 0.035, green: 0.045, blue: 0.09)
    private var recordedCount: Int { store.entries.filter { $0.score != nil }.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Label("BACK TO ARCADE", systemImage: "arrow.left")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .tint(amber)
                Spacer()
                Button { store.refresh() } label: {
                    Label("REFRESH SCORES", systemImage: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .tint(amber)
                .help("Re-read local personal bests after playing a game")
            }
            .padding(20)
            Rectangle().fill(amber.opacity(0.3)).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("FUN CITY  /  THE HALL OF FAME")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(amber)
                    Text("HIGH SCORES")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .shadow(color: .pink.opacity(0.65), radius: 13)
                    Text("THREE LETTERS. ENDLESS BRAGGING RIGHTS.")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.cyan)
                    Text("Personal bests saved by your games on this Mac. Each cabinet has its own scoring system; scores are not ranked against different games.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Label("\(recordedCount) OF 7 RECORDS", systemImage: "trophy")
                        Spacer()
                        Text("LOCAL ARCADE RECORDS")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(amber)
                    .padding(13)
                    .background(amber.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 14)], spacing: 14) {
                        ForEach(store.entries) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.score == nil ? "arcade.stick.console" : "trophy.fill")
                                    .foregroundStyle(item.accent)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(.white)
                                    if let score = item.score {
                                        Text(score.formatted())
                                            .font(.system(size: 23, weight: .black, design: .monospaced))
                                            .monospacedDigit()
                                            .foregroundStyle(item.accent)
                                        Text(item.initials.map { "PLAYER \($0)" } ?? "PERSONAL BEST")
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.6))
                                    } else {
                                        Text("NO RECORD YET")
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.62))
                                        Text("Play this cabinet to set a record")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.48))
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, minHeight: 114, alignment: .leading)
                            .background(Color(red: 0.075, green: 0.085, blue: 0.15),
                                        in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13)
                                .stroke(item.accent.opacity(0.25), lineWidth: 1))
                        }
                    }
                    Text("Records are read from the local preferences of the individual games. Missing or inaccessible records are shown as NO RECORD YET. Newly added score persistence appears after a game saves a new record.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.48))
                        .fixedSize(horizontal: false, vertical: true)
                    Button { dismiss() } label: {
                        Label("RETURN TO THE ARCADE", systemImage: "gamecontroller.fill")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(amber)
                    .padding(.bottom, 18)
                }
                .padding(26)
                .frame(maxWidth: 850, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(background)
        }
        .frame(minWidth: 640, idealWidth: 890, minHeight: 540, idealHeight: 750)
        .preferredColorScheme(.dark)
        .onAppear { store.refresh() }
    }
}
