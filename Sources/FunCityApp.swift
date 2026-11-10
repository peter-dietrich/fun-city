import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct FunCityApp: App {
    var body: some Scene {
        WindowGroup("Fun City") {
            ArcadeLobby().preferredColorScheme(.dark).frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 770)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

private struct ArcadeGame: Codable, Identifiable {
    var id: String
    var title: String
    var tagline: String
    var description: String
    var bundleID: String?
    var appPath: String?
    var artwork: String
    var builtIn: Bool

    static let featured: [ArcadeGame] = [
        ArcadeGame(id: "drift", title: "VECTOR DRIFT", tagline: "SPACE COMBAT / 1 PLAYER",
                   description: "Asteroids, black holes, hyperspace and one more wave.",
                   bundleID: "io.vectordrift.prototype", appPath: nil, artwork: "space", builtIn: true),
        ArcadeGame(id: "siege", title: "VECTOR SIEGE", tagline: "TANK COMBAT / 1 PLAYER",
                   description: "Defend the horizon from a wireframe tank cockpit.",
                   bundleID: "io.vectorsiege.game", appPath: nil, artwork: "tank", builtIn: true),
        ArcadeGame(id: "vortex", title: "VECTOR VORTEX", tagline: "TUBE SHOOTER / 1 PLAYER",
                   description: "Ride the rim, vaporize the climbers, survive the neon vortex.",
                   bundleID: "io.vectorvortex.game", appPath: nil, artwork: "vortex", builtIn: true)
    ]

    var accent: Color {
        artwork == "tank" ? Color(red: 0.51, green: 1, blue: 0.59)
        : artwork == "space" ? Color(red: 0.45, green: 0.82, blue: 1)
        : artwork == "vortex" ? Color(red: 1, green: 0.30, blue: 0.77)
        : Color(red: 1, green: 0.72, blue: 0.39)
    }
}

@MainActor
private final class ArcadeLibrary: ObservableObject {
    @Published var games: [ArcadeGame]
    @Published var message: String?
    private let key = "FunCity.Library.v1"

    init() {
        let stored = UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([ArcadeGame].self, from: $0) } ?? []
        var library = stored
        for game in ArcadeGame.featured where !library.contains(where: { $0.id == game.id }) {
            library.append(game)
        }
        games = library
    }

    func location(for game: ArcadeGame) -> URL? {
        if let path = game.appPath {
            let url = URL(fileURLWithPath: path)
            if url.pathExtension.lowercased() == "app",
               FileManager.default.fileExists(atPath: url.path) { return url }
        }
        if let identifier = game.bundleID {
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier)
        }
        return nil
    }

    func play(_ game: ArcadeGame) {
        guard let url = location(for: game) else {
            message = "Build \(game.title) in Xcode, then use Locate Game to choose the built .app."
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async { self?.message = "Launch failed: \(error.localizedDescription)" }
            }
        }
    }

    func locate(_ game: ArcadeGame) {
        guard let url = pickApplication() else { return }
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].appPath = url.path
        save()
    }

    func add() -> String? {
        guard let url = pickApplication() else { return nil }
        let bundle = Bundle(url: url)
        let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let entry = ArcadeGame(id: UUID().uuidString, title: name.uppercased(),
                               tagline: "GUEST CABINET / FREE PLAY",
                               description: "An additional game in your personal arcade.",
                               bundleID: bundle?.bundleIdentifier, appPath: url.path,
                               artwork: "generic", builtIn: false)
        games.append(entry)
        save()
        return entry.id
    }

    func remove(_ game: ArcadeGame) {
        guard !game.builtIn else { return }
        games.removeAll { $0.id == game.id }
        save()
    }

    private func pickApplication() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a game application"
        panel.message = "Select the .app from Applications or Xcode's Build/Products/Debug folder."
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              url.pathExtension.lowercased() == "app" else { return nil }
        return url
    }

    private func save() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private struct ArcadeLobby: View {
    @StateObject private var library = ArcadeLibrary()
    @State private var selection = "drift"
    private var current: ArcadeGame? {
        library.games.first(where: { $0.id == selection }) ?? library.games.first
    }

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.09).ignoresSafeArea()
            Canvas { context, size in
                var path = Path()
                for x in stride(from: CGFloat(0), through: size.width, by: 48) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: CGFloat(0), through: size.height, by: 48) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.025)))
            }
            .ignoresSafeArea().allowsHitTesting(false)
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    HStack {
                        Image(systemName: "star.fill")
                        Spacer()
                        Text("THE ARCADE NEVER CLOSES").tracking(3)
                        Spacer()
                        Image(systemName: "star.fill")
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
                    .padding(13)
                    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(.orange.opacity(0.23)))

                    if let game = current { featured(game) }

                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("THE ARCADE FLOOR")
                                .font(.system(size: 21, weight: .heavy, design: .monospaced))
                                .tracking(1.7)
                            Text("SELECT YOUR NEXT GAME")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5)).tracking(2)
                        }
                        Spacer()
                        Button {
                            if let id = library.add() { selection = id }
                        } label: {
                            Label("ADD GAME", systemImage: "plus.square")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .buttonStyle(.bordered).tint(.orange)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 18)], spacing: 18) {
                        ForEach(library.games) { game in
                            Button { selection = game.id } label: {
                                CabinetCard(game: game, selected: current?.id == game.id,
                                            available: library.location(for: game) != nil)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        Text("FUN CITY / REBUILT FOR MAC")
                        Spacer()
                        Text("\(library.games.count) CABINETS")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38)).tracking(1.3)
                }
                .padding(30)
                .frame(maxWidth: 1150)
                .frame(maxWidth: .infinity)
            }
        }
        .alert("FUN CITY", isPresented: Binding(
            get: { library.message != nil },
            set: { if !$0 { library.message = nil } }
        )) {
            Button("OK", role: .cancel) { library.message = nil }
        } message: {
            Text(library.message ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("FUN CITY")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .tracking(5)
                    .shadow(color: .pink.opacity(0.9), radius: 16)
                Text("YOUR PERSONAL ARCADE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(3.3).foregroundStyle(.orange)
            }
            Spacer()
            Label("FREE PLAY", systemImage: "circle.fill")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.green).padding(12)
                .background(.green.opacity(0.07), in: Capsule())
                .overlay(Capsule().stroke(.green.opacity(0.3)))
        }
    }

    private func featured(_ game: ArcadeGame) -> some View {
        HStack(spacing: 22) {
            CabinetArt(kind: game.artwork, accent: game.accent)
                .frame(width: 300, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 10) {
                Text("NOW SELECTED  //  CABINET")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2).foregroundStyle(game.accent)
                Text(game.title)
                    .font(.system(size: 30, weight: .black, design: .monospaced))
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(game.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.62))
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    Button {
                        library.play(game)
                    } label: {
                        Label("PLAY NOW", systemImage: "play.fill")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 15).padding(.vertical, 10)
                            .foregroundStyle(.black)
                            .background(game.accent, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                    Button {
                        library.locate(game)
                    } label: {
                        Label(library.location(for: game) == nil ? "LOCATE GAME" : "CHANGE .APP",
                              systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    if !game.builtIn {
                        Button(role: .destructive) {
                            library.remove(game)
                            selection = "drift"
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .help("Remove cabinet, not the app itself")
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 246)
        .background(Color(red: 0.07, green: 0.08, blue: 0.15), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(game.accent.opacity(0.27)))
    }
}

private struct CabinetCard: View {
    let game: ArcadeGame
    let selected: Bool
    let available: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CabinetArt(kind: game.artwork, accent: game.accent)
                .frame(height: 125).clipShape(RoundedRectangle(cornerRadius: 10))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(size: 17, weight: .heavy, design: .monospaced))
                    Text(game.tagline)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? game.accent : .gray)
            }
            Label(available ? "READY TO LAUNCH" : "LINK GAME TO PLAY",
                  systemImage: available ? "checkmark.circle" : "link")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(available ? .green : .orange)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.075, green: 0.088, blue: 0.15), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(selected ? game.accent : .white.opacity(0.12), lineWidth: selected ? 2 : 1))
    }
}

