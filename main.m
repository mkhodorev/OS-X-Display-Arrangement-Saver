// OS X Display Arrangement Saver
//
// Copyright (c) 2014 Eugene Cherny
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IOKit/graphics/IOGraphicsLib.h>

void printHelp();
void printInfo();
void saveArrangement(NSString* savePath);
void loadArrangement(NSString* savePath);

bool checkDisplayAvailability(NSArray* displaySerials);
CGDirectDisplayID getDisplayID(NSScreen* screen);
NSString* getScreenSerial(NSScreen* screen);
NSPoint getScreenPosition(NSScreen* screen);

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        printInfo();
        saveArrangement(@"~/Desktop/config.plist");
        loadArrangement(@"~/Desktop/config.plist");
    }
    return 0;
}

@implementation NSData (Hex) // Somewhere from StackOverflow
- (NSString *) hexString
{
    NSUInteger bytesCount = self.length;
    if (bytesCount) {
        const char* hexChars = "0123456789ABCDEF";
        const unsigned char* dataBuffer = self.bytes;
        char* chars = malloc(sizeof(char) * (bytesCount * 2 + 1));
        char* s = chars;
        for (unsigned i = 0; i < bytesCount; ++i) {
            *s++ = hexChars[((*dataBuffer & 0xF0) >> 4)];
            *s++ = hexChars[(*dataBuffer & 0x0F)];
            dataBuffer++;
        }
        *s = '\0';
        NSString* hexString = [NSString stringWithUTF8String:chars];
        free(chars);
        return hexString;
    }
    return @"";
}
@end


// COMMAND LINE

void printHelp() {
    
}

void printInfo() {
    NSArray* screens = [NSScreen screens];
    printf("Total: %lu\n", (unsigned long)[screens count]);
    for (NSScreen* screen in screens) {
        CGDirectDisplayID screenNumber = getDisplayID(screen);
        NSString* serial = getScreenSerial(screen);
        NSPoint position = getScreenPosition(screen);
        printf("  Display %li\n", (long)screenNumber);
        printf("    Serial:   %s\n", [serial UTF8String]);
        printf("    Position: {%i, %i}\n", (int)position.x, (int)position.y);
    }
}

void saveArrangement(NSString* savePath) {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    NSArray* screens = [NSScreen screens];
    [dict setObject:@"ScreenArrangement" forKey:@"About"];
    for (NSScreen* screen in screens) {
        NSString* serial = getScreenSerial(screen);
        NSPoint position = getScreenPosition(screen);
        NSArray* a = [NSArray arrayWithObjects: [NSNumber numberWithInt:position.x], [NSNumber numberWithInt: position.y], nil];
        [dict setObject:a forKey:serial];
    }
    if ([dict writeToFile:[savePath stringByExpandingTildeInPath] atomically: YES]) {
        printf("Configuration file has been saved.\n");
    } else {
        printf("Error: Error saving configuration file.\n");
    }
}

void loadArrangement(NSString* savePath) {
    NSMutableDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:[savePath stringByExpandingTildeInPath]];
    if (dict == nil) {
        printf("Error: Can't load file\n");
    }
    if (![[dict objectForKey:@"About"] isEqualToString:@"ScreenArrangement"]) {
        printf("Error: Wrong .plist file.\n");
    }
    [dict removeObjectForKey:@"About"];
    if (!checkDisplayAvailability([dict allKeys])) {
        printf("Error: Probably, this configuration file has been made for different display set.\n");
        return;
    }
    
    CGDisplayConfigRef config;
    CGBeginDisplayConfiguration(&config);
    for (NSScreen* screen in [NSScreen screens]) {
        NSString* serial = getScreenSerial(screen);
        CGDirectDisplayID displayID = getDisplayID(screen);
        NSArray* xy = [dict objectForKey:serial];
        int32_t x = [(NSNumber*)xy[0] intValue];
//        int32_t y = [(NSNumber*)xy[1] doubleValue];
        CGConfigureDisplayOrigin(config, displayID, x, 0);  // TODO for my need y-aligning is not necessary
    }
    CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    printf("Screen arrangement has been loaded\n");
}

// UTILITY FUNCTIONS

bool checkDisplayAvailability(NSArray* displaySerials) {
    NSArray* screens = [NSScreen screens];
    for (NSScreen* screen in screens) {
        NSString* serial = getScreenSerial(screen);
        if (![displaySerials containsObject:serial]) {
            return false;
        }
    }
    return true;
}

CGDirectDisplayID getDisplayID(NSScreen* screen) {
    NSDictionary* screenDescription = [screen deviceDescription];
    return [[screenDescription objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

NSString* getScreenSerial(NSScreen* screen) {
    // In fact, the function returns vendor id concateneted with serial number
    CGDirectDisplayID displayID = getDisplayID(screen);
    NSDictionary *deviceInfo = (__bridge_transfer NSDictionary*) IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
    NSData* edid = [deviceInfo objectForKey:@"IODisplayEDID"];
    NSString* name = [[edid subdataWithRange:NSMakeRange(10, 6)] hexString];
    return name;
}

NSPoint getScreenPosition(NSScreen* screen) {
    NSRect frame = [screen frame];
    NSPoint point;
    point.x = frame.origin.x;
    point.y = frame.origin.y;
    return point;
}

