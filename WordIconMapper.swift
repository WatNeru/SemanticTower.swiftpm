import UIKit

/// 単語からアイコンを引くマッパー。
/// SF Symbols を優先し、対応がなければ Emoji にフォールバック。
/// 外部アセット不要（OS 内蔵リソースのみ）。
enum WordIconMapper {

    enum Icon {
        case sfSymbol(String)
        case emoji(String)
    }

    // MARK: - Public

    static func icon(for word: String) -> Icon {
        let key = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let mapped = mapping[key] {
            return mapped
        }
        return categoryFallback(for: key)
    }

    /// UIImage としてレンダリング（テクスチャ用）
    static func renderIcon(
        for word: String,
        size: CGFloat = 80,
        color: UIColor = .white
    ) -> UIImage? {
        let iconType = icon(for: word)
        switch iconType {
        case .sfSymbol(let name):
            return renderSFSymbol(name: name, size: size, color: color)
        case .emoji(let emoji):
            return renderEmoji(emoji, size: size)
        }
    }

    // MARK: - Mapping table

    private static let mapping: [String: Icon] = [
        // Animals
        "dog": .sfSymbol("dog.fill"),
        "cat": .sfSymbol("cat.fill"),
        "lion": .emoji("🦁"),
        "eagle": .sfSymbol("bird.fill"),
        "whale": .emoji("🐋"),
        "bird": .sfSymbol("bird.fill"),
        "fish": .sfSymbol("fish.fill"),
        "rabbit": .sfSymbol("hare.fill"),
        "hare": .sfSymbol("hare.fill"),
        "ant": .sfSymbol("ant.fill"),
        "bear": .emoji("🐻"),
        "horse": .emoji("🐴"),
        "elephant": .emoji("🐘"),
        "tiger": .emoji("🐯"),
        "monkey": .emoji("🐵"),
        "snake": .emoji("🐍"),
        "turtle": .sfSymbol("tortoise.fill"),
        "bug": .sfSymbol("ladybug.fill"),
        "wolf": .emoji("🐺"),
        "fox": .emoji("🦊"),
        "penguin": .emoji("🐧"),
        "butterfly": .emoji("🦋"),
        "cow": .emoji("🐄"),
        "pig": .emoji("🐷"),
        "sheep": .emoji("🐑"),
        "deer": .emoji("🦌"),
        "frog": .emoji("🐸"),

        // Nature
        "tree": .sfSymbol("tree.fill"),
        "river": .sfSymbol("water.waves"),
        "mountain": .sfSymbol("mountain.2.fill"),
        "forest": .sfSymbol("tree.fill"),
        "ocean": .sfSymbol("water.waves"),
        "flower": .emoji("🌸"),
        "sun": .sfSymbol("sun.max.fill"),
        "moon": .sfSymbol("moon.fill"),
        "star": .sfSymbol("star.fill"),
        "rain": .sfSymbol("cloud.rain.fill"),
        "snow": .sfSymbol("snowflake"),
        "wind": .sfSymbol("wind"),
        "cloud": .sfSymbol("cloud.fill"),
        "leaf": .sfSymbol("leaf.fill"),
        "fire": .sfSymbol("flame.fill"),
        "earth": .sfSymbol("globe.americas.fill"),
        "sky": .sfSymbol("sky.fill"),
        "garden": .emoji("🌻"),
        "volcano": .emoji("🌋"),
        "island": .emoji("🏝️"),

        // Machines
        "car": .sfSymbol("car.fill"),
        "train": .sfSymbol("train.side.front.car"),
        "airplane": .sfSymbol("airplane"),
        "computer": .sfSymbol("desktopcomputer"),
        "robot": .emoji("🤖"),
        "phone": .sfSymbol("iphone"),
        "camera": .sfSymbol("camera.fill"),
        "rocket": .emoji("🚀"),
        "bicycle": .sfSymbol("bicycle"),
        "bus": .sfSymbol("bus.fill"),
        "ship": .sfSymbol("ferry.fill"),
        "helicopter": .emoji("🚁"),
        "engine": .sfSymbol("engine.combustion.fill"),
        "battery": .sfSymbol("battery.100"),
        "satellite": .emoji("🛰️"),
        "drone": .emoji("🛸"),

        // Objects
        "stone": .emoji("🪨"),
        "chair": .sfSymbol("chair.fill"),
        "table": .sfSymbol("table.furniture.fill"),
        "book": .sfSymbol("book.fill"),
        "key": .sfSymbol("key.fill"),
        "clock": .sfSymbol("clock.fill"),
        "lamp": .sfSymbol("lamp.desk.fill"),
        "cup": .sfSymbol("cup.and.saucer.fill"),
        "ball": .sfSymbol("soccerball"),
        "hammer": .sfSymbol("hammer.fill"),
        "guitar": .sfSymbol("guitars.fill"),
        "bell": .sfSymbol("bell.fill"),
        "pen": .sfSymbol("pencil"),
        "bag": .sfSymbol("bag.fill"),
        "gift": .sfSymbol("gift.fill"),
        "crown": .sfSymbol("crown.fill"),
        "shield": .sfSymbol("shield.fill"),
        "sword": .emoji("⚔️"),
        "diamond": .emoji("💎"),
        "ring": .emoji("💍"),

        // Emotions
        "happy": .sfSymbol("face.smiling"),
        "sad": .emoji("😢"),
        "angry": .emoji("😤"),
        "calm": .sfSymbol("leaf.fill"),
        "excited": .sfSymbol("bolt.fill"),
        "love": .sfSymbol("heart.fill"),
        "fear": .emoji("😨"),
        "surprise": .emoji("😲"),
        "hope": .sfSymbol("sun.max.fill"),
        "joy": .sfSymbol("sparkles"),
        "peace": .sfSymbol("peacesign"),
        "pride": .sfSymbol("crown.fill"),

        // Abstract
        "freedom": .sfSymbol("bird.fill"),
        "justice": .sfSymbol("scale.3d"),
        "power": .sfSymbol("bolt.fill"),
        "idea": .sfSymbol("lightbulb.fill"),
        "time": .sfSymbol("clock.fill"),
        "music": .sfSymbol("music.note"),
        "art": .sfSymbol("paintpalette.fill"),
        "science": .sfSymbol("atom"),
        "dream": .sfSymbol("moon.stars.fill"),
        "wisdom": .sfSymbol("brain.head.profile"),
        "courage": .sfSymbol("shield.fill"),
        "truth": .sfSymbol("eye.fill"),
        "beauty": .sfSymbol("sparkles"),
        "chaos": .sfSymbol("tornado"),
        "magic": .sfSymbol("wand.and.stars"),
        "energy": .sfSymbol("bolt.fill"),
        "nature": .sfSymbol("leaf.fill"),
        "machine": .sfSymbol("gearshape.fill"),
        "animal": .sfSymbol("pawprint.fill"),
        "object": .sfSymbol("cube.fill"),
        "human": .sfSymbol("person.fill")
    ]

    // MARK: - Category fallback

    private static func categoryFallback(for word: String) -> Icon {
        .sfSymbol("textformat.abc")
    }

    // MARK: - Rendering

    private static func renderSFSymbol(
        name: String,
        size: CGFloat,
        color: UIColor
    ) -> UIImage? {
        let config = UIImage.SymbolConfiguration(
            pointSize: size * 0.5,
            weight: .medium
        )
        guard let symbol = UIImage(systemName: name, withConfiguration: config) else {
            return nil
        }
        return symbol.withTintColor(color, renderingMode: .alwaysOriginal)
    }

    private static func renderEmoji(_ emoji: String, size: CGFloat) -> UIImage? {
        let fontSize = size * 0.6
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (emoji as NSString).size(withAttributes: attributes)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let origin = CGPoint(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2
            )
            (emoji as NSString).draw(at: origin, withAttributes: attributes)
        }
    }
}
