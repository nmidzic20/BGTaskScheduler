//
//  BGApp.swift
//  BG
//
//  Created by FOI on 27.11.2022..
//

import SwiftUI
import UIKit
import BackgroundTasks
import Foundation

@main
struct BGApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        print("SceneDelegate is connected")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene)
    {
        print("Entered background")
        scheduleAppRefresh()
        scheduleDatabaseCleaning()
    }
    
    func scheduleDatabaseCleaning()
    {
        let lastCleaned = MockServer.mockServer.lastCleaned
        print(lastCleaned)
        let now = Date()
        let oneMinute = TimeInterval(60)

        guard now > (lastCleaned + oneMinute) else { return }
        
        let request = BGProcessingTaskRequest(identifier: "hr.foi.nmidzic20.BG.clean")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
            let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
            sceneConfig.delegateClass = SceneDelegate.self
            return sceneConfig
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        print("Launched")
                
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "hr.foi.nmidzic20.BG.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "hr.foi.nmidzic20.BG.clean", using: nil) { task in
            self.handleDatabaseCleaning(task: task as! BGProcessingTask)
        }
        return true
    }

    func handleAppRefresh(task: BGAppRefreshTask)
    {
        scheduleAppRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = MockServer.mockServer.generateNewDataOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperation(operation)
    }
    
    func handleDatabaseCleaning(task: BGProcessingTask)
    {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let cleanDatabaseOperation = MockServer.mockServer.cleanDatabaseOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        cleanDatabaseOperation.completionBlock = {
            let success = !cleanDatabaseOperation.isCancelled
            if success {
                MockServer.mockServer.lastCleaned = Date()
            }
            
            task.setTaskCompleted(success: success)
        }
        
        queue.addOperation(cleanDatabaseOperation)
    }
    
}

func scheduleAppRefresh()
{
    let request = BGAppRefreshTaskRequest(identifier: "hr.foi.nmidzic20.BG.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 0)
    
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Could not schedule app refresh: \(error)")
    }
}

