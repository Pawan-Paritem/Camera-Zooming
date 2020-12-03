//
//  AppDelegate.swift
//  CameraZooming
//
//  Created by Pawan  on 11/11/2020.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController  = CameraViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}

