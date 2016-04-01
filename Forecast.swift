//
//  Forecast.swift
//  Skycast
//
//  Created by Kevin Kong on 2/27/16.
//  Copyright © 2016 Kevin Kong. All rights reserved.
//

import Foundation
import ForecastIO

class ForecastWrapper {
    
    var forecast: Forecast!
    var summarizedHourly: [(String, Int)]!
    var summarizedDaily: [(String, Int)]!
    
    init(forecast: Forecast) {
        
        self.forecast = forecast
        
        
        
        if let hourByHour = forecast.hourly {
            self.summarizedHourly = summarizeAndReduceNoise(hourByHour)
        }
        
        
        if let dayByDay = forecast.daily {
            self.summarizedDaily = summarizeForecast(dayByDay)
            
        }
        
        
    }
    
    
    private func summarizeAndReduceNoise(forecast: DataBlock) -> [(String, Int)] {
        return self.reduceNoise(summarizeForecast(forecast))
    }
    
    private func summarizeForecast(forecast: DataBlock) -> [(String, Int)] {
        
        
        
        // Remap the conditions into higher-level categories
        
        // {"time":1456617600,"summary":"Partly Cloudy","icon":"partly-cloudy-night","precipIntensity":0,"precipProbability":0,"temperature":34.37,"apparentTemperature":26.8,"dewPoint":15.51,"humidity":0.45,"windSpeed":9.73,"windBearing":203,"visibility":10,"cloudCover":0.29,"pressure":1013.32,"ozone":414.23},
        // {"time":1456621200,"summary":"Mostly Cloudy","icon":"partly-cloudy-night","precipIntensity":0,"precipProbability":0,"temperature":33.11,"apparentTemperature":24.21,"dewPoint":18.57,"humidity":0.55,"windSpeed":11.95,"windBearing":206,"visibility":10,"cloudCover":0.38,"pressure":1013.1,"ozone":410.34},
        
        // into
        
        // ["partly-cloudy", "party-cloudy"]
        
        let conditionCategoryArray = forecast.data!.map({  $0.icon!  })
        
        
        
        
        
        
        // Group the repeating conditions into blocks
        
        // ["clear", "clear", "partly-cloudy", "party-cloudy", "partly-cloudy", "rainy"]
        //
        // into
        //
        // [("clear", 2), ("partly-cloudy", 3), ("rainy", 1)]
        
        
        // Array of tuples - data struct to keep track of frequency & preserve sequence
        var reducedArray = [(String, Int)]()
        
        for conditionSummary in conditionCategoryArray {
            
            // First item in list
            if reducedArray.isEmpty {
                reducedArray.append((conditionSummary.rawValue, 1))
            } else {
                
                // If repeating
                if conditionSummary.rawValue == reducedArray.last!.0 {
                    if let lastItem = reducedArray.last {
                        reducedArray.removeLast()
                        reducedArray.append((lastItem.0, lastItem.1 + 1))
                    }
                    
                } else {
                    
                    // New set of conditions: add a new tuple (condition, 1)
                    reducedArray.append((conditionSummary.rawValue, 1))
                    
                }
            }
        }
        
        
        return reducedArray
        
    }
    
    
    private func reduceNoise(forecastSummary: [(String, Int)]) -> [(String, Int)] {
        
        
        
        // Reduce noise:
        
        // if current value is 1 hr, then check the previous & next conditions.
        // merge with whichever has a longer pattern.
        // In the example, you'd merge with PC1, not PC2.
        
        // ex: Partly Cloudy - 5 hrs
        //     Clear         - 1 hr
        //     Partly Cloudy - 2 hr
        
        // into
        
        //     Partly Cloudy - 6 hrs
        //     Partly Cloudy - 2 hr
        
        
        // Local mutable copy
        var forecastSummary = forecastSummary
        
        
        
        // Reduce "noise" - conditions that last only 1 hour
        
        var noiseToRemove = [Int]()
        
        for (index, obj) in forecastSummary.enumerate() {
            
            // Current key-value
            let (_, length0) = obj
            
            // If this is noise (conditions lasting 1 hour):
            if length0 == 1 {
                
                // If this obj is first in the array
                if index == 0 {
                    
                    // Append to next item in array
                    let (condition1, length1) = forecastSummary[index + 1]
                    forecastSummary[index + 1] = (condition1, length1 + length0)
                    
                    
                    // Last object in the array
                } else if index == forecastSummary.count - 1 {
                    
                    // Append to the prev item in array
                    let (condition1, length1) = forecastSummary[index - 1]
                    forecastSummary[index - 1] = (condition1, length1 + length0)
                    
                    
                    // Middle of the array
                } else if index > 0 && index < forecastSummary.count - 1 {
                    
                    // Get prev/next condition/length
                    let (pc, pl) = forecastSummary[index - 1]
                    let (nc, nl) = forecastSummary[index + 1]
                    
                    // If prev value is greater/equal, then add to prev
                    if pl >= nl {
                        forecastSummary[index - 1] = (pc, pl + length0)
                    } else {
                        forecastSummary[index + 1] = (nc, nl + length0)
                    }
                    
                }
                
                
                // Remove item from array
                noiseToRemove.append(index)
                
            }
            
        }
        
        
        // Iterate in reverse through array to remove noise
        
        for idx in forecastSummary.count.stride(to: 0, by: -1) {
            if noiseToRemove.contains(idx) {
                forecastSummary.removeAtIndex(idx)
            }
        }
        
        
        return forecastSummary
        

        
    }
    
    
}
