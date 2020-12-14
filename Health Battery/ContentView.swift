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


typealias FinishedGettingHealthData = () -> ()

//var date = NSDate()
//let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
//var lastMidnight = cal.startOfDay(for: date as Date)

//let date: Date = Date()
//let cal: Calendar = Calendar(identifier: .gregorian)
//let lastMidnight: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
var rightNow = Date()

var calendar = Calendar.current
var startDate = calendar.startOfDay(for: rightNow)
var yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
var weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
var monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)
var lastMidnight = calendar.startOfDay(for: rightNow)


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
            let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let variability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            let stepsTest = HKObjectType.quantityType(forIdentifier: .stepCount),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
        
        completion(false, HealthkitSetupError.dataTypeNotAvailable)
        return
    }
    //3. Prepare a list of types you want HealthKit to read and write
    let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
                                                    activeEnergy,
                                                    HKObjectType.workoutType()]
    
    let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                   bloodType,
                                                   biologicalSex,
                                                   bodyMassIndex,
                                                   height,
                                                   stepsTest,
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
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
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

    //MARK: - HomeView
    //MARK: - Variables
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

    struct HomeView: View {
        //Core Data SwiftUI Object Management
        @Environment(\.managedObjectContext) var managedObjectContext
        
        //State Variables
        @State private var recentHRVValueState = 0
        @State private var recentHRVTimeState: String = ""
        @State private var finalReadinessPercentage = 0
        @State private var readinessColorState:Color = .gray
        @State private var hrvMorningRecordedAlertHidden = true
        @State private var noLastHRVAlertHidden = true
        @State private var creatingBaselineAlertHidden = true
        @State private var readinessBarState = 0
        
        
        //Alert Enum
        
        
        //MARK: - SWiftui
        var body: some View {
            NavigationView {
                VStack {
                    HStack(alignment: .center) {
                        Text("Energy:")
                            .multilineTextAlignment(.center)

                        ZStack {
                            CircularProgress(
                                progress: CGFloat(readinessBarState),
                                lineWidth: 15,
                                foregroundColor: readinessColorState,
                                backgroundColor: readinessColorState.opacity(0.20)
                            ).rotationEffect(.degrees(-90)).frame(width: 150, height: 150, alignment: .center)
                            CircularProgress(
                                progress: 26,
                                lineWidth: 15,
                                foregroundColor: .gray,
                                backgroundColor: Color.gray.opacity(0.20)
                            ).rotationEffect(.degrees(-90)).frame(width: 200, height: 200, alignment: .center)
                            Circle()
                                .foregroundColor(readinessColorState)
                                    .frame(width: 85, height: 85)
                            Text("\(finalReadinessPercentage)")
                                .font(Font.largeTitle.bold())
                                .foregroundColor(.white)
                                .shadow(radius: 8)
                            
                        }
                        Text("Day Load:")
                            .multilineTextAlignment(.center)

                    }
                    Text("Last HRV Number: \(recentHRVValueState)")
                    Text("Last HRV Recorded Time: \(recentHRVTimeState)")
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                print("Moving back to the foreground!")
                            newReadinessCalculation()
                        }
                    Button(action: {
                        newReadinessCalculation()
                    }) {
                        Text("Test Button - Developer Use")
                    }.onAppear(perform: {
                        print("Recovery Appeared using OnAppear")
                        newReadinessCalculation()
                    })
                    
                    if !hrvMorningRecordedAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.orange)
                                    Text("Your Calculation is not up to date.")
                                        .font(.headline)

                                }
                                Text("The most recent Energy score is from yesterday. Go to the breathe app on your Apple Watch to update your score.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    if !creatingBaselineAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.blue)
                                    Text("Calculating Baseline")
                                        .font(.headline)
                                }
                                Text("We are currently calculating your baseline. Please wear your watch and come back regularly to see your energy levels.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    if !noLastHRVAlertHidden {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.20))
                                .frame(width: 350, height: 120)
                                .cornerRadius(10)
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.red)
                                    Text("There is no HRV Health data.")
                                        .font(.headline)
                                }
                                Text("Please wear your Watch all day and report back later to see your readiness calculation.")
                                    .frame(width: 340)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.gray.opacity(0.20))
                            .frame(width: 350, height: 120)
                            .cornerRadius(10)
                        VStack {
                            HStack {
                                Image(systemName: "info.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("You can push it hard today!")
                                    .font(.headline)
                            }
                            Text("To reach your Recommended Day Load, go on your normal 20 mile bike ride! (Work in progress, not an actual suggestion)")
                                .frame(width: 340)
                                .multilineTextAlignment(.center)
                        }
                    }
                    Text("Build 0.1.13")
                }
            }
        }
        
        // MARK: - CRUD Functions
        
        //Saves whatever we are working with
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
        
        //MARK: - Date Formatting
        func getFormattedDate(date: Date, format: String) -> String {
                let dateformat = DateFormatter()
                dateformat.dateFormat = format
                return dateformat.string(from: date)
        }
        
        //MARK: - New Functions
        func newReadinessCalculation() {
            //Where all of our functions will be put in and then called
            findNewHRVReading {
                findOldCoreDataReading {
                    compareNewAndOldData {
                        getHRVArrayFromHealth {
                            checkAmountofHRVArrayValues {
                                    removeOutliers {
                                        calculateStats {
                                            recentHRVRecoveryCalculation {
                                                compareAndCalculateNewReadinessScore {
                                                    changeReadinessColorsandText {
                                                        saveNewCalculationToCD()
                                                    }
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        
        
        
        func findNewHRVReading(_ completion : @escaping()->()) {
            hkm.variabilityMostRecent(from: weekAgoStartDate, to: Date()) { (results) in
                var lastHRV = 0.0
                var lastHRVTime: Date? = nil
                
                for result in results {
                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
                    lastHRVTime = result.startDate
                }
                
                //Revise this?
                guard lastHRV > 0.0 else {
                    print("No recent data to calculate, guard is enabled, everything stops, and alert shows")
                    self.finalReadinessPercentage = 0
                    self.noLastHRVAlertHidden = false
                    self.readinessColorState = .gray
                    return
                }
                
                self.noLastHRVAlertHidden = true
                recentHRVValue = Double(lastHRV)
                recentHRVTime = lastHRVTime
                
                if recentHRVTime! < lastMidnight {
                    hrvMorningRecordedAlertHidden = false
                } else if recentHRVTime! >= lastMidnight {
                    hrvMorningRecordedAlertHidden = true
                }
                completion()
            }
        }
        
        func findOldCoreDataReading(_ completion : @escaping()->()) {
            coreDataHRVCalculationArray = coreDataItems.map {$0.calculation}
            coreDataHRVTimeArray = coreDataItems.map {$0.time!}
            coreDataHRVValueArray = coreDataItems.map {$0.hrv}
            
            coreDataHRVValue = coreDataHRVValueArray.first ?? 0
            coreDataHRVTime = coreDataHRVTimeArray.first ?? nil
            coreDataHRVCalculation = coreDataHRVCalculationArray.first ?? 0
            
            guard coreDataHRVValue > 0 else {

                
                newFinalHRVCalculation = Double.random(in: 60...65)
                
                saveNewCalculationToCD()
                
                changeReadinessColorsandTextnoCompletion()

                
                print("There were 0 core data items, so we created a baseline to save")
                self.creatingBaselineAlertHidden = false
                return
            }
                        
            print("Last core data value: \(coreDataHRVValue)")
            print("Last core data time: \(coreDataHRVTime)")
            print("Last core data calculation: \(coreDataHRVCalculation)")
            
            completion()
        }
        
        
        
        func compareNewAndOldData(_ completion : @escaping()->()) {
            //Compares new hrv reading and old to see if they are the same and continues or doesn't\
            //This stops with guard and just sets our values to what was in our core data variables if the recent hrv and the core data items are the same, meaning that nothing new has happened
            //It will continue with calculation if our hrv from health is newer than our core data items
            
            guard recentHRVTime! > coreDataHRVTime! else {
                //They are the same time, just update @state and color variables with most recent and formatting
                changeReadinessColorsandTextCoreData()
                return
            }
            completion()
            
        }
        
        func getHRVArrayFromHealth(_ completion : @escaping()->()) {
            hkm.variability(from: monthAgoStartDate, to: Date()) { (results) in
                
                var variabilityRetrieve = 0.0
                var variabilityRetrieveArray = [Double]()
                
                for result in results {
                    variabilityRetrieve = result.quantity.doubleValue(for: .variabilityUnit)
                    variabilityRetrieveArray.append(variabilityRetrieve)
                }
                variability30DayArray = variabilityRetrieveArray
                print(variability30DayArray)
                completion()
            }
            
        }

        func checkAmountofHRVArrayValues(_ completion : @escaping()->()) {
            //When we get our array we will see how many values we have
            //If there are not 4 data points, guard, calculate and save to core data, and have blue ! warning
                     
            guard variability30DayArray.count > 3 else {
                //If variability has less than 4 values, run this
                
                //Set our newFinalHRVCalculation to random Double(int 60...65)
                
                newFinalHRVCalculation = Double.random(in: 60...65)
                
                //Save to core data using saveNewCalculationToCD
                saveNewCalculationToCD()
                
                //Run change readiness colors and text w/o completion
                changeReadinessColorsandTextnoCompletion()
                
                //Make blue notification saying we are creating baseline
                print("Less than 4 data points worth of hrv from health")
                self.creatingBaselineAlertHidden = false

                return
            }
            
            self.creatingBaselineAlertHidden = true
            
            
            
            //If we have more than 4 items, continue as normal
            
            completion()
            
        }
        
        
        func removeOutliers(_ completion : @escaping()->()) {
            hrvOutlier1Q = (Sigma.percentile(variability30DayArray, percentile: 0.25) ?? 0.0)
            hrvOutlier3Q = (Sigma.percentile(variability30DayArray, percentile: 0.75) ?? 0.0)
            
            hrvOutlierIQR = hrvOutlier3Q - hrvOutlier1Q
            
            hrvOutlierLowCutoff = hrvOutlier1Q - (1.5 * hrvOutlierIQR)
            hrvOutlierHighCutoff = hrvOutlier3Q + (1.5 * hrvOutlierIQR)
            
            variability30DayArrayNoOutliers = variability30DayArray.filter { $0 < hrvOutlierHighCutoff && $0 > hrvOutlierLowCutoff }
            
            completion()
        }
        
        func calculateStats(_ completion : @escaping()->()) {
            hrvMax = variability30DayArrayNoOutliers.max() ?? 0.0
            hrvMin = variability30DayArrayNoOutliers.min() ?? 0.0
            hrv1Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.25) ?? 0.0
            hrv0_75Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.1875) ?? 0.0
            hrv1_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.375) ?? 0.0
            hrv2_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.625) ?? 0.0
            hrv3_25Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.8125) ?? 0.0
            hrv3Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.75) ?? 0.0
            hrvMedian = Sigma.median(variability30DayArrayNoOutliers) ?? 0.0
            
            print("Max: \(hrvMax) Min: \(hrvMin) 1Q: \(hrv1Q) 3Q: \(hrv3Q) Median: \(hrvMedian) 0.75Q: \(hrv0_75Q) 1.5Q: \(hrv1_5Q) 2.5Q: \(hrv2_5Q) 3.25Q: \(hrv3_25Q)")
            
            completion()
        }
        
        func recentHRVRecoveryCalculation(_ completion : @escaping()->()) {
            //We need to calculate our hrv recovery first before apply it into our algorithm...
            
            if recentHRVValue <= hrvMin {
                recentHRVCalculation = 0.0
            } else if recentHRVValue >= hrvMax {
                recentHRVCalculation = 99.0
            } else if hrvMin <= recentHRVValue && recentHRVValue <= hrv1Q {
                recentHRVCalculation = ((((recentHRVValue - hrvMin) / (hrv1Q - hrvMin)) * 25.0) + 0.0)
            } else if hrv1Q <= recentHRVValue && recentHRVValue <= hrvMedian {
                recentHRVCalculation = ((((recentHRVValue - hrv1Q) / (hrvMedian - hrv1Q)) * 25.0) + 25.0)
            } else if hrvMedian <= recentHRVValue && recentHRVValue <= hrv3Q {
                recentHRVCalculation = ((((recentHRVValue - hrvMedian) / (hrv3Q - hrvMedian)) * 25.0) + 50.0)
            } else if hrv3Q <= recentHRVValue && recentHRVValue <= hrvMax {
                recentHRVCalculation = ((((recentHRVValue - hrv3Q) / (hrvMax - hrv3Q)) * 25.0) + 75.0)
            }
            print("Recent HRV Calculation Func run")
            completion()
        }
        
        func compareAndCalculateNewReadinessScore(_ completion : @escaping()->()) {
            //Compares our old and new data to come up with a new score\
            //Append new calculation to new calculation variable
            //Appends to "newFinalHRVCalculation"
            
            //Check where our old readiness is first, then apply new
            
            if coreDataHRVCalculation < 25 { //in red
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 68
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 70
                            }
                        } else if coreDataHRVCalculation == 25 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 43
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 69
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 71
                            }
                            
                        } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation < 40 { //in yellow
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 20
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 72
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 75
                            }

                        } else if coreDataHRVCalculation == 40 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 25
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 30
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 75
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 80
                            }

                        } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation < 65 { //in blue
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 35
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 38
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 80
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 85
                            }

                        } else if coreDataHRVCalculation == 65 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 38
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 45
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 49
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = 90
                            }
                            
                        } else if coreDataHRVCalculation > 65 && coreDataHRVCalculation < 85 { //in green
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 40
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 50
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                            
                        } else if coreDataHRVCalculation == 85 { //on gate
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 42
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                            
                        } else if coreDataHRVCalculation > 85 { //in pink
                            if recentHRVCalculation < 25 {
                                newFinalHRVCalculation = 42
                            } else if recentHRVCalculation == 25 {
                                newFinalHRVCalculation = 53
                            } else if recentHRVCalculation > 25 && recentHRVCalculation < 40 {
                                newFinalHRVCalculation = 55
                            } else if recentHRVCalculation == 40 {
                                newFinalHRVCalculation = 58
                            } else if recentHRVCalculation > 40 && recentHRVCalculation < 65 {
                                newFinalHRVCalculation = 60
                            } else if recentHRVCalculation == 65 {
                                newFinalHRVCalculation = 65
                            } else if recentHRVCalculation > 65 && recentHRVCalculation < 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            } else if recentHRVCalculation == 85 {
                                newFinalHRVCalculation = 85
                            } else if recentHRVCalculation > 85 {
                                newFinalHRVCalculation = recentHRVCalculation
                            }
                        }
            print("New HRV Calculation Func run")

            completion()
        }
        
        func changeReadinessColorsandText(_ completion : @escaping()->()) {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
            
            //Changes Colors and Bar Data
            if newFinalHRVCalculation <= 25 {
                readinessColor = .red
            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
                readinessColor = .orange
            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
                readinessColor = .blue
            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
                readinessColor = .green
            } else if newFinalHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(newFinalHRVCalculation)
            self.readinessColorState = readinessColor
            
            completion()
            
        }
        
        func saveNewCalculationToCD() {
            //Saves new calculation / data to core data with save context
            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)

            newReadinessCalculationWrite.calculation = newFinalHRVCalculation
            newReadinessCalculationWrite.hrv = recentHRVValue
            newReadinessCalculationWrite.time = recentHRVTime
            
            saveContext()
        }
        
        func saveNewCalculationToCDGuard() {
            //Saves new calculation / data to core data with save context
            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)

            newReadinessCalculationWrite.calculation = recentHRVCalculation
            newReadinessCalculationWrite.hrv = recentHRVValue
            newReadinessCalculationWrite.time = recentHRVTime
            
            saveContext()
        }
        
        func changeReadinessColorsandTextCoreData() {
            //Same as above function, but uses core data in our comparison
            
            let formattedCoreDataDate = getFormattedDate(date: coreDataHRVTime!, format: "MMM d, hh:mm a")
            
            //Changes Text
            self.recentHRVValueState = Int(coreDataHRVValue)
            self.recentHRVTimeState = String("\(formattedCoreDataDate)")
            self.finalReadinessPercentage = Int(coreDataHRVCalculation)
            
            //Changes Colors and Bar
            if coreDataHRVCalculation <= 25 {
                readinessColor = .red
            } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation <= 40 {
                readinessColor = .orange
            } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation <= 65 {
                readinessColor = .blue
            } else if coreDataHRVCalculation > 65 && coreDataHRVCalculation <= 85 {
                readinessColor = .green
            } else if coreDataHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            print("Readiness color is \(readinessColor)")
            
            self.readinessBarState = Int(coreDataHRVCalculation)
            self.readinessColorState = readinessColor
        }
        
        func changeReadinessColorsandTextnoCompletion() {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
            
            //Changes Colors and Bar Data
            if newFinalHRVCalculation <= 25 {
                readinessColor = .red
            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
                readinessColor = .orange
            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
                readinessColor = .blue
            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
                readinessColor = .green
            } else if newFinalHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(newFinalHRVCalculation)
            self.readinessColorState = readinessColor
            
        }
        
        func changeReadinessColorsandTextnoCompletionGuard() {
            //Changes the text based on our 3 new calculation variables
            //Changes the colors based on our new calculation
            
            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d, hh:mm a")

            
            //Changes Text
            self.recentHRVValueState = Int(recentHRVValue)
            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
            self.finalReadinessPercentage = Int(recentHRVCalculation)
            
            //Changes Colors and Bar Data
            if recentHRVCalculation <= 25 {
                readinessColor = .red
            } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
                readinessColor = .orange
            } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
                readinessColor = .blue
            } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
                readinessColor = .green
            } else if recentHRVCalculation > 85 {
                readinessColor = .purple
            }
            
            self.readinessBarState = Int(recentHRVCalculation)
            self.readinessColorState = readinessColor
            
        }
        
        
        
    }



    //MARK: - Readiness View
    struct EnergyView: View {
        var body: some View {
            VStack {
                HStack {
                    VStack {
                        Text("75")
                            .font(.title).bold()
                            .foregroundColor(.green)
                        Text("Energy")
                            .fontWeight(.heavy)
                            .foregroundColor(.green)
                    }
                    LinearProgress(
                        progress: 75,
                      foregroundColor: .green,
                        backgroundColor: Color.green.opacity(0.2),
                      fillAxis: .vertical
                    )
                    .frame(width: 60, height: 100)
                    ZStack {
                        LinearProgress(
                            progress: 20,
                            foregroundColor: .secondary,
                            backgroundColor: Color.secondary.opacity(0.20),
                          fillAxis: .vertical
                        )
                        .frame(width: 60, height: 100)
                        
                        LinearProgress(
                            progress: 50,
                            foregroundColor: Color.secondary.opacity(0.35),
                            backgroundColor: .clear,
                          fillAxis: .vertical
                        )
                        .frame(width: 60, height: 100)
                    }
                    VStack {
                        Text("8.9")
                            .font(.title).bold()
                            .foregroundColor(.secondary)
                        Text("Day Load")
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)

                    }
                }
                HStack {
                    Text("You are at a 8.9 Day Load out of a suggested 13 Day Load for the day.")
                        .multilineTextAlignment(.center)
                }
                
                
            }
            }
    }

//MARK: - Body Load View
struct LoadView: View {
    var body: some View {
        NavigationView {
            Text("More detailed information about your Body Load will be available here.")
                .multilineTextAlignment(.center)

        }
    }
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
                EnergyView()
                    .tabItem {
                        Image(systemName: "battery.100")
                        Text("Energy")
                    }
                LoadView()
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text("Load")
                    }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Get Started")
                    }
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                AppView()
                    .preferredColorScheme(.dark)
                    .previewDevice("iPhone 12 mini")
            }
        }
    }
