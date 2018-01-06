//
//  ViewController.swift
//  PTVN to PF 2
//
//  Created by Fool on 1/5/17.
//  Copyright © 2017 Fulgent Wake. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
	
	@IBOutlet var mainView: NSView!
	@IBOutlet weak var dragAndDropZone: DragAndDropZone!
	@IBOutlet weak var originLabel: NSTextField!
	@IBOutlet var subjectiveTextView: NSTextView!
	@IBOutlet var assessmentTextView: NSTextView!
	@IBOutlet var planTextView: NSTextView!
	@IBOutlet var objectiveTextView: NSTextView!
	@IBOutlet var pmhTextView: NSTextView!
	@IBOutlet weak var fontSizeLabel: NSTextField!

	var textCleaningData = [String:String]()
	let localDocumentData = ImportedDocumentData()
	
	let basicCleaningDataFile = "\(NSHomeDirectory())/WPCMSharedFiles/WPCM Software Bits/00 CAUTION - Data Files/PTVN2PFCleaningDataBasic.txt"
	let complexCleaningDataFile = ""

	override func viewDidLoad() {
		super.viewDidLoad()
		// Create an instance of the default notification center
		let nc = NotificationCenter.default
		//Add an observer for the messages being sent by the DragAndDropZone class
		nc.addObserver(self, selector: #selector(dragAndDropUpdated), name: Notification.Name("DragAndDropUpdated"), object: nil)
		

		//Set the font attributes for the text fields
		fontSizeLabel.intValue = 18
		setFontSize(size: CGFloat(fontSizeLabel.intValue))

		//Get text cleaning data from document
		fetchCleaningData()
		
	}

	//Process the data and update the UI when the DragAndDropZone messages
	//that its finished receiving a file
	func dragAndDropUpdated() {
		originLabel.stringValue = ImportedDocumentData.fileName!
		let results = localDocumentData.parseTheText()
		
		subjectiveTextView.string = results?.sub
		assessmentTextView.string = results?.ass
		planTextView.string = results?.plan
		pmhTextView.string = results?.pmh
		objectiveTextView.string = results?.obj
	}
	
	func clearForms() {
		//clear all the NSTextFields
		mainView.clearControllers()
		//clear the label
		originLabel.stringValue = "Please choose a file."
	}
	
	@IBAction func takeClear(_ sender: NSButton) {
		clearForms()
	}
	
	@IBAction func takeCopySubjective(_ sender: NSButton) {
		subjectiveTextView.string?.copyToPasteboard()
	}

	@IBAction func takeCopyPMH(_ sender: NSButton) {
		pmhTextView.string?.copyToPasteboard()
	}

	@IBAction func takeCopyObjective(_ sender: NSButton) {
		objectiveTextView.string?.copyToPasteboard()
	}
	
	@IBAction func takeCopyAssessment(_ sender: NSButton) {
		assessmentTextView.string?.copyToPasteboard()
	}
	
	@IBAction func takeCopyPlan(_ sender: NSButton) {
		planTextView.string?.copyToPasteboard()
	}
	
	
	func setFontSize(size: CGFloat) {
		let theUserFont:NSFont = NSFont.systemFont(ofSize: size)
		let fontAttributes = NSDictionary(object: theUserFont, forKey: NSFontAttributeName as NSCopying)
		let textFields = [subjectiveTextView, assessmentTextView, planTextView, pmhTextView, objectiveTextView]
		for field in textFields {
			field?.typingAttributes = fontAttributes as! [String:AnyObject]
		}
	}
	
	@IBAction func increaseFontSize(_ sender: NSButton) {
		if fontSizeLabel.intValue > 0 {
			let textFields = [subjectiveTextView, assessmentTextView, planTextView, pmhTextView, objectiveTextView]
			let newSize = fontSizeLabel.intValue + 1
			
			for field in textFields {
			let temp = field!.string
			field!.string = ""
			setFontSize(size: CGFloat(newSize))
			fontSizeLabel.intValue = newSize
			field!.string = temp
			}
		}
	}
	
	@IBAction func decreaseFontSize(_ sender: NSButton) {
		if fontSizeLabel.intValue > 0 {
			let textFields = [subjectiveTextView, assessmentTextView, planTextView, pmhTextView, objectiveTextView]
			let newSize = fontSizeLabel.intValue - 1
			
			for field in textFields {
				let temp = field!.string
				field!.string = ""
				setFontSize(size: CGFloat(newSize))
				fontSizeLabel.intValue = newSize
				field!.string = temp
			}
		}
	}
	
	@IBAction func selectFile(_ sender: AnyObject) {
		
		//Create a panel for the user to find the file they want to work on
		let panel = NSOpenPanel()
		panel.title = "Choose a PTVN to load."
		panel.showsResizeIndicator = true
		panel.showsHiddenFiles = false
		panel.canChooseDirectories = false
		panel.allowsMultipleSelection = false
		panel.canChooseFiles = true
		panel.allowedFileTypes = ["txt"]

		panel.beginSheetModal(for: self.view.window!, completionHandler: { (returnCode) -> Void in
			if returnCode == NSModalResponseOK {
				//The returned URL array should only have one item in it
				//Grab that item and put it in a variable
				let message = panel.urls[0]
				//Get the name of the file from URL by breaking the URL
				//into path components and grabbing the last item
				//which should be the file name
				if let theReturnedFileName = message.pathComponents.last {
					print(theReturnedFileName)
					self.originLabel.stringValue = theReturnedFileName
					//Set the fileName variable in the the FileInfo object to the chosen file's path as a string
					ImportedDocumentData.filePath = message.path
					
				}
			}
		})
		
	}
	
	@IBAction func processSelectedFile(_ sender: NSButton) {
		dragAndDropUpdated()
	}
	
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	//Make sure to remove the notification center observer to stop possible memory leaks
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}




