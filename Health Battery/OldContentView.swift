////Last update:
////Sees the last HRV and RHR recordings during today(s) time frame and reports it in text fields. THis would glitch if there are multiple reportings in a day as it would see all recordings that day, instead of just the most recent one.
//
//import Foundation
//import HealthKit
//import UIKit
//import SwiftUI
//import CoreData
//import Dispatch
//import SwiftProgress
//import PZCircularControl
//import SwiftUICharts
//import ActivityIndicatorView
//import OrderedDictionary
//
//let delegate = UIApplication.shared.delegate as! AppDelegate
//
//let hkm = HealthKitManager()
//
//var arrayVariability7Day2 = [Double]()
//var arrayRHR7Day2 = [Double]()
//var mostRecentHRV = 0.0
//var mostRecentRHR = 0.0
//var max7DayHRV = 0.0
//var min7DayHRV = 0.0
//var max7DayRHR = 0.0
//var min7DayRHR = 0.0
//var recoveryRHRPercentageValue = 0.0
//var recoveryHRVPercentageValue = 0.0
//var finalRecoveryPercentageValue = 0.0
////Bar Data
//var barColor:Color = .yellow
//
////Check Variables
//var checkHRVAlert = 0
//var baselineDaysLeft = 0
//var baselineDays = 3
//
//    //Array
//var arrayHRV = [Double]()
//var arrayRHR = [Double]()
//var arrayNumbers = [NSManagedObject]()
//    //Recent
//var recentHRV = 0.0
//var recentRHR = 0.0
//var arrayHRVDone = false
//var arrayRHRDone = false
//    // Array's with outliers removed
//var recentHRVNoOutlierArray = [Double]()
//var initialHRVIQR = 0.0
//var initialHRV1q = 0.0
//var initialHRV3q = 0.0
//var initialHRVLowOutlierCutoff = 0.0
//var initialHRVHighOutlierCutoff = 0.0
//
//    // Min/Max/1q/3q/avg HRV
//var maxHRV = 0.0
//var minHRV = 0.0
//var q1HRV = 0.0
//var q3HRV = 0.0
//var avgHRV = 0.0
//var sumHRV = 0.0
//var medianHRV = 0.0
//    // Min/Max RHR
//var maxRHR = 0.0
//var minRHR = 0.0
//var minHRVDone = false
//var maxHRVDone = false
//var minRHRDone = false
//var maxRHRDone = false
//    // HRV/RHR Calculation
//var hrvRecoveryPercentage = 0.0
//var rhrRecoveryPercentage = 0.0
//var hrvPercentageDone = false
//var rhrPercentageDone = false
//    // Final Calculation
//var finalRecoveryPercentage2 = 0.0
//var finalRecoveryIndicator = false
//    // Loading Last Recovery
//var lastRecoveryArray = [Double]()
//var lastHRVValueArray = [Double]()
//var lastRHRValueArray = [Double]()
//var lastHRVPercentArray = [Double]()
//var lastRHRPercentArray = [Double]()
//var lastRecoveryVar = 0.0
//var lastHRVVar = 0.0
//var lastRHRVar = 0.0
//var lastHRVPercentVar = 0.0
//var lastRHRPercentVar = 0.0
//    // Core Data Check
//var hasRecoveryHappened = [Double]()
//var howManyRecoveries = [Double]()
//    //Energy View
//var coreDataDictionary = [[Date]:[Double]]()
//var coreDataTimeArray = [Date]()
//var coreDataCalculationArray = [Double]()
//var coreDataTodayTimeArray = [Date]()
//var coreDataTodayCalculationArray = [Double]()
////
//var activeEnergyArrayEachHour = [Double]()
//var activeEnergyRetrieveArrayAdded = 0.0
//
//var earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(0) //Starts at midnight
//var lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(120) //Starts 1 hour after midnight
//var hourAfter = calendar.startOfDay(for: rightNow).addingTimeInterval(120)
//
//var earlyTimeInterval = 0
//var lateTimeInterval = 120
//
//var arrayTest = [Double]()
//var basalArray = [Double]()
//var finalActivityArrayPerTime = [Double]()
//
//var heartRateArray = [Double]()
//var heartRateRatioArray = [Double]()
//
//private let userHealthProfile = UserHealthProfile()
//
//var age = 0
//
//
//
//precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
//infix operator ^^ : PowerPrecedence
//func ^^ (radix: Int, power: Int) -> Int {
//    return Int(pow(Double(radix), Double(power)))
//}
//
//typealias FinishedGettingHealthData = () -> ()
//
////var date = NSDate()
////let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
////var lastMidnight = cal.startOfDay(for: date as Date)
//
////let date: Date = Date()
////let cal: Calendar = Calendar(identifier: .gregorian)
////let lastMidnight: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
//var rightNow = Date()
//
//let date = Date()
//let dateFormatter = DateFormatter()
//
//var calendar = Calendar.current
//var startDate = calendar.startOfDay(for: rightNow)
//var yesterdayStartDate = calendar.startOfDay(for: Date.yesterday)
//var weekAgoStartDate = calendar.startOfDay(for: Date.weekAgo)
//var monthAgoStartDate = calendar.startOfDay(for: Date.monthAgo)
//var lastMidnight = calendar.startOfDay(for: rightNow)
//
//var lastMidnightFormatted = dateFormatter.string(from: lastMidnight)
//
//
//private enum HealthkitSetupError: Error {
//    case notAvailableOnDevice
//    case dataTypeNotAvailable
//}
//
//func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
//    //1. Check to see if HealthKit Is Available on this device
//    guard HKHealthStore.isHealthDataAvailable() else {
//        completion(false, HealthkitSetupError.notAvailableOnDevice)
//        return
//    }
//    //2. Prepare the data types that will interact with HealthKit
//    guard   let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
//            let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
//            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
//            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
//            let height = HKObjectType.quantityType(forIdentifier: .height),
//            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
//            let variability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
//            let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
//            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
//            let stepsTest = HKObjectType.quantityType(forIdentifier: .stepCount),
//            let basalEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
//            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
//
//        completion(false, HealthkitSetupError.dataTypeNotAvailable)
//        return
//    }
//    //3. Prepare a list of types you want HealthKit to read and write
//    let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
//                                                    activeEnergy,
//                                                    HKObjectType.workoutType()]
//
//    let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
//                                                   bloodType,
//                                                   activeEnergy,
//                                                   basalEnergy,
//                                                   biologicalSex,
//                                                   bodyMassIndex,
//                                                   heartRate,
//                                                   height,
//                                                   stepsTest,
//                                                   variability,
//                                                   restingHR,
//                                                   bodyMass,
//                                                   HKObjectType.workoutType()]
//    //4. Request Authorization
//    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
//                                         read: healthKitTypesToRead) { (success, error) in
//        completion(success, error)
//    }
//
//}
//
//extension Date {
//    static var yesterday: Date { return rightNow.dayBefore }
//    static var tomorrow:  Date { return rightNow.dayAfter }
//    static var weekAgo: Date { return rightNow.weekAgo }
//    static var monthAgo: Date { return rightNow.monthAgo }
//    static var hourAgo: Date { return rightNow.hourBefore }
//    var dayBefore: Date {
//        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
//    }
//    var hourBefore: Date {
//        return Calendar.current.date(byAdding: .hour, value: -1, to: self)!
//    }
//    var hourAfter: Date {
//        return Calendar.current.date(byAdding: .hour, value: 1, to: self)!
//    }
//    var dayAfter: Date {
//        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
//    }
//    var weekAgo: Date {
//        return Calendar.current.date(byAdding: .day, value: -7, to: noon)!
//    }
//    var monthAgo: Date {
//        return Calendar.current.date(byAdding: .month, value: -1, to: noon)!
//    }
//    var noon: Date {
//        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
//    }
//    var month: Int {
//        return Calendar.current.component(.month,  from: self)
//    }
//    var isLastDayOfMonth: Bool {
//        return dayAfter.month != month
//    }
//    func to(timeZone outputTimeZone: TimeZone, from inputTimeZone: TimeZone) -> Date {
//         let delta = TimeInterval(outputTimeZone.secondsFromGMT(for: self) - inputTimeZone.secondsFromGMT(for: self))
//         return addingTimeInterval(delta)
//    }
//
//}
//extension DateFormatter {
//    func date(from string: String, timeZoneInString: TimeZone, outputTimeZone: TimeZone = .autoupdatingCurrent) -> Date? {
//        date(from: string)?.to(timeZone: outputTimeZone, from: timeZoneInString)
//    }
//}
//
//    //MARK: - SettingsView
//    struct SettingsView: View {
//
//        let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//
//        var body: some View {
//            NavigationView {
//                VStack {
//                    Text("When loading the application for the first time, press the Authorize Healthkit button:")
//                        .multilineTextAlignment(.center)
//                    Button(action: {
//                        // What to perform
//                        // Need to look back to see how to accept healthkit authorizations
//                        authorizeHealthKit { (authorized, error) in
//
//                            guard authorized else {
//
//                                let baseMessage = "HealthKit Authorization Failed"
//
//                                if let error = error {
//                                    print("\(baseMessage). Reason: \(error.localizedDescription)")
//                                } else {
//                                    print(baseMessage)
//                                }
//
//                                return
//                            }
//
//                            print("HealthKit Successfully Authorized.")
//                        }
//                    }) {
//                        // How the button looks like
//                        Text("Authorize HealthKit")
//                    }
//                    Text("Now, every morning just put on your watch and double tap the recovery button.")
//                        .multilineTextAlignment(.center)
//                    Text("Indicate using the sliding bar how you actually feel, take a screen shot, and send it to me!")
//                        .multilineTextAlignment(.center)
//                    Button(action: {
//                        print(dataFilePath)
//
//                    }) {
//                        // How the button looks like
//                        Text("Find Data Path")
//                    }
//                    Button(action: {
//                        deleteAllRecords()
//
//                    }) {
//                        // How the button looks like
//                        Text("Delete Array Records")
//                    }
//                    Button(action: {
//                        deleteAllRecordsReadiness()
//
//                    }) {
//                        // How the button looks like
//                        Text("Delete Readiness Records")
//                    }
//                    Text("Version 0.1.13")
//                        .multilineTextAlignment(.center)
//                }
//            }
//
//        }
//
//        func deleteAllRecords() {
//            let delegate = UIApplication.shared.delegate as! AppDelegate
//            let context = delegate.persistentContainer.viewContext
//
//            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Array30Day")
//            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//
//            do {
//                try context.execute(deleteRequest)
//                try context.save()
//            } catch {
//                print ("There was an error")
//            }
//        }
//
//        func deleteAllRecordsReadiness() {
//            let delegate = UIApplication.shared.delegate as! AppDelegate
//            let context = delegate.persistentContainer.viewContext
//
//            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Readiness")
//            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//
//            do {
//                try context.execute(deleteRequest)
//                try context.save()
//            } catch {
//                print ("There was an error")
//            }
//        }
//
//        func deleteAllRecordsRecovery() {
//            let delegate = UIApplication.shared.delegate as! AppDelegate
//            let context = delegate.persistentContainer.viewContext
//
//            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Recovery")
//            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//
//            do {
//                try context.execute(deleteRequest)
//                try context.save()
//            } catch {
//                print ("There was an error")
//            }
//        }
//    }
//
//    //MARK: - HomeView
//    //MARK: - Variables
//    var recentHRVValue = 0.0
//    var recentHRVTime: Date? = nil
//    var recentHRVCalculation = 0.0
////
//    var newFinalHRVCalculation = 0.0
////
//    var variability30DayArray = [Double]()
////
//    var variability30DayArrayNoOutliers = [Double]()
//    var hrvOutlierIQR = 0.0
//    var hrvOutlier1Q = 0.0
//    var hrvOutlier3Q = 0.0
//    var hrvOutlierLowCutoff = 0.0
//    var hrvOutlierHighCutoff = 0.0
////
//    var hrvMax = 0.0
//    var hrvMin = 0.0
//    var hrv1Q = 0.0
//    var hrv0_75Q = 0.0
//    var hrv1_5Q = 0.0
//    var hrv2_5Q = 0.0
//    var hrv3_25Q = 0.0
//    var hrv3Q = 0.0
//    var hrvMedian = 0.0
////
//    var hrvReadinessPercentage = 0.0
////
//    var coreDataHRVCalculationArray = [Double]()
//    var coreDataHRVTimeArray = [Date]()
//    var coreDataHRVValueArray = [Double]()
////
//    var coreDataHRVValue = 0.0
//    var coreDataHRVTime: Date? = nil
//    var coreDataHRVCalculation = 0.0
////
//    var readinessColor:Color = .blue
//// Active Cals
//    var activeCalsAdded = 0.0
//    var loadCalculation = 0.0
//    var finalActivity = 0.0
//
//    struct HomeView: View {
//        //Core Data SwiftUI Object Management
//        @Environment(\.managedObjectContext) var managedObjectContext
//
//        //State Variables
//        @State private var recentHRVValueState = 0
//        @State private var recentHRVTimeState: String = ""
//        @State private var finalReadinessPercentage = 0
//        @State private var readinessColorState:Color = .gray
//        @State private var hrvMorningRecordedAlertHidden = true
//        @State private var noLastHRVAlertHidden = true
//        @State private var creatingBaselineAlertHidden = true
//        @State private var readinessBarState = 0
//        @State private var activeCalsState = 0.0
//        @State private var showLoadingIndicator = false
//        @State private var scale: CGFloat = 0
//        @State private var rotation: Double = 0
//        //
//        @State private var updatedTextColor:Color = .primary
//        //
//        @State private var alertTextHidden = true
//        @State private var recommendationTextHidden = false
//        @State private var alertText = ""
//        @State private var recommendationTitle = ""
//        @State private var recommendationText = ""
//        @State private var recommendationTextColor:Color = .primary
//        //
//        @State private var activityArrayAddedState = 0.0
//
//
//
//        //Alert Enum
//
//
//        //MARK: - SWiftui
//        var body: some View {
//            GeometryReader{ geometry in
//                VStack {
//                    VStack {
//                        HStack {
//                           Spacer()
//                           VStack {
//                               VStack {
//                                   Text("\(finalReadinessPercentage)")
//                                       .font(.title).bold()
//                                       .foregroundColor(readinessColorState)
//                                       .frame(width: geometry.size.width * 0.33 - 30, alignment: .trailing)
//                                       .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//                                                                       print("Moving back to the foreground!")
//                                           print("Right now is: \(Date())")
//                                           print("Last Midnight is: \(lastMidnight)")
//                                            rightNow = Date()
//                                            lastMidnight = calendar.startOfDay(for: rightNow)
//                                                                   //finalLoadFunction()
//                                                                    finalActivityFunction()
//                                                                   newReadinessCalculation()
//                                                               }
//                                       .onAppear(perform: {
//                                                               print("Recovery Appeared using OnAppear")
//                                        rightNow = Date()
//                                        lastMidnight = calendar.startOfDay(for: rightNow)
//                                                               //finalLoadFunction()
//                                                                finalActivityFunction()
//                                                               newReadinessCalculation()
//                                                           })
//                                   Text("Energy")
//                                       .fontWeight(.heavy)
//                                       .foregroundColor(readinessColorState)
//                                       .frame(width: geometry.size.width * 0.33 - 30, alignment: .trailing)
//                                       //.multilineTextAlignment(.leading)
//                               }.frame(height: 60)
//                               Text("Updated")
//                                .font(.caption)
//                                .foregroundColor(updatedTextColor)
//                                .frame(width: geometry.size.width * 0.33 - 30, alignment: .trailing)
//                               Text("\(recentHRVTimeState)")
//                                .font(.caption)
//                                .foregroundColor(updatedTextColor)
//                                .frame(width: geometry.size.width * 0.33 - 30, alignment: .trailing)
//                                   }
//                           Spacer()
//                           ZStack {
//                               ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .growingCircle)
//                                   .foregroundColor(Color(UIColor.systemTeal))
//                                   .frame(width: geometry.size.width * 0.10, height: geometry.size.width * 0.10)
//                                   CircularProgress(
//                                       progress: CGFloat((activeCalsState/21)*100),
//                                       lineWidth: 15,
//                                       foregroundColor: Color(UIColor.systemTeal),
//                                       backgroundColor: Color(UIColor.systemTeal).opacity(0.20)
//                                   ).rotationEffect(.degrees(-90)).frame(width: geometry.size.width * 0.38, height: geometry.size.height * 0.20, alignment: .center)
//   //                                .rotationEffect(.degrees(rotation))
//   //                                .onAppear {
//   //                                    self.rotation = 0
//   //                                    withAnimation(Animation.timingCurve(0.5, 0.15, 0.25, 1, duration: 4)) {
//   //                                        self.rotation = 360
//   //                                    }
//   //                                }
//                               CircularProgress(
//                                   progress: CGFloat(readinessBarState),
//                                   lineWidth: 15,
//                                   foregroundColor: readinessColorState,
//                                   backgroundColor: readinessColorState.opacity(0.20)
//                               ).rotationEffect(.degrees(-90)).frame(width: geometry.size.width * 0.25, height: geometry.size.height * 0.20, alignment: .center)
//                           }
//                           Spacer()
//                            VStack {
//                                VStack {
//                                    Text("\(activeCalsState, specifier: "%.1f")")
//                                        .font(.title).bold()
//                                        .foregroundColor(Color(UIColor.systemTeal))
//                                        .frame(width: geometry.size.width * 0.33 - 30, alignment: .leading)
//                                        .multilineTextAlignment(.center)
//
//                                    Text("Activity")
//                                        .fontWeight(.heavy)
//                                        .foregroundColor(Color(UIColor.systemTeal))
//                                        .frame(width: geometry.size.width * 0.33 - 30, alignment: .leading)
//                                        .multilineTextAlignment(.center)
//
//                                }.frame(height: 60)
//                                Text("Day Calories")
//                                    .font(.caption)
//                                    .frame(width: geometry.size.width * 0.33 - 30, alignment: .leading)
//                                Text("xxxx")
//                                    .font(.caption)
//                                    .frame(width: geometry.size.width * 0.33 - 30, alignment: .leading)
//                            }
//
//                           Spacer()
//                       }
//                        Text("\(recommendationTitle)")
//                            .font(.title).bold()
//                            .foregroundColor(recommendationTextColor)
//                            .frame(width: geometry.size.width * 0.90)
//                            .multilineTextAlignment(.center)
////                        Text("With an Energy Level of XX, Load your body XX.X more points to reach your recommended Day Load of XX.X")
//                        Button(action: {
//                            finalActivityFunction()
//                        }) {
//                            // How the button looks like
//                            Text("TEST")
//                        }
//                        if !alertTextHidden {
//                            Text("\(alertText)")
//                                .font(.footnote)
//                                .frame(width: geometry.size.width * 0.90, height: 70)
//                                .multilineTextAlignment(.center)
//                        }
//                        if !recommendationTextHidden {
//                            Text("With an Energy Level of \(finalReadinessPercentage), your recommended Day Activity is XX.X")
//                                .font(.footnote)
//                                .frame(width: geometry.size.width * 0.90, height: 70)
//                                .multilineTextAlignment(.center)
//                        }
//
//                    }.frame(width: geometry.size.width, height: geometry.size.height / 2, alignment: .center)
//                    Spacer()
//
//
//                    VStack {
//                        HStack {
//                            Spacer()
//                            Text("Strain: \(activityArrayAddedState)")
////                            if !hrvMorningRecordedAlertHidden {
////                                ZStack {
////                                    Rectangle()
////                                        .foregroundColor(Color.gray.opacity(0.20))
////                                        .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                        .cornerRadius(10)
////                                    VStack {
////                                        HStack {
////                                            Image(systemName: "exclamationmark.triangle")
////                                                .resizable()
////                                                .frame(width: 25, height: 25)
////                                                .foregroundColor(.orange)
////                                            Text("Your Calculation is not up to date.")
////                                                .font(.headline)
////
////                                        }
////                                        Text("The most recent Energy score is from yesterday. Go to the breathe app on your Apple Watch to update your score.")
////                                            .frame(width: geometry.size.width * 0.85)
////                                            .multilineTextAlignment(.center)
////                                    }
////                                }
////                            }
//
////                            if !creatingBaselineAlertHidden {
////                                ZStack {
////                                    Rectangle()
////                                        .foregroundColor(Color.gray.opacity(0.20))
////                                        .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                        .cornerRadius(10)
////                                    VStack {
////                                        HStack {
////                                            Image(systemName: "exclamationmark.triangle")
////                                                .resizable()
////                                                .frame(width: 25, height: 25)
////                                                .foregroundColor(.blue)
////                                            Text("Calculating Baseline")
////                                                .font(.headline)
////                                        }
////                                        Text("We are currently calculating your baseline. Please wear your watch and come back regularly to see your energy levels.")
////                                            .frame(width: geometry.size.width * 0.87)
////                                            .multilineTextAlignment(.center)
////                                    }
////                                }
////                            }
//
////                            if !noLastHRVAlertHidden {
////                                ZStack {
////                                    Rectangle()
////                                        .foregroundColor(Color.gray.opacity(0.20))
////                                        .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                        .cornerRadius(10)
////                                    VStack {
////                                        HStack {
////                                            Image(systemName: "exclamationmark.triangle")
////                                                .resizable()
////                                                .frame(width: 25, height: 25)
////                                                .foregroundColor(.red)
////                                            Text("There is no HRV Health data.")
////                                                .font(.headline)
////                                        }
////                                        Text("Please wear your Watch all day and report back later to see your readiness calculation.")
////                                            .frame(width: geometry.size.width * 0.85)
////                                            .multilineTextAlignment(.center)
////                                    }
////                                }
////                            }
//                            //
//                            Spacer()
//                        }
//
//                    }
//
//                    .frame(width: geometry.size.width, height: geometry.size.height / 2, alignment: .center)
//                }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
//            }
//        }
//
//        // MARK: - CRUD Functions
//
//        //Saves whatever we are working with
//        func saveContext() {
//            do {
//                try managedObjectContext.save()
//            } catch {
//                print("Error saving managed object context: \(error)")
//            }
//        }
//
//        //MARK: - New Core Data Manipulation
//        @FetchRequest(
//            entity: Readiness.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \Readiness.time, ascending: false)]
//        ) var coreDataItems: FetchedResults<Readiness>
//
//        //MARK: - Date Formatting
//        func getFormattedDate(date: Date, format: String) -> String {
//                let dateformat = DateFormatter()
//                dateformat.dateFormat = format
//                return dateformat.string(from: date)
//        }
//
//        //MARK: - New Load Functions
//
//
//        func testNewDateFunction() {
//
////            let date = Date()
////            let dateFormatter = DateFormatter()
////            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
////            let str = dateFormatter.string(from: date)
//
//            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
//
//            let str = dateFormatter.string(from: lastMidnight)
//
//            print(str)
//            print(lastMidnightFormatted)
//
//            //This works because we use our date formatter in the function
//
//
//
//        }
//
//        func finalActivityFunction() {
//            getHeartRatesTest1 {
//                DispatchQueue.main.async {
//                    saveNewActivityCalculationToCD()
//                }
//            }
//        }
//
//
//        func finalLoadFunction() {
//            initialActiveEnergyArray {
//                DispatchQueue.main.async {
//                    saveNewLoadCalculationToCD()
//                }
//            }
//        }
//
//        func activeEnergyFinalFunctionTest() {
//            activeEnergyEveryHour {
//                    //This runs after the while loop goes for 12 or so times?
//                    print("Why doesnt this run?")
//
//                    let testFinalLoadForDay = activeEnergyArrayEachHour.reduce(0, +)
//                    print("Test Final Load: \(testFinalLoadForDay)")
//            }
//        }
//
//
//        func requestItemsTest(_ completion : @escaping()->()) {
//                //This is working now... I think... NOPE
//                //Need to reset array each time
//
//            hkm.activeEnergy(from: earlyTime, to: lateTime) { (results) in
//                var activeEnergyRetrieveArray = [Double]()
//                var activeEnergyRetrieve = 0.0
//                var activeEnergyTimeEndRetrieve: Date? = nil
//                var orderedDictionary: OrderedDictionary<Date, Double> = [:]
//
//                for result in results {
//                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
//                    activeEnergyTimeEndRetrieve = result.endDate
//                    //var orderedDictionary: OrderedDictionary<Date, Double> = [activeEnergyTimeEndRetrieve!: activeEnergyRetrieve]
//                    orderedDictionary[activeEnergyTimeEndRetrieve!] = activeEnergyRetrieve
//                }
//                print(activeEnergyRetrieveArray)
//                let activeEnergyArrayAdded = activeEnergyRetrieveArray.reduce(0, +)
//                print("Active Energy Array Added: \(activeEnergyArrayAdded)")
//                //This is where it appends to our total array
//                //Everytime this loop runs, it clears array and starts fresh
//
//                let activeEnergyPerMinute = activeEnergyArrayAdded / 10.0
//
//                activeEnergyArrayEachHour.append(activeEnergyPerMinute)
//                print("Active Energy Array Hour: \(activeEnergyArrayEachHour)")
//
//            }
//
//            //As setup, this is currently creating an array every 10 minutes since midnight that appends the calories / minute to each 10 minute period!
//            completion()
//
//
//        }
//
//        //MARK: - Get Age Functions
//
//        func getAgeAndBloodType() throws -> (age: Int, biologicalSex: HKBiologicalSex) {
//            let healthKitStore = HKHealthStore()
//
//            do {
//                let birthdayComponents = try healthKitStore.dateOfBirthComponents()
//                let biologicalSex = try healthKitStore.biologicalSex()
//
//                let today = Date()
//                let calendar = Calendar.current
//                let todayDateComponents = calendar.dateComponents([.year], from: today)
//                //This is only doing year without birthday being included.
//
//                let thisYear = todayDateComponents.year!
//                print("ThisYear = \(thisYear)")
//
//                let age = thisYear - birthdayComponents.year!
//
//                print("Birthday Year: \(birthdayComponents.year!)")
//                print("Age per get function: \(age)")
//
//                let unwrappedBiologicalSex = biologicalSex.biologicalSex
//
//                return (age, unwrappedBiologicalSex)
//            }
//        }
//
//        //MARK: - Start Heart Rate Functions
//
//        func getHeartRatesTest1(_ completion : @escaping()->()) {
//
//            self.showLoadingIndicator = true
//
//            //self.recentHRVTimeState = "Start"
//
//            rightNow = Date()
//            earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(0)
//            lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(120)
//            earlyTimeInterval = 0
//            lateTimeInterval = 120
//            heartRateArray.removeAll()
//            heartRateRatioArray.removeAll()
//
//
//            do {
//                let userAgeSexAndBloodType = try getAgeAndBloodType()
//                userHealthProfile.age = userAgeSexAndBloodType.age
//                userHealthProfile.biologicalSex = userAgeSexAndBloodType.biologicalSex
//                age = userHealthProfile.age ?? 0
//
//            } catch let error {
//                print(error)
//            }
//
//            hkm.heartRate(from: lastMidnight, to: rightNow) { (results) in
//                var recentHRRetrieve = 0.0
//                var recentHRTimeStartRetrieve: Date? = nil
//                var recentHRTimeEndRetrieve: Date? = nil
//                var allHRArray = [Double]()
//                var hrDictionary = [Date:Double]()
//
//                for result in results {
//                    recentHRRetrieve = result.quantity.doubleValue(for: .heartRateUnit)
//                    recentHRTimeStartRetrieve = result.startDate
//                    recentHRTimeEndRetrieve = result.endDate
//                    allHRArray.append(recentHRRetrieve)
//                    hrDictionary[recentHRTimeEndRetrieve!] = recentHRRetrieve
//                    print("Recent HR Value:\(recentHRRetrieve)")
//                    print("Recent HR Value Start Time:\(recentHRTimeStartRetrieve)")
//                    print("Recent HR Value End Time:\(recentHRTimeEndRetrieve)")
//
//                }
//                print("All HR array: \(allHRArray)")
//                print("All HR dictionary: \(hrDictionary)") //Not in order since its a dictionary
//
//                while lateTime < rightNow {
//
//                    let filtered = hrDictionary.filter { $0.key >= earlyTime && $0.key <= lateTime }
//
//                    let values = filtered.values
//
//                    let valuesSum = values.reduce(0, +)
//
//                    let valuesAverage = valuesSum / Double(values.count)
//
//                    if filtered.isEmpty {
//
//                        let twoMinsBefore = earlyTime - 120
//                        let twoMinsAfter = lateTime + 120
//
//                        let twoMinsBeforeValues = hrDictionary.filter { $0.key >= twoMinsBefore && $0.key <= earlyTime }
//                        let twoMinsAfterValues = hrDictionary.filter { $0.key >= lateTime && $0.key <= twoMinsAfter }
//
//                        if twoMinsBeforeValues.isEmpty || twoMinsAfterValues.isEmpty {
//
//                            //Max HR = 211 - (0.64 * Age(26))
//                            //Average HR for me is 70, which is 40% max
//                            //MARK: - ANSWER THIS
//                            //Maybe dont do this? Just apply 0?
//                            //let averageHR = (211 - (0.64 * 26)) * 0.40
//                            //heartRateArray.append(averageHR)
//                            heartRateArray.append(0.0)
//
//                            //Append to ratio array a value of 0
//                            heartRateRatioArray.append(0.0028)
//
//                        } else {
//                            let earlyValues = twoMinsBeforeValues.values
//                            let lateValues = twoMinsAfterValues.values
//
//                            let earlyValueSum = earlyValues.reduce(0, +)
//                            let lateValueSum = lateValues.reduce(0, +)
//
//                            let earlyValueAverage = earlyValueSum / Double(earlyValues.count)
//                            let lateValueAverage = lateValueSum / Double(lateValues.count)
//
//                            let newValueAveraged = (earlyValueAverage + lateValueAverage) / 2
//
//                            heartRateArray.append(newValueAveraged)
//
//                            //Append to ratio array a value based on where newvalueaveraged is in an if then statement accoring to max HR
//                            let maxHR = 211 - (0.64 * Double(age))
//                            print("Max HR is: \(maxHR)")
//                            let percentOfMax = newValueAveraged / maxHR
//
//                            if percentOfMax <= 0.35 {
//                                heartRateRatioArray.append(0.0028)
//                            } else if percentOfMax > 0.35 && percentOfMax <= 0.45 {
//                                heartRateRatioArray.append(0.0066)
//                            } else if percentOfMax > 0.46 && percentOfMax <= 0.55 {
//                                heartRateRatioArray.append(0.013)
//                            } else if percentOfMax > 0.56 && percentOfMax <= 0.65 {
//                                heartRateRatioArray.append(0.230)
//                            } else if percentOfMax > 0.66 && percentOfMax <= 0.75 {
//                                heartRateRatioArray.append(0.375)
//                            } else if percentOfMax > 0.76 && percentOfMax <= 0.85 {
//                                heartRateRatioArray.append(0.575)
//                            } else if percentOfMax > 0.86 {
//                                heartRateRatioArray.append(1.0)
//                            }
//                        }
//
//                        // if twoMinsBeforeValues.isEmpty OR twoMinsAfterValues.isEmpty
//                        // then append 0.0
//                        //else
//                        //Find average and append
//
//
//
//                        //Check the number 2 minutes earlier
//                        //Check number 2 minutes later
//                        //If any of these numbers have a 0, or nil, don't calculate and just put 0.0
//                        //If they do have numbers or values, then find the average and append!
//                        //This is where we find the below and above and create an average?
//                        //If no below and above...?
//                        //Maybe if nothing, we look at below and above, if there are 2 numbers to divide, then we do it
//                        //Else if there is a 0 within those neighboring, we just do 0.0, most likely this means the watrch was off and isnt just lack of data in the 2 minute period
//                    } else {
//                        heartRateArray.append(valuesAverage)
//
//                        //Append to ratio array a value based on where valuesaverage is in an if then statement according to max HR
//                        let maxHR = 211 - (0.64 * Double(age))
//                        print("Max HR is: \(maxHR)")
//                        let percentOfMax = valuesAverage / maxHR
//
//                        if percentOfMax <= 0.35 {
//                            heartRateRatioArray.append(0.0028)
//                        } else if percentOfMax > 0.35 && percentOfMax <= 0.45 {
//                            heartRateRatioArray.append(0.0066)
//                        } else if percentOfMax > 0.46 && percentOfMax <= 0.55 {
//                            heartRateRatioArray.append(0.013)
//                        } else if percentOfMax > 0.56 && percentOfMax <= 0.65 {
//                            heartRateRatioArray.append(0.230)
//                        } else if percentOfMax > 0.66 && percentOfMax <= 0.75 {
//                            heartRateRatioArray.append(0.375)
//                        } else if percentOfMax > 0.76 && percentOfMax <= 0.85 {
//                            heartRateRatioArray.append(0.575)
//                        } else if percentOfMax > 0.86 {
//                            heartRateRatioArray.append(1.0)
//                        }
//
//
//                    }
//
//
//
//                    earlyTimeInterval += 120
//
//                    lateTimeInterval += 120
//
//                    earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
//                    lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
//                    print("Late Time: \(lateTime)")
//                    print("Right Now: \(rightNow)")
//
//                }
//                print("Heart Rate Array: \(heartRateArray)")
//                print("Ratio Array: \(heartRateRatioArray)")
//                //self.recentHRVTimeState = "End"
//                print("Heart Rate Array Count: \(heartRateArray.count)")
//                print("Heart Rate Ratio Array Count: \(heartRateRatioArray.count)")
//
//                let arrayRatioSum = heartRateRatioArray.reduce(0, +)
//                print("Ratio Sum: \(arrayRatioSum)")
//
//                //let strain = 21.94158 + (1.275316 - 21.94158) / (1.0 + (pow(Double((arrayRatioSum/18.99556))), Double(1.062108)))
////                let strain1 =
////                let strain2 =
//                finalActivity = (21.94158 + ((1.275316 - 21.94158)) / ((1.0) + (pow(Double(arrayRatioSum/18.99556),Double(1.062108)))))
//                let powTest = pow(Double(2),Double(3))
//                print(powTest)
//                print("Strain: \(finalActivity)")
//                print("Age is: \(age)")
//                self.activityArrayAddedState = finalActivity
//                self.activeCalsState = finalActivity
//                self.showLoadingIndicator = false
//
//                completion()
//            }
//
//        }
//
//
//        //MARK: - End Heart Rate Functions
//
//        func finalActiveandBasalTest() {
//            basalEnergyTest {
//                activeEnergytoActivityTest {
//                    finalArrayCalculation {
//                        finalArrayAddedTogether()
//                    }
//                }
//            }
//
//        }
//
//        func finalArrayCalculation(_ completion : @escaping()->()) {
//            finalActivityArrayPerTime = zip(arrayTest, basalArray).map {
//                if $0 == $1 {
//                    return 0.0
//                } else {
//                    return $0 / ($0 + $1)
//                }
//            }
//            print("Final Activity Array: \(finalActivityArrayPerTime)")
//            completion()
//        }
//
//        func finalArrayAddedTogether() {
//
//            let finalActivityArrayAdded = finalActivityArrayPerTime.reduce(0, +)
//
//            activityArrayAddedState = finalActivityArrayAdded
//
//            print(finalActivityArrayAdded)
//
//        }
//
//        func basalEnergyTest(_ completion : @escaping()->()) {
//
//            rightNow = Date()
//            earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(0)
//            lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(3600)
//            earlyTimeInterval = 0
//            lateTimeInterval = 3600
//            basalArray.removeAll()
//
//            hkm.basalEnergy(from: lastMidnight, to: rightNow) { (results) in
//                var basalEnergyRetrieve = 0.0
//                var basalEnergyTimeEndRetrieve: Date? = nil
//                var orderedDictionary: OrderedDictionary<Date, Double> = [:]
//                var regularDictionary = [Date:Double]()
//
//                for result in results {
//                    basalEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
//                    basalEnergyTimeEndRetrieve = result.startDate
//
//                    orderedDictionary[basalEnergyTimeEndRetrieve!] = basalEnergyRetrieve
//                    regularDictionary[basalEnergyTimeEndRetrieve!] = basalEnergyRetrieve
//                }
//                print("Ordered Basal Dictionary: \(orderedDictionary)")
//                print("Regular Basal Dictionary: \(regularDictionary)")
//
//                let sortedRegularDictionary = regularDictionary.sorted( by: { $0.0 < $1.0 })
//
//                while lateTime < rightNow {
//
//                    let filtered = regularDictionary.filter { $0.key >= earlyTime && $0.key <= lateTime }
//
//                    print(filtered)
//
//                    let values = filtered.values
//
//                    print("Values: \(values)")
//
//                    let valuesAdded = values.reduce(0, +)
//
//                    if filtered.isEmpty {
//                        basalArray.append(0.0)
//                    } else {
//                        basalArray.append(valuesAdded)
//                    }
//
//                    print("Basal Array: \(basalArray)")
//
//                    earlyTimeInterval += 3600
//
//                    lateTimeInterval += 3600
//
//                    earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
//                    lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
//                    print("Late Time: \(lateTime)")
//                    print("Right Now: \(rightNow)")
//
//                }
//                completion()
//
//            }
//
//        }
//
//        func activeEnergytoActivityTest(_ completion : @escaping()->()) {
//            //Late time is resetting to tomorrow at 0:00?
//            rightNow = Date()
//            earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(0)
//            lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(3600)
//            earlyTimeInterval = 0
//            lateTimeInterval = 3600
//            arrayTest.removeAll()
//            print("1")
//
//            hkm.activeEnergy(from: lastMidnight, to: rightNow) { (results) in
//                //var activeEnergyRetrieveArray = [Double]()
//                print("2")
//
//                var activeEnergyRetrieve = 0.0
//                var activeEnergyTimeEndRetrieve: Date? = nil
//                var orderedDictionary: OrderedDictionary<Date, Double> = [:]
//                var regularDictionary = [Date:Double]()
//
//                for result in results {
//                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
//                    activeEnergyTimeEndRetrieve = result.startDate
//                    //var orderedDictionary: OrderedDictionary<Date, Double> = [activeEnergyTimeEndRetrieve!: activeEnergyRetrieve]
//                    orderedDictionary[activeEnergyTimeEndRetrieve!] = activeEnergyRetrieve
//                    regularDictionary[activeEnergyTimeEndRetrieve!] = activeEnergyRetrieve
//                    print("3")
//
//
//                }
//                print("Ordered Dictionary: \(orderedDictionary)")
//                print("Regular Dictionary: \(regularDictionary)")
//                print(activeEnergyRetrieve)
//                print(activeEnergyTimeEndRetrieve)
//
//                print("4")
//
//                let sortedRegularDictionary = regularDictionary.sorted( by: { $0.0 < $1.0 })
//
//                print("Sorted regular dictionary: \(sortedRegularDictionary)")
//
//                print("5")
//
//                while lateTime < rightNow {
//                    print("6")
//
//                    let filtered = regularDictionary.filter { $0.key >= earlyTime && $0.key <= lateTime }
//
//                    print(filtered)
//
//                    let values = filtered.values
//                    print("Values: \(values)")
//
//
//                    let valuesAdded = values.reduce(0, +)
//
//                    if filtered.isEmpty {
//                        print("1 Early Time: \(earlyTime)")
//                        arrayTest.append(0.0)
//                        print("1 Late Time: \(lateTime)")
//
//                    } else {
//                        print("2 Early Time: \(earlyTime)")
//                        arrayTest.append(valuesAdded)
//                        print("2 Late Time: \(lateTime)")
//                    }
//                    //arrayTest has all our values!
//                    //But, when we re-initialize it... it adds the 25 to the last value only... It is taking our array and just adding the first hour... Why is that?
//                    //Something with timing each initialize...
//
//
//                    print("Array Test: \(arrayTest)")
//
//                    earlyTimeInterval += 3600
//
//                    lateTimeInterval += 3600
//
//                    earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
//                    lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
//                    print("Late Time: \(lateTime)")
//                    print("Right Now: \(rightNow)")
//
//                }//While loop
//                completion()
//            } //HKM
//
//        } //Fullfunction
//
//        func activeEnergyEveryHour(_ completion : @escaping()->()) {
//
//            //Need to loop through this
//            //Start with last midnight, find data 1 hour later
//            //Then find data from last midnight + 1 hour later -> +2 hours later
//            //Keep doing this until we get to current time
//
//            //Everytime we get a result, we should add it together, apply a function, then append it to an array
//            //Then we can take that array and all together to find our number to put into a strain/load algorithm
//            //This finds our load for the day
//
//
//
//            //This while statement will run until we hit right now...
//            //Change this to start of hour for right now?
//
//
//
//            //This works, turn it into a loop and then apply a formula of activity / min
//            //Then change it to every 5 mins loop!
////            hkm.activeEnergy(from: calendar.startOfDay(for: rightNow).addingTimeInterval(0), to: calendar.startOfDay(for: rightNow).addingTimeInterval(3600)) { (results) in
////                print("Last midnight from initial active energy array: \(lastMidnight)")
////                print("Last midnight formatted from initial active energy array: \(lastMidnightFormatted)")
////                print("Right now: \(rightNow)")
////                var activeEnergyRetrieve = 0.0
////                var activeEnergyRetrieveArray = [Double]()
////
////                for result in results {
////                    print("Getting Results")
////                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
////                    activeEnergyRetrieveArray.append(activeEnergyRetrieve)
////                }
////                print(activeEnergyRetrieveArray)
////                let activeEnergyArrayAdded = activeEnergyRetrieveArray.reduce(0, +)
////                print("Active Energy Array Added 1: \(activeEnergyArrayAdded)")
////                activeEnergyArrayEachHour.append(activeEnergyArrayAdded)
////                print("Active Energy Array Hour 1: \(activeEnergyArrayEachHour)")
////
////            }
////            hkm.activeEnergy(from: calendar.startOfDay(for: rightNow).addingTimeInterval(3600), to: calendar.startOfDay(for: rightNow).addingTimeInterval(7200)) { (results) in
////                print("Last midnight from initial active energy array: \(lastMidnight)")
////                print("Last midnight formatted from initial active energy array: \(lastMidnightFormatted)")
////                print("Right now: \(rightNow)")
////                var activeEnergyRetrieve = 0.0
////                var activeEnergyRetrieveArray = [Double]()
////
////                for result in results {
////                    print("Getting Results")
////                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
////                    activeEnergyRetrieveArray.append(activeEnergyRetrieve)
////                }
////                print(activeEnergyRetrieveArray)
////                let activeEnergyArrayAdded = activeEnergyRetrieveArray.reduce(0, +)
////                print("Active Energy Array Added 2: \(activeEnergyArrayAdded)")
////                activeEnergyArrayEachHour.append(activeEnergyArrayAdded)
////                print("Active Energy Array Hour 2: \(activeEnergyArrayEachHour)")
////            }
//
////            for _ in stride(from: 0 as Double, to: 70 as Double, by: +1 as Double) {
////                requestItemsTest {
////                    earlyTimeInterval += 600
////
////                    lateTimeInterval += 600
////
////                    earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
////                    lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
////                    print("Late Time: \(lateTime)")
////                    print("Right Now: \(rightNow)")
////                }
////            }
//
//            while earlyTime <= rightNow {
//
//                requestItemsTest {
//                    earlyTimeInterval += 600
//
//                    lateTimeInterval += 600
//
//                    earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
//                    lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
//                    print("Late Time: \(lateTime)")
//                    print("Right Now: \(rightNow)")
//                }
//
//                //Its doing things out of order... How to make it go in order?
//                //It loops but then goes to completion then keeps looping...
//            }
//            completion()
//
//
//
//
//
//
//
//
////            while lateTime < rightNow {
////                //run hkm.function then add 1 hour to each
////
////                hkm.activeEnergy(from: earlyTime, to: lateTime) { (results) in
////                    var activeEnergyRetrieve = 0.0
////                    var activeEnergyRetrieveArray = [Double]()
////
////                    for result in results {
////                        activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
////                        activeEnergyRetrieveArray.append(activeEnergyRetrieve)
////                        //This will get all the data from the hours shown above
////                        print("Active Energy Retrieve: \(activeEnergyRetrieve)")
////                        print("Active Energy Retrieve Array: \(activeEnergyRetrieveArray)")
////                    }
////                    //Need to add that data together then append to an array created outside this while loop
////                    activeEnergyRetrieveArrayAdded = activeEnergyRetrieveArray.reduce(0, +)
////                    //ActiveEnergyRetrieveArrayAdded is now appended to array
////                }
////
////                //This adds an hour to each pass
////                earlyTimeInterval += 3600
////                lateTimeInterval += 3600
////
////                print("Early Time Interval: \(earlyTimeInterval)")
////                print("Late Time Interval: \(lateTimeInterval)")
////
////                //This applies that hour change to time interval
////                earlyTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(earlyTimeInterval))
////                lateTime = calendar.startOfDay(for: rightNow).addingTimeInterval(TimeInterval(lateTimeInterval))
////
////                print("Early Time: \(earlyTime)")
////                print("Late Time: \(lateTime)")
////                activeEnergyArrayEachHour.append(activeEnergyRetrieveArrayAdded)
////
////                print("Active Energy Array Each Hour: \(activeEnergyArrayEachHour)")
////            }
//
////            hkm.activeEnergy(from: lastMidnight, to: Date()) { (results) in
////
////                //It runs through this once...
////                var activeEnergyRetrieve = 0.0
////                var activeEnergyRetrieveArray = [Double]()
////
////                for result in results {
////                    //It runs through this over and over until it gets all results in given time period
////                    //Can we change the request time in here, or have to put our hkm.activeEnergy into its own loop, so it loops through for a time period, then switches time period, then loops through, appending to array for 1 loop each time?
////                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
////                    activeEnergyRetrieveArray.append(activeEnergyRetrieve)
////                    //Will loop through to get results
////                    //Append all results in given time to array
////                    //Will add that array up into a variable
////                    //Will append that to a final array
////                    //Will then loop through this over and over until last hour -> Date()
////                }
////                //Add and append to array here before looping
////                print(activeEnergyRetrieveArray)
////                //This finds ALL data points since last midnight and appends them to an array
////            }
//        }
//
//        func initialActiveEnergyArray(_ completion : @escaping()->()) {
//            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
////            rightNow = Date()
////            //For some reason lastmidnight does not change but Date() does...
////            lastMidnight = calendar.startOfDay(for: rightNow)
////            //Add the above to our other functions
//            let hourAgo = Date.hourAgo
//            let hourAfterMidnight = calendar.startOfDay(for: rightNow).addingTimeInterval(3600)
//            var twoHourAfterMidnight = calendar.startOfDay(for: rightNow).addingTimeInterval(7200)
//
//
//            hkm.activeEnergy(from: lastMidnight, to: Date()) { (results) in
//                print("Last midnight from initial active energy array: \(lastMidnight)")
//                print("Last midnight formatted from initial active energy array: \(lastMidnightFormatted)")
//                print("Right now: \(rightNow)")
//                var activeEnergyRetrieve = 0.0
//                var activeEnergyRetrieveArray = [Double]()
//
//                for result in results {
//                    print("Getting Results")
//                    activeEnergyRetrieve = result.quantity.doubleValue(for: .kilocalorie())
//                    activeEnergyRetrieveArray.append(activeEnergyRetrieve)
//                }
//                print(activeEnergyRetrieveArray)
//                let activeEnergyArrayAdded = activeEnergyRetrieveArray.reduce(0, +)
//                print(activeEnergyArrayAdded)
//
//                loadCalculation = 7.7008 * log(activeEnergyArrayAdded) - 41.193
//                self.activeCalsState = loadCalculation
//                completion()
//            }
//
//
//
//        }
//        func saveNewActivityCalculationToCD() {
//
//            //Need to delete any items in today before writing to CD
//            let context = delegate.persistentContainer.viewContext
//            let predicate = NSPredicate(format: "date >= %@", lastMidnight as NSDate)
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Load")
//
//            fetchRequest.predicate = predicate
//
//            do {
//                let result = try context.fetch(fetchRequest)
//                print(result.count)
//                if result.count > 0 {
//                    for object in result {
//                        context.delete(object as! NSManagedObject)
//                    }
//                }
//            } catch {
//
//            }
//
//
//
//            print("Start saving load to CD")
//            let newLoadCalculationWrite = Load(context: managedObjectContext)
//
//            newLoadCalculationWrite.calculation = finalActivity
//            newLoadCalculationWrite.date = Date()
//
//            saveContext()
//            print("End saving load to CD")
//        }
//
//        func saveNewLoadCalculationToCD() {
//
//            //Need to delete any items in today before writing to CD
//            let context = delegate.persistentContainer.viewContext
//            let predicate = NSPredicate(format: "date >= %@", lastMidnight as NSDate)
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Load")
//
//            fetchRequest.predicate = predicate
//
//            do {
//                let result = try context.fetch(fetchRequest)
//                print(result.count)
//                if result.count > 0 {
//                    for object in result {
//                        context.delete(object as! NSManagedObject)
//                    }
//                }
//            } catch {
//
//            }
//
//
//
//            print("Start saving load to CD")
//            let newLoadCalculationWrite = Load(context: managedObjectContext)
//
//            newLoadCalculationWrite.calculation = loadCalculation
//            newLoadCalculationWrite.date = Date()
//
//            saveContext()
//            print("End saving load to CD")
//        }
//
//
//        //MARK: - New Energy Functions
//        func newReadinessCalculation() {
//            //Where all of our functions will be put in and then called
//            ///rightNow = Date()
//            findNewHRVReading {
//                findOldCoreDataReading {
//                    compareNewAndOldData {
//                        getHRVArrayFromHealth {
//                            checkAmountofHRVArrayValues {
//                                    removeOutliers {
//                                        calculateStats {
//                                            recentHRVRecoveryCalculation {
//                                                compareAndCalculateNewReadinessScore {
//                                                    changeReadinessColorsandText {
//                                                        saveNewCalculationToCD()
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//
//
//        func findNewHRVReading(_ completion : @escaping()->()) {
//            print("Right now HRV: \(rightNow)")
//
//            hkm.variabilityMostRecent(from: weekAgoStartDate, to: Date()) { (results) in
//                var lastHRV = 0.0
//                var lastHRVTime: Date? = nil
//
//                for result in results {
//                    lastHRV = result.quantity.doubleValue(for: .variabilityUnit)
//                    lastHRVTime = result.startDate
//                }
//
//                //Revise this?
//                guard lastHRV > 0.0 else {
//                    //This is when there is literally nothing, no HRV data at all.
//                    print("No recent data to calculate, guard is enabled, everything stops, and alert shows")
//                    self.finalReadinessPercentage = 0
//                    self.recommendationTextHidden = true
//                    self.alertTextHidden = false
//                    self.recommendationTitle = "There is no Watch data"
//                    self.alertText = "Please wear your watch all day and report back later to see your readiness calculation."
//                    self.recommendationTextColor = .orange
//                    self.readinessColorState = .gray
//                    return
//                }
//
//                self.noLastHRVAlertHidden = true
//                self.alertTextHidden = true
//                self.recommendationTextHidden = false
//                //self.noLastHRVAlertHidden = true
//                recentHRVValue = Double(lastHRV)
//                recentHRVTime = lastHRVTime
//
//                if recentHRVTime! < lastMidnight {
//                    //hrvMorningRecordedAlertHidden = false
//                    self.updatedTextColor = .red
//                } else if recentHRVTime! >= lastMidnight {
//                    //hrvMorningRecordedAlertHidden = true
//                    self.updatedTextColor = .primary
//                }
//                completion()
//            }
//        }
//
//        func findOldCoreDataReading(_ completion : @escaping()->()) {
//            coreDataHRVCalculationArray = coreDataItems.map {$0.calculation}
//            coreDataHRVTimeArray = coreDataItems.map {$0.time!}
//            coreDataHRVValueArray = coreDataItems.map {$0.hrv}
//
//            coreDataHRVValue = coreDataHRVValueArray.first ?? 0
//            coreDataHRVTime = coreDataHRVTimeArray.first ?? nil
//            coreDataHRVCalculation = coreDataHRVCalculationArray.first ?? 0
//
//            guard coreDataHRVCalculationArray.count > 0 else {
//
//
//                newFinalHRVCalculation = Double.random(in: 60...65)
//
//                saveNewCalculationToCD()
//
//                changeReadinessColorsandTextnoCompletion()
//
//
//                print("There were 0 core data items, so we created a baseline to save")
//                self.recommendationTextHidden = true
//                self.alertTextHidden = false
//                self.recommendationTitle = "Calculating your baseline"
//                self.alertText = "Please wear your watch and come back regularly to see your energy levels and load."
//                self.recommendationTextColor = .blue
//                return
//            }
//            self.alertTextHidden = true
//            self.recommendationTextHidden = false
//
//            print("Last core data value: \(coreDataHRVValue)")
//            print("Last core data time: \(coreDataHRVTime)")
//            print("Last core data calculation: \(coreDataHRVCalculation)")
//
//            completion()
//        }
//
//
//
//        func compareNewAndOldData(_ completion : @escaping()->()) {
//            //Compares new hrv reading and old to see if they are the same and continues or doesn't\
//            //This stops with guard and just sets our values to what was in our core data variables if the recent hrv and the core data items are the same, meaning that nothing new has happened
//            //It will continue with calculation if our hrv from health is newer than our core data items
//
//            guard recentHRVTime! > coreDataHRVTime! else {
//                //They are the same time, just update @state and color variables with most recent and formatting
//                changeReadinessColorsandTextCoreData()
//                return
//            }
//            completion()
//
//        }
//
//        func getHRVArrayFromHealth(_ completion : @escaping()->()) {
//            print("Right now Array: \(rightNow)")
//            hkm.variability(from: monthAgoStartDate, to: Date()) { (results) in
//
//                var variabilityRetrieve = 0.0
//                var variabilityRetrieveArray = [Double]()
//
//                for result in results {
//                    variabilityRetrieve = result.quantity.doubleValue(for: .variabilityUnit)
//                    variabilityRetrieveArray.append(variabilityRetrieve)
//                }
//                variability30DayArray = variabilityRetrieveArray
//                print(variability30DayArray)
//                completion()
//            }
//
//        }
//
//        func checkAmountofHRVArrayValues(_ completion : @escaping()->()) {
//            //When we get our array we will see how many values we have
//            //If there are not 4 data points, guard, calculate and save to core data, and have blue ! warning
//
//            guard variability30DayArray.count > 3 else {
//                //If variability has less than 4 values, run this
//
//                //Set our newFinalHRVCalculation to random Double(int 60...65)
//
//                newFinalHRVCalculation = Double.random(in: 60...65)
//
//                //Save to core data using saveNewCalculationToCD
//                saveNewCalculationToCD()
//
//                //Run change readiness colors and text w/o completion
//                changeReadinessColorsandTextnoCompletion()
//
//                //Make blue notification saying we are creating baseline
//                print("Less than 4 data points worth of hrv from health")
//                self.creatingBaselineAlertHidden = false
//                self.recommendationTextHidden = true
//                self.alertTextHidden = false
//                self.recommendationTitle = "Calculating your baseline"
//                self.alertText = "Please wear your watch and come back regularly to see your energy levels and activity"
//                self.recommendationTextColor = .blue
//
//                return
//            }
//            self.alertTextHidden = true
//            self.recommendationTextHidden = false
//            self.creatingBaselineAlertHidden = true
//            //If we have more than 4 items, continue as normal
//
//            completion()
//
//        }
//
//
//        func removeOutliers(_ completion : @escaping()->()) {
//            hrvOutlier1Q = (Sigma.percentile(variability30DayArray, percentile: 0.25) ?? 0.0)
//            hrvOutlier3Q = (Sigma.percentile(variability30DayArray, percentile: 0.75) ?? 0.0)
//
//            hrvOutlierIQR = hrvOutlier3Q - hrvOutlier1Q
//
//            hrvOutlierLowCutoff = hrvOutlier1Q - (1.5 * hrvOutlierIQR)
//            hrvOutlierHighCutoff = hrvOutlier3Q + (1.5 * hrvOutlierIQR)
//
//            variability30DayArrayNoOutliers = variability30DayArray.filter { $0 < hrvOutlierHighCutoff && $0 > hrvOutlierLowCutoff }
//
//            completion()
//        }
//
//        func calculateStats(_ completion : @escaping()->()) {
//            hrvMax = variability30DayArrayNoOutliers.max() ?? 0.0
//            hrvMin = variability30DayArrayNoOutliers.min() ?? 0.0
//            hrv1Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.25) ?? 0.0
//            hrv0_75Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.1875) ?? 0.0
//            hrv1_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.375) ?? 0.0
//            hrv2_5Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.625) ?? 0.0
//            hrv3_25Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.8125) ?? 0.0
//            hrv3Q = Sigma.percentile(variability30DayArrayNoOutliers, percentile: 0.75) ?? 0.0
//            hrvMedian = Sigma.median(variability30DayArrayNoOutliers) ?? 0.0
//
//            print("Max: \(hrvMax) Min: \(hrvMin) 1Q: \(hrv1Q) 3Q: \(hrv3Q) Median: \(hrvMedian) 0.75Q: \(hrv0_75Q) 1.5Q: \(hrv1_5Q) 2.5Q: \(hrv2_5Q) 3.25Q: \(hrv3_25Q)")
//
//            completion()
//        }
//
//        func recentHRVRecoveryCalculation(_ completion : @escaping()->()) {
//            //We need to calculate our hrv recovery first before apply it into our algorithm...
//
//            if recentHRVValue <= hrvMin {
//                recentHRVCalculation = 0.0
//            } else if recentHRVValue >= hrvMax {
//                recentHRVCalculation = 99.0
//            } else if hrvMin <= recentHRVValue && recentHRVValue <= hrv1Q {
//                recentHRVCalculation = ((((recentHRVValue - hrvMin) / (hrv1Q - hrvMin)) * 25.0) + 0.0)
//            } else if hrv1Q <= recentHRVValue && recentHRVValue <= hrvMedian {
//                recentHRVCalculation = ((((recentHRVValue - hrv1Q) / (hrvMedian - hrv1Q)) * 25.0) + 25.0)
//            } else if hrvMedian <= recentHRVValue && recentHRVValue <= hrv3Q {
//                recentHRVCalculation = ((((recentHRVValue - hrvMedian) / (hrv3Q - hrvMedian)) * 25.0) + 50.0)
//            } else if hrv3Q <= recentHRVValue && recentHRVValue <= hrvMax {
//                recentHRVCalculation = ((((recentHRVValue - hrv3Q) / (hrvMax - hrv3Q)) * 25.0) + 75.0)
//            }
//            print("Recent HRV Calculation Func run")
//            completion()
//        }
//
//        func compareAndCalculateNewReadinessScore(_ completion : @escaping()->()) {
//            //Compares our old and new data to come up with a new score\
//            //Append new calculation to new calculation variable
//            //Appends to "newFinalHRVCalculation"
//
//            //Check where our old readiness is first, then apply new
//                            //Test
//                            if coreDataHRVCalculation <= 25 { //in red
//                                if recentHRVCalculation <= 25 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                                    newFinalHRVCalculation = 65
//                                } else if recentHRVCalculation > 85 {
//                                    newFinalHRVCalculation = 75
//                                }
//                            } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation <= 40 { //in yellow
//                                if recentHRVCalculation <= 25 {
//                                    newFinalHRVCalculation = 20
//                                } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                                    newFinalHRVCalculation = 70
//                                } else if recentHRVCalculation > 85 {
//                                    newFinalHRVCalculation = 85
//                                }
//                            } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation <= 65 { //in blue
//                                if recentHRVCalculation <= 25 {
//                                    newFinalHRVCalculation = 25
//                                } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 85 {
//                                    newFinalHRVCalculation = 90
//                                }
//                            }  else if coreDataHRVCalculation > 65 && coreDataHRVCalculation <= 85 { //in green
//                                if recentHRVCalculation <= 25 {
//                                    newFinalHRVCalculation = 30
//                                } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                                    newFinalHRVCalculation = 35
//                                } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                                    newFinalHRVCalculation = recentHRVCalculation
//                                } else if recentHRVCalculation > 85 {
//                                    newFinalHRVCalculation = 90
//                                }
//                        } else if coreDataHRVCalculation > 85 { //in pink
//                            if recentHRVCalculation <= 25 {
//                                newFinalHRVCalculation = 35
//                            } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                                newFinalHRVCalculation = 40
//                            } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                                newFinalHRVCalculation = recentHRVCalculation
//                            } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                                newFinalHRVCalculation = recentHRVCalculation
//                            } else if recentHRVCalculation > 85 {
//                                newFinalHRVCalculation = recentHRVCalculation
//                            }
//                        }
//                            //Test
//            print("New HRV Calculation Func run")
//
//            completion()
//        }
//
//        func changeReadinessColorsandText(_ completion : @escaping()->()) {
//            //Changes the text based on our 3 new calculation variables
//            //Changes the colors based on our new calculation
//
//            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d h:mma")
//
//            //Changes recommendation
//            self.recommendationTextColor = .primary
//
//            //Changes Text
//            self.recentHRVValueState = Int(recentHRVValue)
//            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
//            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
//
//            //Changes Colors and Bar Data
//            if newFinalHRVCalculation <= 25 {
//                readinessColor = .red
//                self.recommendationTitle = "Minimal Energy"
//            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
//                readinessColor = .orange
//                self.recommendationTitle = "Low Energy"
//            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
//                readinessColor = .blue
//                self.recommendationTitle = "Normal Energy"
//            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
//                readinessColor = .green
//                self.recommendationTitle = "Elevated Energy"
//            } else if newFinalHRVCalculation > 85 {
//                readinessColor = .purple
//                self.recommendationTitle = "Max Performance"
//            }
//
//            self.readinessBarState = Int(newFinalHRVCalculation)
//            self.readinessColorState = readinessColor
//
//            completion()
//
//        }
//
//        func saveNewCalculationToCD() {
//            //Saves new calculation / data to core data with save context
//            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)
//
//            newReadinessCalculationWrite.calculation = newFinalHRVCalculation
//            newReadinessCalculationWrite.hrv = recentHRVValue
//            newReadinessCalculationWrite.time = recentHRVTime
//
//            saveContext()
//        }
//
//        func saveNewCalculationToCDGuard() {
//            //Saves new calculation / data to core data with save context
//            let newReadinessCalculationWrite = Readiness(context: managedObjectContext)
//
//            newReadinessCalculationWrite.calculation = recentHRVCalculation
//            newReadinessCalculationWrite.hrv = recentHRVValue
//            newReadinessCalculationWrite.time = recentHRVTime
//
//            saveContext()
//        }
//
//        func changeReadinessColorsandTextCoreData() {
//            //Same as above function, but uses core data in our comparison
//
//            //if coredata count is less than 3 then do baseline text
//            if coreDataHRVCalculationArray.count < 3 {
//                self.recommendationTextHidden = true
//                self.alertTextHidden = false
//                self.recommendationTitle = "Calculating your baseline"
//                self.alertText = "Please wear your watch and come back regularly to see your energy levels and activity"
//                self.recommendationTextColor = .blue
//            } else {
//                self.recommendationTextHidden = false
//                self.alertTextHidden = true
//                self.recommendationTextColor = .primary
//            }
//
//            let formattedCoreDataDate = getFormattedDate(date: coreDataHRVTime!, format: "MMM d h:mma")
//
//            //Changes Text
//            self.recentHRVValueState = Int(coreDataHRVValue)
//            self.recentHRVTimeState = String("\(formattedCoreDataDate)")
//            self.finalReadinessPercentage = Int(coreDataHRVCalculation)
//
//            //Changes Colors and Bar
//            if coreDataHRVCalculation <= 25 {
//                readinessColor = .red
//                self.recommendationTitle = "Minimal Energy"
//            } else if coreDataHRVCalculation > 25 && coreDataHRVCalculation <= 40 {
//                readinessColor = .orange
//                self.recommendationTitle = "Low Energy"
//            } else if coreDataHRVCalculation > 40 && coreDataHRVCalculation <= 65 {
//                readinessColor = .blue
//                self.recommendationTitle = "Normal Energy"
//            } else if coreDataHRVCalculation > 65 && coreDataHRVCalculation <= 85 {
//                readinessColor = .green
//                self.recommendationTitle = "Elevated Energy"
//            } else if coreDataHRVCalculation > 85 {
//                readinessColor = .purple
//                self.recommendationTitle = "Max Performance"
//            }
//
//            print("Readiness color is \(readinessColor)")
//
//            self.readinessBarState = Int(coreDataHRVCalculation)
//            self.readinessColorState = readinessColor
//        }
//
//        func changeReadinessColorsandTextnoCompletion() {
//            //Changes the text based on our 3 new calculation variables
//            //Changes the colors based on our new calculation
//
//            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d h:mma")
//
//            //Changes recommendation
//            self.recommendationTextColor = .primary
//
//            //Changes Text
//            self.recentHRVValueState = Int(recentHRVValue)
//            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
//            self.finalReadinessPercentage = Int(newFinalHRVCalculation)
//
//            //Changes Colors and Bar Data
//            if newFinalHRVCalculation <= 25 {
//                readinessColor = .red
//                self.recommendationTitle = "Minimal Energy"
//            } else if newFinalHRVCalculation > 25 && newFinalHRVCalculation <= 40 {
//                readinessColor = .orange
//                self.recommendationTitle = "Low Energy"
//            } else if newFinalHRVCalculation > 40 && newFinalHRVCalculation <= 65 {
//                readinessColor = .blue
//                self.recommendationTitle = "Normal Energy"
//            } else if newFinalHRVCalculation > 65 && newFinalHRVCalculation <= 85 {
//                readinessColor = .green
//                self.recommendationTitle = "Elevated Energy"
//            } else if newFinalHRVCalculation > 85 {
//                readinessColor = .purple
//                self.recommendationTitle = "Max Performance"
//            }
//
//            self.readinessBarState = Int(newFinalHRVCalculation)
//            self.readinessColorState = readinessColor
//
//        }
//
//        func changeReadinessColorsandTextnoCompletionGuard() {
//            //Changes the text based on our 3 new calculation variables
//            //Changes the colors based on our new calculation
//
//            let formattedRecentHRVDate = getFormattedDate(date: recentHRVTime!, format: "MMM d h:mma")
//
//            //Changes recommendation
//            self.recommendationTextColor = .primary
//
//            //Changes Text
//            self.recentHRVValueState = Int(recentHRVValue)
//            self.recentHRVTimeState = String("\(formattedRecentHRVDate)")
//            self.finalReadinessPercentage = Int(recentHRVCalculation)
//
//            //Changes Colors and Bar Data
//            if recentHRVCalculation <= 25 {
//                readinessColor = .red
//                self.recommendationTitle = "Minimal Energy"
//            } else if recentHRVCalculation > 25 && recentHRVCalculation <= 40 {
//                readinessColor = .orange
//                self.recommendationTitle = "Low Energy"
//            } else if recentHRVCalculation > 40 && recentHRVCalculation <= 65 {
//                readinessColor = .blue
//                self.recommendationTitle = "Normal Energy"
//            } else if recentHRVCalculation > 65 && recentHRVCalculation <= 85 {
//                readinessColor = .green
//                self.recommendationTitle = "Elevated Energy"
//            } else if recentHRVCalculation > 85 {
//                readinessColor = .purple
//                self.recommendationTitle = "Max Performance"
//            }
//
//            self.readinessBarState = Int(recentHRVCalculation)
//            self.readinessColorState = readinessColor
//
//        }
//
//
//
//    }
//
//
//
//    //MARK: - Readiness View
//    struct EnergyView: View {
//
//        @Environment(\.managedObjectContext) var managedObjectContext
//
//
//
//        var body: some View {
//            NavigationView {
//                Text("Coming soon...")
//            }
//        }
//
//        @FetchRequest(
//            entity: Readiness.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \Readiness.time, ascending: false)]
//        ) var coreDataRequest: FetchedResults<Readiness>
//
//
//
//        func loadCoreDataValuesIntoDictionary() {
//            coreDataTimeArray = coreDataRequest.map {$0.time!}
//            coreDataCalculationArray = coreDataRequest.map {$0.calculation}
//
//            print("Core Data times: \(coreDataTimeArray)")
//            print("Core Data Calculations: \(coreDataCalculationArray)")
//
//            coreDataDictionary[coreDataTimeArray] = coreDataCalculationArray
//            print(coreDataDictionary)
//        }
//
//    }
//
////MARK: - Body Load View
//struct LoadView: View {
//    var body: some View {
//        NavigationView {
//            Text("Activity Details will go here")
//
//
//        }
////        GeometryReader{ geometry in
////            VStack {
////                HStack {
////                    Spacer()
////                    VStack {
////                        Text("\(finalReadinessPercentage)")
////                            .font(.title).bold()
////                            .foregroundColor(readinessColorState)
////                            .frame(width: geometry.size.width * 0.25 - 10)
////                            .multilineTextAlignment(.center)
////
////                        Text("Energy")
////                            .fontWeight(.heavy)
////                            .foregroundColor(readinessColorState)
////                            .frame(width: geometry.size.width * 0.25 - 10)
////                            .multilineTextAlignment(.center)
////                            }
////                    Spacer()
////                    ZStack {
////                        CircularProgress(
////                            progress: 50,
////                            lineWidth: 25,
////                            foregroundColor: Color(UIColor.systemTeal),
////                            backgroundColor: Color(UIColor.systemTeal).opacity(0.20)
////                        ).rotationEffect(.degrees(-90)).frame(width: geometry.size.width * 0.50, height: geometry.size.height / 3, alignment: .center)
////                        CircularProgress(
////                            progress: CGFloat(readinessBarState),
////                            lineWidth: 25,
////                            foregroundColor: readinessColorState,
////                            backgroundColor: readinessColorState.opacity(0.20)
////                        ).rotationEffect(.degrees(-90)).frame(width: geometry.size.width * 0.325, height: geometry.size.height * 0.325, alignment: .center)
////                    }
////                    Spacer()
////                    VStack {
////                        Text("7.8")
////                            .font(.title).bold()
////                            .foregroundColor(Color(UIColor.systemTeal))
////                            .frame(width: geometry.size.width * 0.25 - 10)
////                            .multilineTextAlignment(.center)
////
////                        Text("Load")
////                            .fontWeight(.heavy)
////                            .foregroundColor(Color(UIColor.systemTeal))
////                            .frame(width: geometry.size.width * 0.25 - 10)
////                            .multilineTextAlignment(.center)
////
////                    }
////                    Spacer()
////                }.frame(width: geometry.size.width, height: geometry.size.height / 2, alignment: .center)
////
////                Spacer()
////                VStack {
////                    HStack {
////                        Spacer()
////
////                        if !hrvMorningRecordedAlertHidden {
////                            ZStack {
////                                Rectangle()
////                                    .foregroundColor(Color.gray.opacity(0.20))
////                                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                    .cornerRadius(10)
////                                VStack {
////                                    HStack {
////                                        Image(systemName: "exclamationmark.triangle")
////                                            .resizable()
////                                            .frame(width: 25, height: 25)
////                                            .foregroundColor(.orange)
////                                        Text("Your Calculation is not up to date.")
////                                            .font(.headline)
////
////                                    }
////                                    Text("The most recent Energy score is from yesterday. Go to the breathe app on your Apple Watch to update your score.")
////                                        .frame(width: geometry.size.width * 0.85)
////                                        .multilineTextAlignment(.center)
////                                }
////                            }
////                        }
////
////                        if !creatingBaselineAlertHidden {
////                            ZStack {
////                                Rectangle()
////                                    .foregroundColor(Color.gray.opacity(0.20))
////                                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                    .cornerRadius(10)
////                                VStack {
////                                    HStack {
////                                        Image(systemName: "exclamationmark.triangle")
////                                            .resizable()
////                                            .frame(width: 25, height: 25)
////                                            .foregroundColor(.blue)
////                                        Text("Calculating Baseline")
////                                            .font(.headline)
////                                    }
////                                    Text("We are currently calculating your baseline. Please wear your watch and come back regularly to see your energy levels.")
////                                        .frame(width: geometry.size.width * 0.87)
////                                        .multilineTextAlignment(.center)
////                                }
////                            }
////                        }
////
////                        if !noLastHRVAlertHidden {
////                            ZStack {
////                                Rectangle()
////                                    .foregroundColor(Color.gray.opacity(0.20))
////                                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                    .cornerRadius(10)
////                                VStack {
////                                    HStack {
////                                        Image(systemName: "exclamationmark.triangle")
////                                            .resizable()
////                                            .frame(width: 25, height: 25)
////                                            .foregroundColor(.red)
////                                        Text("There is no HRV Health data.")
////                                            .font(.headline)
////                                    }
////                                    Text("Please wear your Watch all day and report back later to see your readiness calculation.")
////                                        .frame(width: geometry.size.width * 0.85)
////                                        .multilineTextAlignment(.center)
////                                }
////                            }
////                        }
////                        //
////                        Spacer()
////                    }
////                    HStack {
////                        Spacer()
////                        ZStack {
////                            Rectangle()
////                                .foregroundColor(Color.gray.opacity(0.20))
////                                .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.20)
////                                .cornerRadius(10)
////                            VStack {
////                                HStack {
////                                    Image(systemName: "info.circle")
////                                        .resizable()
////                                        .frame(width: 25, height: 25)
////
////                                    Text("You can push it hard today!")
////                                        .font(.headline)
////                                }
////                                Text("To reach your Recommended Day Load, go on your normal 20 mile bike ride!")
////                                    .frame(width: geometry.size.width * 0.85)
////                                    .multilineTextAlignment(.center)
////                            }
////                        }
////                        Spacer()
////                    }
////                }
////
////                .frame(width: geometry.size.width, height: geometry.size.height / 2, alignment: .center)
////
////            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
////        }
//    }
//}
//
//    //MARK: - AppView to Create Tabs
//    struct AppView: View {
//        var body: some View {
//            TabView {
//                HomeView()
//                    .tabItem {
//                        Image(systemName: "house.fill")
//                        Text("Home")
//                    }
//                EnergyView()
//                    .tabItem {
//                        Image(systemName: "battery.100")
//                        Text("Energy")
//                    }
//                LoadView()
//                    .tabItem {
//                        Image(systemName: "bolt.fill")
//                        Text("Activity")
//                    }
//                SettingsView()
//                    .tabItem {
//                        Image(systemName: "gear")
//                        Text("Get Started")
//                    }
//            }
//        }
//    }
//
//    struct ContentView_Previews: PreviewProvider {
//        static var previews: some View {
//            Group {
//                HomeView()
//                    .preferredColorScheme(.dark)
//                    .previewDevice("iPhone 12 Pro Max")
//                HomeView()
//                    .preferredColorScheme(.light)
//                    .previewDevice("iPhone 8")
//            }
//        }
//    }
