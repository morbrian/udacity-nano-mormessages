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

        // this is not working yet in testing do to a variety of ATS restrictions,
        // raning from IP addresses not allowed any more to self signed certs not allowed.
        //
        // trustServerCert()
        
        return true
    }
    
    private func trustServerCert() -> Bool {
        // want to trust my own server
        // tips from stackoverflow:
        // http://stackoverflow.com/questions/5323686/ios-pre-install-ssl-certificate-in-keychain-programmatically
        
        // TODO: after doing this, still wasn't able to connect to my server.
        
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
        return false
    }

}

