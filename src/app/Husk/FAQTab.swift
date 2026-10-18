// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI

/// Help: common problems and what to do about them, so a user stuck on JIT or on an app that will not open has an answer
/// without leaving Husk. A page in Settings (it was a tab of its own; four tabs read simpler than five).
struct FAQTab: View {
    @State private var query = ""

    private var sections: [FAQ.Section] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return FAQ.sections }
        return FAQ.sections.compactMap { s in
            let items = s.items.filter { $0.question.localizedCaseInsensitiveContains(q) || $0.answer.localizedCaseInsensitiveContains(q) }
            return items.isEmpty ? nil : FAQ.Section(title: s.title, symbol: s.symbol, items: items)
        }
    }

    var body: some View {
            List {
                ForEach(sections) { s in
                    Section {
                        ForEach(s.items) { item in FAQRow(item: item, expanded: !query.isEmpty) }
                    } header: {
                        Label(s.title, systemImage: s.symbol)
                    }
                }
                if sections.isEmpty {
                    Text("没有匹配“\(query)”的内容。打开 设置 › 关于 › 打开控制台 查看 Husk 在做什么。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("帮助")
            .searchable(text: $query, prompt: "搜索问题")
    }
}

private struct FAQRow: View {
    let item: FAQ.Item
    var expanded: Bool
    @State private var open = false

    var body: some View {
        DisclosureGroup(isExpanded: Binding(get: { open || expanded }, set: { open = $0 })) {
            Text(.init(item.answer))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        } label: {
            Text(item.question).font(.body.weight(.medium))
        }
    }
}

enum FAQ {
    struct Item: Identifiable { let question: String; let answer: String; var id: String { question } }
    struct Section: Identifiable { let title: String; let symbol: String; let items: [Item]; var id: String { title } }

    static let sections: [Section] = [
        Section(title: "JIT", symbol: "bolt.fill", items: [
            Item(question: "JIT 是什么？Husk 为什么需要它？",
                 answer: "安卓应用和游戏在运行时编译，需要既可写又可执行的内存。iOS 只允许在调试器附加到应用时这样做。开启 JIT 会短暂附加一个。没有它，Husk 只能显示游戏库，无法启动安卓或游戏。"),
            Item(question: "应该用哪种方式开启 JIT？",
                 answer: "• **iOS 27 及以上：** 设置 › JIT › 在此 iPhone 上配对，无需电脑。
• **旧版 iOS，或 Husk 在 LiveContainer 内：** 使用 StikDebug 应用。
• **TrollStore 安装：** 使用 TrollStore，并打开其 URL Scheme 设置。
• **Dopamine 越狱：** 在越狱设置中为应用开启 JIT。"),
            Item(question: "StikJIT 提示无法连接，或启用 JIT 失败",
                 answer: "1. 确保已安装并连接 **LocalDevVPN**，状态栏应出现 VPN 图标。
2. Wi-Fi 必须开启，尽管没有任何数据离开你的 iPhone。
3. **开发者模式**必须开启（设置 › 隐私与安全性 › 开发者模式）。
4. 仍失败？把 LocalDevVPN 关闭再打开，然后重新配对。"),
            Item(question: "开发者模式里没有出现“与 Husk 配对”",
                 answer: "先在 Husk 中轻点**开始配对**，并在询问时允许**本地网络**权限。如果之前拒绝过，可在 设置 › 隐私与安全性 › 本地网络 › Husk 中打开；Wi-Fi 必须开启。开发者模式必须已启用（首次开启会重启 iPhone）。"),
            Item(question: "我的配对文件失效了",
                 answer: "配对文件在 iPhone 信任设置重置后会失效，有时 iOS 更新后也会失效。重新生成一个，或（iOS 27）直接在 iPhone 上配对，然后在 设置 › JIT 重新导入。"),
            Item(question: "StikDebug 打开了但 JIT 仍未开启",
                 answer: "单独打开 StikDebug，检查它已有你的配对文件且 LocalDevVPN 已连接。把 StikDebug 更新到最新版。Husk 会自行把脚本发给 StikDebug，因此无需在 StikDebug 里为 Husk 做任何配置。"),
            Item(question: "为什么要再次开启 JIT？",
                 answer: "JIT 只在 Husk 运行期间有效。当 iOS 在后台关闭 Husk、或你上滑移除它后，下次启动需要重新开 JIT。用“在此 iPhone 上配对”或配对文件只需轻点一下。"),
            Item(question: "不用 JIT 能用 Husk 吗？",
                 answer: "可以浏览和导入应用，但安卓内容都无法运行。每个游戏和应用都需要 JIT。"),
        ]),
        Section(title: "Husk 本体", symbol: "app.badge", items: [
            Item(question: "Husk 完全打不开",
                 answer: "• **秒开秒关：** 签名证书可能已过期，免费 Apple 账户只有 7 天。用你的侧载工具重签或重装 Husk，应用与存档都会保留。
• **“不受信任的开发者”：** 前往 设置 › 通用 › VPN 与设备管理，信任你的证书。
• **要求开发者模式：** 在 设置 › 隐私与安全性 中开启。"),
            Item(question: "游戏玩着玩着 Husk 就关了",
                 answer: "再次打开 Husk 时会显示发生了什么，并附可分享的报告。通常是游戏内存耗尽，或撞上了 Husk 尚不支持的功能。关闭其他应用；若反复出现请分享报告。"),
            Item(question: "如何获取日志反馈问题？",
                 answer: "在游戏库打开该应用的页面，轻点**分享报告**。Husk 自身日志在 设置 › 关于 › **打开控制台**；在那里开启**开发者信息**可看到更多细节。"),
            Item(question: "如何更新 Husk？",
                 answer: "有新版本时 Husk 会提醒你。用同一个侧载工具把新 IPA 覆盖安装到旧版上，游戏库、应用和存档都会保留。"),
        ]),
        Section(title: "应用与游戏", symbol: "gamecontroller.fill", items: [
            Item(question: "如何添加 PS4 游戏？",
                 answer: "轻点 + 选择假包（.pkg）、包文件夹或已解压的游戏文件夹（含 eboot.bin 和 sce_sys）。Husk 会把它装进“文件”的 PS4 Games，更新包会放到它所更新游戏旁边。零售包锁定单一 PS4 无法安装。PS4 游戏需要 iOS 17.4 或更高。"),
            Item(question: "应用打不开",
                 answer: "在游戏库打开它的页面，Husk 会说明停止原因：
"),
            Item(question: "屏幕一直黑屏",
                 answer: "大游戏首次启动要准备代码和数据，可能需要一分钟。若之后仍黑屏，关闭再打开一次；仍无变化就分享报告。"),
            Item(question: "魔改或重打包的 APK 崩溃",
                 answer: "APKVISION 之类站点的重打包常把应用代码换成自己的库或加入防篡改检查，这类更容易出问题。试试开发者原版或 APKMirror 的 APK。"),
            Item(question: "可以导入哪些文件？",
                 answer: "支持 .apk，整合包支持 .apks、.xapk 或 .apkm。可分享给 Husk、从“文件”打开，或轻点游戏库的 +。"),
            Item(question: "游戏很慢或手机发热",
                 answer: "关闭其他应用让手机降温。游戏原生运行，但部分工作在真实安卓手机上由硬件完成，这里由 CPU 承担。低电量模式也会拖慢 Husk。"),
            Item(question: "可以用手柄吗？",
                 answer: "可以。在蓝牙设置中把手柄连接到 iPhone，支持手柄的游戏就能看到它。"),
            Item(question: "游戏运行时还能用 Husk 吗？",
                 answer: "在设置中开启**在窗口中打开应用**。应用就会在可移动、可缩放、可最小化的窗口中打开。"),
            Item(question: "Google 登录不好使",
                 answer: "Husk 没有 Google Play 服务，“使用 Google 登录”按钮可能失败。应用若提供邮箱或其他登录方式请改用。"),
        ]),
        Section(title: "存档与存储", symbol: "externaldrive.fill", items: [
            Item(question: "我的存档在哪？",
                 answer: "每个应用的数据都保存在 Husk 内。在应用页面，**备份存档**可导出，**恢复存档**可还原，也能恢复到另一台 iPhone。"),
            Item(question: "Husk 占用了很多存储",
                 answer: "导入的应用与其数据存放在 Husk 的文件夹里。不再玩的游戏可在其页面移除。完整安卓系统下载约多占 2 GB，仅在需要安卓本身时才用。"),
        ]),
        Section(title: "安卓系统", symbol: "cpu", items: [
            Item(question: "应用和安卓系统有什么区别？",
                 answer: "大多数应用和游戏像原生应用一样直接在 iPhone 上运行。完整安卓系统是单独的、更慢的选项，用于只能在真实安卓内运行的内容。"),
            Item(question: "安卓启动要很久",
                 answer: "首次启动要下载安卓镜像并冷启动，需要几分钟。之后 Husk 会恢复已保存的快照，快得多。"),
        ]),
    ]
}
