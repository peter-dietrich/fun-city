import AVFoundation
import SwiftUI

// Personal recollection supplied and approved by the project owner.
// No historical imagery, external assets, or network access are required.
private struct OriginChapter: Identifiable {
    let id: Int
    let title: String
    let body: String

    var paragraphs: [String] {
        body.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private enum OriginStoryCopy {
    static let chapters: [OriginChapter] = [
        OriginChapter(id: 1, title: "Every Great Adventure Started With a Quarter", body: """
        There was a time before the internet, before smartphones, before online gaming, and long before anyone thought staring at a screen for eight hours a day was a perfectly respectable way to earn a living. Back then, if you wanted to escape into another world, you had to leave the house. For us, that meant a little arcade tucked into the corner of a shopping center in Towson, Maryland.

        It was called **Fun City**.

        You could practically hear it from the parking lot. The frantic electronic chirping of Pac-Man, the explosions of Asteroids, the distinctive sounds of Centipede, and the unmistakable clatter of pinball machines. A glorious, chaotic symphony of technology, competition, and questionable financial decisions. Inside, the lights were low, the screens glowed, and rows of cabinets stood shoulder to shoulder. Each one offered another universe to conquer, another impossible challenge, another opportunity to become a three-letter legend.

        And all it took was a quarter.

        Well, usually a lot of quarters.
        """),
        OriginChapter(id: 2, title: "The Great Arcade Panic", body: """
        Of course, not everyone shared our enthusiasm.

        According to some parents, teachers, politicians, and television commentators, video arcades were apparently the beginning of the end of Western civilization.

        They worried that we'd skip school, fall in with the wrong crowd, become addicted to electronic games, develop antisocial tendencies, and eventually turn to a life of crime to support our increasingly desperate need for quarters.

        There were even warnings about video games causing violence, ruining our eyesight, damaging our wrists, and turning perfectly normal children into something called *video junkies*.

        From where we stood, the greatest threat to public safety was running out of money with the Centipede still halfway down the screen.

        We weren't joining gangs. We were trying to figure out how somebody had scored 100,000 points on Asteroids.

        We weren't gambling away our futures. We were calculating whether the last seventy-five cents in our pockets would be better invested in Pac-Man or three more attempts at pinball.

        And as for becoming antisocial?

        We were crammed shoulder to shoulder with half the neighborhood, cheering each other on, talking trash, exchanging strategies, and making friends. It was arguably one of the most social things we ever did.

        But the grown-ups weren't convinced.

        Apparently, standing outside getting into trouble was preferable to standing inside trying to avoid a pixelated ghost.
        """),
        OriginChapter(id: 3, title: "The Economics of Being Thirteen", body: """
        We'd show up with our brothers, our friends, and whatever change we could scrape together.

        Quarters were precious. They had to be budgeted, protected, and strategically deployed.

        A dollar meant four games. Maybe ten minutes of entertainment if you were terrible. An entire afternoon if you were really good.

        There were no microtransactions, no subscriptions, no downloadable upgrades. The machines took your money up front, defeated you mercilessly, and demanded another quarter for the privilege of trying again.

        Somehow, we considered this an excellent business arrangement.

        We learned to stretch a dollar, develop strategies, recognize patterns, and remain calm under pressure.

        Our parents probably thought we were wasting our money.

        In hindsight, they weren't entirely wrong.

        But we were having an incredible time.
        """),
        OriginChapter(id: 4, title: "Three Letters of Immortality", body: """
        Asteroids demanded nerves of steel. Centipede tested reflexes we didn't know we had. Pac-Man required memorization, strategy, and the ability to make life-or-death decisions while being chased by four colorful ghosts.

        And pinball was a world of its own, where timing, instinct, and a little carefully applied body English could turn a single quarter into a personal triumph.

        We'd gather around the really good players, watching in amazement as they reached levels the rest of us could barely imagine.

        Sometimes we'd mark our place in line by balancing a quarter on the edge of the cabinet. That was the reservation system. No apps, no accounts, no confirmation emails. Just an unspoken code of arcade etiquette.

        There were no save games. No pause button. No internet walkthroughs.

        You learned by playing. And losing. And playing again.

        And when those three little letters finally appeared beside a high score, you had achieved something extraordinary.

        Not fame. Not fortune.

        Something better.

        **Bragging rights until somebody knocked you off the leaderboard.**
        """),
        OriginChapter(id: 5, title: "Somehow, We Survived", body: """
        The newspapers had warned about the dangers. The politicians debated restrictions. The experts worried about our development.

        And somehow, against all odds, we grew up.

        We got jobs. Raised families. Built careers. Paid mortgages. Became responsible adults.

        Some of us even ended up spending our days working with computers.

        Which, considering all those warnings about screen time, seems a little ironic.

        Eventually, the arcades faded. The machines disappeared. The shopping centers changed. The world moved on to home consoles, personal computers, and games more sophisticated than anything we could have imagined back in 1982.

        But something was lost along the way.

        The anticipation of walking through that door.

        The sound of a dozen games competing for your attention.

        The satisfaction of mastering something genuinely difficult.

        The friends and brothers standing beside you.

        And that magical feeling that, with just one more quarter, you might finally beat the machine.
        """),
        OriginChapter(id: 6, title: "Welcome Back to Fun City", body: """
        More than forty years later, Fun City is coming back.

        Not as a museum. Not as a perfect reproduction of the past.

        But as a tribute to the spirit of those original games, those unforgettable afternoons, and an era when imagination was measured in pixels and adventure cost twenty-five cents.

        We're bringing back the simple controls, relentless challenges, escalating difficulty, satisfying explosions, and the irresistible urge to play just one more game.

        Only this time, with a few modern enhancements those early arcade designers could only have dreamed about.

        And maybe, just maybe, we're finally going to prove something to all those concerned adults.

        **They were right about one thing.**

        **Those video games really did get into our heads.**

        Forty-five years later, we're still playing them.

        Only now, we're building them ourselves.
        """)
    ]
}

/// Optional original synthesized arcade ambience. Off for every story opening;
/// no third-party sounds, remote requests, or bundled music.
@MainActor
private final class OriginStoryAmbience: ObservableObject {
    @Published private(set) var playing = false
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = 0.22
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            if playing { return }
            if !engine.isRunning { try? engine.start() }
            guard engine.isRunning else { return }

            let duration = 8.0
            let count = AVAudioFrameCount(sampleRate * duration)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
                  let samples = buffer.floatChannelData?.pointee else { return }
            buffer.frameLength = count
            // Coin-op hum and intermittent distant, original electronic chirps.
            // Frequencies/timing are intentionally not taken from existing games.
            let chirps: [(Double, Double, Double)] = [
                (0.85, 0.19, 490), (2.65, 0.16, 660),
                (4.55, 0.22, 390), (6.75, 0.20, 570)
            ]
            for i in 0..<Int(count) {
                let t = Double(i) / sampleRate
                var sample = 0.024 * sin(2 * .pi * 55 * t)
                sample += 0.01 * sin(2 * .pi * 110 * t)
                for (start, length, pitch) in chirps {
                    let u = t - start
                    if u >= 0 && u < length {
                        let envelope = sin(.pi * u / length)
                        sample += 0.035 * envelope * sin(2 * .pi * pitch * u)
                    }
                }
                samples[i] = Float(sample)
            }
            player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            player.play()
            playing = true
        } else {
            player.stop()
            engine.stop()
            playing = false
        }
    }

