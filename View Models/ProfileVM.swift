//
//  ProfileVM.swift
//  Created by Michael Simms on 10/6/22.
//

import Foundation

let STR_SEDENTARY =         "Sedentary"
let STR_LIGHT =             "Light"
let STR_MODERATELY_ACTIVE = "Moderately Active"
let STR_HIGHLY_ACTIVE =     "Highly Active"
let STR_EXTREMELY_ACTIVE =  "Extremely Active"

let STR_MALE =              "Male"
let STR_FEMALE =            "Female"

class ProfileVM {
	static func activityLevelToString(activityLevel: ActivityLevel) -> String {
		switch activityLevel {
		case ACTIVITY_LEVEL_SEDENTARY:
			return STR_SEDENTARY
		case ACTIVITY_LEVEL_LIGHT:
			return STR_LIGHT
		case ACTIVITY_LEVEL_MODERATE:
			return STR_MODERATELY_ACTIVE
		case ACTIVITY_LEVEL_ACTIVE:
			return STR_HIGHLY_ACTIVE
		case ACTIVITY_LEVEL_EXTREME:
			return STR_EXTREMELY_ACTIVE
		default:
			break
		}
		return STR_MODERATELY_ACTIVE
	}
	
	static func activityLevelStringToType(activityLevelStr: String) -> ActivityLevel {
		if activityLevelStr == STR_SEDENTARY {
			return ACTIVITY_LEVEL_SEDENTARY
		}
		if activityLevelStr == STR_LIGHT {
			return ACTIVITY_LEVEL_LIGHT
		}
		if activityLevelStr == STR_MODERATELY_ACTIVE {
			return ACTIVITY_LEVEL_MODERATE
		}
		if activityLevelStr == STR_HIGHLY_ACTIVE {
			return ACTIVITY_LEVEL_ACTIVE
		}
		if activityLevelStr == STR_EXTREMELY_ACTIVE {
			return ACTIVITY_LEVEL_EXTREME
		}
		return ACTIVITY_LEVEL_MODERATE
	}
	
	static func genderToString(genderType: Gender) -> String {
		switch genderType {
		case GENDER_MALE:
			return STR_MALE
		case GENDER_FEMALE:
			return STR_FEMALE
		default:
			break
		}
		return STR_COMPLETION
	}
	
	static func genderStringToType(genderStr: String) -> Gender {
		if genderStr == STR_MALE {
			return GENDER_MALE
		}
		if genderStr == STR_FEMALE {
			return GENDER_FEMALE
		}
		return GENDER_MALE
	}
	
	static func getDisplayedHeight() -> Double {
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = Preferences.heightCm()
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_HEIGHT
		attr.unitSystem = UNIT_SYSTEM_METRIC
		attr.valid = true
		ConvertToPreferredUnits(&attr)
		return attr.value.doubleVal
	}
	
	static func getDisplayedWeight() -> Double {
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = Preferences.weightKg()
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_WEIGHT
		attr.unitSystem = UNIT_SYSTEM_METRIC
		attr.valid = true
		ConvertToPreferredUnits(&attr)
		return attr.value.doubleVal
	}
	
	static func setHeight(height: Double) {
		let unitSystem = Preferences.preferredUnitSystem()
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = height
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_HEIGHT
		attr.unitSystem = unitSystem
		attr.valid = true
		ConvertToMetric(&attr)
		
		Preferences.setHeightCm(value: attr.value.doubleVal)
		HealthManager.shared.saveHeightIntoHealthStore(height: height, unitSystem: unitSystem)
		CommonApp.shared.updateUserProfile()
	}
	
	static func setWeight(weight: Double) {
		let unitSystem = Preferences.preferredUnitSystem()
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = weight
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_WEIGHT
		attr.unitSystem = unitSystem
		attr.valid = true
		ConvertToMetric(&attr)
		
		Preferences.setWeightKg(value: attr.value.doubleVal)
		HealthManager.shared.saveWeightIntoHealthStore(weight: weight, unitSystem: unitSystem)
		CommonApp.shared.updateUserProfile()
	}
	
	static func setBiologicalGender(gender: Gender) {
		Preferences.setBiologicalGender(value: gender)
		CommonApp.shared.updateUserProfile()
	}
	
	static func setActivityLevel(activityLevel: ActivityLevel) {
		Preferences.setActivityLevel(value: activityLevel)
		CommonApp.shared.updateUserProfile()
	}
	
	static func setFtp(ftp: Double) -> Bool {
		Preferences.setUserDefinedFtp(value: ftp)
		HealthManager.shared.setFtp(ftp: ftp)
		CommonApp.shared.updateUserProfile()
		return ApiClient.shared.sendUpdatedUserFtp(timestamp: Date())
	}
	
	static func setRestingHr(hr: Double) -> Bool {
		Preferences.setUserDefinedRestingHr(value: hr)
		HealthManager.shared.setRestingHr(hr: hr)
		CommonApp.shared.updateUserProfile()
		return ApiClient.shared.sendUpdatedUserRestingHr(timestamp: Date())
	}
	
	static func setMaxHr(hr: Double) -> Bool {
		Preferences.setUserDefinedMaxHr(value: hr)
		CommonApp.shared.updateUserProfile()
		return ApiClient.shared.sendUpdatedUserMaxHr(timestamp: Date())
	}
	
	static func setVO2Max(vo2Max: Double) -> Bool {
		Preferences.setUserDefinedVO2Max(value: vo2Max)
		HealthManager.shared.setVO2Max(vo2Max: vo2Max)
		CommonApp.shared.updateUserProfile()
		return ApiClient.shared.sendUpdatedUserVO2Max(timestamp: Date())
	}
	
	static func updateEstimations() {
		// Pick the best estimate, either the one calculated from our database or the one calculated from HealthKit data.
		let estimatedFtpFromOurDb = EstimateFtp()
		let estimatedFtpFromHealthKit = HealthManager.shared.estimatedFtp
		var estimatedFtp = estimatedFtpFromOurDb
		if estimatedFtpFromHealthKit != nil && estimatedFtpFromHealthKit! > estimatedFtpFromOurDb {
			estimatedFtp = estimatedFtpFromHealthKit!
		}

		// Pick the best estimate, either the one calculated from our database or the one calculated from HealthKit data.
		let estimatedMaxHrFromOurDb = EstimateMaxHr()
		let estimatedMaxHrFromHealthKit = HealthManager.shared.estimatedMaxHr
		var estimatedMaxHr = estimatedMaxHrFromOurDb
		if estimatedMaxHrFromHealthKit != nil && estimatedMaxHrFromHealthKit! > estimatedMaxHrFromOurDb {
			estimatedMaxHr = estimatedMaxHrFromHealthKit!
		}

		let best5KAttr = QueryBestActivityAttributeByActivityType(ACTIVITY_TYPE_RUNNING, ACTIVITY_ATTRIBUTE_FASTEST_5K, true, nil)

		Preferences.setEstimatedFtp(value: estimatedFtp)
		Preferences.setEstimatedMaxHr(value: estimatedMaxHr)
		if best5KAttr.valid {
			Preferences.setBestRecent5KSecs(value: UInt32(best5KAttr.value.intVal))
		}
		CommonApp.shared.updateUserProfile()
	}
}
