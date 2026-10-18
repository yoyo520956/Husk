// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

// MARK: - what's new

/// What this version brought, shown once after updating to it (not on a first install: onboarding is the welcome then).
enum WhatsNew {
    struct Item: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        var id: String { title }
    }

    /// The version whose notes these are. A build of the same version shows nothing again.
    static let version = "3.0.0"
    static let items: [Item] = [
        Item(symbol: "gamecontroller.fill", title: "焕然一新的 Husk",
             detail: "主机风格主页：游戏陈列架上，选中即满屏封面，一键开玩。安卓与 PS4 游戏并列，全新游戏库，浅色或深色随 设置 › 外观 而定。"),
        Item(symbol: "playstation.logo", title: "PS4 游戏",
             detail: "用 + 按钮添加 PS4 游戏：假包（.pkg）、包文件夹或已解压的游戏文件夹，加入游戏库即玩。更新包装在游戏旁边，着色器跨次启动保留，要求输入名称的游戏会弹出键盘。"),
        Item(symbol: "square.stack.3d.up.fill", title: "新增数百款安卓游戏",
             detail: "兼容性列表新增数百款可玩游戏，还有 Sonic Robo Blast 2、Ring Racers、NetHack、PokeWilds 等非官方移植；此前白屏的 Flutter 游戏恢复显示；Godot 4 游戏可运行；Python 游戏可联网。"),
        Item(symbol: "arrow.down.circle.fill", title: "完成商店下载",
             detail: "把数据放在扩展文件里的游戏会随下载一并获得数据，拆分成多个包的游戏也能加载。"),
        Item(symbol: "keyboard.fill", title: "随处输入",
             detail: "Unity、Java、Flutter、cocos2d-x 与 SDL 游戏的文本框可唤出键盘。"),
        Item(symbol: "textformat", title: "中文、日文和韩文",
             detail: "在 设置 › 字体 下载字体，游戏不再显示方框。"),
        Item(symbol: "bolt.fill", title: "JIT 独立开启",
             detail: "TrollStore 安装的版本启动时自动开 JIT；没有 JIT 就无法启动的内容，Husk 会在屏幕上说明。"),
        Item(symbol: "iphone", title: "iOS 15",
             detail: "Husk 现已支持 iOS 15.5 及以上（PS4 游戏需要 iOS 17.4）。"),
        Item(symbol: "wrench.and.screwdriver.fill", title: "Fixes",
             detail: "安卓下载完成后不再崩溃；完整安卓模拟器移入设置页并附警告；从应用切换器关闭 Husk 不再被记为崩溃；还有更多改进。"),
    ]

    private static let seenKey = "husk.whatsNew.seen"

    /// Whether to show the notes now: an update to this version, not a new install.
    static var due: Bool {
        let seen = UserDefaults.standard.string(forKey: seenKey)
        if seen == version { return false }
        if Onboarding.needed { markSeen(); return false }       // a first install: onboarding welcomes them
        return true
    }

    static func markSeen() { UserDefaults.standard.set(version, forKey: seenKey) }
}

struct WhatsNewSheet: View {
    var done: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Husk \(WhatsNew.version) 更新内容").font(.largeTitle.weight(.bold))
                        Text("全新界面、PS4 游戏，以及数百款新增安卓游戏。").foregroundStyle(.secondary)
                    }
                    .padding(.top, 36)
                    ForEach(WhatsNew.items) { item in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 26))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.headline)
                                Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }
            Button(action: done) {
                Text("继续").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - a newer Husk

/// A newer Husk on GitHub: the releases page is asked at launch (at most twice a day) and the person is told once per release.
@MainActor
final class AppUpdates: ObservableObject {
    static let shared = AppUpdates()

    struct Release: Equatable {
        let version: String
        let page: URL
    }

    @Published var available: Release?

    private static let api = URL(string: "https://api.github.com/repos/Leviidev/Husk/releases/latest")!
    private static let checkedKey = "husk.updates.checked", dismissedKey = "husk.updates.dismissed"

    static var current: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    func check() async {
        let d = UserDefaults.standard
        if Date().timeIntervalSince1970 - d.double(forKey: Self.checkedKey) < 12 * 3600 { return }
        var req = URLRequest(url: Self.api)
        req.timeoutInterval = 20
        req.setValue("Husk", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = obj["tag_name"] as? String,
              let page = (obj["html_url"] as? String).flatMap(URL.init(string:)) else { return }
        d.set(Date().timeIntervalSince1970, forKey: Self.checkedKey)
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        guard Self.newer(version, than: Self.current), d.string(forKey: Self.dismissedKey) != version else { return }
        HuskLog.log("update", "Husk \(version) is out (this is \(Self.current))")
        available = Release(version: version, page: page)
    }

    func dismiss() {
        if let v = available?.version { UserDefaults.standard.set(v, forKey: Self.dismissedKey) }
        available = nil
    }

    /// "1.0.10" is newer than "1.0.9": compared number by number.
    static func newer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }
}
