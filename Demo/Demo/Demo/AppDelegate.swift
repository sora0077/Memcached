//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2016/01/19.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Cocoa
import Memcached


struct Options: ServerConnectionOption {
    
    var host: String = "localhost"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let pool = ConnectionPool(options: Options())
        let conn = try! pool.connection()
        
        print(conn.ping)
        
        do {
            if let val = try conn.stringForKey("value") {
                print(val)
            } else {
                try conn.set("日本語😬👨‍👩‍👧‍👧", forKey: "value", expire: 60)
                print("failure")
            }
        } catch {
            print(error)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

