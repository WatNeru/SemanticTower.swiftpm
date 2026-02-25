import UIKit

/// 単語ごとのアイコン・形状を定義する統合データベース。
/// Dolch Word List (220 + 95 nouns) + 基本英語語彙で約1000語をカバー。
/// 外部アセット不要: SF Symbols (Apple 内蔵) + System Emoji のみ使用。
// swiftlint:disable type_body_length file_length
enum WordDatabase {

    struct Entry {
        let icon: IconType
        let shape: DiscShapeType
    }

    enum IconType {
        case sfSymbol(String)
        case emoji(String)
    }

    /// 単語のエントリを返す。未登録語はカテゴリ推定で fallback。
    static func entry(for word: String) -> Entry {
        let key = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return database[key] ?? Entry(icon: .sfSymbol("textformat.abc"), shape: .circle)
    }

    /// アイコンを UIImage としてレンダリング
    static func renderIcon(for word: String, size: CGFloat = 80, color: UIColor = .white) -> UIImage? {
        let entry = self.entry(for: word)
        switch entry.icon {
        case .sfSymbol(let name):
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
            return UIImage(systemName: name, withConfiguration: config)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
        case .emoji(let emoji):
            return renderEmoji(emoji, size: size)
        }
    }

    /// 単語の形状を返す
    static func shape(for word: String) -> DiscShapeType {
        entry(for: word).shape
    }

