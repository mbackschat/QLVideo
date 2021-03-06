#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>

#include "snapshotter.h"

extern NSBundle *myBundle;

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // https://developer.apple.com/library/prerelease/mac/documentation/UserExperience/Conceptual/Quicklook_Programming_Guide/Articles/QLImplementationOverview.html

    @autoreleasepool {
        Snapshotter *snapshotter = [[Snapshotter alloc] initWithURL:url];
        if (!snapshotter) return kQLReturnNoError;
        
        if (QLPreviewRequestIsCancelled(preview)) return kQLReturnNoError;
        CGSize size = [snapshotter displaySize];
        CGImageRef snapshot = [snapshotter CreateSnapshotWithSize:size];
        if (!snapshot) return kQLReturnNoError;

        if (QLPreviewRequestIsCancelled(preview))
        {
            CGImageRelease(snapshot);
            return kQLReturnNoError;
        }

        // Replace title string
        NSString *title, *channels;
        switch ([snapshotter channels])
        {
            case 0:
                channels = myBundle ? [myBundle localizedStringForKey:@"🔇"     value:nil table:nil] : @"🔇"; break;
            case 1:
                channels = myBundle ? [myBundle localizedStringForKey:@"mono"   value:nil table:nil] : @"mono"; break;
            case 2:
                channels = myBundle ? [myBundle localizedStringForKey:@"stereo" value:nil table:nil] : @"stereo"; break;
            case 6:
                channels = myBundle ? [myBundle localizedStringForKey:@"5.1"    value:nil table:nil] : @"5.1"; break;
            case 7:
                channels = myBundle ? [myBundle localizedStringForKey:@"6.1"    value:nil table:nil] : @"6.1"; break;
            case 8:
                channels = myBundle ? [myBundle localizedStringForKey:@"7.1"    value:nil table:nil] : @"7.1"; break;
            default:    // Quadraphonic, LCRS or something else
                channels = [NSString stringWithFormat:(myBundle ? [myBundle localizedStringForKey:@"%d🔉" value:nil table:nil] : @"%d🔉"),
                            [snapshotter channels]];
        }
        if ([snapshotter title])
            title = [NSString stringWithFormat:@"%@ (%d×%d %@)", [snapshotter title],
                     (int) size.width, (int) size.height, channels];
        else
            title = [NSString stringWithFormat:@"%@ (%d×%d %@)", [(__bridge NSURL *)url lastPathComponent],
                     (int) size.width, (int) size.height, channels];
        NSDictionary *properties = [NSDictionary dictionaryWithObject:title forKey:(NSString *) kQLPreviewPropertyDisplayNameKey];

        // display
        CGContextRef context = QLPreviewRequestCreateContext(preview, size, true, (__bridge CFDictionaryRef) properties);
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), snapshot);
        QLPreviewRequestFlushContext(preview, context);
        CGContextRelease(context);
        CGImageRelease(snapshot);
    }
    return kQLReturnNoError;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
