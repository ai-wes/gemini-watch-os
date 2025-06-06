import SwiftUI
import Combine
import WatchKit
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// Represents the shared state and data for the NotiZen watchOS app.
// This will be the single source of truth for dynamic data displayed in views.
class WatchAppState: ObservableObject, NotificationCollectorDelegate {
    
    // MARK: - Published Properties for UI Updates
    
    // Dashboard Card Data
    @Published var unreadHighPriorityCount: Int = 0
    @Published var latestHighPriorityMessage: String = "No critical alerts"
    @Published var batteryHoursRemaining: Int = 0
    @Published var batteryPercentage: Double = 0.0 // For a potential gauge or detail view
    
    // Dashboard Notification List
    @Published var dashboardNotifications: [WatchNotificationItem] = []
    
    // High-Priority Feed
    @Published var highPriorityFeed: [NotificationEvent] = [] // Using the actual data model
    @Published var highPriorityNotifications: [NotificationEvent] = []
    @Published var lowPriorityNotifications: [NotificationEvent] = []
    @Published var estimatedTimeToEmpty: TimeInterval = 8 * 3600 // Default 8 hours
    
    // User Preferences (subset relevant to watch display)
    @Published var isBatteryGuardSmartModeEnabled: Bool = true
    @Published var digestStartTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())! // Default 9 AM
    @Published var digestEndTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())! // Default 5 PM
    @Published var userCategories: [CategoryPreference] = [
        CategoryPreference(name: "Finance", isEnabled: true, keywords: ["bank", "payment", "transaction", "invoice", "wire"]),
        CategoryPreference(name: "Social", isEnabled: true, keywords: ["mention", "reply", "message", "friend", "post"]),
        CategoryPreference(name: "Work", isEnabled: true, keywords: ["meeting", "deadline", "project", "task", "slack", "teams"]),
        CategoryPreference(name: "Promotions", isEnabled: false, keywords: ["sale", "discount", "offer", "coupon", "deal"]),
        CategoryPreference(name: "News", isEnabled: true, keywords: ["breaking", "update", "report", "article", "headline"]),
        CategoryPreference(name: "Health", isEnabled: true, keywords: ["workout", "steps", "heart rate", "sleep", "medication"]),
        CategoryPreference(name: "Reminders", isEnabled: true, keywords: ["reminder", "due", "appointment", "alert", "event"])
    ]
    @Published var notificationSummary: String = "No new low-priority notifications."
    @Published var currentDigests: [NotificationDigest] = [] // For storing generated digests
    @Published var digestSummary: String = "Nothing to summarize yet."
    @Published var digestItems: [NotificationEvent] = []

    // MARK: - AI Engines & Services
    let notificationClassifier: NotificationClassifier
    let batchingEngine: BatchingEngine
    let summarizer: Summarizer
    let batterySampler: BatterySampler
    private let drainPredictor = DrainPredictor()
    private let optimizer = Optimizer()
    // private let cloudSyncCoordinator = CloudSyncCoordinator() // Remove or comment out the direct property initialization

    // Declare cloudSyncCoordinator as a let property without an initial value
    private let cloudSyncCoordinator: CloudSyncCoordinator
    private let notificationCollector = NotificationCollector()
    
    private var cancellables = Set<AnyCancellable>()
    private var digestUpdateTimer: Timer? // Timer for scheduling digest preview
    private var userDefaultsObserver: NSObjectProtocol?
    private var appGroupMonitoringTimer: Timer? // Timer for app group checks

    // MARK: - Initialization
    init() {
        var isForPreviewEnvironment = false
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            isForPreviewEnvironment = true
        }
        #endif
        // Temporarily disable CloudSyncCoordinator to prevent crashes
        // self.cloudSyncCoordinator = CloudSyncCoordinator(forPreview: isForPreviewEnvironment)
        self.cloudSyncCoordinator = CloudSyncCoordinator(forPreview: true) // Force preview mode

        // Initialize AI Engines and Services
        self.notificationClassifier = NotificationClassifier()
        self.batchingEngine = BatchingEngine()
        self.summarizer = Summarizer()
        self.batterySampler = BatterySampler()
        
        // Set up notification collection
        self.notificationCollector.delegate = self

        // Initialize battery monitoring and start sampling
        batterySampler.startSampling()
        
        // Load sample data for development
        loadDummyData()
        
        // Schedule digest updates
        scheduleDigestTimer()
        
        // Setup Watch Connectivity
        setupWatchConnectivity()
        
        print("WatchAppState: Initialization complete")
        startMonitoringAppGroupNotifications() // Start monitoring for new notifications

        // Subscribe to battery sampler updates to update predictions
        batterySampler.$currentSnapshots
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshots in
                guard let self = self, let latestSnapshot = snapshots.last else { return }
                self.drainPredictor.addSnapshot(latestSnapshot) // Update predictor with the latest
                self.batteryPercentage = latestSnapshot.level
                // TODO: Get current charging state from WKInterfaceDevice.current().batteryState
                let currentChargingState = WKInterfaceDevice.current().batteryState.rawValue // Or map to your enum/int
                if let timeRemaining = self.drainPredictor.estimateTimeRemaining(currentLevel: latestSnapshot.level, currentChargingState) {
                    self.estimatedTimeToEmpty = timeRemaining
                    self.batteryHoursRemaining = Int(timeRemaining / 3600)
                }
                
                // Sync battery data to iOS app
                self.syncBatteryDataToiOS()
                
                // Trigger optimizer to re-evaluate based on new battery data
                // self.optimizer.evaluateAndApplyOptimizations()
            }
            .store(in: &cancellables)
        
        // Example of how you might subscribe to a service that updates data:
        // notificationStore.$highPriorityNotifications
        //     .receive(on: DispatchQueue.main)
        //     .assign(to: \\.highPriorityFeed, on: self)
        //     .store(in: &cancellables)

        // Perform initial CloudKit setup/check
        // cloudSyncCoordinator.checkAccountStatus()
        // cloudSyncCoordinator.subscribeToPreferenceChanges { error in
        //     if let error = error {
        //         print("Failed to subscribe to preference changes: \\(error.localizedDescription)")
        //     }
        // }
    }
    
    deinit {
        if let observer = userDefaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        digestUpdateTimer?.invalidate()
        // Invalidate the app group monitoring timer as well
        appGroupMonitoringTimer?.invalidate()
    }
    
    // MARK: - App Group Notification Monitoring
    
    private func startMonitoringAppGroupNotifications() {
        // Using UserDefaults KVO (less ideal) or a timer to check periodically.
        // A more robust solution might involve Darwin notifications if possible from app to extension,
        // or simply checking on app foreground/background transitions.
        // For simplicity, we'll use a timer here to periodically check UserDefaults.
        
        // Initial check
        processPendingNotificationsFromAppGroup()
        
        // Periodically check (e.g., every 30 seconds when app is active)
        // This is a fallback; ideally, the app processes these on launch or when brought to foreground.
        // A better trigger would be `UIApplication.willEnterForegroundNotification` or similar for watchOS.
        // For watchOS, we can check when the app becomes active.
        // NotificationCenter.default.addObserver(forName: WKApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
        //     self.processPendingNotificationsFromAppGroup()
        // }
        // For now, a simple timer to illustrate the concept.
        // In a real app, you'd hook into app lifecycle events.
        appGroupMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.processPendingNotificationsFromAppGroup()
        }
        
        // Alternative: If running on iOS and you want to observe UserDefaults changes directly (not typical for watchOS extension to app)
        // userDefaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: UserDefaults(suiteName: "group.com.wesley.NotiZen"), queue: .main) { [weak self] _ in
        //     self?.processPendingNotificationsFromAppGroup()
        // }
    }
    
    func processPendingNotificationsFromAppGroup() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.wesley.NotiZen") else {
            print("WatchAppState: Failed to access App Group UserDefaults.")
            return
        }
        
        guard let notificationsData = userDefaults.array(forKey: "pendingNotifications") as? [Data], !notificationsData.isEmpty else {
            // print("WatchAppState: No pending notifications in App Group.")
            return
        }
        
        print("WatchAppState: Found \(notificationsData.count) pending notifications in App Group.")
        
        var successfullyProcessedIndices: [Int] = []
        let decoder = JSONDecoder()
        
        for (index, data) in notificationsData.enumerated() {
            do {
                let notificationEvent = try decoder.decode(NotificationEvent.self, from: data)
                // Call the existing processing logic
                processIncomingNotification(notificationEvent) // This is already on main queue if called from UI context
                successfullyProcessedIndices.append(index)
            } catch {
                print("WatchAppState: Failed to decode NotificationEvent from App Group: \(error.localizedDescription)")
                // Decide if you want to remove malformed data or leave it
            }
        }
        
        // Remove processed notifications from UserDefaults to prevent reprocessing
        if !successfullyProcessedIndices.isEmpty {
            var currentNotificationsData = userDefaults.array(forKey: "pendingNotifications") as? [Data] ?? []
            // Remove in reverse order to maintain correct indices
            for index in successfullyProcessedIndices.sorted(by: >) {
                if index < currentNotificationsData.count {
                    currentNotificationsData.remove(at: index)
                }
            }
            userDefaults.set(currentNotificationsData, forKey: "pendingNotifications")
            print("WatchAppState: Processed and cleared \(successfullyProcessedIndices.count) notifications from App Group.")
        }
    }

    // MARK: - Data Loading and Updating Methods
    
    func refreshDashboardData() {
        // This method would be called to update all dashboard-related data.
        // It would interact with your services and AI engines.
        print("WatchAppState: Refreshing dashboard data...")
        // Example:\n        // self.unreadHighPriorityCount = notificationStore.getUnreadHighPriorityCount()\n        // self.latestHighPriorityMessage = notificationStore.getLatestHighPriorityMessage()?.title ?? "No critical alerts"\n        // self.batteryHoursRemaining = Int(batteryMonitor.getEstimatedHoursRemaining())\n        // self.dashboardNotifications = notificationStore.getDashboardNotifications(limit: 8).map { /* convert to WatchNotificationItem */ }
        
        // For now, just re-apply dummy data or slightly modify it to show changes
        loadDummyData(slightlyModify: true)

        // Example: Use the summarizer for the latest high priority message
        if let latestHigh = highPriorityFeed.first {
            self.latestHighPriorityMessage = summarizer.summarize(notification: latestHigh)
        }
    }
    
    func processIncomingNotification(_ notification: NotificationEvent) {
        DispatchQueue.main.async { // Ensure UI updates are on the main thread
            let classificationResult = self.notificationClassifier.classify(notification: notification, userCategories: self.userCategories)
            
            switch classificationResult.priority {
            case .high:
                self.highPriorityNotifications.append(notification)
                self.highPriorityFeed.insert(notification, at: 0) // Add to top of the feed
                if self.highPriorityFeed.count > 20 { // Keep feed size manageable
                    self.highPriorityFeed.removeLast()
                }
                self.unreadHighPriorityCount += 1
                self.latestHighPriorityMessage = self.summarizer.summarize(notification: notification)
                // Potentially trigger immediate haptic feedback or UI alert for high priority
                WKInterfaceDevice.current().play(.notification) 

            case .low:
                self.lowPriorityNotifications.append(notification)
                self.batchingEngine.addNotificationToBatch(notification)
                // Low priority notifications don't update unread count or latest message directly
                // They will be processed into digests later.
                self.triggerDigestUpdateIfNeeded() // Check if digests should be created

            case .unknown: // Treat unknown as low for now, or define specific handling
                print("Notification with unknown priority: \(notification.title ?? "Untitled") - \(notification.message)")
                self.lowPriorityNotifications.append(notification) // Default to low priority handling
                self.batchingEngine.addNotificationToBatch(notification)
                self.triggerDigestUpdateIfNeeded()
            default: // Ensure switch is exhaustive
                print("Notification with unhandled priority: \(notification.title ?? "Untitled")")
                self.lowPriorityNotifications.append(notification) // Default to low priority handling for safety
                self.batchingEngine.addNotificationToBatch(notification)
                self.triggerDigestUpdateIfNeeded()
            }
            
            // Update dashboard notifications (simplified example)
            self.updateDashboardNotifications()
            
            // Persist changes if necessary (e.g., to Core Data or UserDefaults for app state)
            // self.saveAppState()
        }
    }

    // Deprecated: Notifications are now pulled from App Group UserDefaults
    // func handleNewRemoteNotification(userInfo: [AnyHashable : Any]) {
    //     // This method would be called by the system when a new remote notification arrives.
    //     // It needs to parse `userInfo`, create a `NotificationEvent`, and then process it.
    //     print("WatchAppState: Handling new remote notification...")
        
    //     // Example parsing (highly dependent on your payload structure)
    //     guard let aps = userInfo["aps"] as? [String: AnyObject],
    //           let alert = aps["alert"] as? [String: String],
    //           let title = alert["title"],
    //           let body = alert["body"] else {
    //         print("WatchAppState: Failed to parse notification payload.")
    //         return
    //     }
        
    //     let category = aps["category"] as? String ?? "Default"
    //     let appName = userInfo["appName"] as? String ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown App")
    //     let message = body // Assuming body is the main message content for now

    //     let newNotification = NotificationEvent(
    //         id: UUID(), 
    //         timestamp: Date(), 
    //         appName: appName, 
    //         bundleID: userInfo["bundleID"] as? String ?? "com.example.unknown",
    //         title: title, 
    //         body: body, 
    //         message: message, // Set message explicitly
    //         category: category, 
    //         categoryIdentifier: category, // Assuming category from payload matches identifier
    //         priority: .unknown // Priority will be determined by the classifier
    //     )
        
    //     processIncomingNotification(newNotification)
    // }
    
    private func updateDashboardNotifications() {
        // Simple logic: show a mix of high-priority and recent low-priority (or digests)
        // This is a placeholder and should be refined.
        var items: [WatchNotificationItem] = []
        
        // Add some high-priority notifications
        for hpNotif in highPriorityFeed.prefix(3) {
            items.append(WatchNotificationItem(id: hpNotif.id, title: hpNotif.title ?? hpNotif.appName, messageSnippet: summarizer.summarize(notification: hpNotif), timestamp: hpNotif.date, type: .highPriority))
        }
        
        // Add some digests or recent low-priority notifications
        for digest in currentDigests.prefix(2) {
            let (title, _) = summarizer.summarize(digest: digest)
            items.append(WatchNotificationItem(id: digest.id, title: title, messageSnippet: "\(digest.notifications.count) items", timestamp: digest.creationDate, type: .digest))
        }
        
        // If no digests, show some recent low-priority items directly
        if currentDigests.isEmpty {
            for lpNotif in lowPriorityNotifications.suffix(2).reversed() { // Most recent low-prio
                 items.append(WatchNotificationItem(id: lpNotif.id, title: lpNotif.title ?? lpNotif.appName, messageSnippet: summarizer.summarize(notification: lpNotif), timestamp: lpNotif.date, type: .lowPriority))
            }
        }
        
        self.dashboardNotifications = items.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5).map{$0} // Show latest 5 items
    }
    
    // MARK: - NotificationCollectorDelegate
    
    func didReceiveNotification(_ notification: NotificationEvent) {
        DispatchQueue.main.async {
            self.processNewNotification(notification)
        }
    }
    
    private func processNewNotification(_ notification: NotificationEvent) {
        // Classify the notification
        let classificationResult = notificationClassifier.classify(
            notification: notification, 
            userCategories: userCategories
        )
        
        // Create a new notification with classification results
        var classifiedNotification = notification
        classifiedNotification.score = classificationResult.priority == .high ? 0.8 : 
                                     (classificationResult.priority == .medium ? 0.5 : 0.2)
        
        // Route based on priority
        switch classificationResult.priority {
        case .high:
            highPriorityNotifications.append(classifiedNotification)
            highPriorityFeed.append(classifiedNotification)
            unreadHighPriorityCount = highPriorityNotifications.count
            latestHighPriorityMessage = notification.title ?? notification.message
            
            // Trigger haptic feedback for high priority
            WKInterfaceDevice.current().play(.notification)
            
        case .medium:
            // Add to low priority for now, could create separate medium priority handling
            lowPriorityNotifications.append(classifiedNotification)
            
        case .low:
            lowPriorityNotifications.append(classifiedNotification)
            if classificationResult.shouldDigest {
                batchingEngine.addNotificationToBatch(classifiedNotification)
            }
            
        case .unknown:
            // Handle unknown priority as low priority
            lowPriorityNotifications.append(classifiedNotification)
            batchingEngine.addNotificationToBatch(classifiedNotification)
        }
        
        // Update dashboard and complications
        updateDashboardNotifications()
        updateComplicationData()
        
        print("WatchAppState: Processed \(classificationResult.priority) priority notification: \(notification.title ?? "No Title")")
    }

    // MARK: - Digest Management
    
    func triggerDigestUpdateIfNeeded() {
        // This function decides when to finalize batches and create digests.
        // It could be based on time, number of pending items, or app state (e.g., app becoming active).
        // For now, let's assume it's called after adding a low-priority notification
        // and we'll create digests if there are enough items or enough time has passed.

        // Simple trigger: if batching engine has items, try to finalize.
        // More complex logic can be added based on BatchingRule.maxTimeWindow etc.
        // Create digests from batching engine
        let newDigests = batchingEngine.finalizeAndCreateDigests(categoryPreferences: self.userCategories)
        if !newDigests.isEmpty {
            DispatchQueue.main.async {
                self.currentDigests.append(contentsOf: newDigests)
                // Sort digests by creation date, newest first
                self.currentDigests.sort { $0.creationDate > $1.creationDate }
                // Limit the number of stored digests if necessary
                if self.currentDigests.count > 10 { // Keep max 10 digests
                    self.currentDigests = Array(self.currentDigests.prefix(10))
                }
                self.notificationSummary = self.summarizer.generateOverallSummary(for: self.currentDigests)
                self.updateDashboardNotifications() // Update dashboard as digests are created
                print("WatchAppState: Created \\(newDigests.count) new digests. Total digests: \\(self.currentDigests.count)")
            }
        }
    }

    private func scheduleDigestTimer() {
        // This timer is for the *preview* of the digest, not its creation.
        // Digest creation is now triggered by `triggerDigestUpdateIfNeeded`.
        // The PRD mentions a digest preview sheet (A5) that might appear at `preferredDigestTime`.
        // This timer could trigger that UI event.
        
        // Remove existing timer if any
        digestUpdateTimer?.invalidate()
        
        // Calculate time until next digestEndTime (when we should show digest)
        var nextDigestPreviewTime = Calendar.current.nextDate(after: Date(), matching: Calendar.current.dateComponents([.hour, .minute], from: digestEndTime), matchingPolicy: .nextTime)!
        
        // If the time is in the past for today, schedule for tomorrow
        if nextDigestPreviewTime < Date() {
            nextDigestPreviewTime = Calendar.current.date(byAdding: .day, value: 1, to: nextDigestPreviewTime)!
        }
        
        let timeInterval = nextDigestPreviewTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return } // Should not happen if logic above is correct

        digestUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("WatchAppState: Digest preview time reached. (Preferred time: \\(self.preferredDigestTime))")
            // TODO: Trigger the display of DigestPreviewSheetView (PRD A5)
            // This might involve setting a @Published var that a view is observing to present the sheet.
            // For example: self.shouldShowDigestPreviewSheet = true
            
            // Reschedule for the next day
            self.scheduleDigestTimer()
        }
        print("WatchAppState: Digest preview scheduled for \\(nextDigestPreviewTime).")
    }
    
    // MARK: - User Actions
    
    func muteNotification(id: UUID, for duration: TimeInterval) {
        // Logic to mute a notification
        // This would interact with NotificationStore and potentially CloudKit
        print("WatchAppState: Muting notification \\(id) for \\(duration) seconds.")
        // HapticManager.shared.play(.success) // Example haptic feedback
        // Potentially inform optimizer or batching engine
    }
    
    func archiveNotification(_ notification: NotificationEvent) {
        if let index = highPriorityNotifications.firstIndex(where: { $0.id == notification.id }) {
            highPriorityNotifications.remove(at: index)
            updateComplicationData()
            // TODO: Persist this change (e.g., mark as archived in CoreData)
            // TODO: Notify CloudSyncCoordinator
        }
        // Potentially move to a general "processed" or "archived" list if needed later
    }

    func updateCategory(_ category: CategoryPreference) {
        if let index = userCategories.firstIndex(where: { $0.id == category.id }) {
            userCategories[index] = category
            // TODO: Persist this change
            // TODO: Notify CloudSyncCoordinator
            // TODO: Potentially re-classify existing notifications if a category is disabled/enabled
        }
    }

    func addCategory(name: String) {
        let newCategory = CategoryPreference(name: name, isEnabled: true)
        userCategories.append(newCategory)
        // TODO: Persist this change
        // TODO: Notify CloudSyncCoordinator
    }

    func deleteCategory(at offsets: IndexSet) {
        userCategories.remove(atOffsets: offsets)
        updateComplicationData() // Categories might affect counts indirectly
        // TODO: Persist this change
        // TODO: Notify CloudSyncCoordinator
        // TODO: Handle notifications that belonged to the deleted category
    }
    
    func saveDigestTimePreference() {
        // This is where you would persist digest times, e.g., to UserDefaults or CoreData
        // For now, it's already updated in @Published var, if persistence is added, call it here.
        print("Digest time preferences saved: \(digestStartTime) to \(digestEndTime)")
        // self.cloudSyncCoordinator.syncUserPreference(key: "digestStartTime", value: digestStartTime)
        // self.cloudSyncCoordinator.syncUserPreference(key: "digestEndTime", value: digestEndTime)
        scheduleDigestTimer() // Reschedule timer with new times
    }


    @Published var shouldShowDigestPreviewSheet = false

    private func triggerDigestUpdateIfNeeded(forceShow: Bool = false) {
        // Called when a new low-priority notification arrives or when the timer fires.
        // The actual summarization and decision to show the sheet will happen here.
        
        guard !lowPriorityNotifications.isEmpty else {
            notificationSummary = "No new low-priority notifications."
            if forceShow { // If timer fired but no notifications, still update summary
                 print("Digest timer fired, but no low-priority notifications to summarize.")
            }
            return
        }

        // Generate summary using the Summarizer AI Engine
        let summary = summarizer.summarize(notifications: lowPriorityNotifications, categoryPreferences: userCategories)
        notificationSummary = summary
        
        // PRD A5: Triggered at scheduled time
        // The `forceShow` parameter handles the scheduled time trigger.
        // We might also add logic here to show it if a certain number of low-prio notifs accumulate.
        if forceShow {
            print("Force showing digest preview sheet.")
            shouldShowDigestPreviewSheet = true
            WKInterfaceDevice.current().play(.failure) // PRD Haptics for digest created
        }
    }


    // --- Private Methods ---
    private func handleNotificationTapped(_ notification: NotificationEvent) {
        // Logic to handle when a notification is tapped
        // This might involve navigating to a detail view or performing an action
        print("Notification tapped: \\(notification.title)")
        // Example: Navigate to a detail view or present options
    }
    
    // MARK: - Watch Connectivity
    private func setupWatchConnectivity() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            print("WatchAppState: WatchConnectivity not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = WatchConnectivityManager.shared
        WatchConnectivityManager.shared.watchAppState = self
        session.activate()
        
        print("WatchAppState: WatchConnectivity setup initiated. isCompanionAppInstalled: \(session.isCompanionAppInstalled)")
        #endif
    }
    
    // MARK: - Sync Methods
    func syncBatteryDataToiOS() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        
        let batteryData = [
            "level": batteryPercentage,
            "isCharging": WKInterfaceDevice.current().batteryState == .charging,
            "estimatedHours": Double(batteryHoursRemaining)
        ] as [String : Any]
        
        let message = ["batteryData": batteryData]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Watch: Failed to send battery data to iOS: \(error.localizedDescription)")
            }
        } else {
            // Use application context for background updates
            do {
                try WCSession.default.updateApplicationContext(message)
            } catch {
                print("Watch: Failed to update application context: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    func requestSyncFromiOS() {
        #if canImport(WatchConnectivity)
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("Watch: Session not activated, cannot sync")
            return
        }
        
        
        guard session.isCompanionAppInstalled else {
            print("Watch: Companion iOS app not installed, cannot sync")
            return
        }
        
        guard session.isReachable else {
            print("Watch: iPhone not reachable for sync request")
            return
        }
        
        let message = ["requestSync": true]
        session.sendMessage(message, replyHandler: { response in
            print("Watch: Sync request acknowledged: \(response)")
        }) { error in
            print("Watch: Failed to request sync from iOS: \(error.localizedDescription)")
        }
        #endif
    }
    
    // Methods to handle incoming sync data from iOS
    func updateCategoriesFromiOS(_ categories: [IOSNotificationCategory]) {
        DispatchQueue.main.async {
            // Convert iOS categories to watch categories format
            self.userCategories = categories.map { iosCategory in
                CategoryPreference(
                    name: iosCategory.name,
                    isEnabled: iosCategory.priority > 30, // Enable if priority > 30
                    keywords: [] // iOS doesn't have keywords, keep empty
                )
            }
            print("Watch: Updated \(categories.count) categories from iOS")
        }
    }
    
    func updateBatterySettingsFromiOS(_ settings: IOSBatterySettings) {
        DispatchQueue.main.async {
            // Apply battery mode settings from iOS
            switch settings.mode {
            case .balanced:
                self.isBatteryGuardSmartModeEnabled = true
            case .runtimePlus:
                self.isBatteryGuardSmartModeEnabled = true
                // Additional runtime optimization could be applied here
            case .performance:
                self.isBatteryGuardSmartModeEnabled = false
            }
            print("Watch: Updated battery settings from iOS - Mode: \(settings.mode)")
        }
    }
    
    // Add more methods for other user actions and data manipulations as needed.
}