private struct CabinetArt: View {
    let kind: String
    let accent: Color
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [accent.opacity(0.19), Color(red: 0.02, green: 0.03, blue: 0.08), .black]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            let cx = size.width / 2, cy = size.height / 2
            if kind == "space" {
                for i in 0..<50 {
                    let x = CGFloat((i * 137 + 31) % 983) / 983 * size.width
                    let y = CGFloat((i * 181 + 43) % 997) / 997 * size.height
                    let r: CGFloat = i.isMultiple(of: 7) ? 1.5 : 0.7
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2*r, height: 2*r)),
                                 with: .color(.white.opacity(0.5)))
                }
                var ship = Path()
                ship.move(to: CGPoint(x: cx, y: cy - 43))
                ship.addLine(to: CGPoint(x: cx - 26, y: cy + 28))
                ship.addLine(to: CGPoint(x: cx, y: cy + 14))
                ship.addLine(to: CGPoint(x: cx + 26, y: cy + 28))
                ship.closeSubpath()
                context.stroke(ship, with: .color(.white), lineWidth: 2.4)
                for (x, y, r) in [(0.2, 0.68, 23.0), (0.79, 0.28, 33.0), (0.72, 0.79, 13.0)] {
                    context.stroke(Path(ellipseIn: CGRect(x: size.width*x, y: size.height*y,
                                                          width: r, height: r)),
                                   with: .color(accent.opacity(0.8)), lineWidth: 2)
                }
            } else if kind == "tank" {
                let horizon = size.height * 0.48
                var grid = Path()
                for i in 0..<10 {
                    grid.move(to: CGPoint(x: cx, y: horizon))
                    grid.addLine(to: CGPoint(x: size.width * CGFloat(i) / 9, y: size.height))
                }
                for fraction in [0.1, 0.22, 0.43, 0.72, 1.0] {
                    let y = horizon + (size.height - horizon) * fraction
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(accent.opacity(0.35)), lineWidth: 1)
                var mountain = Path()
                mountain.move(to: CGPoint(x: 0, y: horizon))
                mountain.addLine(to: CGPoint(x: size.width * 0.22, y: horizon - 40))
                mountain.addLine(to: CGPoint(x: size.width * 0.4, y: horizon - 7))
                mountain.addLine(to: CGPoint(x: size.width * 0.65, y: horizon - 30))
                mountain.addLine(to: CGPoint(x: size.width, y: horizon - 9))
                context.stroke(mountain, with: .color(accent), lineWidth: 2)
                var tank = Path()
                tank.move(to: CGPoint(x: cx - 28, y: horizon + 23))
                tank.addLine(to: CGPoint(x: cx + 28, y: horizon + 23))
                tank.addLine(to: CGPoint(x: cx + 19, y: horizon + 6))
                tank.addLine(to: CGPoint(x: cx - 19, y: horizon + 6))
                tank.closeSubpath()
                tank.move(to: CGPoint(x: cx, y: horizon + 6))
                tank.addLine(to: CGPoint(x: cx, y: horizon - 35))
                context.stroke(tank, with: .color(accent), lineWidth: 2.5)
            } else if kind == "vortex" {
                let lanes = 14
                let outer = min(size.width * 0.40, size.height * 0.46)
                let inner = outer * 0.14
                let angle = { (i: Int) -> Double in
                    Double(i) * .pi * 2 / Double(lanes) - .pi / 2
                }
                let tubePoint = { (i: Int, depth: CGFloat) -> CGPoint in
                    let a = angle(i)
                    let r = inner + (outer - inner) * depth
                    return CGPoint(x: cx + CGFloat(cos(a)) * r,
                                   y: cy + CGFloat(sin(a)) * r)
                }
                for ring in 0..<6 {
                    let depth = CGFloat(ring) / 5
                    var wire = Path()
                    for i in 0..<lanes {
                        let p = tubePoint(i, depth)
                        if i == 0 { wire.move(to: p) } else { wire.addLine(to: p) }
                    }
                    wire.closeSubpath()
                    context.stroke(wire, with: .color(accent.opacity(0.28 + Double(ring) * 0.11)),
                                   lineWidth: ring == 5 ? 2.2 : 1)
                }
                for i in 0..<lanes {
                    var spoke = Path()
                    spoke.move(to: tubePoint(i, 0))
                    spoke.addLine(to: tubePoint(i, 1))
                    context.stroke(spoke, with: .color(Color.cyan.opacity(0.42)), lineWidth: 1)
                }
                let ship = [tubePoint(0, 0.92), tubePoint(0, 1.1),
                            tubePoint(1, 1.1), tubePoint(1, 0.92)]
                var hull = Path()
                hull.move(to: ship[0])
                for p in ship.dropFirst() { hull.addLine(to: p) }
                hull.closeSubpath()
                context.stroke(hull, with: .color(.white), lineWidth: 2.5)
                let enemy = tubePoint(6, 0.63)
                context.stroke(Path(ellipseIn: CGRect(x: enemy.x - 9, y: enemy.y - 9,
                                                       width: 18, height: 18)),
                               with: .color(.yellow), lineWidth: 2.5)
            } else {
                for i in 0..<5 {
                    let radius = CGFloat(18 + i * 20)
                    context.stroke(Path(roundedRect: CGRect(x: cx-radius, y: cy-radius,
                                                             width: radius*2, height: radius*2),
                                        cornerRadius: 8),
                                   with: .color(accent.opacity(0.9-Double(i)*0.15)), lineWidth: 2)
                }
                context.draw(Text("NEW GAME").font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(accent), at: CGPoint(x: cx, y: cy))
            }
        }
        .accessibilityHidden(true)
    }
}
