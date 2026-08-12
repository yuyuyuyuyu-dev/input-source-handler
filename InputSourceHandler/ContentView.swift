//
//  ContentView.swift
//  InputSourceHandler
//

import Core
import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .imageScale(.large)
                .font(.system(size: 32))
                .foregroundStyle(.tint)

            Text("InputSourceHandler")
                .font(.headline)

            if viewModel.isTrusted {
                Text("✅ アクセシビリティ権限が許可されています。\nバックグラウンドで動作中です。")
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("⚠️ アクセシビリティ権限が必要です。\nシステム設定から許可してください。")
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(.red)

                Button("システム設定を開く") {
                    viewModel.openAccessibilitySettings()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("ショートカット:")
                    .font(.caption).bold()
                Text("⌃ + ⇧ + J  →  かな")
                    .font(.caption)
                Text("⌃ + ⇧ + ;  →  英数")
                    .font(.caption)
            }

            Divider()

            Toggle("ログイン時に開く", isOn: $viewModel.isLaunchAtLoginEnabled)
                .font(.caption)

            Divider()

            Button(ContextMenuCommand.quit.title) {
                viewModel.perform(.quit)
            }
        }
        .padding()
        .frame(width: 250)
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel(
        permission: InertAccessibilityPermission(),
        eventTap: InertKeyEventTap(),
        poster: InertVirtualKeyPoster(),
        loginItem: InertLoginItem(),
        settingsOpener: InertSettingsOpener(),
        terminator: InertAppTerminator()
    ))
}
