//
//  HealthKitManager.swift
//
//  Created by Ben Zimring on 7/25/18.
//  do whatever you'd like with this file
//

import Foundation
import HealthKit

/* useful for requesting HealthKit authorization, among other things */
extension HKObjectType {
    static let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    static let variabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    static let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    static let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    static let workoutType = HKObjectType.workoutType()
    static let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    static let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
}

/* useful for converting from HealthKit's weird output formats */
extension HKUnit {
    static let heartRateUnit = HKUnit(from: "count/min")
    static let variabilityUnit = HKUnit.secondUnit(with: .milli)
}

class HealthKitManager {
    
    fileprivate let health = HKHealthStore()
    
    
    //This gets our most recent active energy but i dont think adds it together...
    public func activeEnergy(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let activeEnergyQuery = HKSampleQuery(sampleType: .activeEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            
            guard let results = results as? [HKQuantitySample] else {
                NSLog("HealthKitManager: activeEnergy: nil AE samples.. auth'd?")
                return
            }
            handler(results)
        }
        health.execute(activeEnergyQuery)
    }
    
    public func basalEnergy(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let basalEnergyQuery = HKSampleQuery(sampleType: .basalEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            
            guard let results = results as? [HKQuantitySample] else {
                NSLog("HealthKitManager: basalEnergy: nil AE samples.. auth'd?")
                return
            }
            handler(results)
        }
        health.execute(basalEnergyQuery)
    }
    
    //I think this will get our total active energy for the day.
    public func activeEnergyAdded(handler: @escaping (HKStatisticsCollection) -> ()) {
        print("HKM 1")
        let calendar = NSCalendar.current
        var interval = DateComponents()
        interval.day = 1
        print("HKM 2")
        
        var anchorComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        print("HKM 3")
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)
        print("HKM 4")
        
        // Define 1-day intervals starting from 0:00
        let activeEnergyQuery = HKStatisticsCollectionQuery(quantityType: .activeEnergyType, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval)
        print("HKM 5")
        
