import SwiftUI

struct FocusTimerView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Timer display
            VStack(spacing: 16) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color(nsColor: .controlBackgroundColor), lineWidth: 4)
                        .frame(width: 160, height: 160)

                    // Animated ring when focusing
                    if store.isFocusing {
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: store.focusElapsed)
                    }

                    // Time text
                    VStack(spacing: 4) {
                        Text(formatTime(store.focusElapsed))
                            .font(.system(size: 36, weight: .light, design: .monospaced))
                            .foregroundColor(.primary)

                        Text(store.isFocusing ? "focusing" : "ready")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                }

                // Start / Stop button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if store.isFocusing {
                            store.stopFocus()
                        } else {
                            store.startFocus()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: store.isFocusing ? "stop.fill" : "play.fill")
                            .font(.system(size: 14))
                        Text(store.isFocusing ? "Stop" : "Start Focus")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(store.isFocusing ?
                                  LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Today's sessions
            if !store.todaySessions.isEmpty {
                Divider().opacity(0.3)

                VStack(spacing: 0) {
                    HStack {
                        Text("Today's Sessions")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Spacer()

                        Text("Total: \(formatDuration(store.todayTotalFocus))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(store.todaySessions) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }
        }
    }

    private var ringProgress: Double {
        // Complete a ring every 30 minutes
        let cycle: Double = 1800
        return (store.focusElapsed.truncatingRemainder(dividingBy: cycle)) / cycle
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack {
            Circle()
                .fill(.green.opacity(0.6))
                .frame(width: 6, height: 6)

            Text(timeString(session.startedAt))
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("-")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.5))

            Text(timeString(session.endedAt ?? Date()))
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Text(durationString(session.duration))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }

    func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    func durationString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
