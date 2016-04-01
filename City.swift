//
//  City.swift
//  Skycast
//
//  Created by Kevin Kong on 2/27/16.
//  Copyright © 2016 Kevin Kong. All rights reserved.
//

import Foundation

class City {
    
    
    var name: String!
    var state: String!
    var country: String!
    var latitude: Double!
    var longitude: Double!
    var forecast: ForecastWrapper?
    
    init(name: String, state: String, country: String, latitude: Double, longitude: Double) {
        self.name = name
        self.state = state
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
        
    
}
