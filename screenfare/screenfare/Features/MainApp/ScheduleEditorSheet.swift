//
//  ScheduleEditorSheet.swift
//  screenfare
//
//  Drill-in view for editing blocking schedules (matches ChallengeTabView pattern)
//

import SwiftUI

struct ScheduleEditorSheet: View {
    @ObservedObject var scheduleManager: ScheduleManager
    let onClose: () -> Void

    @State private var draft: Schedule
    @State private var expandedWindowId: String?

    init(scheduleManager: ScheduleManager, onClose: @escaping () -> Void) {
        self.scheduleManager = scheduleManager
        self.onClose = onClose
        self._draft = State(initialValue: scheduleManager.schedule)
        self._expandedWindowId = State(initialValue: scheduleManager.schedule.windows.first?.id)
    }

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button header
                HStack(spacing: 0) {
                    Button(action: commit) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Blocks")
                                .font(.inter(17, weight: .medium))
                        }
                        .foregroundColor(.focusInk)
                        .padding(.vertical, 10)
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 4)

                // Large title
                Text("Schedule")
                    .font(.instrumentSerif(34))
                    .foregroundColor(.focusInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                ScrollView {
                    VStack(spacing: 0) {
                        // Mode toggle
                        HStack(spacing: 4) {
                            SegmentButton(
                                title: "All day",
                                isSelected: draft.mode == .allday,
                                action: { draft.mode = .allday }
                            )

                            SegmentButton(
                                title: "Scheduled",
                                isSelected: draft.mode == .scheduled,
                                action: { draft.mode = .scheduled }
                            )
                        }
                        .padding(4)
                        .background(Color.focusInk.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.bottom, 18)

                        // Hero timeline card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("A TYPICAL DAY")
                                    .font(.inter(10.5, weight: .semibold))
                                    .foregroundColor(.focusMuted)
                                    .tracking(0.8)

                                Spacer()

                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.focusInk)
                                        .frame(width: 8, height: 8)

                                    Text("Blocking")
                                        .font(.inter(11))
                                        .foregroundColor(.focusMuted)
                                }
                            }

                            TimelineBar(
                                windows: draft.windows,
                                allday: draft.mode == .allday,
                                height: 42,
                                showLabels: true,
                                showNow: true
                            )
                        }
                        .padding(16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.bottom, 20)

                        // Content based on mode
                        if draft.mode == .scheduled {
                            scheduledContent
                        } else {
                            alldayContent
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Commit (save and close)

    private func commit() {
        scheduleManager.schedule = draft
        onClose()
    }

    // MARK: - Scheduled Mode Content

    private var scheduledContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BLOCKING WINDOWS")
                .font(.inter(11, weight: .semibold))
                .foregroundColor(.focusMuted)
                .tracking(0.6)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            // Window cards
            ForEach(Array(draft.windows.enumerated()), id: \.element.id) { index, window in
                WindowCard(
                    window: binding(for: window.id),
                    index: index,
                    isExpanded: expandedWindowId == window.id,
                    onToggleExpand: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedWindowId = expandedWindowId == window.id ? nil : window.id
                        }
                    },
                    onRemove: {
                        removeWindow(id: window.id)
                    },
                    removable: draft.windows.count > 1
                )
                .padding(.bottom, 10)
            }

            // Add window button
            if draft.windows.count < 4 {
                Button(action: addWindow) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Add a window")
                            .font(.inter(14, weight: .semibold))
                    }
                    .foregroundColor(.focusInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                Color.focusInk.opacity(0.22),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 2)
            }

            // Explanation text
            Text("Outside these hours your blocked apps open normally — no fare required.")
                .font(.inter(12.5))
                .foregroundColor(.focusMuted)
                .lineSpacing(4)
                .padding(.horizontal, 4)
                .padding(.top, 18)
                .padding(.bottom, 4)
        }
    }

    // MARK: - All Day Mode Content

    private var alldayContent: some View {
        Text("Screen Fare stays active around the clock. Every blocked app asks for its fare, any time of day.")
            .font(.inter(14))
            .foregroundColor(.focusMuted)
            .lineSpacing(5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func binding(for windowId: String) -> Binding<BlockingWindow> {
        Binding(
            get: {
                draft.windows.first(where: { $0.id == windowId }) ?? draft.windows[0]
            },
            set: { newValue in
                if let index = draft.windows.firstIndex(where: { $0.id == windowId }) {
                    draft.windows[index] = newValue
                }
            }
        )
    }

    private func addWindow() {
        let newWindow = BlockingWindow(
            id: UUID().uuidString,
            start: 18 * 60, // 6 PM
            end: 20 * 60,   // 8 PM
            days: [1, 2, 3, 4, 5] // Weekdays
        )
        withAnimation {
            draft.windows.append(newWindow)
            expandedWindowId = newWindow.id
        }
    }

    private func removeWindow(id: String) {
        withAnimation {
            draft.windows.removeAll { $0.id == id }
            if expandedWindowId == id {
                expandedWindowId = draft.windows.first?.id
            }
        }
    }
}

// MARK: - Segment Button

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inter(14, weight: .semibold))
                .foregroundColor(isSelected ? .focusInk : .focusMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(9)
                .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 3, y: 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScheduleEditorSheet(scheduleManager: ScheduleManager.shared, onClose: {})
}
