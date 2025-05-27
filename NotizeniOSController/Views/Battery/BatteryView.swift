import SwiftUI

struct BatteryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: BatteryMode
    @State private var smartLowPowerEnabled: Bool
    @State private var lowPowerThreshold: Int
    
    init() {
        let settings = BatterySettings()
        self._selectedMode = State(initialValue: settings.mode)
        self._smartLowPowerEnabled = State(initialValue: settings.smartLowPowerEnabled)
        self._lowPowerThreshold = State(initialValue: settings.lowPowerThreshold)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LayoutTokens.spacing6) {
                    // Mode Picker
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing3) {
                        Text("Battery Mode")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Picker("Battery Mode", selection: $selectedMode) {
                            ForEach(BatteryMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedMode) { _, newMode in
                            appState.updateBatteryMode(newMode)
                        }
                    }
                    .padding(.horizontal, LayoutTokens.safePadding)
                    
                    // Runtime Gauge
                    VStack(spacing: LayoutTokens.spacing4) {
                        Text("Runtime Estimate")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        BatteryGaugeView(
                            level: appState.batteryData.level,
                            estimatedHours: appState.batteryData.estimatedHours,
                            isCharging: appState.batteryData.isCharging
                        )
                        .frame(height: 200)
                    }
                    .padding(.horizontal, LayoutTokens.safePadding)
                    
                    // Options
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing4) {
                        Text("Options")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        VStack(spacing: LayoutTokens.spacing4) {
                            // Smart Low Power Toggle
                            OptionCardView {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Smart Low-Power Mode")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Text("Automatically enable at \(lowPowerThreshold)%")
                                            .font(.caption)
                                            .foregroundColor(.accentLow)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $smartLowPowerEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                                        .onChange(of: smartLowPowerEnabled) { _, _ in
                                            HapticManager.shared.soft()
                                        }
                                }
                            }
                            
                            // Threshold Stepper
                            OptionCardView {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Low Battery Threshold")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Text("Trigger at \(lowPowerThreshold)% battery")
                                            .font(.caption)
                                            .foregroundColor(.accentLow)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: $lowPowerThreshold,
                                        in: 5...50,
                                        step: 5
                                    ) {
                                        Text("\(lowPowerThreshold)%")
                                            .font(.body)
                                            .foregroundColor(.accentMed)
                                            .frame(minWidth: 40)
                                    }
                                    .onChange(of: lowPowerThreshold) { _, _ in
                                        HapticManager.shared.warning()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.safePadding)
                    
                    // Drain Sources
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing4) {
                        Text("Top Drain Sources")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        VStack(spacing: LayoutTokens.spacing2) {
                            ForEach(Array(appState.topDrainApps.enumerated()), id: \.element.id) { index, app in
                                DrainSourceRowView(app: app, rank: index + 1)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.safePadding)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.surfaceDark)
            .navigationTitle("Battery")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BatteryGaugeView: View {
    let level: Double
    let estimatedHours: Double
    let isCharging: Bool
    
    var gaugeColor: Color {
        switch level {
        case 50...100:
            return .accentHigh
        case 20...49:
            return .accentMed
        default:
            return .errorColor
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.tileDark, lineWidth: 12)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: level / 100)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [gaugeColor.opacity(0.3), gaugeColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AnimationTokens.modeChange, value: level)
            
            // Center content
            VStack(spacing: LayoutTokens.spacing2) {
                Text("\(Int(estimatedHours))h")
                    .font(.marbleNumber)
                    .foregroundColor(.white)
                
                Text("\(Int(level))%")
                    .font(.title)
                    .foregroundColor(.accentLow)
                
                if isCharging {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.accentHigh)
                        Text("Charging")
                            .font(.caption)
                            .foregroundColor(.accentLow)
                    }
                }
            }
        }
    }
}

struct OptionCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
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
    }
}

struct DrainSourceRowView: View {
    let app: AppDrainData
    let rank: Int
    
    var body: some View {
        HStack(spacing: LayoutTokens.spacing3) {
            // Rank
            Text("\(rank)")
                .font(.caption)
                .foregroundColor(.accentLow)
                .frame(width: 20)
            
            // App icon
            Image(systemName: app.iconName)
                .font(.title3)
                .foregroundColor(.accentMed)
                .frame(width: 24, height: 24)
            
            // App name and percentage
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("\(app.drainPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.accentLow)
            }
            
            Spacer()
            
            // Sparkline (simplified)
            SparklineView(data: app.sparklineData)
                .frame(width: 60, height: 20)
        }
        .padding(.vertical, LayoutTokens.spacing2)
        .padding(.horizontal, LayoutTokens.spacing4)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.spacing3)
                .fill(Color.tileDark)
        )
    }
}

struct SparklineView: View {
    let data: [Double]
    
    var body: some View {
        let maxValue = data.max() ?? 1
        let normalizedData = data.map { $0 / maxValue }
        
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(normalizedData.indices, id: \.self) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: 4,
                        height: max(2, normalizedData[index] * 16)
                    )
                    .cornerRadius(1)
            }
        }
    }
}

#Preview {
    BatteryView()
        .environmentObject(AppState())
}
