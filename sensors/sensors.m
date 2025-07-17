#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

// Declarations from other IOKit source code

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t, int32_t, int64_t);
CFStringRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef property);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

NSDictionary* matching(int page, int usage)
{
    NSDictionary* dict = @ {
        @"PrimaryUsagePage" : [NSNumber numberWithInt:page],
        @"PrimaryUsage" : [NSNumber numberWithInt:usage],
    };
    return dict;
}

NSArray<NSString*>* getProductNames(NSDictionary* sensors)
{
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, (__bridge CFDictionaryRef)sensors);
    NSArray* matchingsrvs = (__bridge NSArray*)IOHIDEventSystemClientCopyServices(system);

    long count = [matchingsrvs count];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (__bridge IOHIDServiceClientRef)matchingsrvs[i];
        NSString* name = (__bridge NSString*)IOHIDServiceClientCopyProperty(sc, (__bridge CFStringRef) @"Product");
        if (name) {
            [array addObject:name];
        } else {
            [array addObject:@"noname"];
        }
    }
    return array;
}

// from IOHIDFamily/IOHIDEventTypes.h
// e.g., https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/IOHIDEventTypes.h.auto.html


#define IOHIDEventFieldBase(type) (type << 16)
#define kIOHIDEventTypeTemperature 15
#define kIOHIDEventTypePower 25

NSArray<NSNumber*>* getPowerValues(NSDictionary* sensors)
{
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, (__bridge CFDictionaryRef)sensors);
    NSArray* matchingsrvs = (__bridge NSArray*)(IOHIDEventSystemClientCopyServices(system));

    long count = [matchingsrvs count];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (__bridge IOHIDServiceClientRef)matchingsrvs[i];
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypePower, 0, 0);

        NSNumber* value;
        double temp = 0.0;
        if (event != 0) {
            temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypePower)) / 1000.0;
        }
        value = [NSNumber numberWithDouble:temp];
        [array addObject:value];
    }
    return array;
}

NSArray<NSNumber*>* getThermalValues(NSDictionary* sensors)
{
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, (__bridge CFDictionaryRef)sensors);
    NSArray* matchingsrvs = (__bridge NSArray*)IOHIDEventSystemClientCopyServices(system);

    long count = [matchingsrvs count];
    NSMutableArray* array = [[NSMutableArray alloc] init];

    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (__bridge IOHIDServiceClientRef)matchingsrvs[i];
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0);

        NSNumber* value;
        double temp = 0.0;
        if (event != 0) {
            temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
        }
        value = [NSNumber numberWithDouble:temp];
        [array addObject:value];
    }
    return array;
}

void dumpValues(NSArray* kvs)
{
    NSUInteger count = [kvs count];
    for (NSUInteger i = 0; i < count; i++) {
        if (i > 0)
            printf(", ");
        printf("%lf", [[kvs[i] lastObject] doubleValue]);
    }
}

void dumpNames(NSArray* kvs, NSString* cat)
{
    NSUInteger count = [kvs count];
    for (NSUInteger i = 0; i < count; i++) {
        if (i > 0)
            printf(", ");
        printf("%s (%s)", [[kvs[i] firstObject] UTF8String], [cat UTF8String]);
    }
}

NSArray* sortKeyValuePairs(NSArray* keys, NSArray* values)
{

    NSMutableArray* unsorted_array = [[NSMutableArray alloc] init];
    for (int i = 0; i < [keys count]; i++) {
        [unsorted_array addObject:[[NSArray alloc] initWithObjects:keys[i], values[i], nil]];
    }

    NSArray* sortedArray = [unsorted_array sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [[obj1 firstObject] compare:[obj2 firstObject]];
    }];
    return sortedArray;
}

NSArray<NSString*>* currentSensorNames(void) {
    NSDictionary* currentSensors = matching(0xff08, 2);
    return getProductNames(currentSensors);
}

NSArray<NSString*>* voltageSensorNames(void) {
    NSDictionary* voltageSensors = matching(0xff08, 3);
    return getProductNames(voltageSensors);
}

NSArray<NSString*>* thermalSensorNames(void) {
    NSDictionary* thermalSensors = matching(0xff00, 5);
    return getProductNames(thermalSensors);
}

NSArray<NSNumber*>* currentSensorValues(void) {
    NSDictionary* currentSensors = matching(0xff08, 2);
    return getPowerValues(currentSensors);
}

NSArray<NSNumber*>* voltageSensorValues(void) {
    NSDictionary* voltageSensors = matching(0xff08, 3);
    return getPowerValues(voltageSensors);
}

NSArray<NSNumber*>* thermalSensorValues(void) {
    NSDictionary* thermalSensors = matching(0xff00, 5);
    return getThermalValues(thermalSensors);
}


extern uint64_t my_mhz(void);
extern void mybat(void);

#if 0
int main () {
    //  Primary Usage Page:
    //    kHIDPage_AppleVendor                        = 0xff00,
    //    kHIDPage_AppleVendorTemperatureSensor       = 0xff05,
    //    kHIDPage_AppleVendorPowerSensor             = 0xff08,
    //
    //  Primary Usage:
    //    kHIDUsage_AppleVendor_TemperatureSensor     = 0x0005,
    //    kHIDUsage_AppleVendorPowerSensor_Current    = 0x0002,
    //    kHIDUsage_AppleVendorPowerSensor_Voltage    = 0x0003,
    // See IOHIDFamily/AppleHIDUsageTables.h for more information
    // https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/AppleHIDUsageTables.h.auto.html
    
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    CFDictionaryRef thermalSensors = matching(0xff05, 5);
    
    CFArrayRef currentNames = getProductNames(system, currentSensors);
    CFArrayRef voltageNames = getProductNames(system, voltageSensors);
    CFArrayRef thermalNames = getProductNames(system, thermalSensors);
    
    
    printf("freq, v_bat, a_bat, temp_bat");
    dumpNames(voltageNames, "V");
    dumpNames(currentNames, "A");
    dumpNames(thermalNames, "degree C");
    printf("\n");
    
    while (1) {
        CFArrayRef currentValues = getPowerValues(system, currentSensors);
        CFArrayRef voltageValues = getPowerValues(system, voltageSensors);
        CFArrayRef thermalValues = getThermalValues(system, thermalSensors);
        printf("%lld, ", my_mhz());
        mybat();
        
        dumpValues(voltageValues);
        dumpValues(currentValues);
        dumpValues(thermalValues);
        printf("\n");
        usleep(900000);
        CFRelease(currentValues);
        CFRelease(voltageValues);
        CFRelease(thermalValues);
    }
    
#if 0
    NSLog(@"%@\n", CFArrayGetValueAtIndex(currentNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(currentNames, 1));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(voltageNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(voltageNames, 1));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(thermalNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(thermalNames, 1));
#endif
    
    // IOHIDEventRef event = IOHIDServiceClientCopyEvent(alssc, 25, 0, 0);
    
    return 0;
}
#endif