    deinit {
        player.stop()
        engine.stop()
    }
}

private struct OriginStoryCoin: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.13, blue: 0.23))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.35), lineWidth: 1))
                .frame(width: 106, height: 70)
                .offset(y: 78)
            Capsule()
                .fill(.black)
                .overlay(Capsule().stroke(Color.orange.opacity(0.7), lineWidth: 2))
                .frame(width: 72, height: 11)
                .offset(y: 98)
            Circle()
                .fill(LinearGradient(colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.43),
                    Color(red: 0.57, green: 0.36, blue: 0.12)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 2))
                .overlay(Text("25¢")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.65)))
                .frame(width: 56, height: 56)
                .offset(y: dropped ? 92 : 4)
                .opacity(dropped ? 0 : 1)
        }
        .frame(width: 136, height: 155)
        .accessibilityLabel("A quarter drops into an arcade coin slot")
        .onAppear {
            if reduceMotion {
                dropped = true
            } else {
                withAnimation(.easeIn(duration: 0.75).delay(0.2)) {
                    dropped = true
                }
            }
        }
    }
}

private struct OriginStoryArcadeArt: View {
    var body: some View {
        Canvas { context, size in
            let cy = size.height * 0.47
            let horizon = size.height * 0.78
            let cyan = Color(red: 0.34, green: 0.86, blue: 0.96)
            let amber = Color(red: 1, green: 0.65, blue: 0.29)
            let magenta = Color(red: 0.92, green: 0.40, blue: 0.77)
            for i in 0..<13 {
                let x = size.width * CGFloat(i) / 12.0
                var trace = Path()
                trace.move(to: CGPoint(x: size.width/2, y: horizon))
                trace.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(trace, with: .color(cyan.opacity(0.22)), lineWidth: 1)
            }
            for i in 0..<5 {
                let y = horizon + CGFloat(i*i) * (size.height-horizon)/16.0
                var trace = Path()
                trace.move(to: CGPoint(x: 0, y: y))
                trace.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(trace, with: .color(cyan.opacity(0.20)), lineWidth: 1)
            }
            for i in 0..<11 {
                let x = CGFloat((i * 67 + 19) % 251) / 251.0 * size.width
                let y = CGFloat((i * 41 + 11) % 127) / 127.0 * cy
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                             with: .color(.white.opacity(0.58)))
            }
            var ship = Path()
            ship.move(to: CGPoint(x: size.width*0.47, y: cy*0.26))
            ship.addLine(to: CGPoint(x: size.width*0.39, y: cy*0.81))
            ship.addLine(to: CGPoint(x: size.width*0.47, y: cy*0.70))
            ship.addLine(to: CGPoint(x: size.width*0.55, y: cy*0.81))
            ship.closeSubpath()
            context.stroke(ship, with: .color(cyan), lineWidth: 2)
            for i in 0..<3 {
                let x = size.width * (0.19 + CGFloat(i) * 0.25)
                let y = cy * (0.60 - CGFloat(i % 2) * 0.20)
                context.stroke(Path(roundedRect: CGRect(x: x, y: y, width: 14, height: 14),
                                    cornerRadius: 2), with: .color(i == 1 ? amber : magenta), lineWidth: 1.8)
            }
        }
        .accessibilityHidden(true)
    }
}

