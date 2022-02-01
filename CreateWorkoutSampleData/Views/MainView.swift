//
//  MainView.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import SwiftUI

/// The main view of the app which will be displayed when the app starts
struct MainView: View {
    
    /// Reference to the app creator which will control the view and create the workout
    @ObservedObject var creator: WorkoutCreator
    
    /// The body of the view
    var body: some View {
        NavigationView {
            
            // MARK: - no health app
            
            if !creator.isHealthDataAvailable {
                Text("Sorry, this device does not support heealth data.\nPlease use a different device.")
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
            } else {
                
                // MARK: - no access yet
                
                if creator.needToAskForHealthAccess {
                    
                    Form {
                        Section {
                            Text("This app needs access to your health data.\nPlease provice access.")
                                .multilineTextAlignment(.center)
                                
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        
                        
                        Button("Grant health access") {
                            Task {
                                await creator.requestPermissionToHealthData()
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    }
                    .navigationTitle("Ask for health access")
                    
                    
                } else {
                    
                    // MARK: - no access
                    
                    if !creator.hasHealthAccess {
                        
                        Text("No access to health.\nPlease go to system settings and grant access")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .navigationTitle("Error")
                        
                    } else {
                        
                        // MARK: - create workout
                        
                        Form {
                            
                            Section(header: Text("Enter workout data")) {
                                
                                Picker("Activity type", selection: $creator.activityType) {
                                    ForEach(creator.availableActivityTypes, id: \.self) { activityType in
                                        Text(activityType.description)
                                    }
                                }
                                
                                if creator.activityType == .swimming {
                                    Picker("Swimming location type", selection: $creator.swimmingLocationType) {
                                        ForEach(creator.availableSwimmingLocationTypes, id: \.self) { locationType in
                                            Text(locationType.description)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("Lap length: ")
                                        TextField("Enter length", text: $creator.lapLength)
                                    }
                                    
                                    Picker("Lap length unit", selection: $creator.lapLengthUnit) {
                                        ForEach(creator.availableLapLengthUnits, id: \.self) { locationType in
                                            Text(locationType.description)
                                        }
                                    }
                                    
                                } else {
                                    Picker("Location type", selection: $creator.locationType) {
                                        ForEach(creator.availableLocationTypes, id: \.self) { locationType in
                                            Text(locationType.description)
                                        }
                                    }
                                }
                                
                                DatePicker("Start date", selection: $creator.workoutStartDate)
                                
                                DatePicker("End date", selection: $creator.workoutEndDate)
                                
                                if creator.locationType == .outdoor {
                                    HStack {
                                        Text("Start latitude: ")
                                        TextField("Enter latitude", text: $creator.workoutStartLatitude)
                                    }
                                    HStack {
                                        Text("Start longitude: ")
                                        TextField("Enter longitude", text: $creator.workoutStartLongitude)
                                    }
                                }
                            }
                            
                            
                            Section {
                                
                                Button("Create workout") {
                                    Task {
                                        await creator.createWorkout()
                                    }
                                }
                                .disabled(creator.isCreatingWorkout)
                            }
                        }
                        .navigationTitle("Create workout")
                    }
                }
            }
        }
        .task {
            await creator.requestPermissionToHealthData()
        }
    }
}


// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        MainView(creator: WorkoutCreator.preview)
    }
}
