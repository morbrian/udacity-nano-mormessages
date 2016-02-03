//
//  AppDelegate.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // TODO: I think this is adding the cert correctly.
        // but I need to learn how to add the trusts on it.
        trustServerCert()
        
        return true
    }
    
    private func trustServerCert() {
        // want to trust my own server
        // tips from stackoverflow:
        // http://stackoverflow.com/questions/5323686/ios-pre-install-ssl-certificate-in-keychain-programmatically
        if let asset = NSDataAsset(name: "servercert"),
            certificate = SecCertificateCreateWithData(nil, asset.data) {
                let dictionary: [NSObject:AnyObject] = [kSecClass:kSecClassCertificate, kSecValueRef:certificate]
                let statusAdd: OSStatus = SecItemAdd(dictionary, nil)
                if statusAdd == noErr {
                    Logger.info("trusting own servercert")
                } else {
                    Logger.error("failed to trust cert: \(statusAdd.description)")
                }
        }
    }

}

