//
//  HKWorkoutSessionLocationType.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import HealthKit

extension HKWorkoutSessionLocationType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .indoor: return "Indoor"
        case .outdoor: return "Outdoor"
        default: return "Unknown"
        }
    }
}
