//
//  main.m
//  ApexCtlOSX
//
//  Created by Joey Korkames on 4/15/14.
//  Copyright (c) 2014 Joey Korkames. All rights reserved.
//
//  HID code based on http://lists.apple.com/archives/Usb/2009/Sep/msg00019.html
//  Apex USB config specs from https://github.com/tuxmark5/ApexCtl/blob/master/src/Main.hs
//http://www.pjrc.com/tmp/bug.c
//http://www.beyondlogic.org/usbnutshell/usb4.shtml#Control

#ifdef NDEBUG
#define MyLog(...) (void)printf("%s\n",[[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define MyLog NSLog
#endif

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

uint8_t macrokeys[32] = {0x02, 0x00, 0x02}; //enable macro keys
//https://github.com/tuxmark5/ApexCtl/blob/master/scancodes.txt
uint8_t dim[32] = {0x05, 0x01, 0x01}; //dim brightness
uint8_t bright[32] = {0x05, 0x01, 0x08}; //full brightness
uint8_t slow[32] = {0x04, 0x00, 0x00}; //125hz poll
uint8_t fast[32] = {}; //1000hz poll
uint8_t colors[32] = {0x07, 0x00,
    /*  R     G      B    bright    */
    0x00, 0xff, 0xff, 0x08, //south = cyan
    0x00, 0xff, 0x00, 0x08, //east = green
    0xff, 0x00, 0xff, 0x08, //north = purple
    0xff, 0x00, 0x00, 0x08, //west = red
    //0xff, 0xff, 0xff, 0x08,  //logo & corners = white
    0x00, 0x00, 0x00, 0x08,  //logo & corners - OFF
};

