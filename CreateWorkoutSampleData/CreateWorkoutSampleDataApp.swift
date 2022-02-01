//
//  CreateWorkoutSampleDataApp.swift
//  CreateWorkoutSampleData
//
//  Created by Andre Albach on 31.01.22.
//

import SwiftUI

@main
struct CreateWorkoutSampleDataApp: App {
    
    /// The main coordinator for the app
    @StateObject private var creator = WorkoutCreator()
    
    /// Access to te scene phase which will allow to be notified when app becomes active again
    @Environment(\.scenePhase) private var scenePhase
    
    /// The body
    var body: some Scene {
        WindowGroup {
            MainView(creator: creator)
        }
        
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                creator.checkHealthAccess()
            }
        }
    }
}
