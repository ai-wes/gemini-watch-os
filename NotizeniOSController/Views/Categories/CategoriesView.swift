import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var showingAddCategory = false
    @State private var selectedCategory: NotificationCategory?
    
    var filteredCategories: [NotificationCategory] {
        if searchText.isEmpty {
            return appState.categories
        } else {
            return appState.categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Notification Overview Section
                NotificationOverviewSection()
                    .padding(.horizontal, LayoutTokens.safePadding)
                    .padding(.bottom, LayoutTokens.spacing4)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, LayoutTokens.safePadding)
                    .padding(.bottom, LayoutTokens.spacing4)
                
                // Categories Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: LayoutTokens.spacing4),
                        GridItem(.flexible(), spacing: LayoutTokens.spacing4)
                    ], spacing: LayoutTokens.spacing4) {
                        ForEach(filteredCategories) { category in
                            CategoryCellView(category: category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.safePadding)
                    .padding(.bottom, 100) // Space for FAB
                }
            }
            .background(Color.surfaceDark)
            .navigationTitle("Notification Management")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentMed)
                                .clipShape(Circle())
                                .shadow(
                                    color: ShadowTokens.cardShadow.color,
                                    radius: ShadowTokens.cardShadow.radius,
                                    x: ShadowTokens.cardShadow.x,
                                    y: ShadowTokens.cardShadow.y
                                )
                        }
                        .padding(.trailing, LayoutTokens.safePadding)
                        .padding(.bottom, 100) // Above tab bar
                    }
                }
            )
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accentLow)
            
            TextField("Search notification categories", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
        }
        .padding(LayoutTokens.spacing3)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.spacing3)
                .fill(Color.tileDark)
        )
    }
}

struct CategoryCellView: View {
    let category: NotificationCategory
    let action: () -> Void
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutTokens.spacing3) {
                // Icon and priority indicator
                HStack {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(.accentMed)
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                    
                    // Priority badge
                    Text("\(Int(category.priority))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, LayoutTokens.spacing2)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(priorityColor(for: category.priority))
                        )
                }
                
                // Category name
                HStack {
                    Text(category.name)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                }
                
                // Priority slider
                VStack(alignment: .leading, spacing: LayoutTokens.spacing1) {
                    HStack {
                        Text("Priority")
                            .font(.caption)
                            .foregroundColor(.accentLow)
                        Spacer()
                    }
                    
                    Slider(
                        value: Binding(
                            get: { category.priority },
                            set: { newValue in
                                appState.updateCategoryPriority(category, priority: newValue)
                            }
                        ),
                        in: 0...100,
                        step: 1
                    ) {
                        Text("Priority")
                    }
                    .accentColor(priorityColor(for: category.priority))
                }
                
                Spacer()
            }
            .padding(LayoutTokens.spacing4)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                    .fill(Color.tileDark)
                    .shadow(
                        color: ShadowTokens.cardShadow.color,
                        radius: ShadowTokens.cardShadow.radius,
                        x: ShadowTokens.cardShadow.x,
                        y: ShadowTokens.cardShadow.y
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func priorityColor(for priority: Double) -> Color {
        switch priority {
        case 70...100:
            return .accentHigh
        case 30...69:
            return .accentMed
        default:
            return .accentLow
        }
    }
}

struct CategoryDetailView: View {
    let category: NotificationCategory
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var priority: Double
    @State private var isDigestEnabled: Bool
    @State private var muteWindows: [MuteWindow]
    @State private var showingAddMuteWindow = false
    
    init(category: NotificationCategory) {
        self.category = category
        self._priority = State(initialValue: category.priority)
        self._isDigestEnabled = State(initialValue: category.isDigestEnabled)
        self._muteWindows = State(initialValue: category.muteWindows)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Priority") {
                    VStack(spacing: LayoutTokens.spacing3) {
                        HStack {
                            Text("Priority: \(Int(priority))")
                                .font(.body)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Slider(value: $priority, in: 0...100, step: 1)
                            .accentColor(priorityColor(for: priority))
                            .onChange(of: priority) { _, newValue in
                                HapticManager.shared.rigid()
                            }
                    }
                }
                .listRowBackground(Color.tileDark)
                
                Section("Notification Behavior") {
                    Toggle("Include in digest", isOn: $isDigestEnabled)
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    Toggle("Sync to Apple Watch", isOn: .constant(true))
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    Toggle("Smart Priority Adjustment", isOn: .constant(true))
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    if isDigestEnabled {
                        HStack {
                            Text("Digest time")
                                .foregroundColor(.white)
                            Spacer()
                            Text("8:00 AM")
                                .foregroundColor(.accentLow)
                        }
                    }
                }
                .listRowBackground(Color.tileDark)
                
                Section {
                    ForEach(muteWindows) { window in
                        MuteWindowRowView(muteWindow: window) {
                            muteWindows.removeAll { $0.id == window.id }
                        }
                    }
                    .onDelete { indexSet in
                        muteWindows.remove(atOffsets: indexSet)
                    }
                    
                    Button("Add Mute Window") {
                        showingAddMuteWindow = true
                    }
                    .foregroundColor(.accentMed)
                } header: {
                    Text("Mute Windows")
                }
                .listRowBackground(Color.tileDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
            }
        }
        .sheet(isPresented: $showingAddMuteWindow) {
            AddMuteWindowView { newWindow in
                muteWindows.append(newWindow)
            }
        }
    }
    
    private func priorityColor(for priority: Double) -> Color {
        switch priority {
        case 70...100:
            return .accentHigh
        case 30...69:
            return .accentMed
        default:
            return .accentLow
        }
    }
    
    private func saveChanges() {
        // Update the category in app state
        if let index = appState.categories.firstIndex(where: { $0.id == category.id }) {
            appState.categories[index].priority = priority
            appState.categories[index].isDigestEnabled = isDigestEnabled
            appState.categories[index].muteWindows = muteWindows
        }
        HapticManager.shared.success()
    }
}

