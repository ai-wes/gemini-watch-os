import Foundation
import CloudKit

/// `CloudSyncCoordinator` manages the synchronization of data between the watchOS app and CloudKit.
/// This includes user preferences, notification metadata (if allowed and configured),
/// and potentially learned patterns from the AI engines to be shared with the iOS companion app.
class CloudSyncCoordinator {

    // MARK: - Properties
    
    private let container: CKContainer?
    private let privateDB: CKDatabase?
    private let isPreviewMode: Bool
    // private let sharedDB: CKDatabase // If using shared data with other iCloud users

    // Define record types (these should match your CloudKit schema)
    static let recordTypeUserPreference = "UserPreference"
    static let recordTypeNotificationEvent = "NotificationEventMetadata" // Example for syncing metadata
    static let recordTypeBatterySnapshot = "BatterySnapshotSummary" // Example for syncing aggregated data

    // MARK: - Initialization
    
    init(containerIdentifier: String? = nil, forPreview: Bool = false) {
        // Skip CloudKit initialization during SwiftUI previews
        #if DEBUG
        let envIsPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        self.isPreviewMode = forPreview || envIsPreview
        #else
        self.isPreviewMode = false // For release builds, never treat as preview.
                                   // Consider if `forPreview` should have any effect here,
                                   // but typically, release builds aren't for previews.
                                   // For safety, keeping it false.
        #endif
        
        if isPreviewMode {
            // Don't initialize CloudKit during previews
            self.container = nil
            self.privateDB = nil
            print("CloudSyncCoordinator initialized in preview mode - CloudKit disabled")
            return
        }
        
        if let identifier = containerIdentifier {
            self.container = CKContainer(identifier: identifier)
        } else {
            self.container = CKContainer.default()
        }
        self.privateDB = container?.privateCloudDatabase
        // self.sharedDB = container.sharedCloudDatabase
        
        print("CloudSyncCoordinator initialized with container: \(self.container?.containerIdentifier ?? "default")")
        checkAccountStatus()
    }

    // MARK: - Account Status
    
    func checkAccountStatus(completion: ((CKAccountStatus, Error?) -> Void)? = nil) {
        guard !isPreviewMode, let container = container else {
            completion?(.available, nil)
            return
        }
        
        container.accountStatus { status, error in
            if let error = error {
                print("CloudKit account status error: \(error.localizedDescription)")
            } else {
                switch status {
                case .available:
                    print("CloudKit account is available.")
                case .noAccount:
                    print("No CloudKit account configured on this device.")
                case .restricted:
                    print("CloudKit account is restricted (e.g., parental controls).")
                case .couldNotDetermine:
                    print("Could not determine CloudKit account status.")
                case .temporarilyUnavailable:
                    print("CloudKit account is temporarily unavailable.")
                @unknown default:
                    print("Unknown CloudKit account status.")
                }
            }
            completion?(status, error)
        }
    }

    // MARK: - Data Upload (Examples)

