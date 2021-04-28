//Last update:
//Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.

import Foundation
import HealthKit
import UIKit
import SwiftUI
import CoreData
import Dispatch
import SwiftProgress
import PZCircularControl
import SwiftUICharts
import ActivityIndicatorView
import OrderedDictionary

let delegate = UIApplication.shared.delegate as! AppDelegate

let hkm = HealthKitManager()

var arrayVariability7Day2 = [Double]()
var arrayRHR7Day2 = [Double]()
var mostRecentHRV = 0.0
var mostRecentRHR = 0.0
var max7DayHRV = 0.0
var min7DayHRV = 0.0
var max7DayRHR = 0.0
var min7DayRHR = 0.0
var recoveryRHRPercentageValue = 0.0
var recoveryHRVPercentageValue = 0.0
var finalRecoveryPercentageValue = 0.0
//Bar Data
var barColor:Color = .yellow

//Check Variables
var checkHRVAlert = 0
var baselineDaysLeft = 0
var baselineDays = 3

    //Array
var arrayHRV = [Double]()
var arrayRHR = [Double]()
var arrayNumbers = [NSManagedObject]()
    //Recent
var recentHRV = 0.0
var recentRHR = 0.0
var arrayHRVDone = false
var arrayRHRDone = false
    // Array's with outliers removed
var recentHRVNoOutlierArray = [Double]()
var initialHRVIQR = 0.0
var initialHRV1q = 0.0
var initialHRV3q = 0.0
var initialHRVLowOutlierCutoff = 0.0
var initialHRVHighOutlierCutoff = 0.0

    // Min/Max/1q/3q/avg HRV
var maxHRV = 0.0
var minHRV = 0.0
var q1HRV = 0.0
var q3HRV = 0.0
var avgHRV = 0.0
var sumHRV = 0.0
var medianHRV = 0.0
    // Min/Max RHR
var maxRHR = 0.0
var minRHR = 0.0
var minHRVDone = false
var maxHRVDone = false
var minRHRDone = false
var maxRHRDone = false
    // HRV/RHR Calculation
var hrvRecoveryPercentage = 0.0
var rhrRecoveryPercentage = 0.0
var hrvPercentageDone = false
var rhrPercentageDone = false
    // Final Calculation
var finalRecoveryPercentage2 = 0.0
var finalRecoveryIndicator = false
    // Loading Last Recovery
var lastRecoveryArray = [Double]()
var lastHRVValueArray = [Double]()
var lastRHRValueArray = [Double]()
var lastHRVPercentArray = [Double]()
var lastRHRPercentArray = [Double]()
var lastRecoveryVar = 0.0
var lastHRVVar = 0.0
var lastRHRVar = 0.0
var lastHRVPercentVar = 0.0
var lastRHRPercentVar = 0.0
    // Core Data Check
var hasRecoveryHappened = [Double]()
var howManyRecoveries = [Double]()
    //Energy View
var coreDataDictionary = [[Date]:[Double]]()
var coreDataTimeArray = [Date]()
var coreDataCalculationArray = [Double]()
var coreDataTodayTimeArray = [Date]()
var coreDataTodayCalculationArray = [Double]()
//
var activeEnergyArrayEachHour = [Double]()
var activeEnergyRetrieveArrayAdded = 0.0

var earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(0) //Starts at midnight
var lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(120) //Starts 1 hour after midnight
var hourAfter = calendar.startOfDay(for: rightNow).addingTimeInterval(120)

var earlyTimeInterval = 0
var lateTimeInterval = 120

var arrayTest = [Double]()
var basalArray = [Double]()
var finalActivityArrayPerTime = [Double]()

var heartRateArray = [Double]()
var heartRateRatioArray = [Double]()

private let userHealthProfile = UserHealthProfile()

var age = 0



precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

typealias FinishedGettingHealthData = () -> ()

//var date = NSDate()
//let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
//var lastMidnight = cal.startOfDay(for: date as Date)

//let date: Date = Date()
//let cal: Calendar = Calendar(identifier: .gregorian)
//let lastMidnight: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
var rightNow = Date()

let date = Date()
let dateFormatter = DateFormatter()

