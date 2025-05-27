import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDataType: HistoryDataType = .notifications
    @State private var showingShareSheet = false
    @State private var csvData = ""
    
    enum HistoryDataType: String, CaseIterable {
        case notifications = "Notifications"
        case battery = "Battery"
    }
    
    var currentData: [HistoryDataPoint] {
        switch selectedDataType {
        case .notifications:
            return appState.notificationHistory
        case .battery:
            return appState.batteryHistory
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: LayoutTokens.spacing4) {
                // Data Type Toggle
                Picker("Data Type", selection: $selectedDataType) {
                    ForEach(HistoryDataType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, LayoutTokens.safePadding)
                
                // Chart Area
                if currentData.isEmpty {
                    EmptyStateView()
                } else {
                    HistoryChartView(data: currentData, dataType: selectedDataType)
                        .padding(.horizontal, LayoutTokens.safePadding)
                }
                
                Spacer()
            }
            .background(Color.surfaceDark)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        csvData = appState.exportHistoryData()
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accentMed)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [csvData])
        }
    }
}

struct HistoryChartView: View {
    let data: [HistoryDataPoint]
    let dataType: HistoryView.HistoryDataType
    @State private var selectedPoint: HistoryDataPoint?
    @State private var dragLocation: CGPoint = .zero
    
    var maxValue: Double {
        data.map(\.value).max() ?? 1
    }
    
    var minValue: Double {
        data.map(\.value).min() ?? 0
    }
    
    var valueRange: Double {
        maxValue - minValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.spacing4) {
            Text(chartTitle)
                .font(.title)
                .foregroundColor(.white)
            
            ZStack {
                // Chart background
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                    .fill(Color.tileDark)
                    .frame(height: 200)
                
                // Chart content
                VStack {
                    if dataType == .notifications {
                        BarChartView(data: data, maxValue: maxValue)
                    } else {
                        LineChartView(data: data, maxValue: maxValue, minValue: minValue)
                    }
                }
                .padding(LayoutTokens.spacing4)
                
                // Crosshair and value popup
                if let selectedPoint = selectedPoint {
                    CrosshairView(
                        point: selectedPoint,
                        data: data,
                        dataType: dataType,
                        maxValue: maxValue,
                        minValue: minValue
                    )
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragLocation = value.location
                        updateSelectedPoint(at: value.location)
                    }
                    .onEnded { _ in
                        selectedPoint = nil
                    }
            )
            .onLongPressGesture(minimumDuration: 0.1) {
                updateSelectedPoint(at: dragLocation)
            }
            
            // Legend
            ChartLegendView(dataType: dataType)
        }
    }
    
    private var chartTitle: String {
        switch dataType {
        case .notifications:
            return "Notifications per Day"
        case .battery:
            return "Battery Level (24h)"
        }
    }
    
    private func updateSelectedPoint(at location: CGPoint) {
        let chartWidth: CGFloat
        #if canImport(UIKit)
        chartWidth = UIScreen.main.bounds.width - (LayoutTokens.safePadding * 2) - (LayoutTokens.spacing4 * 2)
        #else
        chartWidth = 300 // Default width for SwiftUI charts
        #endif
        let pointWidth = chartWidth / CGFloat(data.count)
        let index = Int(location.x / pointWidth)
        
        if index >= 0 && index < data.count {
            selectedPoint = data[index]
            HapticManager.shared.soft()
        }
    }
}

struct BarChartView: View {
    let data: [HistoryDataPoint]
    let maxValue: Double
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                let height = maxValue > 0 ? (point.value / maxValue) * 150 : 0
                
                Rectangle()
                    .fill(Color.accentMed)
                    .frame(height: max(2, height))
                    .cornerRadius(2)
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: height)
            }
        }
        .frame(height: 150)
    }
}

struct LineChartView: View {
    let data: [HistoryDataPoint]
    let maxValue: Double
    let minValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let path = createPath(in: geometry.size)
            
            ZStack {
                // Area fill
                path
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentHigh.opacity(0.3),
                                Color.accentHigh.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Line stroke
                path
                    .stroke(Color.accentHigh, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // Data points
                ForEach(data.indices, id: \.self) { index in
                    let point = data[index]
                    let x = CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width
                    let normalizedValue = (point.value - minValue) / (maxValue - minValue)
                    let y = geometry.size.height - (normalizedValue * geometry.size.height)
                    
                    Circle()
                        .fill(Color.accentHigh)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 150)
    }
    
    private func createPath(in size: CGSize) -> Path {
        var path = Path()
        
        guard !data.isEmpty else { return path }
        
        let valueRange = maxValue - minValue
        
        for (index, point) in data.enumerated() {
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0
            let y = size.height - (normalizedValue * size.height)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Close the area path
        if !data.isEmpty {
            let lastX = CGFloat(data.count - 1) / CGFloat(max(1, data.count - 1)) * size.width // Avoid division by zero
            let firstX: CGFloat = 0
            
            path.addLine(to: CGPoint(x: lastX, y: size.height))
            path.addLine(to: CGPoint(x: firstX, y: size.height))
            path.closeSubpath()
        }
        
        return path
    }
}

struct CrosshairView: View {
    let point: HistoryDataPoint
    let data: [HistoryDataPoint]
    let dataType: HistoryView.HistoryDataType
    let maxValue: Double
    let minValue: Double
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing2) {
            // Value popup
            VStack(spacing: 4) {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.accentLow)
                
                Text(formattedValue)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, LayoutTokens.spacing3)
            .padding(.vertical, LayoutTokens.spacing2)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.spacing2)
                    .fill(Color.surfaceDark)
                    .shadow(radius: 4)
            )
            
            Spacer()
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = dataType == .battery ? .short : .none
        return formatter.string(from: point.timestamp)
    }
    
    private var formattedValue: String {
        switch dataType {
        case .notifications:
            return "\(Int(point.value)) notifications"
        case .battery:
            return "\(Int(point.value))%"
        }
    }
}

struct ChartLegendView: View {
    let dataType: HistoryView.HistoryDataType
    
    var body: some View {
        HStack {
            Circle()
                .fill(legendColor)
                .frame(width: 8, height: 8)
            
            Text(legendText)
                .font(.caption)
                .foregroundColor(.accentLow)
            
            Spacer()
        }
    }
    
    private var legendColor: Color {
        switch dataType {
        case .notifications:
            return .accentMed
        case .battery:
            return .accentHigh
        }
    }
    
    private var legendText: String {
        switch dataType {
        case .notifications:
            return "Daily notification count"
        case .battery:
            return "Battery level over time"
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: LayoutTokens.spacing4) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.accentLow)
            
            Text("No Data Yet")
                .font(.title)
                .foregroundColor(.white)
            
            Text("We'll fill this after a day of usage")
                .font(.body)
                .foregroundColor(.accentLow)
                .multilineTextAlignment(.center)
        }
        .padding(LayoutTokens.spacing6)
    }
}

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: View {
    let items: [Any]
    
    var body: some View {
        Text("Share not available on this platform")
    }
}
#endif

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