    /// Saves a `UserPreference` to CloudKit.
    func saveUserPreference(_ preference: UserPreference, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        guard !isPreviewMode, let privateDB = privateDB else {
            let recordID = CKRecord.ID(recordName: preference.key)
            let record = CKRecord(recordType: CloudSyncCoordinator.recordTypeUserPreference, recordID: recordID)
            completion(.success(record))
            return
        }
        let recordID = CKRecord.ID(recordName: preference.key) // Use preference.key as a unique ID
        let record = CKRecord(recordType: CloudSyncCoordinator.recordTypeUserPreference, recordID: recordID)
        record["value"] = preference.value as CKRecordValue
        // Add other fields from UserPreference if necessary
        
        privateDB.save(record) { savedRecord, error in
            if let error = error {
                print("Error saving UserPreference to CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                print("UserPreference '\(preference.key)' saved to CloudKit.")
                completion(.success(savedRecord))
            }
        }
    }
    
    // TODO: Implement methods to save NotificationEvent metadata, BatterySnapshot summaries, etc.
    // Be mindful of privacy and data volume. For NotificationEvent, only sync non-sensitive metadata
    // or aggregated/anonymized data. For BatterySnapshot, sync summaries or key drain events.

    // MARK: - Data Fetch (Examples)

    /// Fetches a `UserPreference` from CloudKit.
    func fetchUserPreference(key: String, completion: @escaping (Result<UserPreference, Error>) -> Void) {
        guard !isPreviewMode, let privateDB = privateDB else {
            completion(.failure(NSError(domain: "CloudSyncCoordinator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Preview mode - no data available"])))
            return
        }
        
        let recordID = CKRecord.ID(recordName: key)
        privateDB.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Error fetching UserPreference '\(key)' from CloudKit: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let record = record, let value = record["value"] as? Data {
                let preference = UserPreference(key: key, value: value)
                print("UserPreference '\(key)' fetched from CloudKit.")
                completion(.success(preference))
            } else {
                completion(.failure(NSError(domain: "CloudSyncCoordinator", code: 0, userInfo: [NSLocalizedDescriptionKey: "UserPreference not found or data malformed"])))
            }
        }
    }
    
    /// Fetches all `UserPreference` records.
    func fetchAllUserPreferences(completion: @escaping (Result<[UserPreference], Error>) -> Void) {
        guard !isPreviewMode, let privateDB = privateDB else {
            completion(.success([]))
            return
        }
        
        let query = CKQuery(recordType: CloudSyncCoordinator.recordTypeUserPreference, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults
        
        var preferences: [UserPreference] = []
        
        operation.recordMatchedBlock = { recordID, recordResult in
            switch recordResult {
            case .success(let record):
                guard let value = record["value"] as? Data else { return }
                let preference = UserPreference(key: record.recordID.recordName, value: value)
                preferences.append(preference)
            case .failure(let error):
                print("Error fetching individual record \(recordID): \(error.localizedDescription)")
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success:
                print("Fetched \(preferences.count) UserPreferences from CloudKit.")
                completion(.success(preferences))
            case .failure(let error):
                print("Error fetching all UserPreferences: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        privateDB.add(operation)
    }

    // MARK: - Subscriptions (Push Notifications for Changes)

    func subscribeToPreferenceChanges(completion: @escaping (Error?) -> Void) {
        guard !isPreviewMode, let privateDB = privateDB else {
            completion(nil)
            return
        }
        
        let subscriptionID = "user-preferences-changed"
        
        // Check if subscription already exists
        privateDB.fetch(withSubscriptionID: subscriptionID) { [weak self] (subscription, error) in 
            guard let self = self else { return }
            if subscription != nil {
                print("Subscription '\(subscriptionID)' already exists.")
                completion(nil)
                return
            }
            
            // If error is "subscription not found", it's okay, we create a new one.
            // Any other error, report it.
            if let ckError = error as? CKError, ckError.code != .unknownItem {
                 print("Error checking for subscription: \(ckError.localizedDescription)")
                 completion(ckError)
                 return
            }

            let newSubscription = CKQuerySubscription(
                recordType: CloudSyncCoordinator.recordTypeUserPreference,
                predicate: NSPredicate(value: true),
                subscriptionID: subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true // For background updates
            // notificationInfo.alertBody = "Preferences updated" // Optional: for user-visible alerts
            newSubscription.notificationInfo = notificationInfo
            
            guard let privateDB = self.privateDB else { return }
            privateDB.save(newSubscription) { _, error in
                if let error = error {
                    print("Error saving subscription to CloudKit: \(error.localizedDescription)")
                } else {
                    print("Successfully subscribed to UserPreference changes in CloudKit.")
                }
                completion(error)
            }
        }
    }
    
    func unsubscribeFromPreferenceChanges(completion: @escaping (Error?) -> Void) {
        guard !isPreviewMode, let privateDB = privateDB else {
            completion(nil)
            return
        }
        
        let subscriptionID = "user-preferences-changed"
        privateDB.delete(withSubscriptionID: subscriptionID) { (id, error) in 
            if let error = error {
                print("Error deleting subscription: \(error.localizedDescription)")
            } else {
                print("Successfully deleted subscription: \(id ?? "N/A")")
            }
            completion(error)
        }
    }

    // MARK: - Handling Remote Notifications (from AppDelegate or SceneDelegate)
    
    func handleRemoteNotification(userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            print("Received CloudKit Query Notification: \(notification.queryNotificationReason)")
            // TODO: Fetch the changed record(s) based on notification.recordID
            // Example: if notification.recordID != nil {
            //    fetchAndProcessRecord(notification.recordID!)
            // }
            // After processing, call completionHandler with .newData, .noData, or .failed
            completionHandler(true) // Assuming new data was fetched and processed
        } else {
            completionHandler(false)
        }
    }

    // MARK: - Deinitialization
    
    deinit {
        // Clean up any subscriptions or observers if necessary, though CloudKit handles much of this.
        print("CloudSyncCoordinator deinitialized.")
    }
}
