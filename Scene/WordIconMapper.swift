import UIKit

/// WordDatabase への薄いラッパー。後方互換のために残す。
enum WordIconMapper {
    static func renderIcon(for word: String, size: CGFloat = 80, color: UIColor = .white) -> UIImage? {
        WordDatabase.renderIcon(for: word, size: size, color: color)
    }
}
