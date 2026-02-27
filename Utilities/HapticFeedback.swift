import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// スコアに応じた触覚フィードバック（仕様: 衝突時・判定時の感触）。
/// iOS 17+ は sensoryFeedback、それ以前は UINotificationFeedbackGenerator。
enum HapticFeedback {
    static func play(for scoreRank: ScoreRank) {
        #if canImport(UIKit)
        switch scoreRank {
        case .perfect:
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        case .nice:
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.warning)
        case .miss:
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
        }
        #endif
    }

    static func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if canImport(UIKit)
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
        #endif
    }
}
