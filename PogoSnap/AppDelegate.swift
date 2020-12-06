//
//  AppDelegate.swift
//  PogoTrade
//
//  Created by Brandon Nguyen on 11/14/20.
//

import UIKit
import OAuthSwift

//class Application {
//    static var shared: UIApplication {
//        let sharedSelector = NSSelectorFromString("sharedApplication")
//        guard UIApplication.responds(to: sharedSelector) else {
//            fatalError("[Extensions cannot access Application]")
//        }
//
//        let shared = UIApplication.perform(sharedSelector)
//        return shared?.takeUnretainedValue() as! UIApplication
//    }
//
//    func applicationHandle(url: URL) {
//        if (url.host == "response") {
//            OAuthSwift.handle(url: url)
//        } else {
//            // Google provider is the only one with your.bundle.id url schema.
//            OAuthSwift.handle(url: url)
//        }
//    }
//}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    class var sharedInstance: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.host == "response" {
            OAuthSwift.handle(url: url)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: handle callback url
extension AppDelegate {
    
    func applicationHandle(url: URL) {
        if (url.host == "response") {
            OAuthSwift.handle(url: url)
        } else {
            // Google provider is the only one with your.bundle.id url schema.
            OAuthSwift.handle(url: url)
        }
    }
}