IOReturn set_feature(IOHIDDeviceRef deviceRef, NSArray *bytes)
{
    IOReturn sendRet = noErr;
    
    //rethink this..
    //https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/BinaryData/Tasks/WorkingBinaryData.html
    unsigned char *buffer = (unsigned char *) calloc(32,1);
    int i = 0;
    for (NSNumber *num in bytes)
        buffer[i++] = (unsigned char)num.unsignedCharValue;
    //NSData *data = [NSData dataWithBytes:buffer length:bytes.count];
    //free(buffer);
    NSData *bs_report = [[NSData alloc] initWithBytes:(buffer) length:(32)];
    
    MyLog(@"I: sending config via HID feature report: %@", [bs_report description]);
    sendRet = IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeFeature, 0x0200, bs_report.bytes, 32);
    if (sendRet) {
        MyLog(@"I: got kIOReturn from kernel: %d", err_get_code(sendRet)); //kIOReturnSuccess
        MyLog(@"D: %s, IOHIDDeviceSetReport error: %ld (0x%08lX)n",	 __PRETTY_FUNCTION__, (long) sendRet, (long) sendRet);
    }
    return sendRet;
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        NSDictionary *argpairs = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
        NSDictionary *switches = @{ //hid features we can manipulate
                                   @"-macrokeys":    @[ @0x02, @0x00, @0x01 ], //let keyboard & SteelSeries Engine manage Ln/Mn/MXn
                                   @"-rawkeys":    @[ @0x02, @0x00, @0x02 ], //raw return of Ln/Mn/MXn key codes to OS
                                   @"-dim":      @[ @0x05, @0x01, @0x01 ], //dim typing keys
                                   @"-bright":   @[ @0x05, @0x01, @0x08 ], //illuminate typing keys
                                   @"-125hz":    @[ @0x04, @0x00, @0x00 ], //slowest poll
                                   @"-250hz":    @[ @0x04, @0x00, @0x01 ],
                                   @"-500hz":    @[ @0x04, @0x00, @0x02 ],
                                   @"-1000hz":   @[ @0x04, @0x00, @0x03 ], //fastest poll
                                   @"-color_quiet":  @[ @0x07, @0x00, // ? ?
                                                    /*  R     G      B    bright    */
                                                   @0x00, @0xff, @0xff, @0x08, //south = cyan
                                                   @0x00, @0xff, @0x00, @0x08, //east = green
                                                   @0xff, @0x00, @0xff, @0x08, //north = purple
                                                   @0xff, @0x00, @0x00, @0x08, //west = red
                                                   @0x00, @0x00, @0x00, @0x08,  //logo & corners - OFF
                                                   ],
                                   @"-colorL1":  @[ @0x07, @0x00	, // ? ?
                                                    /*  R     G      B    bright    */
                                                    @0x00, @0xff, @0xff, @0x08, //south = cyan
                                                    @0x00, @0xff, @0x00, @0x08, //east = green
                                                    @0xff, @0x00, @0xff, @0x08, //north = purple
                                                    @0xff, @0x00, @0x00, @0x08, //west = red
                                                    @0xff, @0xff, @0xff, @0x08,  //logo & corners = wh
                                                    ]
                                   }; //switches
        
        IOHIDManagerRef managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOHIDManagerOpen(managerRef, 0L);
        
        MyLog(@"I: searching for Apex keyboard");
        const long productId = 0x1202; //APEX keyboard. 0x1200 is Apex RAW
        const long productIds[] = {0x1200, 0x1202}; //APEX RAW & Apex
        const long vendorId  = 0x1038; //SteelSeries
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithLong:vendorId]  forKey:[NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding]]; //*=vid
        [dict setObject:[NSNumber numberWithLong:productId] forKey:[NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding]]; //*=pid
        //[dict setObject:[NSNumber numberWithLong:productIds] forKey:[NSString stringWithCString:kIOHIDProductIDArrayKey encoding:NSUTF8StringEncoding]];
        
        //used IOJones.app to find the specific endpoints - this is a Composite device
        //ioreg -f -r -c IOHIDKeyboard
        //Device Class Definition for Human Interface Devices (HID) http://www.usb.org/developers/devclass_docs/HID1_11.pdf
        //HID Pages and Usages http://www.usb.org/developers/devclass_docs/Hut1_12v2.pdf
        //https://github.com/ake-koomsin/LogitechWirelessPresenterKext/blob/master/LogitechPresentationRemote/LogitechWirelessPresenterDriver.cpp
        //https://code.google.com/p/iousbhiddriver-descriptor-override/
        
        //interface #0: apex keyboard vendor-specific configuration
        [dict setObject:[NSNumber numberWithLong:(kHIDPage_VendorDefinedStart + 0x00c0)]  forKey:[NSString stringWithCString:kIOHIDDeviceUsagePageKey encoding:NSUTF8StringEncoding]]; //0xffc0(65472)
        [dict setObject:[NSNumber numberWithLong:(kHIDUsage_Undefined + 0x1)]  forKey:[NSString stringWithCString:kIOHIDDeviceUsageKey encoding:NSUTF8StringEncoding]];
        
        //interface #1: standard & macro keyboard events
        //[dict setObject:[NSNumber numberWithLong:kHIDPage_GenericDesktop]  forKey:[NSString stringWithCString:kIOHIDDeviceUsagePageKey encoding:NSUTF8StringEncoding]];
        //[dict setObject:[NSNumber numberWithLong:kHIDUsage_GD_Keyboard]  forKey:[NSString stringWithCString:kIOHIDDeviceUsageKey encoding:NSUTF8StringEncoding]];
        
        //interface #2: right-side media key events
        //[dict setObject:[NSNumber numberWithLong:kHIDPage_Consumer]  forKey:[NSString stringWithCString:kIOHIDDeviceUsagePageKey encoding:NSUTF8StringEncoding]];
        //[dict setObject:[NSNumber numberWithLong:kHIDUsage_Csmr_ConsumerControl]  forKey:[NSString stringWithCString:kIOHIDDeviceUsageKey encoding:NSUTF8StringEncoding]];
        
        IOHIDManagerSetDeviceMatching(managerRef, (__bridge CFMutableDictionaryRef)dict);
        NSSet *allDevices = (__bridge NSSet *)IOHIDManagerCopyDevices(managerRef);
        NSArray *deviceRefs = [allDevices allObjects];
        IOHIDDeviceRef deviceRef = ([deviceRefs count]) ? (__bridge IOHIDDeviceRef)[deviceRefs objectAtIndex:0] : nil;
        
        if (deviceRef) {
            MyLog(@"I: found: %@:%@ = %@",
                  IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDTransportKey)),
                  IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDLocationIDKey)),
                  IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDProductKey))
                  );
            //MyLog(@"D: descriptor dump: %@", IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDReportDescriptorKey)));
            
            for (NSString *argname in arguments) {
                if (argname == arguments.firstObject)
                    continue; //skip $0
                MyLog(@"D: command arg: %@", argname);
                
                NSArray *bytes = [switches objectForKey:argname];
                
                if (bytes){ //this is a valid keyboard control from switches
                    set_feature(deviceRef, bytes);
                } else {
                    //usage
                    MyLog(@"Usage:\n apexctl -macrokeys [let keyboard manage Ln/Mn/MXn keys]\n\t-rawkeys [send all key codes to OS]\n\t-dim [dim main typing area lights]\n\t-bright [illuminate main typing area lights]\n\t-colorL1 [L1 color scheme]\n\t-color_quiet [no-edge-lights color scheme]\n\t-125hz\n\t-1000hz");
                    return -1;
                }
            }
        } else {
            MyLog(@"E: did not find Apex device!");
        };
        return 0;
    }
}