struct FunCityOriginStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ambience = OriginStoryAmbience()
    @State private var ambienceEnabled = false

    private let night = Color(red: 0.035, green: 0.045, blue: 0.09)
    private let amber = Color(red: 1, green: 0.66, blue: 0.30)
    private let cyan = Color(red: 0.40, green: 0.84, blue: 0.97)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Label("BACK TO ARCADE", systemImage: "arrow.left")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .tint(amber)
                Spacer(minLength: 10)
                Text("FUN CITY  /  OUR STORY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                Spacer(minLength: 10)
                Toggle(isOn: $ambienceEnabled) {
                    Label("AMBIENCE", systemImage: ambienceEnabled ? "speaker.wave.2" : "speaker.slash")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .fixedSize()
                .accessibilityHint("Play or stop original synthesized arcade atmosphere")
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .background(night.opacity(0.97))

            Rectangle().fill(amber.opacity(0.3)).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 38) {
                    HStack(alignment: .center, spacing: 22) {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("1982  •  TOWSON, MARYLAND")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2.5)
                                .foregroundStyle(amber)
                            Text("FUN CITY")
                                .font(.system(size: 58, weight: .black, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(.white)
                                .shadow(color: .pink.opacity(0.48), radius: 14)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text("Every Great Adventure Started With a Quarter.")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(cyan)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("An arcade story. Towson, Maryland. Circa 1982.")
                                .font(.system(size: 13, weight: .medium))
                                .italic()
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        Spacer(minLength: 0)
                        OriginStoryCoin()
                    }
                    .padding(.top, 30)

                    OriginStoryArcadeArt()
                        .frame(height: 155)
                        .background(
                            LinearGradient(colors: [
                                Color(red: 0.08, green: 0.09, blue: 0.16),
                                Color(red: 0.04, green: 0.05, blue: 0.10)
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(cyan.opacity(0.23)))

                    ForEach(OriginStoryCopy.chapters) { chapter in
                        VStack(alignment: .leading, spacing: 17) {
                            HStack(alignment: .firstTextBaseline, spacing: 13) {
                                Text(String(format: "%02d", chapter.id))
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(amber)
                                Text(chapter.title)
                                    .font(.system(size: 25, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 5)
                            ForEach(chapter.paragraphs.indices, id: \.self) { index in
                                let paragraph = chapter.paragraphs[index]
                                if let attributed = try? AttributedString(markdown: paragraph) {
                                    Text(attributed)
                                        .font(.system(size: 15.5))
                                        .foregroundStyle(.white.opacity(0.87))
                                        .lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
                                } else {
                                    Text(paragraph)
                                        .font(.system(size: 15.5))
                                        .foregroundStyle(.white.opacity(0.87))
                                        .lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    VStack(alignment: .center, spacing: 17) {
                        Rectangle().fill(amber.opacity(0.48)).frame(height: 1)
                        Text("WELCOME BACK TO FUN CITY.")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .tracking(1)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .shadow(color: amber.opacity(0.45), radius: 14)
                        Text("Insert quarter. Ignore the grown-ups. Save the universe.")
                            .font(.system(size: 15))
                            .italic()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(amber)
                        Button(action: { dismiss() }) {
                            Label("RETURN TO THE ARCADE", systemImage: "gamecontroller.fill")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(amber)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 38)
                }
                .frame(maxWidth: 800, alignment: .leading)
                .padding(.horizontal, 34)
                .frame(maxWidth: .infinity)
            }
            .background(
                ZStack {
                    night
                    Canvas { context, size in
                        var lines = Path()
                        for y in stride(from: CGFloat(0), through: size.height, by: 5) {
                            lines.move(to: CGPoint(x: 0, y: y))
                            lines.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(lines, with: .color(.black.opacity(0.12)), lineWidth: 1)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            )
        }
        .frame(minWidth: 620, idealWidth: 890, minHeight: 490, idealHeight: 760)
        .preferredColorScheme(.dark)
        .onChange(of: ambienceEnabled) { enabled in
            ambience.setEnabled(enabled)
        }
        .onDisappear {
            ambience.setEnabled(false)
        }
    }
}
