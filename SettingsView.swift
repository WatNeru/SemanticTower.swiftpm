import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                anchorSection
                anchorPresetsSection
                soundSection
                accessibilitySection
                gameSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Anchors

    private var anchorSection: some View {
        Section {
            anchorRow(label: "+X Axis", icon: "arrow.right", value: $settings.anchorNature,
                      color: STTheme.Colors.perfectBlue, hint: "e.g. nature, joy, earth")
            anchorRow(label: "−X Axis", icon: "arrow.left", value: $settings.anchorMachine,
                      color: STTheme.Colors.nebulaPurple, hint: "e.g. machine, sadness, fire")
            anchorRow(label: "+Y Axis", icon: "arrow.up", value: $settings.anchorLiving,
                      color: STTheme.Colors.accentGold, hint: "e.g. animal, love, water")
            anchorRow(label: "−Y Axis", icon: "arrow.down", value: $settings.anchorObject,
                      color: STTheme.Colors.accentCyan, hint: "e.g. object, fear, air")
        } header: {
            Label("Semantic Axes", systemImage: "axis.horizontal.and.vertical")
        } footer: {
            Text("Words are positioned based on their semantic similarity to these four anchor words.")
        }
    }

    private func anchorRow(label: String, icon: String, value: Binding<String>,
                           color: Color, hint: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                TextField(hint, text: value)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
    }

    // MARK: - Presets

    private var anchorPresetsSection: some View {
        Section {
            ForEach(GameSettings.anchorPresets) { preset in
                Button {
                    withAnimation { settings.applyPreset(preset) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("\(preset.nature) · \(preset.machine) · \(preset.living) · \(preset.object)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isCurrentPreset(preset) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        } header: {
            Label("Presets", systemImage: "square.grid.2x2")
        }
    }

    private func isCurrentPreset(_ preset: GameSettings.AnchorPreset) -> Bool {
        settings.anchorNature == preset.nature
        && settings.anchorMachine == preset.machine
        && settings.anchorLiving == preset.living
        && settings.anchorObject == preset.object
    }

    // MARK: - Sound

    private var soundSection: some View {
        Section {
            Toggle(isOn: $settings.soundEnabled) {
                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
            }

            if settings.soundEnabled {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    Slider(value: $settings.soundVolume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }

                Toggle(isOn: $settings.hapticEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                }
            }
        } header: {
            Label("Sound & Haptics", systemImage: "speaker.wave.2.circle")
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $settings.highContrast) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("High Contrast", systemImage: "circle.lefthalf.filled")
                    Text("Increases text contrast and border visibility")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $settings.largeText) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Larger Text", systemImage: "textformat.size.larger")
                    Text("Increases HUD text size for readability")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("Accessibility", systemImage: "accessibility")
        } footer: {
            Text("Motion reduction follows your device's system setting (Settings → Accessibility → Motion).")
        }
    }

    // MARK: - Game

    private var gameSection: some View {
        Section {
            Toggle(isOn: $settings.showTutorial) {
                Label("Show Tutorial on Launch", systemImage: "questionmark.circle")
            }
        } header: {
            Label("Game", systemImage: "gamecontroller")
        }
    }
}
