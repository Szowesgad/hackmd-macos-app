//
//  NotificationManager.swift
//  HackMD
//
//  Created on March 19, 2025
//

import Cocoa
import UserNotifications

/**
 * NotificationManager handles all system notifications for the HackMD app.
 * It provides methods to request permissions and send various types of notifications.
 */
class NotificationManager {
    
    // MARK: - Singleton instance
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    
    // Notification category identifiers
    enum Category: String {
        case noteUpdate = "NOTE_UPDATE"
        case collaboration = "COLLABORATION"
        case reminder = "REMINDER"
        case mention = "MENTION"
        case comment = "COMMENT"
    }
    
    // Notification types for analytics and settings
    enum NotificationType: String, CaseIterable {
        case noteUpdate = "Note Updates"
        case collaboration = "Collaboration Invites"
        case comment = "Comments" 
        case mention = "Mentions"
        case reminder = "Reminders"
        
        var isEnabled: Bool {
            get {
                return UserDefaults.standard.bool(forKey: "notification_\(self.rawValue)")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "notification_\(self.rawValue)")
            }
        }
        
        var category: Category {
            switch self {
            case .noteUpdate: return .noteUpdate
            case .collaboration: return .collaboration
            case .comment: return .comment
            case .mention: return .mention
            case .reminder: return .reminder
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /**
     * Requests notification permissions from the user if not already granted
     */
    func requestPermissionsIfNeeded(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                self.requestPermissions(completion: completion)
            } else {
                self.isAuthorized = true
                completion(true)
            }
        }
    }
    
    /**
     * Sends a notification about note updates
     */
    func sendNoteUpdateNotification(title: String, note: String, noteId: String) {
        guard isAuthorized && NotificationType.noteUpdate.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = note
        content.sound = .default
        content.categoryIdentifier = Category.noteUpdate.rawValue
        
        // Add note ID as user info
        content.userInfo = ["noteId": noteId]
        
        // Create a request with an immediate trigger
        let request = UNNotificationRequest(
            identifier: "noteUpdate-\(noteId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        // Add the request to the notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending note update notification: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Sends a notification about collaboration events
     */
    func sendCollaborationNotification(title: String, message: String, collaborator: String, noteId: String) {
        guard isAuthorized && NotificationType.collaboration.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.collaboration.rawValue
        
        // Add user info
        content.userInfo = [
            "noteId": noteId,
            "collaborator": collaborator
        ]
        
        // Create a request with an immediate trigger
        let request = UNNotificationRequest(
            identifier: "collaboration-\(noteId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        // Add the request to the notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending collaboration notification: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Sends a notification about mentions
     */
    func sendMentionNotification(title: String, message: String, fromUser: String, noteId: String) {
        guard isAuthorized && NotificationType.mention.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.mention.rawValue
        
        // Add user info
        content.userInfo = [
            "noteId": noteId,
            "fromUser": fromUser
        ]
        
        // Create a request with an immediate trigger
        let request = UNNotificationRequest(
            identifier: "mention-\(noteId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        // Add the request to the notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending mention notification: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Sends a notification about comments
     */
    func sendCommentNotification(title: String, message: String, fromUser: String, noteId: String, commentId: String) {
        guard isAuthorized && NotificationType.comment.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.comment.rawValue
        
        // Add user info
        content.userInfo = [
            "noteId": noteId,
            "fromUser": fromUser,
            "commentId": commentId
        ]
        
        // Create a request with an immediate trigger
        let request = UNNotificationRequest(
            identifier: "comment-\(noteId)-\(commentId)",
            content: content,
            trigger: nil
        )
        
        // Add the request to the notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending comment notification: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Schedules a reminder notification
     */
    func scheduleReminderNotification(title: String, message: String, date: Date, noteId: String?) {
        guard isAuthorized && NotificationType.reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Category.reminder.rawValue
        
        // Add note ID to user info if available
        if let noteId = noteId {
            content.userInfo = ["noteId": noteId]
        }
        
        // Create date components for the trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        
        // Create a trigger using the date components
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create the request
        let requestIdentifier = "reminder-\(noteId ?? "general")-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling reminder notification: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Cancels all pending notifications
     */
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /**
     * Cancels specific pending notifications
     */
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Private Methods
    
    /**
     * Sets up notification categories and actions
     */
    private func setupNotificationCategories() {
        // Note update category actions
        let viewNoteAction = UNNotificationAction(
            identifier: "VIEW_NOTE",
            title: "View Note",
            options: .foreground
        )
        
        let noteUpdateCategory = UNNotificationCategory(
            identifier: Category.noteUpdate.rawValue,
            actions: [viewNoteAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Collaboration category actions
        let viewCollaborationAction = UNNotificationAction(
            identifier: "VIEW_COLLABORATION",
            title: "View Changes",
            options: .foreground
        )
        
        let collaborationCategory = UNNotificationCategory(
            identifier: Category.collaboration.rawValue,
            actions: [viewCollaborationAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Reminder category actions
        let openReminderAction = UNNotificationAction(
            identifier: "OPEN_REMINDER",
            title: "Open",
            options: .foreground
        )
        
        let dismissReminderAction = UNNotificationAction(
            identifier: "DISMISS_REMINDER",
            title: "Dismiss",
            options: .destructive
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: Category.reminder.rawValue,
            actions: [openReminderAction, dismissReminderAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Mention category actions
        let viewMentionAction = UNNotificationAction(
            identifier: "VIEW_MENTION",
            title: "View Mention",
            options: .foreground
        )
        
        let replyMentionAction = UNNotificationAction(
            identifier: "REPLY_MENTION",
            title: "Reply",
            options: [.foreground, .authenticationRequired]
        )
        
        let mentionCategory = UNNotificationCategory(
            identifier: Category.mention.rawValue,
            actions: [viewMentionAction, replyMentionAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Comment category actions
        let viewCommentAction = UNNotificationAction(
            identifier: "VIEW_COMMENT",
            title: "View Comment",
            options: .foreground
        )
        
        let replyCommentAction = UNNotificationAction(
            identifier: "REPLY_COMMENT",
            title: "Reply",
            options: [.foreground, .authenticationRequired]
        )
        
        let commentCategory = UNNotificationCategory(
            identifier: Category.comment.rawValue,
            actions: [viewCommentAction, replyCommentAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the notification categories
        notificationCenter.setNotificationCategories([
            noteUpdateCategory,
            collaborationCategory,
            reminderCategory,
            mentionCategory,
            commentCategory
        ])
    }
    
    /**
     * Checks the current authorization status for notifications
     */
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /**
     * Requests notification permissions from the user
     */
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
                
                if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }
            }
        }
    }
}
