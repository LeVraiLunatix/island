import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        TabView {
            TweakWorkbench()
                .tabItem { Label("工具", systemImage: "switch.2") }

            NavigationStack { AdvancedGestaltEditor() }
                .tabItem { Label("字段", systemImage: "list.bullet.rectangle") }

            BackupLibrary()
                .tabItem { Label("备份", systemImage: "archivebox") }
        }
        .task { viewModel.load() }
        .alert(item: $viewModel.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("好"))
            )
        }
    }
}

private struct TweakWorkbench: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        NavigationStack {
            List {
                Section { deviceStatus }

                if viewModel.plist != nil {
                    dynamicIslandSection
                    modelNameSection

                    ForEach(GestaltTweakCategory.allCases) { category in
                        let definitions = GestaltTweakCatalog.definitions.filter { $0.category == category }
                        Section(category.rawValue) {
                            ForEach(definitions) { definition in
                                TweakToggle(
                                    definition: definition,
                                    isOn: Binding(
                                        get: { viewModel.selectedTweaks.contains(definition.id) },
                                        set: { viewModel.setTweak(definition.id, enabled: $0) }
                                    )
                                )
                            }
                            if category == .region {
                                Toggle(
                                    "启用 Siri AI（美国地区）",
                                    isOn: Binding(
                                        get: { viewModel.stagesAIRegion },
                                        set: { viewModel.setAIRegion(enabled: $0) }
                                    )
                                )
                                .disabled(viewModel.aiRegionProfile == nil)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MobileGestalt")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { viewModel.load() }
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasStagedTweaks {
                    applyBar
                }
            }
        }
    }

    @ViewBuilder
    private var deviceStatus: some View {
        if viewModel.plist == nil {
            HStack(spacing: 10) {
                if viewModel.isBusy || !viewModel.hasAttemptedLoad {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在读取 MobileGestalt…")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("无法读取 MobileGestalt")
                        Button("重新读取", action: viewModel.load)
                            .font(.footnote)
                    }
                }
            }
        } else {
            LabeledContent {
                Text("已连接")
                    .foregroundStyle(.green)
            } label: {
                Label(viewModel.aiRegionProfile?.marketingName ?? "当前设备", systemImage: "iphone")
            }
        }
    }

    private var dynamicIslandSection: some View {
        Section {
            Picker("设备子类型", selection: $viewModel.dynamicIslandSubtype) {
                Text("不修改").tag(Int?.none)
                ForEach(DynamicIslandOption.all) { option in
                    Text("\(option.subtype) · \(option.title)").tag(Int?.some(option.subtype))
                }
            }
        } header: {
            Text("灵动岛")
        } footer: {
            Text("选择后会同时写入 ArtworkDeviceSubType 与灵动岛支持标记。")
        }
    }

    private var modelNameSection: some View {
        Section("设备名称") {
            Toggle("修改“关于本机”型号名称", isOn: $viewModel.changesModelName)
            if viewModel.changesModelName {
                TextField("型号名称", text: $viewModel.modelName)
                    .textInputAutocapitalization(.words)
            }
        }
    }

    private var applyBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.stagedChangeCount) 项待写入")
                    .font(.subheadline.weight(.semibold))
                Text("写入前自动备份")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("应用") { viewModel.applySelectedTweaks() }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isBusy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct TweakToggle: View {
    let definition: GestaltTweakDefinition
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(definition.title)
                    if definition.isRisky {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("高风险")
                    }
                }
                Text(definition.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct BackupLibrary: View {
    @EnvironmentObject private var viewModel: GestaltViewModel
    @State private var backupToRestore: GestaltBackup?
    @State private var showsBackupImporter = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        viewModel.createBackup()
                    } label: {
                        Label("备份当前 MobileGestalt", systemImage: "plus.circle.fill")
                    }
                    .disabled(viewModel.plist == nil || viewModel.isBusy)

                    Button {
                        showsBackupImporter = true
                    } label: {
                        Label("导入备份", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isBusy)
                } footer: {
                    Text("导入只会加入备份库，不会立即写入。每次写入前也会自动保存一份原始 plist。")
                }

                Section("本机备份") {
                    if viewModel.backups.isEmpty {
                        Label("暂无备份", systemImage: "archivebox")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.backups) { backup in
                            BackupRow(backup: backup) {
                                backupToRestore = backup
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets { viewModel.delete(viewModel.backups[index]) }
                        }
                    }
                }
            }
            .navigationTitle("备份")
            .refreshable { viewModel.refreshBackups() }
            .onAppear { viewModel.refreshBackups() }
            .fileImporter(
                isPresented: $showsBackupImporter,
                allowedContentTypes: [.propertyList],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { viewModel.importBackup(from: url) }
                case .failure(let error):
                    viewModel.notice = GestaltNotice(kind: .error, message: error.localizedDescription)
                }
            }
            .confirmationDialog(
                "恢复这份 MobileGestalt？",
                isPresented: Binding(
                    get: { backupToRestore != nil },
                    set: { if !$0 { backupToRestore = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("恢复并写入", role: .destructive) {
                    if let backupToRestore { viewModel.restore(backupToRestore) }
                    backupToRestore = nil
                }
                Button("取消", role: .cancel) { backupToRestore = nil }
            } message: {
                Text("当前文件会先自动备份；恢复后需要立即强制重启。")
            }
        }
    }
}

