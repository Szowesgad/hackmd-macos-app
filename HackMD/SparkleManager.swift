//
//  SparkleManager.swift
//  HackMD
//
//  Created on 2025-03-19.
//

import Cocoa

class SparkleManager {
    static let shared = SparkleManager()
    
    // Używamy lazy, aby umożliwić import Sparkle w przyszłości, gdy zostanie dodany do projektu
    private lazy var updater: Any? = {
        // Dynamiczne załadowanie Sparkle, aby uniknąć błędów kompilacji gdy brakuje frameworka
        // Docelowo zastąpić to przez:
        // updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        let bundleID = "org.sparkle-project.Sparkle"
        guard let bundle = Bundle(identifier: bundleID) else {
            print("[SparkleManager] Could not find Sparkle bundle")
            return nil
        }
        
        // Dynamicznie załaduj klasę SPUStandardUpdaterController
        let className = "SPUStandardUpdaterController"
        guard let updaterClass = bundle.classNamed(className) as? NSObject.Type else {
            print("[SparkleManager] Could not load class \(className)")
            return nil
        }
        
        // Utwórz instancję klasy
        let selector = NSSelectorFromString("initWithStartingUpdater:updaterDelegate:userDriverDelegate:")
        let instance = updaterClass.alloc()
        
        let method = unsafeBitCast(
            class_getInstanceMethod(updaterClass, selector),
            to: (@convention(c) (Any, Selector, Bool, Any?, Any?) -> Any).self
        )
        return method(instance, selector, true, nil, nil)
    }()
    
    private init() {
        // Prywatny inicjalizator dla singletona
    }
    
    func checkForUpdatesInBackground() {
        // Dynamicznie wywołaj sprawdzanie aktualizacji
        if let updater = updater {
            let selector = NSSelectorFromString("checkForUpdatesInBackground")
            if updater.responds(to: selector) {
                updater.perform(selector)
            }
        }
    }
    
    func checkForUpdates() {
        // Dynamicznie wywołaj sprawdzanie aktualizacji z interfejsem użytkownika
        if let updater = updater {
            let selector = NSSelectorFromString("checkForUpdates:")
            if updater.responds(to: selector) {
                updater.perform(selector, with: nil)
            }
        }
    }
}