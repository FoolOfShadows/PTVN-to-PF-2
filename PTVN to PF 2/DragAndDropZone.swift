//
//  DragAndDropZone.swift
//  PTVN to PF
//
//  Created by Fool on 12/16/15.
//  Copyright © 2015 Fulgent Wake. All rights reserved.
//

import Cocoa

class DragAndDropZone: NSView {
	//Set the file types the zone will accept
	let fileTypes = ["txt", "md"]
	var fileTypeIsGood = false
	
	//Create a notification center instance to send messages to the default NC
	let nc = NotificationCenter.default
	
	//Required initializer for the frame
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		commonInit()
	}
	
	//Define the appearance of the zone
	override func draw(_ dirtyRect: NSRect) {
		let bPath:NSBezierPath = NSBezierPath(rect: dirtyRect)
		let fillColor = NSColor.lightGray
		fillColor.set()
		bPath.fill()
		
		let borderColor = NSColor.lightGray
		borderColor.set()
		bPath.lineWidth = 1.0
		bPath.stroke()
	}
	
	//Not sure wht this is, but it seems to be required
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	//Set up the initialization parameters for the types of objects the zone will accept
	func commonInit() {
		self.register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType])
	}
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if checkExtension(sender) == true {
			self.fileTypeIsGood = true
			return .copy
		} else {
			self.fileTypeIsGood = false
			return []
		}
	}
	
	//Do I need this.  It doesn't seem to be doing much of anything
	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		return true
	}
	
	override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
		if self.fileTypeIsGood {
			return .copy
		} else {
			return []
		}
	}
	
	//Checks the extension of the dropped file against the list of acceptable file types
	func checkExtension(_ drag: NSDraggingInfo) -> Bool {
		if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray, let path = board[0] as? String {
			let url = NSURL(fileURLWithPath: path)
			if let fileExtension = url.pathExtension?.lowercased() {
				return fileTypes.contains(fileExtension)
			}
			//if let suffix = url.pathExtension {
//				for ext in self.fileTypes {
//					if ext.lowercased() == url.pathExtension/*suffix*/ {
//						return true
//					}
//				}
			//}
		}
		return false
	}
	
	//Respond to the drop
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		guard let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray else { return false }
		if let theFilePath = board[0] as? String {
			//Update the filePath static var in the struct with the new value
			ImportedDocumentData.filePath = theFilePath
			//Message the default notification center about the update
			nc.post(name: Notification.Name("DragAndDropUpdated"), object: nil)
		}
		
		return true
	}
	
}
