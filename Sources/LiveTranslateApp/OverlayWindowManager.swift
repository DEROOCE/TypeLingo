import AppKit
import SwiftUI

@MainActor
final class OverlayWindowManager {
    private var panel: NSPanel?
    private var settingsObserver: NSObjectProtocol?
    private var hideObserver: NSObjectProtocol?
    private var showObserver: NSObjectProtocol?
    private var toggleObserver: NSObjectProtocol?

    func bind(to appState: AppState) {
        guard panel == nil else {
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 60, y: 80, width: 540, height: 170),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.minSize = NSSize(width: 420, height: 150)
        panel.contentView = NSHostingView(rootView: OverlayView(appState: appState))
        panel.orderFrontRegardless()

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .overlaySettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak panel] _ in
            Task { @MainActor in
                guard let panel else {
                    return
                }

                panel.invalidateShadow()
            }
        }

        hideObserver = NotificationCenter.default.addObserver(
            forName: .overlayHideRequested,
            object: nil,
            queue: .main
        ) { [weak panel] _ in
            Task { @MainActor in
                panel?.orderOut(nil)
            }
        }

        showObserver = NotificationCenter.default.addObserver(
            forName: .overlayShowRequested,
            object: nil,
            queue: .main
        ) { [weak panel] _ in
            Task { @MainActor in
                panel?.orderFrontRegardless()
            }
        }

        toggleObserver = NotificationCenter.default.addObserver(
            forName: .overlayToggleRequested,
            object: nil,
            queue: .main
        ) { [weak panel] _ in
            Task { @MainActor in
                guard let panel else {
                    return
                }

                if panel.isVisible {
                    panel.orderOut(nil)
                } else {
                    panel.orderFrontRegardless()
                }
            }
        }

        self.panel = panel
    }
}

struct OverlayView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(appState.overlayOpacity)

            VStack(alignment: .leading, spacing: 10) {
                headerRow

                translationCard
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .environment(\.colorScheme, .dark)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            closeButton

            toolbarGroup

            Spacer()
            settingsButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var toolbarGroup: some View {
        HStack(spacing: 0) {
            providerMenu

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 24)

            targetLanguageMenu
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.black.opacity(0.001))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var translationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.vertical, showsIndicators: true) {
                Text(appState.translatedText.isEmpty ? appState.targetLanguage.emptyTranslationPlaceholder : appState.translatedText)
                    .font(.system(size: appState.subtitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, minHeight: 72, maxHeight: .infinity)

            if appState.translatedText.isEmpty || appState.errorMessage != nil {
                Text(appState.errorMessage ?? appState.providerStatus)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var settingsButton: some View {
        Button {
            NotificationCenter.default.post(name: .overlayShowControlPanel, object: nil)
        } label: {
            Image(systemName: "gearshape")
        }
        .buttonStyle(OverlayCapsuleButtonStyle())
    }

    private var targetLanguageMenu: some View {
        Menu {
            ForEach(TargetLanguage.allCases) { language in
                Button {
                    appState.targetLanguage = language
                } label: {
                    if language == appState.targetLanguage {
                        Label(language.displayName, systemImage: "checkmark")
                    } else {
                        Text(language.displayName)
                    }
                }
            }
        } label: {
            OverlaySecondaryMenuLabel(title: appState.targetLanguage.displayName)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }

    private var providerMenu: some View {
        Menu {
            Button {
                appState.chooseGoogleProvider()
            } label: {
                if appState.selectedProvider == .googleWeb {
                    Label(TranslationProviderKind.googleWeb.displayName, systemImage: "checkmark")
                } else {
                    Text(TranslationProviderKind.googleWeb.displayName)
                }
            }

            if !appState.providerProfiles.isEmpty {
                Divider()
            }

            ForEach(appState.providerProfiles) { profile in
                Button {
                    appState.chooseProviderProfile(id: profile.id)
                } label: {
                    if appState.selectedProvider == .openAICompatible && appState.selectedProviderProfileID == profile.id {
                        Label(profile.name, systemImage: "checkmark")
                    } else {
                        Text(profile.name)
                    }
                }
            }
        } label: {
            OverlaySecondaryMenuLabel(title: appState.currentProviderDisplayName)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            NotificationCenter.default.post(name: .overlayHideRequested, object: nil)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.black.opacity(0.65))
                .frame(width: 14, height: 14)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
    }
}

struct OverlaySecondaryMenuLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.68))
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .frame(minWidth: 96, alignment: .leading)
    }
}

struct OverlayCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.18 : 0.10))
            )
    }
}
