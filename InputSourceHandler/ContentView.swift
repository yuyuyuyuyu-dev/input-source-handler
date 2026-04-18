//
//  ContentView.swift
//  InputSourceHandler
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: KeyEventMonitor

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .imageScale(.large)
                .font(.system(size: 32))
                .foregroundStyle(.tint)
            
            Text("InputSourceHandler")
                .font(.headline)
            
            if monitor.isTrusted {
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
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
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
            
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 250)
    }
}

#Preview {
    ContentView()
        .environmentObject(KeyEventMonitor())
}
