//
//  WorkoutCreator.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import CoreLocation
import HealthKit
import SwiftUI


/// The main coordinator for the whole app
final class WorkoutCreator: ObservableObject {
    
    /// The health store through which the app will access HealthKit
    private let healthStore = HKHealthStore()
    
    /// Indicator, if health data is available on this device
    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    
    // MARK: - Initialisation
    
    /// Initialisation
    init() {
        setRandomDate()
    }
    
    /// Call this function to check if the app has health access
    func checkHealthAccess() {
        let hasHealthAccess = healthStore.authorizationStatus(for: HKQuantityType.workoutType()) == .sharingAuthorized
        print("Has sharing health access: \(hasHealthAccess)")
        self.hasHealthAccess = hasHealthAccess
        self.needToAskForHealthAccess = healthStore.authorizationStatus(for: HKQuantityType.workoutType()) == .notDetermined
    }
    
    
    /// Use this function to request permission to health data.
    /// This is an aync call, since we need to wait for the user response
    /// - Returns: True, if the user gave us permission
    ///            False, if the user denied access
    @discardableResult
    func requestPermissionToHealthData() async -> Bool {
        
        let write: Set<HKSampleType> = [
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
            HKSampleType.quantityType(forIdentifier: .distanceSwimming)!,
            HKSampleType.quantityType(forIdentifier: .stepCount)!,
            HKSampleType.quantityType(forIdentifier: .swimmingStrokeCount)!
        ]
        let read: Set<HKObjectType> = [
            HKSeriesType.activitySummaryType(),
            HKSeriesType.workoutRoute(),
            HKSeriesType.workoutType(),
            HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSampleType.quantityType(forIdentifier: .distanceCycling)!,
            HKSampleType.quantityType(forIdentifier: .distanceSwimming)!,
            HKSampleType.quantityType(forIdentifier: .stepCount)!,
            HKSampleType.quantityType(forIdentifier: .swimmingStrokeCount)!
        ]
        
        guard (try? await healthStore.requestAuthorization(toShare: write, read: read)) != nil else { return false }

        DispatchQueue.main.async {
            self.checkHealthAccess()
        }
        return true
    }
    
    /// This function will set a random start and end date for the workout.
    /// The workout will be within the last 30 days.
    /// The workout has a length between 20 and 90 minutes
    /// The workout will start between 2 and 3 hours before the current time
    private func setRandomDate() {
        let randomStartDay = Double(Int.random(in: 1 ... 30)) /// Random number of days in the past the workout should be on
        
        let randomStart = Double(Int.random(in: 2*60*60...3*60*60))
        let randomDuration = Double(Int.random(in: 60*20...60*90))
        let start = Date()
            .advanced(by: -(randomStartDay * 60 * 60 * 24))
            .advanced(by: -(randomStart + randomDuration))
        
        DispatchQueue.main.async {
            self.workoutStartDate = start
            self.workoutEndDate = start.advanced(by: randomDuration)
        }
    }
    
    
    // MARK: - UI State
    
    /// Indicator, if the app has health access
    @Published private(set) var hasHealthAccess: Bool = false
    
    /// Indicator if the app needs to ask for health access
    @Published private(set) var needToAskForHealthAccess: Bool = true
    
    /// A list of all the available activity types you can create workout data for
    let availableActivityTypes: [HKWorkoutActivityType] = [
        .walking,
        .running,
        .swimming,
        .cycling,
        .hiking
    ]
    /// The current picked activity type
    @Published var activityType: HKWorkoutActivityType = .walking
    
    /// A list of all the available location types
    let availableLocationTypes: [HKWorkoutSessionLocationType] = [
        .outdoor,
        .indoor
    ]
    /// The current picked location type
    @Published var locationType: HKWorkoutSessionLocationType = .outdoor
    
    /// A list of all the available swimming location types
    let availableSwimmingLocationTypes: [HKWorkoutSwimmingLocationType] = [
        .pool,
        .openWater
    ]
    /// The current picked swimming location type
    @Published var swimmingLocationType: HKWorkoutSwimmingLocationType = .pool
    