private struct BackupRow: View {
    let backup: GestaltBackup
    let restore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(backup.createdAt, format: .dateTime.year().month().day().hour().minute().second())
                Text(ByteCountFormatter.string(fromByteCount: backup.byteCount, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(item: backup.url) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("导出备份")
            Button(action: restore) {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("恢复备份")
        }
    }
}

private struct AdvancedGestaltEditor: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    @State private var searchText = ""
    @State private var activeEditor: FieldEditorRoute?

    private var cacheExtraKeys: [String] {
        filtered(viewModel.plist?.cacheExtraKeys ?? [], section: .cacheExtra)
    }

    private var topLevelKeys: [String] {
        filtered(
            viewModel.plist?.topLevelKeys.filter { $0 != "CacheExtra" } ?? [],
            section: .topLevel
        )
    }

    var body: some View {
        List {
            if viewModel.plist != nil {
                KeySection(
                    title: "CacheExtra",
                    keys: cacheExtraKeys,
                    value: { value(for: PlistKey(section: .cacheExtra, key: $0)) },
                    select: {
                        activeEditor = .edit(
                            PlistKey(section: .cacheExtra, key: $0)
                        )
                    }
                )

                KeySection(
                    title: "Top Level",
                    keys: topLevelKeys,
                    value: { value(for: PlistKey(section: .topLevel, key: $0)) },
                    select: {
                        activeEditor = .edit(
                            PlistKey(section: .topLevel, key: $0)
                        )
                    }
                )
            }
        }
        .navigationTitle("高级字段编辑")
        .searchable(text: $searchText, prompt: "搜索 key 或 value")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    activeEditor = .addCacheExtra
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新增 CacheExtra 字段")
                .disabled(viewModel.plist == nil || viewModel.isBusy)

                Button("保存", action: viewModel.applyChanges)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isDirty || viewModel.isBusy)
            }
        }
        .sheet(item: $activeEditor) { editor in
            Group {
                switch editor {
                case .edit(let key):
                    ValueEditor(
                        key: key.key,
                        initialValue: value(for: key),
                        save: { update($0, for: key) },
                        delete: key.section == .cacheExtra
                            ? { deleteCacheExtraField(key.key) }
                            : nil
                    )
                case .addCacheExtra:
                    AddCacheExtraFieldEditor(save: addCacheExtraField)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func filtered(_ keys: [String], section: PlistSection) -> [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return keys }

        return keys.filter { key in
            let reference = PlistKey(section: section, key: key)
            let info = PlistValueInfo.info(for: value(for: reference))
            return key.localizedCaseInsensitiveContains(query)
                || info.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    private func value(for key: PlistKey) -> Any? {
        switch key.section {
        case .cacheExtra:
            viewModel.plist?.cacheExtra[key.key]
        case .topLevel:
            viewModel.plist?.value(forKey: key.key)
        }
    }

    private func update(_ value: Any, for key: PlistKey) {
        guard var plist = viewModel.plist else { return }
        switch key.section {
        case .cacheExtra:
            plist.setCacheExtra(value, forKey: key.key)
        case .topLevel:
            plist.setValue(value, forKey: key.key)
        }
        viewModel.plist = plist
        viewModel.isDirty = true
    }

    private func addCacheExtraField(key: String, value: Any) throws {
        guard var plist = viewModel.plist else { return }
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            throw AddFieldError.emptyKey
        }
        guard plist.cacheExtra[normalizedKey] == nil else {
            throw AddFieldError.duplicateKey(normalizedKey)
        }

        plist.setCacheExtra(value, forKey: normalizedKey)
        viewModel.plist = plist
        viewModel.isDirty = true
    }

    private func deleteCacheExtraField(_ key: String) {
        guard var plist = viewModel.plist else { return }
        plist.removeCacheExtraValue(forKey: key)
        viewModel.plist = plist
        viewModel.isDirty = true
    }
}

private enum PlistSection: String {
    case cacheExtra
    case topLevel
}

private struct PlistKey: Identifiable {
    let section: PlistSection
    let key: String
    var id: String { "\(section.rawValue)/\(key)" }
}

private enum FieldEditorRoute: Identifiable {
    case edit(PlistKey)
    case addCacheExtra

    var id: String {
        switch self {
        case .edit(let key): "edit/\(key.id)"
        case .addCacheExtra: "add/cacheExtra"
        }
    }
}

private enum AddFieldError: LocalizedError {
    case emptyKey
    case duplicateKey(String)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            "Key 不能为空"
        case .duplicateKey(let key):
            "CacheExtra 已存在字段：\(key)"
        }
    }
}

