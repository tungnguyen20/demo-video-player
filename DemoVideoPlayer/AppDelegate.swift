//
//  AppDelegate.swift
//  DemoVideoPlayer
//
//  Created by Tung on 5/10/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = VideoViewController()
        window?.makeKeyAndVisible()
        return true
    }

}