        //Set the results handler
        activeEnergyQuery.initialResultsHandler = { query, results, error in
            if let result = results {
                print("HKM 6")
                handler(result)
                print("HKM 7")
            } else {
                print(error!.localizedDescription)
            }
        }
        print("HKM 8")
        health.execute(activeEnergyQuery)
        print("HKM 9")
    }
    
    
    
    
    
    /**
     Fetches ALL saved heart rate readings bound by the input date range.
     - Parameter from: start of date range
     - Parameter to: end of date range
     - Parameter handler: closure to handle the list of samples returned
     */
    public func heartRate(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let heartRateQuery = HKSampleQuery(sampleType: .heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKQuantitySample] else { NSLog("HealthKitManager: heartRate: nil HR samples.. auth'd?"); return }
            handler(results)
        }
        health.execute(heartRateQuery)
    }
    
    /**
     Fetches daily resting HR info from some date to another.
     - Parameter from: Starting date from which data will be retrieved
     - Parameter to: Ending date from which data will be retrieved
     - Parameter handler: your closure to handle the list of HKQuantitySamples
     */
    public func restingHeartRate(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        // HealthKit query
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let query = HKSampleQuery(sampleType: .restingHeartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                NSLog("HealthKitManager: restingHeartRate: nil RHR samples.. auth'd?")
                return
            }
            // found sample(s)
            handler(samples)
        }
        health.execute(query)
    }
    
    //This will find the MOST recent Resting Heart Rate reading from the dates inputted in ContentView when running function
    public func restingHeartRateMostRecent(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        // HealthKit query
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .restingHeartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                NSLog("HealthKitManager: restingHeartRate: nil RHR samples.. auth'd?")
                return
            }
            // found sample(s)
            handler(samples)
        }
        health.execute(query)
    }
    
    //This will find the maximum Resting Heart Rate reading from the dates inputted in ContentView when running function

    
    
    /**
     Fetches daily steps info.
     - Parameter handler: closure handling the HKStatisticsCollection object
     returned by the query.  Use:
           1. results.enumerateStatistics(from: Date, to: Date) {
           2.     statistics, stop in
           ..     ...
            }
     which loops through each day.
     https://developer.apple.com/documentation/healthkit/hkstatisticscollection/1615783-enumeratestatistics
     */
    public func dailySteps(handler: @escaping (HKStatisticsCollection) -> ()) {
        let calendar = NSCalendar.current
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)
        
        // Define 1-day intervals starting from 0:00
        let stepsQuery = HKStatisticsCollectionQuery(quantityType: .stepsType, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval)
        
        // Set the results handler
        stepsQuery.initialResultsHandler = { query, results, error in
            if let results = results {
                handler(results)
            } else {
                print(error!.localizedDescription)
            }
        }
        health.execute(stepsQuery)
    }
    
    /**
     Fetches heart rate variability measurements for each day of the given range.
     - note: there may be multiple readings for each day.. Apple's Health app averages these!
     - Parameter from: start of date range
     - Parameter to: end of date range
     - Parameter handler: closure to handle the list of samples returned
     */
    public func variability(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        // HealthKit query
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        //Looks at data from a day to a day
        let query = HKSampleQuery(sampleType: .variabilityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            //If we change our limit to 1 and sortDescriptors to above, itll find the most recent...?
            //Yup! Just have to use [sortDescriptor]
            //I think I may be able to use this to queryStatistics for an average, a low / high for a certain period (Week, month) remove outliers. Make multiple of these functions to use for algorithm!
            //??How do make a query for "7 Days Ago"
            guard let samples = samples as? [HKQuantitySample] else {
                NSLog("HealthKitManager: variability: nil variability samples.. auth'd?")
                return
            }
            // found sample(s)
            handler(samples)
        }
        health.execute(query)
    }
    
    //This will find the MOST recent variability reading from the dates inputted in ContentView when running function
    public func variabilityMostRecent(from: Date, to: Date, handler: @escaping ([HKQuantitySample]) -> ()) {
        // HealthKit query
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        //Looks at data from a day to a day
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        //Creates a sort descriptor of descending paramaters
        //Did this push?
        let query = HKSampleQuery(sampleType: .variabilityType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            //If we change our limit to 1 and sortDescriptors to above, itll find the most recent...?
            //Yup! Just have to use [sortDescriptor]
            //I think I may be able to use this to queryStatistics for an average, a low / high for a certain period (Week, month) remove outliers. Make multiple of these functions to use for algorithm!
            //??How do make a query for "7 Days Ago"
            guard let samples = samples as? [HKQuantitySample] else {
                NSLog("HealthKitManager: variability: nil variability samples.. auth'd?")
                return
            }
            // found sample(s)
            handler(samples)
        }
        health.execute(query)
    }
    
    //This will find the maximum variability reading from the dates inputted in ContentView when running function
    //Need to find how to use statistics variability requests to find the max somehow...
    //Use dailysteps above as an example!
    //Still trying to figure this out...https://github.com/sobri909/ArcMini/blob/2395c925aa5da094a9168c8a0d8ac156603d79c3/Arc%20Mini/Models/External/Health.swift ?
    //Could also just put everything into an array and find min max from there?
    
    /**
     Fetches workouts recorded in the given date range.
     - Parameter from: start of date range
     - Parameter to: end of date range
     - Parameter handler: closure to handle the list of samples returned
     */
    public func workouts(from: Date, to: Date, handler: @escaping ([HKWorkout]) -> ()) {
        // HealthKit query
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKWorkout] else { NSLog("HealthKitManager: workouts: nil workout samples.. auth'd?"); return }
            handler(samples)
        }
        health.execute(query)
    }
    
    /**
     Requests HealthKit authorization for the given types, executes closure upon success
     - Parameter readingTypes: types to request HealthKit for read access (optional)
     - Parameter writingTypes: types to request HealthKit for write access (optional)
     - Parameter completion: codeblock to execute upon authorization completion
     - note: this does not mean the user actually granted you privileges!
     */
    public func requestAuthorization(readingTypes: Set<HKObjectType>?, writingTypes: Set<HKSampleType>?, completion: @escaping () -> ()) {
        health.requestAuthorization(toShare: writingTypes, read: readingTypes) { (success, error) in
            if let error = error {
                fatalError("** HealthKitManager: authorization failure. \(error.localizedDescription) **")
            }
            completion()
        }
    }
    
    
}
