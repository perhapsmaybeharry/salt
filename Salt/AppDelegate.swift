//
//  AppDelegate.swift
//  Salt
//
//  Created by Harry Wang on 13/5/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	// casually increments the build count
	func incrementBuildCount() {
		var buildCount = String()
		do {
			buildCount = try String(contentsOfFile: "/Users/Harry/Programs/Swift 2/Salt/Salt/buildcount.txt")
			buildCount = String(Int(buildCount)!+1)
			try buildCount.writeToFile("/Users/Harry/Programs/Swift 2/Salt/Salt/buildcount.txt", atomically: false, encoding: NSUTF8StringEncoding)
			print("Build: \(buildCount)")
			
		} catch let err as NSError {
			print("Could not increment build count")
			print(err.localizedDescription)
		}
	}

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		incrementBuildCount()
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {return true}
}

