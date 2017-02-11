//
//  AppDelegate.swift
//  HomeWork
//
//  Created by Robert on 1/2/17.
//  Copyright © 2017 Robert. All rights reserved.
//

import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Configure Admods
        GADMobileAds.configure(withApplicationID: "ca-app-pub-1414338236854162~7149835131")
        
        VungleSDK.shared().start(withAppId: "589e83e1ad2b403705000196");
        
        return true
    }
    
}

