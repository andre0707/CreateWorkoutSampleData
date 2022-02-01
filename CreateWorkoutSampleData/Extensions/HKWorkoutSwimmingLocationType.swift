//
//  HKWorkoutSwimmingLocationType.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import HealthKit

extension HKWorkoutSwimmingLocationType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .pool: return "Pool"
        case .openWater: return "Open water"
        default: return "Unknown"
        }
    }
}
