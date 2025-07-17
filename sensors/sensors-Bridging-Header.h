//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <Foundation/Foundation.h>

extern NSArray<NSString*>* currentSensorNames();
extern NSArray<NSString*>* voltageSensorNames();
extern NSArray<NSString*>* thermalSensorNames();

extern NSArray<NSNumber*>* currentSensorValues();
extern NSArray<NSNumber*>* voltageSensorValues();
extern NSArray<NSNumber*>* thermalSensorValues();
