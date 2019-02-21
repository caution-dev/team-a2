//
//  CoreDataWeatherService.swift
//  OneDay
//
//  Created by juhee on 12/02/2019.
//  Copyright © 2019 teamA2. All rights reserved.
//

import Foundation

protocol CoreDataWeatherService {
    var numbersOfWeathers: Int { get }
    var weathers: [Weather] { get }
    func insertWeather() -> Weather
}
