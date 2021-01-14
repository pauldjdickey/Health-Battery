//
//  UserHealthProfile.swift
//  Health Battery
//
//  Created by Paul Dickey on 1/14/21.
//

import HealthKit

class UserHealthProfile {
  
  var age: Int?
  var biologicalSex: HKBiologicalSex?
  var bloodType: HKBloodType?
  var heightInMeters: Double?
  var weightInKilograms: Double?
  
  var bodyMassIndex: Double? {
    
    guard let weightInKilograms = weightInKilograms,
      let heightInMeters = heightInMeters,
      heightInMeters > 0 else {
        return nil
    }
    
    return (weightInKilograms/(heightInMeters*heightInMeters))
  }
}
