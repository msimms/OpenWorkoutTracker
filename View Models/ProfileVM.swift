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
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = height
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_HEIGHT
		attr.unitSystem = Preferences.preferredUnitSystem()
		attr.valid = true
		ConvertToMetric(&attr)
		Preferences.setHeightCm(value: attr.value.doubleVal)
	}
	
	static func setWeight(weight: Double) {
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = weight
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_WEIGHT
		attr.unitSystem = Preferences.preferredUnitSystem()
		attr.valid = true
		ConvertToMetric(&attr)
		Preferences.setWeightKg(value: attr.value.doubleVal)
	}
}
