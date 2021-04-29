//
//  AppDelegate.swift
//  plistChanger
//
//  Created by 宋佳恒 on 2021/2/25.
//

import Cocoa
import PythonKit
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    override init() {
             // Force the bridging code to load Python 3
             PythonLibrary.useVersion(3)
         }
       
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
    }


}

