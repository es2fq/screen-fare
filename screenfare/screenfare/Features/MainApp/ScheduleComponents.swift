//
//  ScheduleComponents.swift
//  Screen Fare
//
//  Reusable components for schedule editing: time steppers and day pickers
//

import SwiftUI

// MARK: - Time Stepper

struct TimeStepper: View {
    let label: String
    @Binding var value: Int
    let step: Int = 15 // 15-minute increments

    @State private var showPicker: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.inter(13.5))
                .foregroundColor(.focusMuted)

            Spacer()

            HStack(spacing: 12) {
                // Minus button
                Button(action: {
                    value = ((value - step) % 1440 + 1440) % 1440
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.focusInk)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())

                // Time display - tappable to show picker
                Button(action: {
                    showPicker.toggle()
                }) {
                    Text(ScheduleManager.minToLabel(value))
                        .font(.instrumentSerif(25))
                        .foregroundColor(.focusInk)
                        .monospacedDigit()
                        .frame(minWidth: 96)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showPicker) {
                    HStack(spacing: 0) {
                        // Hour picker
                        Picker("Hour", selection: Binding(
                            get: { value / 60 },
                            set: { newHour in
                                let currentMinute = (value % 60) / 15 * 15
                                value = newHour * 60 + currentMinute
                            }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%d", hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70)

                        // Minute picker (15-minute increments only)
                        Picker("Minute", selection: Binding(
                            get: { (value % 60) / 15 },
                            set: { quarterIndex in
                                let currentHour = value / 60
                                value = currentHour * 60 + quarterIndex * 15
                            }
                        )) {
                            ForEach(0..<4, id: \.self) { quarter in
                                Text(String(format: "%02d", quarter * 15))
                                    .tag(quarter)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70)

                        // AM/PM picker
                        Picker("Period", selection: Binding(
                            get: { value / 60 >= 12 ? 1 : 0 },
                            set: { period in
                                let currentHour = value / 60
                                let currentMinute = value % 60
                                var newHour = currentHour % 12
                                if period == 1 { // PM
                                    newHour += 12
                                }
                                value = newHour * 60 + currentMinute
                            }
                        )) {
                            Text("AM").tag(0)
                            Text("PM").tag(1)
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70)
                    }
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }

                // Plus button
                Button(action: {
                    value = (value + step) % 1440
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.focusInk)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Day Picker

struct DayPicker: View {
    @Binding var days: [Int]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ScheduleManager.dayPills, id: \.1) { letter, dayNum in
                let isSelected = days.contains(dayNum)

                Button(action: {
                    toggleDay(dayNum)
                }) {
                    Text(letter)
                        .font(.inter(13.5, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .focusMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(isSelected ? Color.focusInk : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(isSelected ? Color.clear : Color.focusLine, lineWidth: 1)
                        )
                        .cornerRadius(11)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func toggleDay(_ day: Int) {
        var newDays = days
        if let index = newDays.firstIndex(of: day) {
            // Don't allow removing the last day
            if newDays.count > 1 {
                newDays.remove(at: index)
            }
        } else {
            newDays.append(day)
        }
        days = newDays.sorted()
    }
}

#Preview {
    VStack(spacing: 40) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Stepper")
                .font(.caption)
                .foregroundColor(.secondary)

            TimeStepper(label: "Starts", value: .constant(9 * 60))
            TimeStepper(label: "Ends", value: .constant(17 * 60))
        }

        VStack(alignment: .leading, spacing: 16) {
            Text("Day Picker")
                .font(.caption)
                .foregroundColor(.secondary)

            DayPicker(days: .constant([1, 2, 3, 4, 5]))
        }
    }
    .padding()
    .background(Color.focusBg)
}
