//
//  FocusTheme.swift
//  whitespace
//
//  用途：集中定义设计稿颜色、字体和常用 View 修饰器。
//

import SwiftUI

enum FocusPalette {
    static let background = Color(hex: 0xFAFAF8)
    static let card = Color(hex: 0xF0F0EE)
    static let paper = Color(hex: 0xFAFAF8)
    static let ink = Color(hex: 0x0A0A0A)
    static let textPrimary = Color(hex: 0x0A0A0A)
    static let textSecondary = Color(hex: 0x525252)
    static let textMuted = Color(hex: 0x737373)
    static let border = Color(hex: 0xD4D4D2)
    static let borderSubtle = Color(hex: 0xE0E0E0)
    static let accent = Color(hex: 0xC5E803)
    static let accentOn = Color(hex: 0x0A0A0A)
    static let iosBlue = Color(hex: 0xC5E803)
    static let danger = Color(hex: 0xFF3B30)
    static let success = Color(hex: 0xC5E803)
    static let gridLine = Color(hex: 0x0A0A0A, alpha: 0.08)
}

enum FocusLayout {
    static let pageHorizontalPadding: CGFloat = 24
    static let pageTopPadding: CGFloat = 32
    static let pageBottomPadding: CGFloat = 28
    static let listRowHorizontalPadding: CGFloat = 20
    static let bottomActionTopPadding: CGFloat = 12
    static let bottomActionBottomPadding: CGFloat = 22
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Font {
    static let focusTitle = Font.system(size: 34, weight: .light, design: .default)
    static let focusSection = Font.system(size: 12, weight: .semibold, design: .monospaced)
    static let focusBody = Font.system(size: 17, weight: .regular, design: .default)
    static let focusCaption = Font.system(size: 13, weight: .medium, design: .monospaced)
}

extension View {
    func iosCard(cornerRadius: CGFloat = 0) -> some View {
        background(FocusPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FocusPalette.border, lineWidth: 1)
            }
    }

    func pressableScale() -> some View {
        buttonStyle(PressScaleButtonStyle())
    }
}

struct SwissGridBackground: View {
    var spacing: CGFloat = 24
    var lineColor: Color = FocusPalette.gridLine

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                stride(from: CGFloat.zero, through: proxy.size.width, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }

                stride(from: CGFloat.zero, through: proxy.size.height, by: spacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }
            .stroke(lineColor, lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