// Add this struct at the top of WatchAppState or create a separate file
struct WatchNotificationItem: Identifiable {
    let id: UUID
    let title: String
    let messageSnippet: String
    let timestamp: Date
    let type: NotificationType
    
    enum NotificationType {
        case highPriority
        case lowPriority
        case digest
    }
    
    init(id: UUID = UUID(), title: String, messageSnippet: String, timestamp: Date, type: NotificationType) {
        self.id = id
        self.title = title
        self.messageSnippet = messageSnippet
        self.timestamp = timestamp
        self.type = type
    }
}

// Add missing priority enum
enum NotificationPriority {
    case high
    case medium
    case low
    case unknown
}

// iOS Data Models for sync (simplified versions)
struct IOSNotificationCategory: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let bundleId: String
    let priority: Double
    let isDigestEnabled: Bool
}

struct IOSBatterySettings: Codable {
    let mode: IOSBatteryMode
    let smartLowPowerEnabled: Bool
    let lowPowerThreshold: Int
}

enum IOSBatteryMode: String, Codable {
    case balanced = "balanced"
    case runtimePlus = "runtime+"
    case performance = "performance"
}

// MARK: - Watch Connectivity Manager
#if canImport(WatchConnectivity)
class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    weak var watchAppState: WatchAppState?
    
    override init() {
        super.init()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch: Session activation completed: \(activationState), error: \(String(describing: error))")
        print("Watch: isCompanionAppInstalled: \(session.isCompanionAppInstalled), isReachable: \(session.isReachable)")
        
        if let error = error {
            print("Watch: Activation error: \(error.localizedDescription)")
        }
        
        if activationState == .activated && session.isCompanionAppInstalled {
            DispatchQueue.main.async {
                // Request initial sync from iOS only if companion app is available
                self.watchAppState?.requestSyncFromiOS()
            }
        } else {
            print("Watch: Cannot sync - activation: \(activationState), companion installed: \(session.isCompanionAppInstalled)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch: Received message from iOS: \(message.keys)")
        
        // Handle ping from iOS
        if message["ping"] != nil {
            replyHandler(["pong": "success"])
            return
        }
        
        // Handle battery mode update
        if let batteryMode = message["batteryMode"] as? String {
            DispatchQueue.main.async {
                if let mode = IOSBatteryMode(rawValue: batteryMode) {
                    let settings = IOSBatterySettings(
                        mode: mode,
                        smartLowPowerEnabled: true,
                        lowPowerThreshold: 20
                    )
                    self.watchAppState?.updateBatterySettingsFromiOS(settings)
                }
            }
            replyHandler(["batteryModeUpdated": true])
            return
        }
        
        // Handle categories sync
        if let categoriesData = message["syncCategories"] as? Data {
            do {
                let decoder = JSONDecoder()
                let categories = try decoder.decode([IOSNotificationCategory].self, from: categoriesData)
                
                DispatchQueue.main.async {
                    self.watchAppState?.updateCategoriesFromiOS(categories)
                }
                replyHandler(["categoriesUpdated": true])
            } catch {
                print("Watch: Failed to decode categories: \(error)")
                replyHandler(["error": "Failed to decode categories"])
            }
            return
        }
        
        // Handle battery settings sync
        if let settingsData = message["syncBatterySettings"] as? Data {
            do {
                let decoder = JSONDecoder()
                let settings = try decoder.decode(IOSBatterySettings.self, from: settingsData)
                
                DispatchQueue.main.async {
                    self.watchAppState?.updateBatterySettingsFromiOS(settings)
                }
                replyHandler(["batterySettingsUpdated": true])
            } catch {
                print("Watch: Failed to decode battery settings: \(error)")
                replyHandler(["error": "Failed to decode battery settings"])
            }
            return
        }
        
        replyHandler(["status": "unknown message type"])
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch: Received application context from iOS: \(applicationContext.keys)")
        
        // Handle background sync from iOS
        if let categoriesData = applicationContext["categories"] as? Data {
            do {
                let decoder = JSONDecoder()
                let categories = try decoder.decode([IOSNotificationCategory].self, from: categoriesData)
                
                DispatchQueue.main.async {
                    self.watchAppState?.updateCategoriesFromiOS(categories)
                }
            } catch {
                print("Watch: Failed to decode categories from context: \(error)")
            }
        }
        
        if let settingsData = applicationContext["batterySettings"] as? Data {
            do {
                let decoder = JSONDecoder()
                let settings = try decoder.decode(IOSBatterySettings.self, from: settingsData)
                
                DispatchQueue.main.async {
                    self.watchAppState?.updateBatterySettingsFromiOS(settings)
                }
            } catch {
                print("Watch: Failed to decode battery settings from context: \(error)")
            }
        }
    }
}
#endif

// Add missing methods to WatchAppState
extension WatchAppState {
    func loadDummyData(slightlyModify: Bool = false) {
        // Initialize with realistic values
        self.batteryHoursRemaining = slightlyModify ? 16 : 18
        
        // Initialize with empty state - no hardcoded notifications
        // This ensures a clean start for the user
        print("WatchAppState: Starting with clean state - no sample notifications loaded")
        
        print("WatchAppState: Loaded realistic sample data. SlightlyModify: \(slightlyModify)")
    }
    
    func archiveNotification(id: UUID) {
        // Remove from high priority notifications
        highPriorityNotifications.removeAll { $0.id == id }
        highPriorityFeed.removeAll { $0.id == id }
        
        // Update counts
        unreadHighPriorityCount = highPriorityNotifications.count
        
        // Update complication data
        updateComplicationData()
    }
    
    func updateComplicationData() {
        // This method updates watch complications with current data
        // Implementation would depend on the complications you've defined
        print("WatchAppState: Updated complication data - High Priority: \(unreadHighPriorityCount), Battery: \(batteryHoursRemaining)h")
        
        // In a real implementation, you would:
        // let server = CLKComplicationServer.sharedInstance()
        // server.reloadTimeline(for: complication)
    }
    
}
