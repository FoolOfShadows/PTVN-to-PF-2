//
//  Model.swift
//  PTVN to PF 2
//
//  Created by Fool on 1/18/17.
//  Copyright © 2017 Fulgent Wake. All rights reserved.
//

import Cocoa


//I need a struct with static variables to pass data between my objects
struct ImportedDocumentData {
	static var fullText:String?
	static var fileName:String?
	static var filePath:String? {
		didSet {
			if let theFilePath = filePath {
				let pathComponents = URL(fileURLWithPath: theFilePath)
				fileName = pathComponents.deletingPathExtension().lastPathComponent
				do {
					fullText = try String(contentsOfFile: theFilePath, encoding: String.Encoding.utf8)
				} catch {
					print("ImportedDocumentData: Could not import text from file")
				}
			}
		}
	}
	
	
	func parseTheText() -> (sub:String, pmh:String, obj:String, ass:String, plan:String)? {
		//Unwrap the value of the fullText var
		guard let rawText = ImportedDocumentData.fullText else { return nil }
		let fullText = correctMisspelledWordsIn(rawText, using: misspelledWordDict, or: incorrectCharactersDict)
		
		//Break the full text into components
		//SUBJECTIVE
		let cc = fullText.findRegexMatchBetween(Boundaries.ccString.rawValue, and: Boundaries.problemsString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.cc.rawValue) ?? ""
		let problems = fullText.findRegexMatchBetween(Boundaries.problemsString.rawValue, and: Boundaries.subjectiveString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.problems.rawValue) ?? ""
		let subjectiveSub = fullText.findRegexMatchBetween(Boundaries.subjectiveString.rawValue, and: Boundaries.newPMHString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.subjective.rawValue) ?? ""
		var newPMH = ""
		var ros = ""
		if fullText.contains(Boundaries.rosString.rawValue.removeRegexCharactersFromString()) {
			newPMH = fullText.findRegexMatchBetween(Boundaries.newPMHString.rawValue, and: Boundaries.rosString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.newPMH.rawValue) ?? ""
			ros = fullText.findRegexMatchBetween(Boundaries.rosString.rawValue, and: Boundaries.chargeString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.ros.rawValue) ?? ""
		} else {
			newPMH = fullText.findRegexMatchBetween(Boundaries.newPMHString.rawValue, and: Boundaries.chargeString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.newPMH.rawValue) ?? ""
		}
		let medications = fullText.findRegexMatchBetween(Boundaries.medicationString.rawValue, and: Boundaries.allergiesString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.medications.rawValue) ?? ""
		let subjectiveArray = [cc, problems, subjectiveSub, newPMH, ros, medications]
		let finalSubjective = subjectiveArray.filter({ $0 != ""}).joined(separator:"\n\n")
		
		//PMH
		let allergies = fullText.findRegexMatchBetween(Boundaries.allergiesString.rawValue, and: Boundaries.preventiveString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.allergies.rawValue) ?? ""
		let preventive = fullText.findRegexMatchBetween(Boundaries.preventiveString.rawValue, and: Boundaries.pmhString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.preventive.rawValue) ?? ""
		let pmhSub = fullText.findRegexMatchBetween(Boundaries.pmhString.rawValue, and: Boundaries.pshString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.pmh.rawValue) ?? ""
		let psh = fullText.findRegexMatchBetween(Boundaries.pshString.rawValue, and: Boundaries.nutritionString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.psh.rawValue) ?? ""
		let nutrition = fullText.findRegexMatchBetween(Boundaries.nutritionString.rawValue, and: Boundaries.socialString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.nutrition.rawValue) ?? ""
		let social = fullText.findRegexMatchBetween(Boundaries.socialString.rawValue, and: Boundaries.fhhString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.social.rawValue) ?? ""
		let family = fullText.findRegexMatchBetween(Boundaries.fhhString.rawValue, and: Boundaries.diagnosisString.rawValue)?.removeWhiteSpace().prependSectionHeader(SectionHeadings.family.rawValue) ?? ""
		let pmhArray = [allergies, preventive, pmhSub, psh, social, nutrition, family]
		let finalPMH = pmhArray.filter({ $0 != "" }).joined(separator: "\n\n")
		
		//OBJECTIVE
		let objective = fullText.findRegexMatchBetween(Boundaries.objectiveString.rawValue, and: Boundaries.medicationString.rawValue)?.removeWhiteSpace() ?? ""
		
		//ASSESSMENT
		let assessment = fullText.findRegexMatchBetween(Boundaries.chargeString.rawValue, and: Boundaries.planString.rawValue)?.removeWhiteSpace() ?? ""
		
		//PLAN
		let planSub = fullText.findRegexMatchBetween(Boundaries.planString.rawValue, and: Boundaries.rx.rawValue)?.removeWhiteSpace() ?? ""
		let rx = fullText.findRegexMatchBetween(Boundaries.rx.rawValue, and: Boundaries.objectiveString.rawValue)?.removeWhiteSpace() ?? ""
		let planArray = [planSub, rx]
		let finalPlan = planArray.filter({ $0 != "" }).joined(separator: "\n\n")

		//Send the final vars back to the view controller to update the UI
		return (sub:finalSubjective, pmh:finalPMH, obj:objective, ass:assessment, plan:finalPlan)
	}
	
}