private struct KeySection: View {
    let title: String
    let keys: [String]
    let value: (String) -> Any?
    let select: (String) -> Void

    var body: some View {
        Section(title) {
            if keys.isEmpty {
                Text("没有结果")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(keys, id: \.self) { key in
                    Button { select(key) } label: {
                        KeyRow(key: key, value: value(key))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct KeyRow: View {
    let key: String
    let value: Any?

    var body: some View {
        let info = PlistValueInfo.info(for: value)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(info.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct ValueEditor: View {
    @Environment(\.dismiss) private var dismiss

    let key: String
    let initialValue: Any?
    let save: (Any) -> Void
    let delete: (() -> Void)?

    @State private var kind: PlistValueKind
    @State private var text: String
    @State private var errorMessage: String?
    @State private var showsDeleteConfirmation = false

    init(
        key: String,
        initialValue: Any?,
        save: @escaping (Any) -> Void,
        delete: (() -> Void)? = nil
    ) {
        self.key = key
        self.initialValue = initialValue
        self.save = save
        self.delete = delete
        let kind = PlistValueKind.kind(of: initialValue)
        _kind = State(initialValue: kind)
        _text = State(initialValue: PlistValueInfo.encode(initialValue, as: kind))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("类型", selection: $kind) {
                        ForEach(PlistValueKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("值") {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if delete != nil {
                    Section {
                        Button("删除字段", role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(key)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成", action: commit)
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "删除 CacheExtra 字段？",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    delete?()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除将在返回编辑器并点击“保存”后写入文件。")
            }
        }
    }

    private func commit() {
        do {
            save(try PlistValueInfo.parse(text, as: kind))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddCacheExtraFieldEditor: View {
    @Environment(\.dismiss) private var dismiss

    let save: (String, Any) throws -> Void

    @State private var key = ""
    @State private var kind: PlistValueKind = .string
    @State private var text = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("字段") {
                    LabeledContent("位置", value: "CacheExtra")
                    TextField("Key", text: $key)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("类型") {
                    Picker("类型", selection: $kind) {
                        ForEach(PlistValueKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("值") {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("新增字段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加", action: commit)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func commit() {
        do {
            let value = try PlistValueInfo.parse(text, as: kind)
            try save(key, value)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GestaltViewModel())
}
