//
//  CustomToggle.swift
//  screenfare
//
//  Custom toggle component matching design handoff specs
//  Provides instant visual feedback with optimistic state updates
//

import SwiftUI

struct CustomToggle: View {
    @Binding var isOn: Bool
    var onToggle: ((Bool) -> Void)? = nil

    // Colors
    var trackColorOn: Color = .focusInk
    var trackColorOff: Color = Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 0.15)
    var thumbColor: Color = .white

    init(isOn: Binding<Bool>, onToggle: ((Bool) -> Void)? = nil, trackColorOn: Color = .focusInk, trackColorOff: Color = Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 0.15), thumbColor: Color = .white) {
        self._isOn = isOn
        self.onToggle = onToggle
        self.trackColorOn = trackColorOn
        self.trackColorOff = trackColorOff
        self.thumbColor = thumbColor
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: 13)
                .fill(isOn ? trackColorOn : trackColorOff)
                .frame(width: 44, height: 26)

            // Thumb
            Circle()
                .fill(thumbColor)
                .frame(width: 22, height: 22)
                .shadow(color: Color.black.opacity(0.18), radius: 1.5, y: 1)
                .offset(x: isOn ? 20 : 2)
                .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.2), value: isOn)
        }
        .frame(width: 44, height: 26)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            // Toggle the binding
            isOn.toggle()
            // Also call the callback if provided
            onToggle?(isOn)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        HStack {
            Text("Off")
            Spacer()
            CustomToggle(isOn: .constant(false), onToggle: { _ in })
        }

        HStack {
            Text("On")
            Spacer()
            CustomToggle(isOn: .constant(true), onToggle: { _ in })
        }

        // Dark background preview
        HStack {
            Text("On (dark)")
                .foregroundColor(.white)
            Spacer()
            CustomToggle(isOn: .constant(true), onToggle: { _ in })
        }
        .padding()
        .background(Color.focusInk)
    }
    .padding(40)
}