var calendar = Calendar.current
var startDate = calendar.startOfDay(for: rightNow)
var yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
var weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
var monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)
var lastMidnight = calendar.startOfDay(for: rightNow)

var lastMidnightFormatted = dateFormatter.string(from: lastMidnight)


private enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case dataTypeNotAvailable
}

func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
    //1. Check to see if HealthKit Is Available on this device
    guard HKHealthStore.isHealthDataAvailable() else {
        completion(false, HealthkitSetupError.notAvailableOnDevice)
        return
    }
    //2. Prepare the data types that will interact with HealthKit
    guard   let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            //let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            //let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let variability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            //let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            //let stepsTest = HKObjectType.quantityType(forIdentifier: .stepCount),
            let basalEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
        
        completion(false, HealthkitSetupError.dataTypeNotAvailable)
        return
    }
    //3. Prepare a list of types you want HealthKit to read and write
    let healthKitTypesToWrite: Set<HKSampleType> = []
    
    let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                   activeEnergy,
                                                   basalEnergy,
                                                   biologicalSex,
                                                   height,
                                                   heartRate,
                                                   variability,
                                                   restingHR,
                                                   bodyMass,
                                                   HKObjectType.workoutType()]
    //4. Request Authorization
    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                         read: healthKitTypesToRead) { (success, error) in
        completion(success, error)
    }
    
}

extension Date {
    static var yesterday: Date { return rightNow.dayBefore }
    static var tomorrow:  Date { return rightNow.dayAfter }
    static var weekAgo: Date { return rightNow.weekAgo }
    static var monthAgo: Date { return rightNow.monthAgo }
    static var hourAgo: Date { return rightNow.hourBefore }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var hourBefore: Date {
        return Calendar.current.date(byAdding: .hour, value: -1, to: self)!
    }
    var hourAfter: Date {
        return Calendar.current.date(byAdding: .hour, value: 1, to: self)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var weekAgo: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: noon)!
    }
    var monthAgo: Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    func to(timeZone outputTimeZone: TimeZone, from inputTimeZone: TimeZone) -> Date {
         let delta = TimeInterval(outputTimeZone.secondsFromGMT(for: self) - inputTimeZone.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
    
}
extension DateFormatter {
    func date(from string: String, timeZoneInString: TimeZone, outputTimeZone: TimeZone = .autoupdatingCurrent) -> Date? {
        date(from: string)?.to(timeZone: outputTimeZone, from: timeZoneInString)
    }
}
    
    //MARK: - SettingsView
    struct SettingsView: View {
        
        let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        var body: some View {
            NavigationView {
                VStack {
                    Text("When loading the application for the first time, press the Authorize Healthkit button:")
                        .multilineTextAlignment(.center)
                    Button(action: {
                        // What to perform
                        // Need to look back to see how to accept healthkit authorizations
                        authorizeHealthKit { (authorized, error) in
                            
                            guard authorized else {
                                
                                let baseMessage = "HealthKit Authorization Failed"
                                
                                if let error = error {
                                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                                } else {
                                    print(baseMessage)
                                }
                                
                                return
                            }
                            
                            print("HealthKit Successfully Authorized.")
                        }
                    }) {
                        // How the button looks like
                        Text("Authorize HealthKit")
                    }
                    Text("Now, every morning just put on your watch and double tap the recovery button.")
                        .multilineTextAlignment(.center)
                    Text("Indicate using the sliding bar how you actually feel, take a screen shot, and send it to me!")
                        .multilineTextAlignment(.center)
                    Button(action: {
                        print(dataFilePath)
                        
                    }) {
                        // How the button looks like
                        Text("Find Data Path")
                    }
                    Button(action: {
                        deleteAllRecords()
                        
                    }) {
                        // How the button looks like
                        Text("Delete Array Records")
                    }
                    Button(action: {
                        deleteAllRecordsReadiness()
                        
                    }) {
                        // How the button looks like
                        Text("Delete Readiness Records")
                    }
                    Text("Version 0.1.13")
                        .multilineTextAlignment(.center)
                }
            }
            
        }
        
        func deleteAllRecords() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Array30Day")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error")
            }
        }
        
        func deleteAllRecordsReadiness() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Readiness")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error")
            }
        }
        
        func deleteAllRecordsRecovery() {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext

            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Recovery")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error")
            }
        }
    }

    //MARK: - Variables Outside HomeView (Can probably go up top?)
    var recentHRVValue = 0.0
    var recentHRVTime: Date? = nil
    var recentHRVCalculation = 0.0
