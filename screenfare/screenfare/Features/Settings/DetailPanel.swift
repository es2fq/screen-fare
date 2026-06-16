//
//  DetailPanel.swift
//  Screen Fare
//
//  Sliding detail panel container for settings screens
//

import SwiftUI

struct DetailPanel<Content: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.focusBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                HStack(spacing: 0) {
                    Button(action: onBack) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.focusInk)

                            Text("Settings")
                                .font(.inter(15))
                                .foregroundColor(.focusInk)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // Title
                Text(title)
                    .font(.instrumentSerif(34))
                    .foregroundColor(.focusInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        content
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