    /// A list of all the available pool length units for swim workouts
    let availableLapLengthUnits: [HKUnit] = [
        .meter(),
        .yard()
    ]
    /// The current picked pool length unit
    @Published var lapLengthUnit: HKUnit = .meter()
    /// The current picked pool lap length
    @Published var lapLength: String = "25"
    
    /// The current picked workout start date
    @Published var workoutStartDate: Date = Date()
    /// The current picked workout end date
    @Published var workoutEndDate: Date = Date()
    
    /// The current picked latitude of the start point for the workout route
    @Published var workoutStartLatitude = "50.1234"
    /// The current picked longitude of the start point for the workout route
    @Published var workoutStartLongitude = "8.1234"
    
    
    
    // MARK: - Create workout
    
    /// Indicator, if a route should be created
    private var createRoute: Bool { locationType == .outdoor }
    
    /// Indicator if the app is currently creating a workout.
    /// If so, disable create workout function call
    @State private(set) var isCreatingWorkout: Bool = false
    
    /// This function will create a workout based on the published values
    func createWorkout() async {
        guard !isCreatingWorkout else { return }
        
        isCreatingWorkout = true
        defer {
            isCreatingWorkout = false
            setRandomDate()
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = locationType
        
        if activityType == .swimming {
            configuration.lapLength = HKQuantity(unit: lapLengthUnit, doubleValue: Double(lapLength)!)
            configuration.swimmingLocationType = swimmingLocationType
        }
        
        let device: HKDevice? = nil /// if `nil`, the current device will be used
        
        let workoutTimeInterval = workoutStartDate.distance(to: workoutEndDate)
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: device)
        do {
            try await builder.beginCollection(at: workoutStartDate)
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            try await builder.addSamples(createSamples(for: workoutTimeInterval))
        } catch {
            print(error.localizedDescription)
        }
        
        let workoutMetaData: [String : Any] = [
            HKMetadataKeyTimeZone : TimeZone.current.identifier
        ]
        
        do {
            try await builder.addMetadata(workoutMetaData)
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            try await builder.endCollection(at: workoutEndDate)
        } catch {
            print(error.localizedDescription)
        }

        let workout: HKWorkout
        do {
            if let _workout = try await builder.finishWorkout() {
                workout = _workout
            } else {
                print("Workout is nil..")
                return
            }
        } catch {
            print(error.localizedDescription)
            return
        }
        
        if locationType == .outdoor {
            let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: device)
            try? await routeBuilder.insertRouteData(createSampleRoute(for: workoutTimeInterval))
            let routeMetaData: [String : Any] = [
                HKMetadataKeyTimeZone : TimeZone.current.identifier
            ]
            do {
                try await routeBuilder.finishRoute(with: workout, metadata: routeMetaData)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    /// This function will create the distance sample data based on the activity types
    /// - Parameter workoutTimeInterval: The timeinterval for which sample data is needed. Depending on the activity the samples take different time length. But they must sum up to this value
    /// - Returns: The created samples which can be added to the workout
    private func createSamples(for workoutTimeInterval: TimeInterval) -> [HKSample] {
        var samples: [HKSample] = []
        
        switch activityType {
        case .walking:
            let quantityTypeDistance = HKQuantityType.init(.distanceWalkingRunning)
            let quantityTypeStepCount = HKQuantityType.init(.stepCount)
            
            var usedTime: TimeInterval = 0
            while usedTime < workoutTimeInterval {
                let randomDistance = Double.random(in: 3 ... 6) /// Distance in meter
                let randomSpeed = TimeInterval.random(in: 4 ... 6) /// Speed in km/h
                
                var timeForSample: TimeInterval = randomDistance * 3.6 / randomSpeed /// Time in seconds
                if usedTime + timeForSample > workoutTimeInterval {
                    timeForSample = workoutTimeInterval - usedTime
                }
                
                let quantityDistance = HKQuantity(unit: .meter(), doubleValue: randomDistance)
                let stepCount = (randomDistance / Double.random(in: 0.7 ... 0.9)).rounded()
                let quantityStepCount = HKQuantity(unit: .count(), doubleValue: stepCount)
                
                let start = workoutStartDate.advanced(by: usedTime)
                let end = start.advanced(by: timeForSample)
                
                samples.append(HKQuantitySample(type: quantityTypeDistance, quantity: quantityDistance, start: start, end: end))
                samples.append(HKQuantitySample(type: quantityTypeStepCount, quantity: quantityStepCount, start: start, end: end))
                usedTime += timeForSample
            }
            
        case .hiking:
            let quantityTypeDistance = HKQuantityType.init(.distanceWalkingRunning)
            let quantityTypeStepCount = HKQuantityType.init(.stepCount)
            
            var usedTime: TimeInterval = 0
            while usedTime < workoutTimeInterval {
                let randomDistance = Double.random(in: 3 ... 6) /// Distance in meter
                let randomSpeed = TimeInterval.random(in: 3 ... 6) /// Speed in km/h
                
                var timeForSample: TimeInterval = randomDistance * 3.6 / randomSpeed /// Time in seconds
                if usedTime + timeForSample > workoutTimeInterval {
                    timeForSample = workoutTimeInterval - usedTime
                }
                
                let quantityDistance = HKQuantity(unit: .meter(), doubleValue: randomDistance)
                let stepCount = (randomDistance / Double.random(in: 0.7 ... 0.9)).rounded()
                let quantityStepCount = HKQuantity(unit: .count(), doubleValue: stepCount)
                
                let start = workoutStartDate.advanced(by: usedTime)
                let end = start.advanced(by: timeForSample)
                
                samples.append(HKQuantitySample(type: quantityTypeDistance, quantity: quantityDistance, start: start, end: end))
                samples.append(HKQuantitySample(type: quantityTypeStepCount, quantity: quantityStepCount, start: start, end: end))
                usedTime += timeForSample
            }
            
        case .running:
            let quantityTypeDistance = HKQuantityType.init(.distanceWalkingRunning)
            let quantityTypeStepCount = HKQuantityType.init(.stepCount)
            
            var usedTime: TimeInterval = 0
            while usedTime < workoutTimeInterval {
                var timeForSample: TimeInterval = 5*60 /// Time in seconds
                if usedTime + timeForSample > workoutTimeInterval {
                    timeForSample = workoutTimeInterval - usedTime
                }
                
                let randomSpeed = TimeInterval(Int.random(in: 7 ... 15)) /// Speed in km/h
                let distance = randomSpeed * 1000 / 3600 * timeForSample /// Distance in meter
                
                let quantityDistance = HKQuantity(unit: .meter(), doubleValue: distance)
                let stepCount = (distance / Double.random(in: 0.7 ... 0.9)).rounded()
                let quantityStepCount = HKQuantity(unit: .count(), doubleValue: stepCount)
                
                let start = workoutStartDate.advanced(by: usedTime)
                let end = start.advanced(by: timeForSample)
                
                samples.append(HKQuantitySample(type: quantityTypeDistance, quantity: quantityDistance, start: start, end: end))
                samples.append(HKQuantitySample(type: quantityTypeStepCount, quantity: quantityStepCount, start: start, end: end))
                usedTime += timeForSample
            }
            
        case .cycling:
            let quantityType = HKQuantityType.init(.distanceCycling)
            
            var usedTime: TimeInterval = 0
            while usedTime < workoutTimeInterval {
                var timeForSample: TimeInterval = 2*60 /// Time in seconds
                if usedTime + timeForSample > workoutTimeInterval {
                    timeForSample = workoutTimeInterval - usedTime
                }
                
                let randomSpeed = TimeInterval(Int.random(in: 12 ... 25)) /// Speed in km/h
                let distance = randomSpeed * 1000 / 3600 * timeForSample /// Distance in meter
                
                let quantity = HKQuantity(unit: .meter(), doubleValue: distance)
                
                let start = workoutStartDate.advanced(by: usedTime)
                let end = start.advanced(by: timeForSample)
                
                samples.append(HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end))
                usedTime += timeForSample
            }
            
        case .swimming:
            let quantityTypeSwimmingDistance = HKQuantityType.init(.distanceSwimming)
            let quantityTypeSwimmingStrokeCount = HKQuantityType.init(.swimmingStrokeCount)
            
            let lapLength = Double(lapLength)!
            var usedTime: TimeInterval = 0
            while usedTime < workoutTimeInterval {
                var timeForLap = TimeInterval(Int.random(in: 20 ... 65)) / 25 * lapLength
                if usedTime + timeForLap > workoutTimeInterval {
                    timeForLap = workoutTimeInterval - usedTime
                }
                
                let quantitySwimmingDistance = HKQuantity(unit: lapLengthUnit, doubleValue: lapLength)
                
                let strokeCountPerLap = (Double(Int.random(in: 7 ... 14)) / 25 * lapLength).rounded()
                let quantitySwimmingStrokeCount = HKQuantity(unit: .count(), doubleValue: strokeCountPerLap)
                
                let start = workoutStartDate.advanced(by: usedTime)
                let end = start.advanced(by: timeForLap)
                
                samples.append(HKQuantitySample(type: quantityTypeSwimmingDistance, quantity: quantitySwimmingDistance, start: start, end: end))
                samples.append(HKQuantitySample(type: quantityTypeSwimmingStrokeCount, quantity: quantitySwimmingStrokeCount, start: start, end: end))
                usedTime += timeForLap
            }
            
        default:
            assertionFailure("Unhandled activity type")
            return []
        }
        
        return samples
    }
    
    
    
    /// This function will create a sample route, starting at the entered coordinates `workoutStartLatitude`, `workoutStartLongitude`.
    /// Going East/West: 1m is about 0.000014º
    /// Going North/South: 1m is about 0.000009º
    /// - Parameter timeInterval: The time interval for which the route is needed. The amount of points depend on it
    /// - Returns: The Locations of the sample route
    private func createSampleRoute(for timeInterval: TimeInterval) -> [CLLocation] {
        guard activityType != .swimming,
              locationType == .outdoor
        else { return [] }
        
        let deltaLat = Double.random(in: 0 ... 0.000009)
        let deltaLon = Double.random(in: 0 ... 0.000014)
        
        var currentLatitude = CLLocationDegrees(workoutStartLatitude)!
        var currentLongitude = CLLocationDegrees(workoutStartLongitude)!
        var locations: [CLLocation] = [CLLocation(latitude: currentLatitude, longitude: currentLongitude)]
        
        switch activityType {
        case .walking:
            for _ in stride(from: 0, to: Int(timeInterval), by: 1) {
                currentLatitude += deltaLat * 1.7
                currentLongitude += deltaLon * 1.7
                locations.append(CLLocation(latitude: currentLatitude, longitude: currentLongitude))
            }
            
        case .running:
            for _ in stride(from: 0, to: Int(timeInterval), by: 1) {
                currentLatitude += deltaLat * 2.6
                currentLongitude += deltaLon * 2.6
                locations.append(CLLocation(latitude: currentLatitude, longitude: currentLongitude))
            }
            
        case .hiking:
            for _ in stride(from: 0, to: Int(timeInterval), by: 1) {
                currentLatitude += deltaLat * 0.9
                currentLongitude += deltaLon * 0.9
                locations.append(CLLocation(latitude: currentLatitude, longitude: currentLongitude))
            }
            
        case .cycling:
            for _ in stride(from: 0, to: Int(timeInterval), by: 1) {
                currentLatitude += deltaLat * 4.9
                currentLongitude += deltaLon * 4.9
                locations.append(CLLocation(latitude: currentLatitude, longitude: currentLongitude))
            }
            
        default:
            assertionFailure("Unhandled activity type")
            return []
        }
        
        return locations
    }
}






// MARK: - Preview data

extension WorkoutCreator {
    
    /// A static member used for the Xcode previews
    static let preview: WorkoutCreator = {
        let creator = WorkoutCreator()
        creator.hasHealthAccess = true
        
        creator.activityType = .hiking
        
        return creator
    }()
}
