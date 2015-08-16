/*

 File: LeDiscovery.h
 
 Abstract: Scan for and discover nearby LE peripherals with the 
 matching service UUID.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

// Modified by Michael Simms on 2/19/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "Discovery.h"
#import "LeBluetoothSensor.h"
#import "BluetoothServices.h"

@interface LeDiscovery : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate, Discovery>
{
	NSMutableArray*   discoveryDelegates;
	NSMutableArray*   discoveredPeripherals;
	NSMutableArray*   discoveredSensors;
	CBCentralManager* centralManager;
	NSTimer*          scanTimer;
}

+ (id)sharedInstance;

- (void)addDelegate:(id<DiscoveryDelegate>)newDelegate;
- (void)removeDelegate:(id<DiscoveryDelegate>)oldDelegate;
- (void)refreshDelegates;

- (BOOL)hasConnectedSensor:(SensorType)sensorType;
- (BOOL)hasDiscoveredPeripheral:(CBPeripheral*)peripheral;
- (void)removeConnectedPeripheral:(CBPeripheral*)peripheral;

- (void)stopScanning;

- (void)connectPeripheral:(CBPeripheral*)peripheral;
- (void)disconnectPeripheral:(CBPeripheral*)peripheral;

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral;
- (void)centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error;
- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI;
- (void)centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error;
- (void)centralManager:(CBCentralManager*)central didRetrieveConnectedPeripherals:(NSArray*)peripherals;
- (void)centralManager:(CBCentralManager*)central didRetrievePeripherals:(NSArray*)peripherals;
- (void)centralManagerDidUpdateState:(CBCentralManager*)central;

- (void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didUpdateValueForDescriptor:(CBDescriptor*)descriptor error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForDescriptor:(CBDescriptor*)descriptor error:(NSError*)error;
- (void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error;

- (NSMutableArray*)discoveredSensorsOfType:(BluetoothService)serviceType;
- (NSMutableArray*)sensorsForPeripheral:(CBPeripheral*)peripheral;

- (BOOL)serviceEquals:(CBService*)service1 withBTService:(BluetoothService)serviceType;

@end
