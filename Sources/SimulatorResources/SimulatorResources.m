//
//  SimulatorResources.m
//  SimulatorResources
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

#import "SimulatorResources.h"

@import Foundation;

#if TARGET_IPHONE_SIMULATOR

// Following assembler code to include binary only works on Apple Silicon.
#if !TARGET_CPU_ARM64
#error Not Supported
#endif

#define STR(x) #x
#define INCBIN(prefix, name, file) \
    __asm__( \
        ".section __TEXT,__const\n" \
        ".global _" STR(prefix) "_" STR(name) "_start\n" \
        ".balign 16\n" \
        "_" STR(prefix) "_" STR(name) "_start:\n" \
        ".incbin \"" file "\"\n" \
        ".global " STR(prefix) "_" STR(name) "_end\n" \
        ".balign 1\n" \
        "_" STR(prefix) "_" STR(name) "_end:\n" \
        ".byte 0\n" \
    ); \
    __attribute__((aligned(16))) extern const char prefix ## _ ## name ## _start[]; \
    extern const char prefix ## _ ## name ## _end[];

// `incbin` is locating the file from `include` path in Swift package.
INCBIN(simulator_resources, front_photo, "../front_photo.jpg");
INCBIN(simulator_resources, back_photo, "../back_photo.jpg");
INCBIN(simulator_resources, video, "../video.mov");

@implementation SimulatorResources

+ (NSData *)frontPhotoData
{
    char * const start = (char *)&simulator_resources_front_photo_start;
    const NSUInteger size = (char *)&simulator_resources_front_photo_end - (char *)&simulator_resources_front_photo_start;
    return [[NSData alloc] initWithBytes:start length:size];
}

+ (NSData *)backPhotoData
{
    char * const start = (char *)&simulator_resources_back_photo_start;
    const NSUInteger size = (char *)&simulator_resources_back_photo_end - (char *)&simulator_resources_back_photo_start;
    return [[NSData alloc] initWithBytes:start length:size];
}

+ (NSData *)videoData
{
    char * const start = (char *)&simulator_resources_video_start;
    const NSUInteger size = (char *)&simulator_resources_video_end - (char *)&simulator_resources_video_start;
    return [[NSData alloc] initWithBytes:start length:size];
}

@end

#endif