//
    var newFinalHRVCalculation = 0.0
//
    var variability30DayArray = [Double]()
//
    var variability30DayArrayNoOutliers = [Double]()
    var hrvOutlierIQR = 0.0
    var hrvOutlier1Q = 0.0
    var hrvOutlier3Q = 0.0
    var hrvOutlierLowCutoff = 0.0
    var hrvOutlierHighCutoff = 0.0
//
    var hrvMax = 0.0
    var hrvMin = 0.0
    var hrv1Q = 0.0
    var hrv0_75Q = 0.0
    var hrv1_5Q = 0.0
    var hrv2_5Q = 0.0
    var hrv3_25Q = 0.0
    var hrv3Q = 0.0
    var hrvMedian = 0.0
//
    var hrvReadinessPercentage = 0.0
//
    var coreDataHRVCalculationArray = [Double]()
    var coreDataHRVTimeArray = [Date]()
    var coreDataHRVValueArray = [Double]()
//
    var coreDataHRVValue = 0.0
    var coreDataHRVTime: Date? = nil
    var coreDataHRVCalculation = 0.0
//
    var readinessColor:Color = .blue
// Active Cals
    var activeCalsAdded = 0.0
    var loadCalculation = 0.0
    var finalActivity = 0.0

///
//NEW BELOW

    var workoutStartTime: Date? = Date()
    var workoutEndTime: Date? = Date()
    
    var heartRateTimePeriod = 0.0

    var heartRateArrayForWorkout = [Double]()
    var heartRateDictionaryForWorkout = [Date: Double]()
    var sortedDictionary = OrderedDictionary<Date, Double>()

    //MARK: - HomeView Start
    struct HomeView: View {
        //Core Data SwiftUI Object Management
        @Environment(\.managedObjectContext) var managedObjectContext
        
        //MARK: - SwiftUI
        var body: some View {
            VStack {
                Text("Calculated Strain: ##.##")
                Text("Calcualted Tolerance: ##.##")
                Text("Training Load: ##.##")
                Button(action: {
                    getLastWorkout()
                }, label: {
                    Text("Test Workout")
                })
                Button(action: {
                    getHeartRatesBetweenTimesAndPutIntoDictionary()
                }, label: {
                    Text("Test HR")
                })
                Button(action: {
                    organizeWorkoutHeartRateDictionaryByTimeToDetermineHowLongEachHRWasFor()
                }, label: {
                    Text("Test Sort Dictionary by Key (Time)")
                })
                Button(action: {
                    calculateHowLongEachHRWasActiveForInDictionaryAndPutIntoNewDictionary()
                }, label: {
                    Text("Test Subtract to find How Long Each HR Was")
                })
            }
        }
        // MARK: - CRUD Functions
        func saveContext() {
            do {
                try managedObjectContext.save()
            } catch {
                print("Error saving managed object context: \(error)")
            }
        }
        //MARK: - New Core Data Manipulation
        @FetchRequest(
            entity: Readiness.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Readiness.time, ascending: false)]
        ) var coreDataItems: FetchedResults<Readiness>
        
        //MARK: - Functions to Calculate
        
        func getLastWorkout () {
            hkm.workouts(from: yesterdayStartDate, to: Date()) { (results) in
                var lastWorkout = 0
                var lastWorkoutDuration = 0.0
                var lastWorkoutStart = Date()
                var lastWorkoutEnd = Date()
                
                for result in results {
                    lastWorkout = Int(result.workoutActivityType.rawValue)
                    lastWorkoutDuration = result.duration
                    lastWorkoutStart = result.startDate
                    lastWorkoutEnd = result.endDate
                    
                }
                print("Workout Key Value: \(lastWorkout)")
                print("Workout duration in seconds: \(lastWorkoutDuration)")
                print("Workout Start time: \(lastWorkoutStart)")
                print("Workout End time: \(lastWorkoutEnd)")
                
                workoutStartTime = lastWorkoutStart
                workoutEndTime = lastWorkoutEnd
                
                print("The last workout was from \(workoutStartTime!) to \(workoutEndTime!)")
            }
        }
        
        //Now we can create a function that uses that workout start and end date to find heart rate details to calculate
        
        func getHeartRatesBetweenTimesAndPutIntoDictionary () {
            heartRateArrayForWorkout.removeAll()
            heartRateDictionaryForWorkout.removeAll()
            hkm.heartRate(from: workoutStartTime!, to: workoutEndTime!) { (results) in
                var heartRateItem = 0.0
                var heartRateTimeStart: Date? = Date()
                var heartRateTimeEnd: Date? = Date()
                var heartRateTimeDifference = ""
                
                for result in results {
                    heartRateItem = result.quantity.doubleValue(for: .heartRateUnit)
                    heartRateTimeStart = result.startDate
                    heartRateTimeEnd = result.endDate
                    
//                    let formatter = DateComponentsFormatter()
//                    formatter.allowedUnits = [.second]
//                    formatter.unitsStyle = .full
//                    heartRateTimeDifference = formatter.string(from: heartRateTimeStart ?? Date(), to: heartRateTimeEnd ?? Date()) ?? "0"
                    
                    heartRateArrayForWorkout.append(heartRateItem)
                    heartRateDictionaryForWorkout[heartRateTimeStart ?? Date()] = heartRateItem

                    //Now we need to format these dates and find the difference in seconds as an integer
                    
                }
                
                print("First Heart Rate from Tests is \(heartRateItem)")
                print("Start of HR Reading is \(heartRateTimeStart)")
                print("End of HR Reading is \(heartRateTimeEnd)")
                print("HR Array for Workout is: \(heartRateArrayForWorkout)")
                print("HR Dictionary for Workout is: \(heartRateDictionaryForWorkout)")
                print("HR TIme Difference Test is: \(heartRateTimeDifference)")
                print("Amount of Array items = \(heartRateArrayForWorkout.count)")
                print("Amount of Dictionary items = \(heartRateDictionaryForWorkout.count)")
            }
        }
        
        func organizeWorkoutHeartRateDictionaryByTimeToDetermineHowLongEachHRWasFor () {
            sortedDictionary = heartRateDictionaryForWorkout.sorted{$0.key < $1.key} //Goes up
            print(sortedDictionary)
            print(sortedDictionary.count)
            print(sortedDictionary.first?.value)
            print(sortedDictionary.first?.key)
            
            //Above all works! Puts it in order by time so no we can calculate how long each was starting with the second index!
            //Value = HR
            //Key = Time
            
            
        }
        
        func calculateHowLongEachHRWasActiveForInDictionaryAndPutIntoNewDictionary () {
            //This function is to refactor the original dictionary into a new one with the existing Hr's and time spent in each HR (previous time - current time)
            
            
            
            
            
            
            var dollarRemovedArr = [60, 40, 10, 30, 100, 50, 90, 80, 20, 70]
            var dollarRemovedArray = [50, 30, 0, 20, 90, 40, 80, 70, 10, 60]
            var outputArray = [Int]()
            
            for var index in (0 ..< dollarRemovedArr.count) {
                guard let  dollarRemovedArrayString =  dollarRemovedArray[index] as? String,let dollarRemovedArrayItem = Int(dollarRemovedArrayString),   dollarRemovedArr.count > index  else {
                    continue
                }
                outputArray.append(dollarRemovedArrayItem - dollarRemovedArr[index])

            }
            print(outputArray)
        }
        
        func organizeWorkoutHeartRateDictionaryValuesByHR () {
            
        }
        
        
        
        
    //MARK: - HomeView End
    }

    
    //MARK: - AppView to Create Tabs
    struct AppView: View {
        var body: some View {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                HomeView()
                    .preferredColorScheme(.dark)
                    .previewDevice("iPhone 12 Pro Max")
                HomeView()
                    .preferredColorScheme(.light)
                    .previewDevice("iPhone 8")
            }
        }
    }
