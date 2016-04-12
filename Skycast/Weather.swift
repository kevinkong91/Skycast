//
//  Weather.swift
//  Skycast
//
//  Created by Kevin Kong on 3/3/16.
//  Copyright © 2016 Kevin Kong. All rights reserved.
//

import Foundation

class Weather {
    
    
    // Mapping names of icons to Major Conditions
    static var categories = [
        
            "clear-day":                  "Clear",
            "clear-night":                "Clear",
            "rain":                       "Rain",
            "snow":                       "Snow",
            "sleet":                      "Sleet",
            "wind":                       "Wind",
            "fog":                        "Fog",
            "cloudy":                     "Cloudy",
            "partly-cloudy-day":          "Partly Cloudy",
            "partly-cloudy-night":        "Partly Cloudy",
        
    ]
    
    
    
    
    // MARK: Forecast Type
    
    class var forecastType:String {
        
        let prefs = NSUserDefaults.standardUserDefaults()
        
        if let forecastType = prefs.stringForKey("forecastType") as String? {
            
            return forecastType
            
        } else {
            
            // Default value "hourly"
            return "hourly"
            
        }
        
    }
    
    class func setForecastType(forecastType: String) {
        
        if forecastType == "hourly" || forecastType == "daily" {
            // Set the value
            NSUserDefaults.standardUserDefaults().setValue(forecastType, forKey: "forecastType")
        }
    }
    
    
    // MARK: Units (F/C) Settings
    
    class var tempUnits:String {
        
        let prefs = NSUserDefaults.standardUserDefaults()
        
        if let units = prefs.stringForKey("tempUnits") as String? {
            
            return units
            
        } else {
            
            let defaultUnit = "F"
            
            // Set defaults
            prefs.setValue(defaultUnit, forKey: "tempUnits")
            
            // Default value "hourly"
            return defaultUnit
            
        }
        
    }
    
    class func toggleTempUnit() {
        
        if Weather.tempUnits == "F" {
            // Set the value
            NSUserDefaults.standardUserDefaults().setValue("C", forKey: "tempUnits")
        } else {
            NSUserDefaults.standardUserDefaults().setValue("F", forKey: "tempUnits")
        }
    }
    
    
    // MARK: Convert Temp Units (F <-> C)
    
    class func convertTemp(temperature: Float, toUnit: String) -> Float {
        
        if toUnit == "F" {
            return (temperature * 1.80) + 32.00
        } else {
            return (temperature - 32.00) / 1.80
        }
        
    }
    
    
    
    
    
    // MARK: Tutorial of UX
    
    
    // Check if user has already been onboarded
    class func isUserOnboarded() -> Bool {
        
        if let userOnboarded = NSUserDefaults.standardUserDefaults().boolForKey("userOnboarded") as Bool? {
            return userOnboarded
        } else {
            return false
        }
        
    }
    
    // Set user as onboarded (first load of the app)
    class func userIsOnboarded() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "userOnboarded")
    }
    
    
    
    
    
}