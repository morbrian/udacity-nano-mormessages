//
//  AppDelegate.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/17/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreData
import Security

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // TODO: I would still like to get this working.
        // perhaps the right place to call this is not
        // at start up, but maybe during the auth challenge?
        
        // keeping the code for now, but leaving out call to method
        // trustExpectedServerCert()
        
        return true
    }
    
    private func trustExpectedServerCert() {
        // want to trust my own server
        // tips from stackoverflow:
        // http://stackoverflow.com/questions/5323686/ios-pre-install-ssl-certificate-in-keychain-programmatically
        // http://stackoverflow.com/questions/21701224/sectrustevaluate-fails-with-ksectrustresultrecoverabletrustfailure-for-self-sign
        if let asset = NSDataAsset(name: "servercert"),
            certificate = SecCertificateCreateWithData(nil, asset.data) {
                let dictionary: [NSObject:AnyObject] = [kSecClass:kSecClassCertificate, kSecValueRef:certificate]
                let statusAdd: OSStatus = SecItemAdd(dictionary, nil)
                if statusAdd == noErr {
                    Logger.info("initial add of server cert")
                } else {
                    Logger.error("failed to add server cert, but it was probably already added: \(statusAdd.description)")
                }
                trustWithPolicy(
                    [SecPolicyCreateSSL(true, "mormessages.morbrian.com"),
                    SecPolicyCreateBasicX509()],
                    certificate: certificate)
        }
    }
    
    private func trustWithPolicy(policyRef:[SecPolicy], certificate: SecCertificate) {
        var serverTrust: SecTrust?
        let serverTrustRef = withUnsafeMutablePointer(&serverTrust, { $0 })
        let statusTrust = SecTrustCreateWithCertificates(certificate, policyRef, serverTrustRef)
        if statusTrust == noErr {
            Logger.info("we trust it")
        } else {
            Logger.error("we do not trust it: \(statusTrust.description)")
        }
        
        if let serverTrust = serverTrust {
            let certArray = [certificate]
            let statusAnchor = SecTrustSetAnchorCertificates(serverTrust, certArray);
            if statusAnchor == noErr {
                Logger.info("anchor set")
            } else {
                Logger.error("anchor not set")
            }
        }
        
        if let serverTrust = serverTrust {
            var trustResult: SecTrustResultType = SecTrustResultType()
            let trustResultRef = withUnsafeMutablePointer(&trustResult, { $0 })
            let statusResult = SecTrustEvaluate(serverTrust, trustResultRef)
            if statusResult == noErr {
                Logger.info("we were able to evaluate the trust")
            } else {
                Logger.info("we failed to evaluate the trust: \(statusResult.description)")
            }
            
            if kSecTrustResultProceed.toIntMax() == trustResult.toIntMax() || kSecTrustResultUnspecified.toIntMax() == trustResult.toIntMax() {
                Logger.info("The trust we added is trusted")
            } else {
                Logger.error("We do not trust the cert we added")
            }
        }
    }

}

