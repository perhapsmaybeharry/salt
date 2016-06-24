//
//  ViewController.swift
//  Salt
//
//  Created by Harry Wang on 13/5/16.
//  Completed Fri 13 May 2016 1157hrs
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa
import IOKit

var action = String(), method = String(), type = String(), file = String(), output = String(), passphrase = String(), generatedhash = "", opensslReturnValue = Int(), taskoutput = String(), errorMessage = String(), errorState = Bool()

// core timer
var coretimer = NSTimer()

let encryptMethods = ["Advanced Encryption Standard (AES)", "Blowfish (BF)", "CAST (CAST)", "Data Encryption Standard (DES)", "Rivest Cipher (RC)"]
let hashMethods = ["Message Digest (MD)", "Modification Detection Code 2 (MDC2)", "RACE Integrity Primitives Evaluation Message Digest (RIPEMD)", "Secure Hash Algorithm (SHA)"]

let aesTypes = ["128-bit AES Cipher Block Chain (AES-128-CBC)", "128-bit AES 128-bit Cipher Feedback (AES-128-CFB)", "128-bit AES 1-bit Cipher Feedback (AES-128-CFB1)", "128-bit AES 8-bit Cipher Feedback (AES-128-CFB8)", "128-bit AES Electronic Checkbook (AES-128-ECB)", "128-bit AES Output Feedback (AES-128-OFB)", "192-bit AES Cipher Block Chain (AES-192-CBC)", "192-bit AES 128-bit Cipher Feedback (AES-192-CFB)", "192-bit AES 1-bit Cipher Feedback (AES-192-CFB1)", "192-bit AES 8-bit Cipher Feedback (AES-192-CFB8)", "192-bit AES Electronic Checkbook (AES-192-ECB)", "192-bit AES Output Feedback (AES-192-OFB)", "256-bit AES Cipher Block Chain (AES-256-CBC)", "256-bit AES 128-bit Cipher Feedback (AES-256-CFB)", "256-bit AES 1-bit Cipher Feedback (AES-256-CFB1)", "256-bit AES 8-bit Cipher Feedback (AES-256-CFB8)", "256-bit AES Electronic Checkbook (AES-256-ECB)", "256-bit AES Output Feedback (AES-256-OFB)", ]
let bfTypes = ["BF Cipher Block Chain (BF-CBC)", "BF Cipher Feedback (BF-CFB)", "BF Electronic Checkbook (BF-ECB)", "BF Output Feedback (BF-OFB)"]
let castTypes = ["CAST Cipher Block Chain (CAST-CBC)", "CAST5 Cipher Block Chain (CAST5-CBC)", "CAST5 Cipher Feedback (CAST5-CFB)", "CAST5 Electronic Checkbook (CAST5-ECB)", "CAST5 Output Feedback (CAST5-OFB)"]
let desTypes = ["DES Cipher Block Chain (DES-CBC)", "DES Cipher Feedback (DES-CFB)", "DES Output Feedback (DES-OFB)", "DES Electronic Checkbook (DES-ECB)", "Two-key DES3 Encrypt-Decrypt-Encrypt Cipher Block Chain (DES-EDE-CBC)", "Two-key DES3 Encrypt-Decrypt-Encrypt Electronic Checkbook (DES-EDE)", "Two-key DES3 Encrypt-Decrypt-Encrypt Cipher Feedback (DES-EDE-CFB)", "Two-key DES3 Encrypt-Decrypt-Encrypt Output Feedback (DES-EDE-OFB)", "Three-key DES3 Encrypt-Decrypt-Encrypt Cipher Block Chain (DES-EDE3-CBC)", "Three-key DES3 Encrypt-Decrypt-Encrypt Electronic Checkbook (DES-EDE3)", "Three-key DES3 Encrypt-Decrypt-Encrypt Cipher Feedback (DES-EDE3-CFB)", "Three-key DES3 Encrypt-Decrypt-Encrypt Output Feedback (DES-EDE3-OFB)", "DESX Algorithm (DESX)"]
let rcTypes = ["40-bit RC2 Cipher Block Chain (RC2-40-CBC)", "64-bit RC2 Cipher Block Chain (RC2-64-CBC)", "128-bit RC2 Cipher Block Chain (RC2-CBC)", "128-bit RC2 Cipher Feedback (RC2-CFB)", "128-bit RC2 Electronic Checkbook (RC2-ECB)", "128-bit RC2 Output Feedback (RC2-OFB)", "128-bit RC4 (RC4)", "40-bit RC4 (RC4-40)"]

