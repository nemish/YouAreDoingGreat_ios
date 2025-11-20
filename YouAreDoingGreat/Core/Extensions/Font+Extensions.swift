import SwiftUI

// MARK: - Custom Fonts

extension Font {
    // MARK: - Comfortaa (Primary - Body Text)

    /// Primary font for body text and general UI
    static func comfortaa(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .light:
            fontName = "Comfortaa-Light"
        case .medium:
            fontName = "Comfortaa-Medium"
        case .semibold:
            fontName = "Comfortaa-SemiBold"
        case .bold:
            fontName = "Comfortaa-Bold"
        default:
            fontName = "Comfortaa-Regular"
        }
        return .custom(fontName, size: size)
    }

    // MARK: - Gloria Hallelujah (Titles)

    /// Handwritten font for titles and headings
    static func gloriaHallelujah(_ size: CGFloat) -> Font {
        .custom("GloriaHallelujah", size: size)
    }

    // MARK: - Semantic Font Styles

    /// Large title style (Gloria Hallelujah)
    static var appLargeTitle: Font {
        .gloriaHallelujah(40)
    }

    /// Title style (Gloria Hallelujah)
    static var appTitle: Font {
        .gloriaHallelujah(32)
    }

    /// Title 2 style (Gloria Hallelujah)
    static var appTitle2: Font {
        .gloriaHallelujah(26)
    }

    /// Title 3 style (Gloria Hallelujah)
    static var appTitle3: Font {
        .gloriaHallelujah(22)
    }

    /// Headline style (Comfortaa Bold)
    static var appHeadline: Font {
        .comfortaa(17, weight: .semibold)
    }

    /// Body style (Comfortaa)
    static var appBody: Font {
        .comfortaa(17)
    }

    /// Callout style (Comfortaa)
    static var appCallout: Font {
        .comfortaa(16)
    }

    /// Subheadline style (Comfortaa)
    static var appSubheadline: Font {
        .comfortaa(15)
    }

    /// Footnote style (Comfortaa)
    static var appFootnote: Font {
        .comfortaa(13)
    }

    /// Caption style (Comfortaa)
    static var appCaption: Font {
        .comfortaa(12)
    }
}
