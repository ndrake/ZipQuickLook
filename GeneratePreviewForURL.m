#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
   Generate a preview for a zip file


   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	// Get the posix-style path for the thing we are quicklooking at
	CFStringRef fullPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);

	NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/unzip"];
	
    NSArray *arguments;
	
	// ZipInfo style (just file names)
    //arguments = [NSArray arrayWithObjects: @"-Z1", fullPath, nil];
	
	arguments = [NSArray arrayWithObjects: @"-l", fullPath, nil];	

    [task setArguments: arguments];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

	// Check for cancel
	if(QLPreviewRequestIsCancelled(preview)) {
		[pool release];
		return noErr;
	}

    [task launch];
	
    NSData *data;
    data = [file readDataToEndOfFile];

	[task waitUntilExit];
	int status = [task terminationStatus];

	if (status != 0) {
		[pool release];
		return noErr;
	}

	// Check for cancel
	if(QLPreviewRequestIsCancelled(preview)) {
		[pool release];
		return noErr;
	}

    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	// Set properties for the preview data
	NSMutableDictionary *props=[[[NSMutableDictionary alloc] init] autorelease];
    [props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
    [props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
	[props setObject:[NSString stringWithFormat:@"Contents of %@", fullPath] forKey:(NSString *)kQLPreviewPropertyDisplayNameKey];
	
	// Build the HTML
    NSMutableString *html=[[[NSMutableString alloc] init] autorelease];
    [html appendString:@"<html><body bgcolor=white><pre>"];
	[html appendString:string];
	[html appendString:@"</pre></body></html>"];
	
	QLPreviewRequestSetDataRepresentation(preview,(CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML,(CFDictionaryRef)props);
	
    [pool release];
    return noErr;

}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