    private static func renderEmoji(_ emoji: String, size: CGFloat) -> UIImage? {
        let fontSize = size * 0.6
        let font = UIFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (emoji as NSString).size(withAttributes: attrs)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let origin = CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2)
            (emoji as NSString).draw(at: origin, withAttributes: attrs)
        }
    }

    // swiftlint:disable function_body_length
    private static let database: [String: Entry] = {
        var dict = [String: Entry]()
        func add(_ words: [(String, IconType)], shape: DiscShapeType) {
            for (word, icon) in words { dict[word] = Entry(icon: icon, shape: shape) }
        }

        // =====================================================================
        // ANIMALS (hexagon) — ~80 words
        // =====================================================================
        add([
            ("dog", .sfSymbol("dog.fill")), ("cat", .sfSymbol("cat.fill")),
            ("bird", .sfSymbol("bird.fill")), ("fish", .sfSymbol("fish.fill")),
            ("rabbit", .sfSymbol("hare.fill")), ("hare", .sfSymbol("hare.fill")),
            ("turtle", .sfSymbol("tortoise.fill")), ("tortoise", .sfSymbol("tortoise.fill")),
            ("ant", .sfSymbol("ant.fill")), ("bug", .sfSymbol("ladybug.fill")),
            ("lion", .emoji("🦁")), ("tiger", .emoji("🐯")), ("bear", .emoji("🐻")),
            ("elephant", .emoji("🐘")), ("horse", .emoji("🐴")), ("cow", .emoji("🐄")),
            ("pig", .emoji("🐷")), ("sheep", .emoji("🐑")), ("chicken", .emoji("🐔")),
            ("duck", .emoji("🦆")), ("eagle", .emoji("🦅")), ("whale", .emoji("🐋")),
            ("dolphin", .emoji("🐬")), ("shark", .emoji("🦈")), ("snake", .emoji("🐍")),
            ("frog", .emoji("🐸")), ("monkey", .emoji("🐵")), ("wolf", .emoji("🐺")),
            ("fox", .emoji("🦊")), ("deer", .emoji("🦌")), ("penguin", .emoji("🐧")),
            ("butterfly", .emoji("🦋")), ("bee", .emoji("🐝")), ("mouse", .emoji("🐭")),
            ("rat", .emoji("🐀")), ("squirrel", .emoji("🐿️")), ("bat", .emoji("🦇")),
            ("owl", .emoji("🦉")), ("parrot", .emoji("🦜")), ("swan", .emoji("🦢")),
            ("crab", .emoji("🦀")), ("octopus", .emoji("🐙")), ("snail", .emoji("🐌")),
            ("worm", .emoji("🪱")), ("spider", .emoji("🕷️")), ("gorilla", .emoji("🦍")),
            ("zebra", .emoji("🦓")), ("giraffe", .emoji("🦒")), ("camel", .emoji("🐪")),
            ("hippo", .emoji("🦛")), ("rhino", .emoji("🦏")), ("kangaroo", .emoji("🦘")),
            ("koala", .emoji("🐨")), ("panda", .emoji("🐼")), ("hamster", .emoji("🐹")),
            ("hedgehog", .emoji("🦔")), ("otter", .emoji("🦦")), ("beaver", .emoji("🦫")),
            ("seal", .emoji("🦭")), ("whale", .emoji("🐋")), ("lobster", .emoji("🦞")),
            ("shrimp", .emoji("🦐")), ("jellyfish", .emoji("🪼")), ("rooster", .emoji("🐓")),
            ("turkey", .emoji("🦃")), ("peacock", .emoji("🦚")), ("flamingo", .emoji("🦩")),
            ("dove", .emoji("🕊️")), ("robin", .emoji("🐦")), ("kitty", .emoji("🐱")),
            ("puppy", .emoji("🐶")), ("lamb", .emoji("🐑")), ("pony", .emoji("🐴")),
            ("animal", .sfSymbol("pawprint.fill"))
        ], shape: .hexagon)

        // =====================================================================
        // NATURE & PLANTS (flower) — ~60 words
        // =====================================================================
        add([
            ("tree", .sfSymbol("tree.fill")), ("leaf", .sfSymbol("leaf.fill")),
            ("flower", .emoji("🌸")), ("forest", .sfSymbol("tree.fill")),
            ("river", .sfSymbol("water.waves")), ("ocean", .sfSymbol("water.waves")),
            ("mountain", .sfSymbol("mountain.2.fill")), ("lake", .emoji("🏞️")),
            ("island", .emoji("🏝️")), ("volcano", .emoji("🌋")),
            ("garden", .emoji("🌻")), ("grass", .emoji("🌿")),
            ("seed", .emoji("🌱")), ("rose", .emoji("🌹")),
            ("corn", .emoji("🌽")), ("mushroom", .emoji("🍄")),
            ("cactus", .emoji("🌵")), ("wood", .emoji("🪵")),
            ("bamboo", .emoji("🎋")), ("moss", .emoji("🌿")),
            ("field", .emoji("🌾")), ("hill", .sfSymbol("triangle.fill")),
            ("valley", .emoji("🏞️")), ("cliff", .emoji("🧗")),
            ("desert", .emoji("🏜️")), ("jungle", .emoji("🌴")),
            ("pond", .emoji("🏞️")), ("creek", .sfSymbol("water.waves")),
            ("waterfall", .emoji("💧")), ("beach", .emoji("🏖️")),
            ("reef", .emoji("🪸")), ("nest", .emoji("🪺")),
            ("nature", .sfSymbol("leaf.fill")), ("earth", .sfSymbol("globe.americas.fill")),
            ("ground", .emoji("🟤")), ("soil", .emoji("🟤")),
            ("rock", .emoji("🪨")), ("stone", .emoji("🪨")),
            ("sand", .emoji("🏖️")), ("cave", .emoji("🕳️")),
            ("spring", .sfSymbol("drop.fill")), ("stream", .sfSymbol("water.waves"))
        ], shape: .flower)

        // =====================================================================
        // WEATHER & SKY (cloud) — ~30 words
        // =====================================================================
        add([
            ("sun", .sfSymbol("sun.max.fill")), ("moon", .sfSymbol("moon.fill")),
            ("star", .sfSymbol("star.fill")), ("cloud", .sfSymbol("cloud.fill")),
            ("rain", .sfSymbol("cloud.rain.fill")), ("snow", .sfSymbol("snowflake")),
            ("wind", .sfSymbol("wind")), ("storm", .sfSymbol("cloud.bolt.fill")),
            ("thunder", .sfSymbol("cloud.bolt.fill")),
            ("lightning", .sfSymbol("bolt.fill")),
            ("rainbow", .emoji("🌈")), ("fog", .sfSymbol("cloud.fog.fill")),
            ("ice", .emoji("🧊")), ("frost", .sfSymbol("snowflake")),
            ("sky", .sfSymbol("sun.max.fill")), ("sunset", .emoji("🌅")),
            ("sunrise", .emoji("🌄")), ("tornado", .sfSymbol("tornado")),
            ("hurricane", .sfSymbol("hurricane")), ("hail", .emoji("🌨️")),
            ("night", .sfSymbol("moon.stars.fill")),
            ("morning", .sfSymbol("sunrise.fill")),
            ("day", .sfSymbol("sun.max.fill")),
            ("weather", .sfSymbol("cloud.sun.fill"))
        ], shape: .cloud)

        // =====================================================================
        // FOOD & DRINK (diamond) — ~60 words
        // =====================================================================
        add([
            ("apple", .emoji("🍎")), ("bread", .emoji("🍞")),
            ("cake", .emoji("🎂")), ("milk", .emoji("🥛")),
            ("egg", .emoji("🥚")), ("water", .sfSymbol("drop.fill")),
            ("rice", .emoji("🍚")), ("meat", .emoji("🥩")),
            ("pizza", .emoji("🍕")), ("soup", .emoji("🍲")),
            ("cookie", .emoji("🍪")), ("candy", .emoji("🍬")),
            ("banana", .emoji("🍌")), ("orange", .emoji("🍊")),
            ("grape", .emoji("🍇")), ("lemon", .emoji("🍋")),
            ("strawberry", .emoji("🍓")), ("cherry", .emoji("🍒")),
            ("peach", .emoji("🍑")), ("melon", .emoji("🍈")),
            ("tomato", .emoji("🍅")), ("potato", .emoji("🥔")),
            ("carrot", .emoji("🥕")), ("onion", .emoji("🧅")),
            ("cheese", .emoji("🧀")), ("butter", .emoji("🧈")),
            ("honey", .emoji("🍯")), ("salt", .emoji("🧂")),
            ("sugar", .emoji("🍬")), ("coffee", .emoji("☕")),
            ("tea", .emoji("🍵")), ("juice", .emoji("🧃")),
            ("chocolate", .emoji("🍫")), ("pie", .emoji("🥧")),
            ("sandwich", .emoji("🥪")), ("burger", .emoji("🍔")),
            ("pasta", .emoji("🍝")), ("salad", .emoji("🥗")),
            ("fish", .emoji("🐟")), ("chicken", .emoji("🍗")),
            ("food", .emoji("🍽️")), ("meal", .emoji("🍽️")),
            ("breakfast", .emoji("🥞")), ("lunch", .emoji("🥪")),
            ("dinner", .emoji("🍽️")), ("snack", .emoji("🍿")),
            ("fruit", .emoji("🍎")), ("vegetable", .emoji("🥦")),
            ("nut", .emoji("🥜")), ("berry", .emoji("🫐"))
        ], shape: .diamond)

        // =====================================================================
        // MACHINES & TRANSPORT (gear) — ~60 words
        // =====================================================================
        add([
            ("car", .sfSymbol("car.fill")), ("bus", .sfSymbol("bus.fill")),
            ("train", .sfSymbol("train.side.front.car")),
            ("airplane", .sfSymbol("airplane")), ("ship", .sfSymbol("ferry.fill")),
            ("bicycle", .sfSymbol("bicycle")), ("truck", .emoji("🚛")),
            ("boat", .emoji("⛵")), ("rocket", .emoji("🚀")),
            ("helicopter", .emoji("🚁")), ("motorcycle", .emoji("🏍️")),
            ("submarine", .emoji("🛥️")), ("taxi", .emoji("🚕")),
            ("ambulance", .emoji("🚑")),
            ("computer", .sfSymbol("desktopcomputer")),
            ("phone", .sfSymbol("iphone")), ("camera", .sfSymbol("camera.fill")),
            ("robot", .emoji("🤖")), ("engine", .sfSymbol("engine.combustion.fill")),
            ("battery", .sfSymbol("battery.100")),
            ("satellite", .emoji("🛰️")), ("drone", .emoji("🛸")),
            ("television", .emoji("📺")), ("radio", .emoji("📻")),
            ("clock", .sfSymbol("clock.fill")), ("watch", .emoji("⌚")),
            ("screen", .sfSymbol("display")), ("keyboard", .sfSymbol("keyboard")),
            ("printer", .sfSymbol("printer.fill")),
            ("microphone", .sfSymbol("mic.fill")),
            ("speaker", .sfSymbol("speaker.wave.3.fill")),
            ("headphone", .sfSymbol("headphones")),
            ("machine", .sfSymbol("gearshape.fill")),
            ("wheel", .emoji("☸️")), ("motor", .sfSymbol("engine.combustion.fill")),
            ("wire", .emoji("🔌")), ("plug", .emoji("🔌")),
            ("scooter", .emoji("🛴")), ("van", .emoji("🚐")),
            ("tractor", .emoji("🚜")), ("excavator", .emoji("🏗️")),
            ("crane", .emoji("🏗️")), ("elevator", .emoji("🛗")),
            ("escalator", .emoji("🛗")), ("radar", .emoji("📡")),
            ("telescope", .emoji("🔭")), ("microscope", .emoji("🔬")),
            ("thermometer", .emoji("🌡️")), ("compass", .emoji("🧭")),
            ("magnet", .emoji("🧲")), ("gear", .sfSymbol("gearshape.fill"))
        ], shape: .gear)

        // =====================================================================
        // HOUSEHOLD & OBJECTS (diamond) — ~80 words
        // =====================================================================
        add([
            ("chair", .sfSymbol("chair.fill")), ("table", .sfSymbol("table.furniture.fill")),
            ("book", .sfSymbol("book.fill")), ("pen", .sfSymbol("pencil")),
            ("pencil", .sfSymbol("pencil")), ("paper", .emoji("📄")),
            ("door", .emoji("🚪")), ("window", .emoji("🪟")),
            ("bed", .emoji("🛏️")), ("lamp", .sfSymbol("lamp.desk.fill")),
            ("cup", .sfSymbol("cup.and.saucer.fill")), ("plate", .emoji("🍽️")),
            ("bottle", .emoji("🍼")), ("box", .sfSymbol("shippingbox.fill")),
            ("bag", .sfSymbol("bag.fill")), ("key", .sfSymbol("key.fill")),
            ("lock", .sfSymbol("lock.fill")), ("bell", .sfSymbol("bell.fill")),
            ("ball", .sfSymbol("soccerball")), ("toy", .emoji("🧸")),
            ("doll", .emoji("🪆")), ("game", .sfSymbol("gamecontroller.fill")),
            ("gift", .sfSymbol("gift.fill")), ("ring", .emoji("💍")),
            ("hat", .emoji("🎩")), ("shoe", .emoji("👟")),
            ("coat", .emoji("🧥")), ("dress", .emoji("👗")),
            ("shirt", .emoji("👕")), ("pants", .emoji("👖")),
            ("glasses", .emoji("👓")), ("umbrella", .emoji("☂️")),
            ("mirror", .emoji("🪞")), ("brush", .emoji("🪥")),
            ("soap", .emoji("🧼")), ("towel", .emoji("🧻")),
            ("basket", .emoji("🧺")), ("bucket", .emoji("🪣")),
            ("candle", .emoji("🕯️")), ("flag", .emoji("🚩")),
            ("map", .sfSymbol("map.fill")), ("ticket", .emoji("🎫")),
            ("money", .emoji("💰")), ("coin", .emoji("🪙")),
            ("letter", .sfSymbol("envelope.fill")),
            ("picture", .sfSymbol("photo.fill")),
            ("hammer", .sfSymbol("hammer.fill")),
            ("guitar", .sfSymbol("guitars.fill")),
            ("drum", .emoji("🥁")), ("piano", .sfSymbol("pianokeys")),
            ("violin", .emoji("🎻")), ("trumpet", .emoji("🎺")),
            ("knife", .emoji("🔪")), ("fork", .emoji("🍴")),
            ("spoon", .emoji("🥄")), ("scissors", .sfSymbol("scissors")),
            ("needle", .emoji("🪡")), ("thread", .emoji("🧵")),
            ("rope", .emoji("🪢")), ("chain", .sfSymbol("link")),
            ("fence", .emoji("🏗️")), ("ladder", .emoji("🪜")),
            ("pillow", .emoji("🛏️")), ("blanket", .emoji("🛏️")),
            ("carpet", .emoji("🟫")), ("shelf", .emoji("📚")),
            ("clock", .sfSymbol("clock.fill")), ("stick", .emoji("🏏")),
            ("string", .emoji("🧵")), ("thing", .sfSymbol("cube.fill")),
            ("top", .emoji("🔝")), ("floor", .emoji("⬛")),
            ("wall", .emoji("🧱")), ("roof", .emoji("🏠")),
            ("crown", .sfSymbol("crown.fill")),
            ("shield", .sfSymbol("shield.fill")),
            ("sword", .emoji("⚔️")), ("diamond", .emoji("💎")),
            ("object", .sfSymbol("cube.fill")),
            ("street", .emoji("🛣️")), ("way", .sfSymbol("arrow.right")),
            ("home", .sfSymbol("house.fill")), ("house", .sfSymbol("house.fill"))
        ], shape: .diamond)

        // =====================================================================
        // PLACES & BUILDINGS (rounded) — ~40 words
        // =====================================================================
        add([
            ("school", .emoji("🏫")), ("church", .emoji("⛪")),
            ("hospital", .emoji("🏥")), ("store", .emoji("🏪")),
            ("restaurant", .emoji("🍴")), ("hotel", .emoji("🏨")),
            ("library", .emoji("📚")), ("museum", .emoji("🏛️")),
            ("park", .emoji("🌳")), ("farm", .emoji("🌾")),
            ("city", .emoji("🏙️")), ("town", .emoji("🏘️")),
            ("village", .emoji("🏘️")), ("country", .sfSymbol("globe.americas.fill")),
            ("world", .sfSymbol("globe.americas.fill")),
            ("room", .emoji("🚪")), ("kitchen", .emoji("🍳")),
            ("bathroom", .emoji("🚿")), ("bedroom", .emoji("🛏️")),
            ("office", .emoji("🏢")), ("factory", .emoji("🏭")),
            ("airport", .emoji("✈️")), ("station", .emoji("🚉")),
            ("bridge", .emoji("🌉")), ("road", .emoji("🛣️")),
            ("market", .emoji("🏪")), ("bank", .emoji("🏦")),
            ("theater", .emoji("🎭")), ("stadium", .emoji("🏟️")),
            ("gym", .emoji("🏋️")), ("pool", .emoji("🏊")),
            ("zoo", .emoji("🦁")), ("circus", .emoji("🎪")),
            ("castle", .emoji("🏰")), ("palace", .emoji("🏛️")),
            ("temple", .emoji("⛩️")), ("tower", .emoji("🗼")),
            ("prison", .emoji("🔒")), ("camp", .emoji("🏕️"))
        ], shape: .rounded)

        // =====================================================================
        // PEOPLE & BODY (circle) — ~60 words
        // =====================================================================
        add([
            ("baby", .emoji("👶")), ("boy", .emoji("👦")),
            ("girl", .emoji("👧")), ("man", .sfSymbol("person.fill")),
            ("men", .sfSymbol("person.2.fill")),
            ("woman", .emoji("👩")), ("child", .emoji("🧒")),
            ("children", .emoji("👧")), ("mother", .emoji("👩")),
            ("father", .emoji("👨")), ("brother", .emoji("👦")),
            ("sister", .emoji("👧")), ("family", .sfSymbol("person.3.fill")),
            ("friend", .sfSymbol("person.2.fill")),
            ("teacher", .emoji("👩‍🏫")), ("doctor", .emoji("👨‍⚕️")),
            ("farmer", .emoji("👨‍🌾")), ("king", .emoji("👑")),
            ("queen", .emoji("👑")), ("prince", .emoji("🤴")),
            ("princess", .emoji("👸")), ("soldier", .emoji("💂")),
            ("police", .emoji("👮")), ("pilot", .emoji("✈️")),
            ("nurse", .emoji("👩‍⚕️")), ("artist", .emoji("🎨")),
            ("singer", .emoji("🎤")), ("dancer", .emoji("💃")),
            ("player", .emoji("⚽")), ("hero", .emoji("🦸")),
            ("human", .sfSymbol("person.fill")), ("people", .sfSymbol("person.3.fill")),
            ("hand", .emoji("✋")), ("head", .emoji("🧠")),
            ("eye", .sfSymbol("eye.fill")), ("ear", .emoji("👂")),
            ("nose", .emoji("👃")), ("mouth", .emoji("👄")),
            ("face", .sfSymbol("face.smiling")),
            ("foot", .emoji("🦶")), ("feet", .emoji("🦶")),
            ("leg", .emoji("🦵")), ("arm", .emoji("💪")),
            ("finger", .emoji("☝️")), ("tooth", .emoji("🦷")),
            ("hair", .emoji("💇")), ("heart", .sfSymbol("heart.fill")),
            ("brain", .sfSymbol("brain.head.profile")),
            ("bone", .emoji("🦴")), ("blood", .emoji("🩸")),
            ("body", .sfSymbol("figure.stand")),
            ("name", .sfSymbol("person.text.rectangle.fill")),
            ("Santa", .emoji("🎅")), ("birthday", .emoji("🎂")),
            ("party", .emoji("🎉")), ("Christmas", .emoji("🎄"))
        ], shape: .circle)

        // =====================================================================
        // EMOTIONS & FEELINGS (heart) — ~50 words
        // =====================================================================
        add([
            ("happy", .sfSymbol("face.smiling")),
            ("sad", .emoji("😢")), ("angry", .emoji("😤")),
            ("calm", .sfSymbol("leaf.fill")),
            ("excited", .sfSymbol("bolt.fill")),
            ("scared", .emoji("😨")), ("afraid", .emoji("😨")),
            ("brave", .sfSymbol("shield.fill")),
            ("tired", .emoji("😴")), ("hungry", .emoji("🍽️")),
            ("thirsty", .emoji("💧")), ("sick", .emoji("🤒")),
            ("lonely", .emoji("😔")), ("proud", .sfSymbol("crown.fill")),
            ("shy", .emoji("😊")), ("kind", .sfSymbol("heart.fill")),
            ("mean", .emoji("😠")), ("funny", .sfSymbol("face.smiling")),
            ("silly", .emoji("🤪")), ("smart", .sfSymbol("brain.head.profile")),
            ("strong", .emoji("💪")), ("weak", .emoji("😰")),
            ("fast", .sfSymbol("hare.fill")), ("slow", .sfSymbol("tortoise.fill")),
            ("love", .sfSymbol("heart.fill")), ("hate", .emoji("💔")),
            ("fear", .emoji("😨")), ("hope", .sfSymbol("sun.max.fill")),
            ("joy", .sfSymbol("sparkles")), ("peace", .sfSymbol("peacesign")),
            ("anger", .emoji("😡")), ("surprise", .emoji("😲")),
            ("worry", .emoji("😟")), ("trust", .sfSymbol("handshake.fill")),
            ("comfort", .sfSymbol("heart.fill")),
            ("pain", .emoji("😣")), ("pleasure", .emoji("😌")),
            ("pride", .sfSymbol("crown.fill")),
            ("shame", .emoji("😳")), ("guilt", .emoji("😞")),
            ("envy", .emoji("😒")), ("jealousy", .emoji("😒")),
            ("gratitude", .sfSymbol("heart.fill")),
            ("sympathy", .sfSymbol("heart.fill")),
            ("wonder", .sfSymbol("sparkles")),
            ("bored", .emoji("😑")), ("confused", .emoji("😕")),
            ("curious", .sfSymbol("questionmark.circle.fill")),
            ("good-bye", .emoji("👋")), ("goodbye", .emoji("👋"))
        ], shape: .heart)

        // =====================================================================
        // ABSTRACT & IDEAS (star) — ~60 words
        // =====================================================================
        add([
            ("freedom", .sfSymbol("bird.fill")),
            ("justice", .sfSymbol("scale.3d")),
            ("power", .sfSymbol("bolt.fill")),
            ("idea", .sfSymbol("lightbulb.fill")),
            ("time", .sfSymbol("clock.fill")),
            ("music", .sfSymbol("music.note")),
            ("art", .sfSymbol("paintpalette.fill")),
            ("science", .sfSymbol("atom")),
            ("dream", .sfSymbol("moon.stars.fill")),
            ("wisdom", .sfSymbol("brain.head.profile")),
            ("courage", .sfSymbol("shield.fill")),
            ("truth", .sfSymbol("eye.fill")),
            ("beauty", .sfSymbol("sparkles")),
            ("chaos", .sfSymbol("tornado")),
            ("magic", .sfSymbol("wand.and.stars")),
            ("energy", .sfSymbol("bolt.fill")),
            ("life", .sfSymbol("heart.fill")),
            ("death", .emoji("💀")),
            ("war", .emoji("⚔️")), ("peace", .sfSymbol("peacesign")),
            ("luck", .sfSymbol("clover.fill")),
            ("fate", .sfSymbol("star.fill")),
            ("soul", .sfSymbol("sparkles")),
            ("mind", .sfSymbol("brain.head.profile")),
            ("spirit", .sfSymbol("wind")),
            ("faith", .sfSymbol("hands.clap.fill")),
            ("story", .sfSymbol("book.fill")),
            ("history", .sfSymbol("clock.fill")),
            ("future", .sfSymbol("arrow.right")),
            ("secret", .sfSymbol("lock.fill")),
            ("mystery", .sfSymbol("questionmark.circle.fill")),
            ("adventure", .sfSymbol("map.fill")),
            ("memory", .sfSymbol("brain.head.profile")),
            ("knowledge", .sfSymbol("book.fill")),
            ("education", .emoji("🎓")),
            ("culture", .emoji("🎭")),
            ("language", .sfSymbol("textformat.abc")),
            ("number", .sfSymbol("number")),
            ("letter", .sfSymbol("envelope.fill")),
            ("word", .sfSymbol("textformat.abc")),
            ("song", .sfSymbol("music.note")),
            ("color", .sfSymbol("paintpalette.fill")),
            ("shape", .sfSymbol("square.on.circle")),
            ("size", .sfSymbol("arrow.up.left.and.arrow.down.right")),
            ("space", .emoji("🌌")),
            ("law", .sfSymbol("scale.3d")),
            ("rule", .sfSymbol("checklist")),
            ("right", .sfSymbol("checkmark.circle.fill")),
            ("wrong", .sfSymbol("xmark.circle.fill")),
            ("problem", .sfSymbol("exclamationmark.triangle.fill")),
            ("answer", .sfSymbol("checkmark.circle.fill")),
            ("question", .sfSymbol("questionmark.circle.fill")),
            ("reason", .sfSymbol("brain.head.profile")),
            ("chance", .sfSymbol("dice.fill"))
        ], shape: .star)

        // =====================================================================
        // ACTIONS & VERBS (rounded) — ~200 words
        // =====================================================================
        add([
            ("run", .sfSymbol("figure.run")), ("walk", .sfSymbol("figure.walk")),
            ("jump", .sfSymbol("figure.jumprope")),
            ("swim", .sfSymbol("figure.pool.swim")),
            ("fly", .sfSymbol("airplane")), ("ride", .sfSymbol("bicycle")),
            ("drive", .sfSymbol("car.fill")), ("climb", .emoji("🧗")),
            ("dance", .emoji("💃")), ("sing", .sfSymbol("music.mic")),
            ("play", .sfSymbol("gamecontroller.fill")),
            ("work", .sfSymbol("briefcase.fill")),
            ("read", .sfSymbol("book.fill")), ("write", .sfSymbol("pencil")),
            ("draw", .sfSymbol("paintbrush.fill")),
            ("paint", .sfSymbol("paintpalette.fill")),
            ("cook", .emoji("🍳")), ("eat", .emoji("🍽️")),
            ("drink", .sfSymbol("cup.and.saucer.fill")),
            ("sleep", .sfSymbol("bed.double.fill")),
            ("wake", .sfSymbol("alarm.fill")),
            ("sit", .sfSymbol("chair.fill")),
            ("stand", .sfSymbol("figure.stand")),
            ("stop", .sfSymbol("stop.fill")),
            ("start", .sfSymbol("play.fill")),
            ("open", .sfSymbol("door.left.hand.open")),
            ("close", .sfSymbol("door.left.hand.closed")),
            ("push", .sfSymbol("arrow.right")),
            ("pull", .sfSymbol("arrow.left")),
            ("throw", .emoji("🤾")), ("catch", .emoji("🤲")),
            ("kick", .emoji("🦶")), ("hit", .sfSymbol("bolt.fill")),
            ("cut", .sfSymbol("scissors")),
            ("break", .emoji("💥")), ("fix", .sfSymbol("wrench.fill")),
            ("build", .sfSymbol("hammer.fill")),
            ("make", .sfSymbol("hammer.fill")),
            ("create", .sfSymbol("sparkles")),
            ("find", .sfSymbol("magnifyingglass")),
            ("look", .sfSymbol("eye.fill")),
            ("see", .sfSymbol("eye.fill")),
            ("watch", .sfSymbol("eye.fill")),
            ("hear", .sfSymbol("ear.fill")),
            ("listen", .sfSymbol("ear.fill")),
            ("speak", .sfSymbol("mouth.fill")),
            ("talk", .sfSymbol("bubble.left.fill")),
            ("say", .sfSymbol("bubble.left.fill")),
            ("tell", .sfSymbol("bubble.left.fill")),
            ("ask", .sfSymbol("questionmark.bubble.fill")),
            ("think", .sfSymbol("brain.head.profile")),
            ("know", .sfSymbol("lightbulb.fill")),
            ("learn", .sfSymbol("book.fill")),
            ("teach", .emoji("👩‍🏫")),
            ("study", .sfSymbol("book.fill")),
            ("try", .sfSymbol("arrow.right")),
            ("help", .sfSymbol("hand.raised.fill")),
            ("give", .sfSymbol("gift.fill")),
            ("take", .sfSymbol("hand.point.right.fill")),
            ("put", .sfSymbol("arrow.down")),
            ("get", .sfSymbol("hand.point.right.fill")),
            ("come", .sfSymbol("arrow.right")),
            ("go", .sfSymbol("arrow.right")),
            ("bring", .sfSymbol("hand.point.right.fill")),
            ("carry", .sfSymbol("shippingbox.fill")),
            ("hold", .sfSymbol("hand.raised.fill")),
            ("drop", .sfSymbol("arrow.down")),
            ("pick", .sfSymbol("hand.point.up.fill")),
            ("buy", .sfSymbol("cart.fill")),
            ("sell", .sfSymbol("dollarsign.circle.fill")),
            ("pay", .sfSymbol("creditcard.fill")),
            ("send", .sfSymbol("paperplane.fill")),
            ("call", .sfSymbol("phone.fill")),
            ("show", .sfSymbol("hand.point.right.fill")),
            ("hide", .sfSymbol("eye.slash.fill")),
            ("keep", .sfSymbol("lock.fill")),
            ("lose", .sfSymbol("xmark.circle.fill")),
            ("win", .sfSymbol("trophy.fill")),
            ("fight", .emoji("🥊")),
            ("save", .sfSymbol("arrow.down.doc.fill")),
            ("move", .sfSymbol("arrow.right")),
            ("turn", .sfSymbol("arrow.turn.right.up")),
            ("grow", .sfSymbol("arrow.up")),
            ("fall", .sfSymbol("arrow.down")),
            ("rise", .sfSymbol("arrow.up")),
            ("change", .sfSymbol("arrow.triangle.2.circlepath")),
            ("wait", .sfSymbol("clock.fill")),
            ("wish", .sfSymbol("star.fill")),
            ("need", .sfSymbol("exclamationmark.circle.fill")),
            ("want", .sfSymbol("heart.fill")),
            ("like", .sfSymbol("hand.thumbsup.fill")),
            ("love", .sfSymbol("heart.fill")),
            ("begin", .sfSymbol("play.fill")),
            ("end", .sfSymbol("stop.fill")),
            ("finish", .sfSymbol("checkmark.circle.fill")),
            ("live", .sfSymbol("heart.fill")),
            ("die", .emoji("💀")),
            ("laugh", .emoji("😂")),
            ("cry", .emoji("😢")),
            ("smile", .sfSymbol("face.smiling")),
            ("clean", .sfSymbol("sparkles")),
            ("wash", .emoji("🧼")),
            ("fill", .sfSymbol("arrow.up")),
            ("pour", .emoji("🫗")),
            ("mix", .sfSymbol("arrow.triangle.2.circlepath")),
            ("plant", .sfSymbol("leaf.fill")),
            ("dig", .emoji("⛏️")),
            ("feed", .emoji("🍽️")),
            ("cross", .sfSymbol("arrow.left.and.right")),
            ("pass", .sfSymbol("arrow.right")),
            ("follow", .sfSymbol("arrow.right")),
            ("lead", .sfSymbol("arrow.right")),
            ("share", .sfSymbol("square.and.arrow.up")),
            ("add", .sfSymbol("plus.circle.fill")),
            ("count", .sfSymbol("number")),
            ("measure", .sfSymbol("ruler.fill")),
            ("guess", .sfSymbol("questionmark.circle.fill")),
            ("choose", .sfSymbol("checkmark.circle.fill")),
            ("decide", .sfSymbol("checkmark.circle.fill")),
            ("agree", .sfSymbol("hand.thumbsup.fill")),
            ("promise", .sfSymbol("handshake.fill")),
            ("allow", .sfSymbol("checkmark.circle.fill")),
            ("visit", .sfSymbol("figure.walk")),
            ("travel", .sfSymbol("airplane")),
            ("arrive", .sfSymbol("arrow.down")),
            ("leave", .sfSymbol("arrow.right")),
            ("return", .sfSymbol("arrow.uturn.left")),
            ("enter", .sfSymbol("door.left.hand.open")),
            ("exit", .sfSymbol("arrow.right.square")),
            ("rest", .sfSymbol("bed.double.fill")),
            ("exercise", .sfSymbol("figure.run")),
            ("practice", .sfSymbol("arrow.triangle.2.circlepath")),
            ("celebrate", .emoji("🎉")),
            ("compete", .sfSymbol("trophy.fill")),
            ("explore", .sfSymbol("binoculars.fill")),
            ("discover", .sfSymbol("magnifyingglass")),
            ("invent", .sfSymbol("lightbulb.fill")),
            ("imagine", .sfSymbol("sparkles")),
            ("believe", .sfSymbol("star.fill")),
            ("forget", .sfSymbol("brain.head.profile")),
            ("remember", .sfSymbol("brain.head.profile")),
            ("understand", .sfSymbol("lightbulb.fill")),
            ("explain", .sfSymbol("bubble.left.fill")),
            ("answer", .sfSymbol("checkmark.circle.fill")),
            ("solve", .sfSymbol("lightbulb.fill")),
            ("test", .sfSymbol("checklist")),
            ("check", .sfSymbol("checkmark")),
            ("prepare", .sfSymbol("checklist")),
            ("plan", .sfSymbol("calendar")),
            ("organize", .sfSymbol("tray.full.fill"))
        ], shape: .rounded)

        // =====================================================================
        // DOLCH FUNCTION WORDS (circle) — articles, prepositions, etc.
        // =====================================================================
        let functionWords = [
            "a", "an", "the", "and", "but", "or", "if", "so", "at", "by",
            "in", "on", "to", "up", "of", "for", "with", "from", "into",
            "about", "after", "before", "between", "under", "over", "around",
            "through", "during", "without", "against", "along", "across",
            "behind", "below", "above", "beside", "beyond", "near", "off",
            "out", "down", "away", "here", "there", "where", "when", "how",
            "what", "which", "who", "why", "that", "this", "these", "those",
            "not", "no", "yes", "all", "some", "any", "every", "each",
            "much", "many", "more", "most", "less", "few", "other",
            "both", "either", "neither", "own", "same", "such",
            "very", "too", "also", "just", "only", "still", "already",
            "never", "always", "often", "sometimes", "usually", "again",
            "once", "twice", "soon", "now", "then", "today", "tomorrow",
            "yesterday", "tonight", "together", "apart", "else",
            "please", "thank", "sorry", "hello", "well", "okay",
            "because", "since", "although", "while", "until",
            "I", "me", "my", "we", "us", "our", "you", "your",
            "he", "him", "his", "she", "her", "it", "its",
            "they", "them", "their", "myself", "himself", "herself",
            "am", "is", "are", "was", "were", "be", "been", "being",
            "do", "does", "did", "done", "have", "has", "had",
            "will", "would", "shall", "should", "can", "could",
            "may", "might", "must", "let"
        ]
        for word in functionWords {
            if dict[word] == nil {
                dict[word] = Entry(icon: .sfSymbol("textformat.abc"), shape: .circle)
            }
        }

        // =====================================================================
        // ADJECTIVES & DESCRIPTORS (star) — ~80 words
        // =====================================================================
        let adjectives: [(String, IconType)] = [
            ("big", .sfSymbol("arrow.up.left.and.arrow.down.right")),
            ("small", .sfSymbol("arrow.down.right.and.arrow.up.left")),
            ("little", .sfSymbol("arrow.down.right.and.arrow.up.left")),
            ("tall", .sfSymbol("arrow.up")),
            ("short", .sfSymbol("arrow.down")),
            ("long", .sfSymbol("arrow.left.and.right")),
            ("wide", .sfSymbol("arrow.left.and.right")),
            ("thin", .sfSymbol("minus")),
            ("thick", .sfSymbol("rectangle.fill")),
            ("heavy", .sfSymbol("scalemass.fill")),
            ("light", .sfSymbol("sun.max.fill")),
            ("hard", .sfSymbol("cube.fill")),
            ("soft", .sfSymbol("cloud.fill")),
            ("hot", .sfSymbol("flame.fill")),
            ("cold", .sfSymbol("snowflake")),
            ("warm", .sfSymbol("sun.max.fill")),
            ("cool", .sfSymbol("wind")),
            ("new", .sfSymbol("sparkles")),
            ("old", .sfSymbol("clock.fill")),
            ("young", .emoji("👶")),
            ("clean", .sfSymbol("sparkles")),
            ("dirty", .emoji("💩")),
            ("wet", .sfSymbol("drop.fill")),
            ("dry", .sfSymbol("sun.max.fill")),
            ("dark", .sfSymbol("moon.fill")),
            ("bright", .sfSymbol("sun.max.fill")),
            ("loud", .sfSymbol("speaker.wave.3.fill")),
            ("quiet", .sfSymbol("speaker.slash.fill")),
            ("full", .sfSymbol("circle.fill")),
            ("empty", .sfSymbol("circle")),
            ("open", .sfSymbol("door.left.hand.open")),
            ("closed", .sfSymbol("door.left.hand.closed")),
            ("rich", .emoji("💰")),
            ("poor", .emoji("😢")),
            ("safe", .sfSymbol("shield.fill")),
            ("dangerous", .sfSymbol("exclamationmark.triangle.fill")),
            ("easy", .sfSymbol("checkmark.circle.fill")),
            ("difficult", .sfSymbol("xmark.circle.fill")),
            ("free", .sfSymbol("bird.fill")),
            ("busy", .sfSymbol("clock.fill")),
            ("ready", .sfSymbol("checkmark.circle.fill")),
            ("pretty", .sfSymbol("sparkles")),
            ("beautiful", .sfSymbol("sparkles")),
            ("ugly", .emoji("👹")),
            ("round", .sfSymbol("circle.fill")),
            ("flat", .sfSymbol("rectangle.fill")),
            ("sharp", .sfSymbol("triangle.fill")),
            ("smooth", .sfSymbol("circle.fill")),
            ("rough", .emoji("🪨")),
            ("sweet", .emoji("🍬")),
            ("sour", .emoji("🍋")),
            ("bitter", .emoji("😖")),
            ("fresh", .sfSymbol("leaf.fill")),
            ("rotten", .emoji("🤢")),
            ("alive", .sfSymbol("heart.fill")),
            ("dead", .emoji("💀")),
            ("true", .sfSymbol("checkmark.circle.fill")),
            ("false", .sfSymbol("xmark.circle.fill")),
            ("real", .sfSymbol("checkmark.circle.fill")),
            ("fake", .sfSymbol("xmark.circle.fill")),
            ("important", .sfSymbol("exclamationmark.circle.fill")),
            ("simple", .sfSymbol("circle")),
            ("complex", .sfSymbol("circle.grid.3x3.fill")),
            ("strange", .sfSymbol("questionmark.circle.fill")),
            ("normal", .sfSymbol("equal.circle.fill")),
            ("special", .sfSymbol("star.fill")),
            ("common", .sfSymbol("circle.fill")),
            ("rare", .sfSymbol("diamond.fill")),
            ("perfect", .sfSymbol("checkmark.seal.fill")),
            ("broken", .emoji("💔")),
            ("whole", .sfSymbol("circle.fill")),
            ("red", .emoji("🔴")), ("blue", .emoji("🔵")),
            ("green", .emoji("🟢")), ("yellow", .emoji("🟡")),
            ("black", .emoji("⚫")), ("white", .emoji("⚪")),
            ("brown", .emoji("🟤")), ("pink", .emoji("🩷")),
            ("purple", .emoji("🟣")), ("gray", .emoji("⚪"))
        ]
        add(adjectives, shape: .star)

        // =====================================================================
        // SPORTS & ACTIVITIES (rounded) — ~50 words
        // =====================================================================
        add([
            ("soccer", .emoji("⚽")), ("football", .emoji("🏈")),
            ("basketball", .emoji("🏀")), ("baseball", .emoji("⚾")),
            ("tennis", .emoji("🎾")), ("volleyball", .emoji("🏐")),
            ("golf", .emoji("⛳")), ("bowling", .emoji("🎳")),
            ("hockey", .emoji("🏒")), ("cricket", .emoji("🏏")),
            ("rugby", .emoji("🏉")), ("boxing", .emoji("🥊")),
            ("wrestling", .emoji("🤼")), ("fencing", .emoji("🤺")),
            ("surfing", .emoji("🏄")), ("skiing", .emoji("⛷️")),
            ("skating", .emoji("⛸️")), ("snowboarding", .emoji("🏂")),
            ("cycling", .sfSymbol("bicycle")), ("rowing", .emoji("🚣")),
            ("archery", .emoji("🏹")), ("fishing", .emoji("🎣")),
            ("hunting", .emoji("🏹")), ("camping", .emoji("🏕️")),
            ("hiking", .sfSymbol("figure.hiking")),
            ("climbing", .emoji("🧗")), ("yoga", .emoji("🧘")),
            ("martial", .emoji("🥋")), ("karate", .emoji("🥋")),
            ("judo", .emoji("🥋")), ("medal", .emoji("🏅")),
            ("trophy", .sfSymbol("trophy.fill")),
            ("race", .sfSymbol("flag.checkered")),
            ("match", .emoji("🏟️")), ("score", .sfSymbol("number")),
            ("goal", .emoji("🥅")), ("team", .sfSymbol("person.3.fill")),
            ("coach", .emoji("📋")), ("athlete", .sfSymbol("figure.run")),
            ("champion", .sfSymbol("trophy.fill")),
            ("sport", .emoji("🏆")), ("gym", .emoji("🏋️")),
            ("pool", .emoji("🏊")), ("stadium", .emoji("🏟️")),
            ("playground", .emoji("🛝")), ("swing", .emoji("🛝")),
            ("slide", .emoji("🛝")), ("puzzle", .emoji("🧩")),
            ("chess", .emoji("♟️")), ("dice", .sfSymbol("dice.fill"))
        ], shape: .rounded)

        // =====================================================================
        // TOOLS & WORK (gear) — ~30 words
        // =====================================================================
        add([
            ("wrench", .sfSymbol("wrench.fill")),
            ("saw", .emoji("🪚")), ("axe", .emoji("🪓")),
            ("drill", .emoji("🔩")), ("nail", .emoji("🔩")),
            ("screw", .emoji("🔩")), ("bolt", .sfSymbol("bolt.fill")),
            ("tape", .emoji("📏")), ("ruler", .sfSymbol("ruler.fill")),
            ("paintbrush", .sfSymbol("paintbrush.fill")),
            ("shovel", .emoji("⛏️")), ("rake", .emoji("🧹")),
            ("broom", .emoji("🧹")), ("mop", .emoji("🧹")),
            ("hose", .emoji("🪠")), ("plunger", .emoji("🪠")),
            ("toolbox", .sfSymbol("wrench.and.screwdriver.fill")),
            ("level", .emoji("📏")), ("clamp", .emoji("🗜️")),
            ("glue", .emoji("🧴")), ("safety", .sfSymbol("shield.fill")),
            ("helmet", .emoji("⛑️")), ("vest", .emoji("🦺")),
            ("goggles", .emoji("🥽")), ("mask", .emoji("😷"))
        ], shape: .gear)

        // =====================================================================
        // CLOTHING & ACCESSORIES (diamond) — ~30 words
        // =====================================================================
        add([
            ("boot", .emoji("🥾")), ("sandal", .emoji("🩴")),
            ("sneaker", .emoji("👟")), ("heel", .emoji("👠")),
            ("sock", .emoji("🧦")), ("glove", .emoji("🧤")),
            ("scarf", .emoji("🧣")), ("tie", .emoji("👔")),
            ("belt", .emoji("🪢")), ("watch", .emoji("⌚")),
            ("necklace", .emoji("📿")), ("earring", .emoji("💍")),
            ("bracelet", .emoji("📿")), ("purse", .emoji("👛")),
            ("wallet", .emoji("👛")), ("backpack", .emoji("🎒")),
            ("suitcase", .emoji("🧳")), ("sunglasses", .emoji("🕶️")),
            ("cap", .emoji("🧢")), ("crown", .sfSymbol("crown.fill")),
            ("uniform", .emoji("👔")), ("costume", .emoji("🎭")),
            ("pajamas", .emoji("🛏️")), ("swimsuit", .emoji("👙")),
            ("jacket", .emoji("🧥")), ("sweater", .emoji("🧶")),
            ("jeans", .emoji("👖")), ("skirt", .emoji("👗"))
        ], shape: .diamond)

        // =====================================================================
        // MUSIC & ART (flower) — ~25 words
        // =====================================================================
        add([
            ("flute", .emoji("🪈")), ("harp", .emoji("🪕")),
            ("banjo", .emoji("🪕")), ("accordion", .emoji("🪗")),
            ("saxophone", .emoji("🎷")), ("microphone", .sfSymbol("mic.fill")),
            ("concert", .emoji("🎶")), ("orchestra", .emoji("🎻")),
            ("band", .emoji("🎸")), ("melody", .sfSymbol("music.note")),
            ("rhythm", .sfSymbol("waveform")),
            ("harmony", .sfSymbol("music.note.list")),
            ("painting", .sfSymbol("paintpalette.fill")),
            ("sculpture", .emoji("🗿")), ("drawing", .sfSymbol("paintbrush.fill")),
            ("photograph", .sfSymbol("camera.fill")),
            ("movie", .sfSymbol("film.fill")), ("theater", .emoji("🎭")),
            ("ballet", .emoji("🩰")), ("opera", .emoji("🎭")),
            ("poetry", .sfSymbol("book.fill")), ("novel", .sfSymbol("book.fill")),
            ("drama", .emoji("🎭")), ("comedy", .emoji("😂")),
            ("circus", .emoji("🎪")), ("magic", .sfSymbol("wand.and.stars"))
        ], shape: .flower)

        // =====================================================================
        // SCIENCE & TECHNOLOGY (gear) — ~25 words
        // =====================================================================
        add([
            ("atom", .sfSymbol("atom")),
            ("molecule", .emoji("🧬")), ("DNA", .emoji("🧬")),
            ("cell", .emoji("🔬")), ("virus", .emoji("🦠")),
            ("bacteria", .emoji("🦠")), ("fossil", .emoji("🦴")),
            ("dinosaur", .emoji("🦕")), ("skeleton", .emoji("💀")),
            ("planet", .emoji("🪐")), ("galaxy", .emoji("🌌")),
            ("comet", .emoji("☄️")), ("meteor", .emoji("☄️")),
            ("orbit", .emoji("🛸")), ("gravity", .sfSymbol("arrow.down")),
            ("experiment", .emoji("🧪")), ("laboratory", .emoji("🔬")),
            ("formula", .sfSymbol("function")),
            ("equation", .sfSymbol("equal.circle.fill")),
            ("data", .sfSymbol("chart.bar.fill")),
            ("code", .sfSymbol("chevron.left.forwardslash.chevron.right")),
            ("program", .sfSymbol("terminal.fill")),
            ("internet", .sfSymbol("globe")),
            ("website", .sfSymbol("globe")),
            ("software", .sfSymbol("app.fill")),
            ("hardware", .sfSymbol("cpu.fill"))
        ], shape: .gear)

        // =====================================================================
        // TIME & CALENDAR (star) — ~20 words
        // =====================================================================
        add([
            ("second", .sfSymbol("clock.fill")),
            ("minute", .sfSymbol("clock.fill")),
            ("hour", .sfSymbol("clock.fill")),
            ("week", .sfSymbol("calendar")),
            ("month", .sfSymbol("calendar")),
            ("year", .sfSymbol("calendar")),
            ("century", .sfSymbol("clock.fill")),
            ("season", .sfSymbol("leaf.fill")),
            ("summer", .sfSymbol("sun.max.fill")),
            ("winter", .sfSymbol("snowflake")),
            ("autumn", .sfSymbol("leaf.fill")),
            ("fall", .sfSymbol("leaf.fill")),
            ("weekend", .sfSymbol("calendar")),
            ("holiday", .emoji("🎉")),
            ("vacation", .emoji("🏖️")),
            ("monday", .sfSymbol("calendar")),
            ("friday", .sfSymbol("calendar")),
            ("sunday", .sfSymbol("calendar"))
        ], shape: .star)

        // =====================================================================
        // EMOTIONS EXTRAS (heart) — ~20 words
        // =====================================================================
        add([
            ("laugh", .emoji("😂")), ("cry", .emoji("😢")),
            ("smile", .sfSymbol("face.smiling")),
            ("frown", .emoji("☹️")), ("wink", .emoji("😉")),
            ("blush", .emoji("😊")), ("yawn", .emoji("🥱")),
            ("scream", .emoji("😱")), ("shiver", .emoji("🥶")),
            ("sweat", .emoji("😰")), ("nervous", .emoji("😬")),
            ("relaxed", .emoji("😌")), ("grateful", .sfSymbol("heart.fill")),
            ("anxious", .emoji("😰")), ("depressed", .emoji("😞")),
            ("cheerful", .emoji("😄")), ("grumpy", .emoji("😠")),
            ("nostalgic", .emoji("🥺")), ("passionate", .sfSymbol("flame.fill")),
            ("peaceful", .sfSymbol("peacesign"))
        ], shape: .heart)

        // =====================================================================
        // MORE ANIMALS (hexagon) — ~30 words
        // =====================================================================
        add([
            ("dragon", .emoji("🐉")), ("unicorn", .emoji("🦄")),
            ("llama", .emoji("🦙")), ("alpaca", .emoji("🦙")),
            ("bison", .emoji("🦬")), ("mammoth", .emoji("🦣")),
            ("dodo", .emoji("🦤")), ("eagle", .emoji("🦅")),
            ("hawk", .emoji("🦅")), ("falcon", .emoji("🦅")),
            ("crow", .emoji("🐦‍⬛")), ("pigeon", .emoji("🐦")),
            ("stork", .emoji("🦩")), ("pelican", .emoji("🦩")),
            ("whale", .emoji("🐋")), ("starfish", .emoji("⭐")),
            ("coral", .emoji("🪸")), ("clam", .emoji("🐚")),
            ("shell", .emoji("🐚")), ("caterpillar", .emoji("🐛")),
            ("cricket", .emoji("🦗")), ("scorpion", .emoji("🦂")),
            ("centipede", .emoji("🐛")), ("lizard", .emoji("🦎")),
            ("crocodile", .emoji("🐊")), ("alligator", .emoji("🐊")),
            ("chameleon", .emoji("🦎")), ("iguana", .emoji("🦎")),
            ("salamander", .emoji("🦎")), ("toad", .emoji("🐸"))
        ], shape: .hexagon)

        return dict
    }()
    // swiftlint:enable function_body_length
}
