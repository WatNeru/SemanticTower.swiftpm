import SwiftUI

/// アプリ全体の設定を管理。@AppStorage で永続化。
final class GameSettings: ObservableObject {

    // MARK: - Anchors (4軸の単語)

    @AppStorage("anchor_nature")  var anchorNature: String = "nature"
    @AppStorage("anchor_machine") var anchorMachine: String = "machine"
    @AppStorage("anchor_living")  var anchorLiving: String = "animal"
    @AppStorage("anchor_object")  var anchorObject: String = "object"

    // MARK: - Sound

    @AppStorage("soundEnabled")     var soundEnabled: Bool = true
    @AppStorage("soundVolume")      var soundVolume: Double = 0.4

    // MARK: - Accessibility

    @AppStorage("highContrast")     var highContrast: Bool = false
    @AppStorage("largeText")        var largeText: Bool = false
    @AppStorage("hapticEnabled")    var hapticEnabled: Bool = true

    // MARK: - Game

    @AppStorage("showTutorial")     var showTutorial: Bool = true

    // MARK: - Preset Anchor Sets

    struct AnchorPreset: Identifiable {
        let id: String
        let nature: String
        let machine: String
        let living: String
        let object: String
        var name: String { id }
    }

    static let anchorPresets: [AnchorPreset] = [
        AnchorPreset(id: "Default",  nature: "nature",  machine: "machine",    living: "animal",    object: "object"),
        AnchorPreset(id: "Emotion",  nature: "joy",     machine: "sadness",    living: "love",      object: "fear"),
        AnchorPreset(id: "Science",  nature: "nature",  machine: "technology", living: "life",      object: "matter"),
        AnchorPreset(id: "Society",  nature: "freedom", machine: "control",    living: "community", object: "individual"),
        AnchorPreset(id: "Elements", nature: "earth",   machine: "fire",       living: "water",     object: "air"),
        AnchorPreset(id: "Time",     nature: "future",  machine: "past",       living: "day",       object: "night"),
        AnchorPreset(id: "Space",    nature: "land",    machine: "sea",        living: "sky",       object: "underground"),
        AnchorPreset(id: "Art",      nature: "beauty",  machine: "chaos",      living: "creation",  object: "destruction")
    ]

    var currentAnchors: AnchorSet {
        AnchorSet(
            natureWord: anchorNature,
            mechanicWord: anchorMachine,
            livingWord: anchorLiving,
            objectWord: anchorObject
        )
    }

    func applyPreset(_ preset: AnchorPreset) {
        anchorNature = preset.nature
        anchorMachine = preset.machine
        anchorLiving = preset.living
        anchorObject = preset.object
    }
}