func fetchCleaningData() {
	let basicCleaningDataFilePath = "\(NSHomeDirectory())/WPCMSharedFiles/WPCM Software Bits/00 CAUTION - Data Files/PTVN2PFCleaningDataBasic.txt"
	let complexCleaningDataFilePath = "\(NSHomeDirectory())/WPCMSharedFiles/WPCM Software Bits/00 CAUTION - Data Files/PTVN2PFCleaningDataComplex.txt"

	//Set the cleaning dictionaries with the contents of the text files
	//If the text files can't be found, use the hard coded values
	if let misspelled = setCleaningDataFrom(basicCleaningDataFilePath) {
		misspelledWordDict = misspelled
	}
//	if let incorrect = setCleaningDataFrom(complexCleaningDataFilePath) {
//		incorrectCharactersDict = incorrect
//		print(incorrectCharactersDict)
//	}
}

func setCleaningDataFrom(_ filePath:String) -> [String:String]? {
	var rawData = String()
	var returnData = [String:String]()
	
	do {
		rawData = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
	} catch {
		let theAlert = NSAlert()
		theAlert.messageText = "Could not import the cleaning text from file at \(filePath)."
		theAlert.alertStyle = NSAlertStyle.warning
		theAlert.addButton(withTitle: "OK")
		theAlert.runModal()
		return nil
	}
	
	let dataArray = rawData.components(separatedBy: "\n")
	for item in dataArray {
		var itemArray = item.components(separatedBy: ":")
		if itemArray.count < 2 {
			itemArray.insert("", at: 1)
		}
		returnData.updateValue(itemArray[1], forKey: itemArray[0])
	}
	print(returnData)
	print(incorrectCharactersDict)
	return returnData
	
}


func correctMisspelledWordsIn(_ textToClean:String, using words:[String:String], or characters:[String:String]) -> String {
	var correctedText = textToClean
	
	for entry in words {
		let regex = try! NSRegularExpression(pattern: "\\b" + entry.key + "\\b", options: .caseInsensitive)
		correctedText = regex.stringByReplacingMatches(in: correctedText, options: [], range: NSRange(0..<correctedText.utf16.count), withTemplate: entry.value)
	}
	
	for entry in characters {
		let regex = try! NSRegularExpression(pattern: entry.key, options: [])
		correctedText = regex.stringByReplacingMatches(in: correctedText, options: [], range: NSRange(0..<correctedText.utf16.count), withTemplate: entry.value)
	}

	
	return correctedText
}

enum Boundaries:String {
	case ccString = "CC:"
	case problemsString = "Problems:"
	case subjectiveString = "S:"
	case newPMHString = "NEW PMH:"
	case rosString = "REVIEW OF SYSTEMS: ROS as per HPI and:"
	//case rosString = "REVIEW OF SYSTEMS:"
	//case chargeStringRaw = "A(Charge):"
	case chargeString = "A*\\(Charge\\):"
	case chargeStringOld = "A*\\(Ch*rg*\\):"
	case planString = "P\\(lan\\):"
	case objectiveString = "O*\\(PE\\):"
	case medicationString = "CURRENT MEDICATIONS:"
	case allergiesString = "ALLERGIES:"
	case preventiveString = "PREVENTIVE CARE:"
	case pmhString = "PAST MEDICAL HISTORY:"
	case pshString = "PAST SURGICAL HISTORY:"
	case nutritionString = "NUTRITION:"
	case socialString = "SOCIAL HISTORY:"
	case fhhString = "FAMILY HEALTH HISTORY:"
	case diagnosisString = "DIAGNOSES:"
	case rx = "\\*\\*Rx\\*\\*"
}

enum SectionHeadings:String {
	case cc = "CHIEF COMPLAINT"
	case problems = "PROBLEMS"
	case subjective = "SUBJECTIVE"
	case ros = "REVIEW OF SYSTEMS: ROS as per HPI and:"
	case newPMH = "UPDATED MEDICAL HISTORY"
	//case assessment = "ASSESSMENT"
	//case objective = "O"
	case allergies = "ALLERGIES"
	case medications = "CURRENT MEDICATIONS"
	case preventive = "PREVENTIVE CARE"
	case pmh = "PAST MEDICAL HISTORY"
	case psh = "PAST SURGICAL HISTORY"
	case nutrition = "NUTRITION"
	case social = "SOCIAL HISTORY"
	case family = "FAMILY HEALTH HISTORY"
	//case plan = "PLAN"
}

var misspelledWordDict = [
	"pvd":"peripheral vascular disease",
	"htn":"hypertension",
	"dm":"diabetes mellitus",
	"dpn":"diabetic peripheral neuropathy",
	"ckd":"chronic kidney disease",
	"afib":"atrial fibrillation",
	"otc":"over the counter",
	"rls":"restless leg syndrome",
	"cts":"carpal tunnel syndrome",
	"gerd":"gastroesophageal reflux disease",
	"copd":"chronic obstructive pulmonary disease",
	"cad":"coronary artery disease",
	"chf":"congestive heart failure",
	"dvt":"deep venous thrombosis",
	"chol":"cholesterol",
	"thy":"thyroid",
	"pt":"patient",
	"pts":"patient's"
]

var incorrectCharactersDict = [
	" , ":", ",
	"Show all \\(\\d\\)":"",
	"Social history \\(free text\\)":"",
	"Lvl .* \\(done dmw\\)":""
]
