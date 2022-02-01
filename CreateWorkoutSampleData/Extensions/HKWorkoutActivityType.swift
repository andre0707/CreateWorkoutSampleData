//
//  HKWorkoutActivityType.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import HealthKit

extension HKWorkoutActivityType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        default: return "Unknown"
        }
    }
}