struct MuteWindowRowView: View {
    let muteWindow: MuteWindow
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeRangeString)
                    .foregroundColor(.white)
                Text("Daily")
                    .font(.caption)
                    .foregroundColor(.accentLow)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.errorColor)
            }
        }
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: muteWindow.startTime)) - \(formatter.string(from: muteWindow.endTime))"
    }
}

struct AddMuteWindowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var endTime = Date()
    let onAdd: (MuteWindow) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Time Range") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.tileDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("Add Mute Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newWindow = MuteWindow(startTime: startTime, endTime: endTime)
                        onAdd(newWindow)
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
            }
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var bundleId = ""
    @State private var selectedIcon = "app"
    
    let availableIcons = ["app", "message", "mail", "phone", "calendar", "photo", "music", "video", "gamecontroller", "cart", "newspaper", "heart"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $name)
                        .foregroundColor(.white)
                    
                    TextField("Bundle ID", text: $bundleId)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .listRowBackground(Color.tileDark)
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: LayoutTokens.spacing3) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .accentMed : .accentLow)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.accentMed.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                }
                .listRowBackground(Color.tileDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("Add Notification Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newCategory = NotificationCategory(
                            name: name,
                            iconName: selectedIcon,
                            bundleId: bundleId
                        )
                        appState.addCategory(newCategory)
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                    .disabled(name.isEmpty || bundleId.isEmpty)
                }
            }
        }
    }
}

struct NotificationOverviewSection: View {
    @EnvironmentObject var appState: AppState
    @State private var showingGlobalSettings = false
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing3) {
            HStack {
                Text("Notification Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    showingGlobalSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.accentMed)
                }
            }
            
            HStack(spacing: LayoutTokens.spacing3) {
                NotificationStatCard(
                    title: "Total",
                    value: "\(appState.notifications.count)",
                    iconName: "bell",
                    color: .accentMed
                )
                
                NotificationStatCard(
                    title: "Unread",
                    value: "\(appState.unreadCount)",
                    iconName: "bell.badge",
                    color: .accentHigh
                )
                
                NotificationStatCard(
                    title: "High Priority",
                    value: "\(appState.highPriorityCount)",
                    iconName: "exclamationmark.circle",
                    color: .errorColor
                )
            }
        }
        .padding(LayoutTokens.spacing4)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                .fill(Color.tileDark)
                .shadow(
                    color: ShadowTokens.cardShadow.color,
                    radius: ShadowTokens.cardShadow.radius,
                    x: ShadowTokens.cardShadow.x,
                    y: ShadowTokens.cardShadow.y
                )
        )
        .sheet(isPresented: $showingGlobalSettings) {
            GlobalNotificationSettingsView()
        }
    }
}

struct NotificationStatCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing2) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.accentLow)
        }
        .frame(maxWidth: .infinity)
        .padding(LayoutTokens.spacing3)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.spacing2)
                .fill(Color.surfaceDark)
        )
    }
}

struct GlobalNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var digestEnabled = true
    @State private var watchSyncEnabled = true
    @State private var smartPriorityEnabled = true
    @State private var batchingEnabled = true
    @State private var digestTime = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Global Settings") {
                    Toggle("Enable Smart Digest", isOn: $digestEnabled)
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    Toggle("Sync to Apple Watch", isOn: $watchSyncEnabled)
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    Toggle("Smart Priority Learning", isOn: $smartPriorityEnabled)
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                    
                    Toggle("Notification Batching", isOn: $batchingEnabled)
                        .foregroundColor(.white)
                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                }
                .listRowBackground(Color.tileDark)
                
                if digestEnabled {
                    Section("Digest Schedule") {
                        DatePicker("Digest Time", selection: $digestTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Next digest")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Tomorrow at \(digestTime, formatter: timeFormatter)")
                                .foregroundColor(.accentLow)
                        }
                    }
                    .listRowBackground(Color.tileDark)
                }
                
                Section("Watch Integration") {
                    HStack {
                        Image(systemName: appState.watchData.isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(appState.watchData.isReachable ? .green : .red)
                        Text("Apple Watch")
                            .foregroundColor(.white)
                        Spacer()
                        Text(appState.watchData.isReachable ? "Connected" : "Disconnected")
                            .foregroundColor(appState.watchData.isReachable ? .green : .red)
                    }
                    
                    Button("Force Sync to Watch") {
                        appState.syncAllDataToWatch()
                        HapticManager.shared.success()
                    }
                    .foregroundColor(.accentMed)
                    .disabled(!appState.watchData.isReachable)
                }
                .listRowBackground(Color.tileDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    CategoriesView()
        .environmentObject(AppState())
}