let mdTypes = [/*"Message Digest 2 (MD2)", */"Message Digest 4 (MD4)", "Message Digest 5 (MD5)"]
let mdc2Types = ["Modification Detection Code 2 (MDC2)"]
let ripemdTypes = ["160-bit RACE Integrity Primitives Evaluation Message Digest (RIPEMD160)"]
let shaTypes = ["SHA-0 (SHA)", "SHA1 (SHA1)", "224-bit SHA2 (SHA-224)", "256-bit SHA2 (SHA-256)", "384-bit SHA2 (SHA-384)", "512-bit SHA2 (SHA-512)"]

class ViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// energy efficiency measures that notify when the application loses/gains focus
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pauseTimer), name: NSApplicationDidResignActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(startTimer), name: NSApplicationDidBecomeActiveNotification, object: nil)
		
		// key view loop
		pathOutlet.nextKeyView = browsePathButton
		browsePathButton.nextKeyView = outputOutlet
		outputOutlet.nextKeyView = browseOutletButton
	}
	// energy efficiency = pauses timer when app is not in focus
	func pauseTimer() {coretimer.invalidate()}
	func startTimer() {coretimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)}
	
	func timerTick() {
		discernMethod()
		discernType()
		
		if errorState {displayErrorInSummaryField()} else {updateSummaryField()}
		
		var isDir : ObjCBool = false
		var denialreason = String()
		
		// NICE
		if action == "" {denialreason = "No action specified"}
		else if pathOutlet.stringValue == "" {denialreason = "No input specified"}
		else if pathOutlet.stringValue.containsString("~") || outputOutlet.stringValue.containsString("~") {denialreason = "Relative paths not permitted"}
		else if !NSFileManager().fileExistsAtPath(pathOutlet.stringValue) {denialreason = "Input file does not exist"}
		else if action != "hash" && outputOutlet.stringValue == "" {denialreason = "No output specified"}
		else if action != "hash" && pathOutlet.stringValue == outputOutlet.stringValue {denialreason = "Output file cannot be the same as input"}
		else if NSFileManager().fileExistsAtPath(outputOutlet.stringValue) {denialreason = "Output file already exists"}
		else if action != "hash" && passphraseOutlet.stringValue == "" {denialreason = "No passphrase specified"}
		else if NSFileManager().fileExistsAtPath(pathOutlet.stringValue, isDirectory: &isDir) {
			if isDir {denialreason = "Operations cannot be performed on directories"}
		}
		else {denialreason = ""}
		
		// print(denialreason)  // SPAMS THE LOGS EVERY 0.1 SECONDS. USE ONLY FOR DEBUGGING!
		
		if denialreason != "" {initiateButtonOutlet.title = denialreason; initiateButtonOutlet.enabled = false}
		else {initiateButtonOutlet.title = "Initiate"; initiateButtonOutlet.enabled = true}
		
		// CLUNKY
//		if pathOutlet.stringValue != "" && outputOutlet.stringValue != "" && passphraseOutlet.stringValue != "" && pathOutlet.stringValue != outputOutlet.stringValue && NSFileManager().fileExistsAtPath(pathOutlet.stringValue, isDirectory: &alwaysfalseobjcbool) && !NSFileManager().fileExistsAtPath(outputOutlet.stringValue) {
//			
//			initiateButtonOutlet.enabled = true
//		} else if action == "hash" && pathOutlet.stringValue != "" && NSFileManager().fileExistsAtPath(pathOutlet.stringValue, isDirectory: &alwaysfalseobjcbool) {initiateButtonOutlet.enabled = true}
//		else {initiateButtonOutlet.enabled = false}
	}
	
	func displayErrorInSummaryField() {
		summaryField.stringValue = errorMessage
	}
	func updateSummaryField() {
		summaryField.stringValue = "Action: \(action)\nMethod: \(method)\nType: \(type)\nInput: \(pathOutlet.stringValue)"
		if action == "encrypt" || action == "decrypt" {summaryField.stringValue.appendContentsOf("\nOutput: \(outputOutlet.stringValue)\nPassphrase: \(passphraseOutlet.stringValue.characters.count) characters")}
		else if action == "hash" {
			summaryField.stringValue.appendContentsOf("\nHash: \(generatedhash)")
		}
	}
	
	func setupMethodMenu() {
		methodOutlet.removeAllItems()
		if action == "encrypt" || action == "decrypt" {
			methodOutlet.addItemsWithTitles(encryptMethods)
			method = "aes"    // this prevents graphical glitches where the method and type popup menus don't reflect their value
		}
		else {
			methodOutlet.addItemsWithTitles(hashMethods)
			method = "md"    // this prevents graphical glitches where the method and type popup menus don't reflect their value
		}
		methodOutlet.selectItemAtIndex(0)
		setupTypeMenu()
	}
	func setupTypeMenu() {
		typeOutlet.removeAllItems()
		if method == "aes" {typeOutlet.addItemsWithTitles(aesTypes)}
		else if method == "bf" {typeOutlet.addItemsWithTitles(bfTypes)}
		else if method == "cast" {typeOutlet.addItemsWithTitles(castTypes)}
		else if method == "des" {typeOutlet.addItemsWithTitles(desTypes)}
		else if method == "rc" {typeOutlet.addItemsWithTitles(rcTypes)}
		else if method == "md" {typeOutlet.addItemsWithTitles(mdTypes)}
		else if method == "mdc2" {typeOutlet.addItemsWithTitles(mdc2Types)}
		else if method == "ripemd" {typeOutlet.addItemsWithTitles(ripemdTypes)}
		else if method == "sha" {typeOutlet.addItemsWithTitles(shaTypes)}
		typeOutlet.selectItemAtIndex(0)
	}

	func resetFields() {
		pathOutlet.stringValue = ""
		outputOutlet.stringValue = ""
		passphraseOutlet.stringValue = ""
		secretNormalTextField.stringValue = ""
		file = ""
		output = ""
		passphrase = ""
		generatedhash = ""
	}
	
	// step 1: which action?
	@IBOutlet var encryptOutlet: NSButton!
	@IBOutlet var hashOutlet: NSButton!
	@IBOutlet var decryptOutlet: NSButton!
	func discernAction() {
		resetFields()
		if encryptOutlet.state == NSOnState {
			action = "encrypt"
			passphraseLabel.stringValue = "Passphrase"
			outputOutlet.enabled = true
			browseOutletButton.enabled = true
			passphraseOutlet.hidden = false
			secretNormalTextField.hidden = true
		}
		else if hashOutlet.state == NSOnState {
			action = "hash"
			passphraseLabel.stringValue = "Hash"
			outputOutlet.enabled = false
			browseOutletButton.enabled = false
			passphraseOutlet.stringValue = ""
			passphraseOutlet.hidden = true
			secretNormalTextField.hidden = false
		}
		else if decryptOutlet.state == NSOnState {
			action = "decrypt"
			passphraseLabel.stringValue = "Passphrase"
			outputOutlet.enabled = true
			browseOutletButton.enabled = true
			passphraseOutlet.hidden = false
			secretNormalTextField.hidden = true
		}
	}
	@IBAction func didSelectAction(sender: AnyObject) {
		discernAction()
		setupMethodMenu()
	}
	
	// step 2: which method?
	@IBOutlet var methodOutlet: NSPopUpButton!
	func discernMethod() {
		if methodOutlet.titleOfSelectedItem == encryptMethods[0] {method = "aes"}
		else if methodOutlet.titleOfSelectedItem == encryptMethods[1] {method = "bf"}
		else if methodOutlet.titleOfSelectedItem == encryptMethods[2] {method = "cast"}
		else if methodOutlet.titleOfSelectedItem == encryptMethods[3] {method = "des"}
		else if methodOutlet.titleOfSelectedItem == encryptMethods[4] {method = "rc"}
		else if methodOutlet.titleOfSelectedItem == hashMethods[0] {method = "md"}
		else if methodOutlet.titleOfSelectedItem == hashMethods[1] {method = "mdc2"}
		else if methodOutlet.titleOfSelectedItem == hashMethods[2] {method = "ripemd"}
		else if methodOutlet.titleOfSelectedItem == hashMethods[3] {method = "sha"}
	}
	@IBAction func didSelectMethod(sender: AnyObject) {
		discernMethod()
		setupTypeMenu()
	}
	
	// step 3: which type?
	@IBOutlet var typeOutlet: NSPopUpButton!
	func discernType() {
		if typeOutlet.titleOfSelectedItem == aesTypes[0] {type = "aes-128-cbc"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[1] {type = "aes-128-cfb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[2] {type = "aes-128-cfb1"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[3] {type = "aes-128-cfb8"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[4] {type = "aes-128-ecb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[5] {type = "aes-128-ofb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[6] {type = "aes-192-cbc"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[7] {type = "aes-192-cfb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[8] {type = "aes-192-cfb1"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[9] {type = "aes-192-cfb8"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[10] {type = "aes-192-ecb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[11] {type = "aes-192-ofb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[12] {type = "aes-256-cbc"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[13] {type = "aes-256-cfb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[14] {type = "aes-256-cfb1"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[15] {type = "aes-256-cfb8"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[16] {type = "aes-256-ecb"}
		else if typeOutlet.titleOfSelectedItem == aesTypes[17] {type = "aes-256-ofb"}
		else if typeOutlet.titleOfSelectedItem == bfTypes[0] {type = "bf-cbc"}
		else if typeOutlet.titleOfSelectedItem == bfTypes[1] {type = "bf-cfb"}
		else if typeOutlet.titleOfSelectedItem == bfTypes[2] {type = "bf-ecb"}
		else if typeOutlet.titleOfSelectedItem == bfTypes[3] {type = "bf-ofb"}
		else if typeOutlet.titleOfSelectedItem == castTypes[0] {type = "cast-cbc"}
		else if typeOutlet.titleOfSelectedItem == castTypes[1] {type = "cast5-cbc"}
		else if typeOutlet.titleOfSelectedItem == castTypes[2] {type = "cast5-cfb"}
		else if typeOutlet.titleOfSelectedItem == castTypes[3] {type = "cast5-ecb"}
		else if typeOutlet.titleOfSelectedItem == castTypes[4] {type = "cast5-ofb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[0] {type = "des-cbc"}
		else if typeOutlet.titleOfSelectedItem == desTypes[1] {type = "des-cfb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[2] {type = "des-ofb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[3] {type = "des-ecb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[4] {type = "des-ede-cbc"}
		else if typeOutlet.titleOfSelectedItem == desTypes[5] {type = "des-ede"}
		else if typeOutlet.titleOfSelectedItem == desTypes[6] {type = "des-ede-cfb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[7] {type = "des-ede-ofb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[8] {type = "des-ede3-cbc"}
		else if typeOutlet.titleOfSelectedItem == desTypes[9] {type = "des-ede3"}
		else if typeOutlet.titleOfSelectedItem == desTypes[10] {type = "des-ede3-cfb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[11] {type = "des-ede3-ofb"}
		else if typeOutlet.titleOfSelectedItem == desTypes[12] {type = "desx"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[0] {type = "rc2-40-cbc"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[1] {type = "rc2-64-cbc"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[2] {type = "rc2-cbc"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[3] {type = "rc2-cfb"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[4] {type = "rc2-ecb"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[5] {type = "rc2-ofb"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[6] {type = "rc4"}
		else if typeOutlet.titleOfSelectedItem == rcTypes[7] {type = "rc4-40"}
//		else if typeOutlet.titleOfSelectedItem == mdTypes[0] {type = "md2"}
		else if typeOutlet.titleOfSelectedItem == mdTypes[0] {type = "md4"}
		else if typeOutlet.titleOfSelectedItem == mdTypes[1] {type = "md5"}
		else if typeOutlet.titleOfSelectedItem == mdc2Types[0] {type = "mdc2"}
		else if typeOutlet.titleOfSelectedItem == ripemdTypes[0] {type = "ripemd160"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[0] {type = "sha"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[1] {type = "sha1"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[2] {type = "sha224"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[3] {type = "sha256"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[4] {type = "sha384"}
		else if typeOutlet.titleOfSelectedItem == shaTypes[5] {type = "sha512"}
	}
	@IBAction func didSelectType(sender: AnyObject) {
		discernType()
	}
	
	// step 4: which files?
	@IBOutlet var pathOutlet: NSTextField!
	@IBOutlet var browsePathButton: NSButton!
	@IBAction func didClickBrowse(sender: AnyObject) {
		let panel = NSOpenPanel()
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = false
		panel.canCreateDirectories = false
		panel.canChooseFiles = true
		panel.directoryURL = NSURL(fileURLWithPath: ("~" as NSString).stringByExpandingTildeInPath)
		panel.beginWithCompletionHandler { (result) -> Void in
			if result == NSFileHandlingPanelOKButton {
				self.pathOutlet.stringValue = (panel.URL?.absoluteString)!.stringByReplacingOccurrencesOfString("file://", withString: "")
				file = self.pathOutlet.stringValue
			}
		}
	}
	@IBOutlet var outputOutlet: NSTextField!
	@IBOutlet var browseOutletButton: NSButton!
	@IBAction func didClickOutputBrowse(sender: AnyObject) {
		let panel = NSSavePanel()
		panel.canCreateDirectories = true
		panel.directoryURL = NSURL(fileURLWithPath: ("~" as NSString).stringByExpandingTildeInPath)
		panel.beginWithCompletionHandler { (result) -> Void in
			if result == NSFileHandlingPanelOKButton {
				self.outputOutlet.stringValue = (panel.URL?.absoluteString)!.stringByReplacingOccurrencesOfString("file://", withString: "")
				output = self.outputOutlet.stringValue
			}
		}
	}
	
	// step 5: passphrase?
	@IBOutlet var passphraseLabel: NSTextField!
	@IBOutlet var passphraseOutlet: NSSecureTextField!
	@IBAction func didSelectPassphrase(sender: AnyObject) {
		passphrase = passphraseOutlet.stringValue
	}
	
	// step 6: summary
	@IBOutlet var summaryField: NSTextField!
	
	// step 7: initiate
	@IBOutlet var initiateButtonOutlet: NSButton!
	@IBAction func didPressInitiate(sender: AnyObject) {
		
		pauseTimer()
		
		print(summaryField.stringValue)
		file = pathOutlet.stringValue
		output = outputOutlet.stringValue
		passphrase = passphraseOutlet.stringValue
		
		initiateButtonOutlet.enabled = false
		if action != "hash" {
			initiateButtonOutlet.title = (action == "encrypt" ? "Encrypting" : "Decrypting")
		} else {initiateButtonOutlet.title = "Hashing"}
		initiateButtonOutlet.title = initiateButtonOutlet.title.stringByAppendingString(" \"\((file as NSString).lastPathComponent)\"...")
		
		if errorState {errorState = false}
		
		let taskstdout = NSPipe()
		
		let task = NSTask()
		task.launchPath = "/bin/bash"
		task.arguments = ["-c", "\(synthesiseCommand())"]
		task.standardOutput = taskstdout
		task.standardError = taskstdout
		task.launch()
		
		task.waitUntilExit()
		
		// gets output of task
		let taskprocessoutput = taskstdout.fileHandleForReading.readDataToEndOfFile()
		if let string = String.fromCString(UnsafePointer(taskprocessoutput.bytes)) {
			taskoutput = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
		}
		print(taskoutput)
		
		// error handling
		opensslReturnValue = Int(task.terminationStatus)
		if opensslReturnValue > 0 {
			print("\nreturned \(opensslReturnValue)")
			if taskoutput.containsString("bad decrypt") && action == "decrypt" {
				errorMessage = "Invalid password or cipher mismatch"
				print(errorMessage)
			}
			else {errorMessage = "An unknown error occurred"; print(errorMessage)}
			do{try NSFileManager().removeItemAtPath(output)} catch let err as NSError {print(err.localizedDescription)}
			errorState = true
		}
		
		if action == "hash" && !errorState {
			generatedhash = taskoutput.componentsSeparatedByString(" ").last!
			print("Hash: \(generatedhash)")
			secretNormalTextField.stringValue = generatedhash
		}
		
		startTimer()
		
		initiateButtonOutlet.enabled = true
		initiateButtonOutlet.title = "Initiate"
		
	}
	@IBOutlet var secretNormalTextField: NSTextField!
	
	func synthesiseCommand() -> String {
		var command = NSBundle.mainBundle().pathForResource("openssl", ofType: "")!
		command.appendContentsOf(" ")
		
		// decide action
		if action == "encrypt" {command.appendContentsOf("enc -e ")}
		else if action == "decrypt" {command.appendContentsOf("enc -d ")}
		else if action == "hash" {command.appendContentsOf("dgst ")}
		
		// add type
		command.appendContentsOf("-\(type) ")
		
		// file and stuff
		if action == "encrypt" {command.appendContentsOf("-in '\(file)' -out '\(output)' -pass pass:'\(passphrase)'")}
		else if action == "decrypt" {command.appendContentsOf("-in '\(file)' -out '\(output)' -pass pass:'\(passphrase)'")}
		else if action == "hash" {command.appendContentsOf("'\(file)'")}
		
		print("Synthesised command: \(command)")
		return command
	}
}

