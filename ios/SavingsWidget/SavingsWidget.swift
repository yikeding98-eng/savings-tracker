import WidgetKit
import SwiftUI

// MARK: - 共享常量（与 Flutter 侧 lib/services/widget_bridge.dart 保持一致）
private let appGroupId = "group.com.personal.savingsTracker"
private let snapshotKey = "savings_snapshot"

// MARK: - 数据模型
struct SavingsSnapshot {
    var balance: Double = 0
    var target: Double = 100000
    var remaining: Double = 0
    var progress: Double = 0
    var monthlySaved: Double = 0
    var currency: String = "¥"
    var nextReminder: String = ""
    var hasData: Bool = false

    static func load() -> SavingsSnapshot {
        var snapshot = SavingsSnapshot()
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let raw = defaults.string(forKey: snapshotKey),
              let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any]
        else {
            return snapshot
        }

        snapshot.balance = json["balance"] as? Double ?? 0
        snapshot.target = json["target"] as? Double ?? 100000
        snapshot.remaining = json["remaining"] as? Double ?? 0
        snapshot.progress = json["progress"] as? Double ?? 0
        snapshot.monthlySaved = json["monthlySaved"] as? Double ?? 0
        snapshot.currency = json["currency"] as? String ?? "¥"
        snapshot.nextReminder = json["nextReminder"] as? String ?? ""
        snapshot.hasData = true
        return snapshot
    }

    var progressValue: Double { min(max(progress, 0), 1) }
}

struct SavingsEntry: TimelineEntry {
    let date: Date
    let snapshot: SavingsSnapshot
}

// MARK: - Timeline
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SavingsEntry {
        SavingsEntry(date: Date(), snapshot: SavingsSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (SavingsEntry) -> Void) {
        completion(SavingsEntry(date: Date(), snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsEntry>) -> Void) {
        let entry = SavingsEntry(date: Date(), snapshot: .load())
        // 30 分钟兜底刷新一次；App 内改动会主动 reloadAllTimelines，不需要等这个
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - 小组件定义
@main
struct SavingsWidget: Widget {
    let kind = "SavingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SavingsWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.985, green: 0.968, blue: 0.925)
                }
        }
        .configurationDisplayName("存款进度")
        .description("当前存款、目标进度和本月已存，数据来自存款管家 App。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 视图
private let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
private let goldDeep = Color(red: 0.541, green: 0.416, blue: 0.082)
private let ink = Color(red: 0.231, green: 0.173, blue: 0.0)

struct SavingsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SavingsEntry

    var body: some View {
        Group {
            if entry.snapshot.hasData {
                switch family {
                case .systemMedium:
                    mediumLayout
                default:
                    smallLayout
                }
            } else {
                emptyLayout
            }
        }
    }

    // MARK: 小号：只看已存金额
    private var smallLayout: some View {
        VStack(spacing: 4) {
            Text("已存")
                .font(.caption2)
                .foregroundStyle(ink.opacity(0.5))

            Text(money(entry.snapshot.balance))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(goldDeep)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: 中号
    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前存款")
                        .font(.caption2)
                        .foregroundStyle(ink.opacity(0.55))
                    Text(money(entry.snapshot.balance))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(goldDeep)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text("\(Int(entry.snapshot.progressValue * 100))%")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(goldDeep)
            }

            ProgressView(value: entry.snapshot.progressValue)
                .tint(goldDeep)

            HStack(spacing: 14) {
                metric(title: "目标", value: money(entry.snapshot.target))
                metric(title: "本月已存", value: money(entry.snapshot.monthlySaved))
                metric(title: "还差", value: money(entry.snapshot.remaining))
            }

            if !entry.snapshot.nextReminder.isEmpty {
                Text("下次提醒 \(entry.snapshot.nextReminder)")
                    .font(.caption2)
                    .foregroundStyle(ink.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(ink.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: 无数据
    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "banknote")
                .font(.system(size: 22))
                .foregroundStyle(gold)
            Text("打开「存款管家」\n记一笔就有数据了")
                .font(.caption)
                .foregroundStyle(ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: 金额格式化
    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"
        return entry.snapshot.currency + number
    }
}
