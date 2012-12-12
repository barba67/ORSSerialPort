//
//  main.m
//  ORSSerialPortCommandLineDemo
//
//  Created by Andrew Madsen on 12/11/12.
//  Copyright (c) 2012 Open Reel Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"

@interface ORSSerialPortHelper : NSObject <ORSSerialPortDelegate>

@property (nonatomic, strong) ORSSerialPort *serialPort;

@end

typedef NS_ENUM(NSUInteger, ORSApplicationState) {
	ORSInitializationState = 0,
	ORSWaitingForPortSelectionState,
	ORSWaitingForBaudRateInput,
	ORSWaitingForUserInputState,
	};

static ORSApplicationState gCurrentApplicationState = ORSInitializationState;
static ORSSerialPortHelper *serialPortHelper = nil;

void printIntroduction(void)
{
	printf("This program demonstrates the use of ORSSerialPort\n");
	printf("in a Foundation-based command-line tool.\n");
	printf("Please see http://github.com/armadsen/ORSSerialPort/\nor email andrew@openreelsoftware.com for more information.\n\n");
}

void printPrompt(void)
{
	printf("\n> ");
}

void listAvailablePorts(void)
{
	printf("\nPlease select a serial port: \n");
	ORSSerialPortManager *manager = [ORSSerialPortManager sharedSerialPortManager];
	NSArray *availablePorts = manager.availablePorts;
	[availablePorts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ORSSerialPort *port = (ORSSerialPort *)obj;
		printf("%lu. %s\n", (unsigned long)idx, [port.name UTF8String]);
	}];
	printPrompt();
}

void promptForBaudRate(void)
{
	printf("\nPlease enter a baud rate:");
}

BOOL setupAndOpenPortWithSelectionString(NSString *selectionString)
{
	selectionString = [selectionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSCharacterSet *invalidChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
	if ([selectionString rangeOfCharacterFromSet:invalidChars].location != NSNotFound) return NO;
	
	ORSSerialPortManager *manager = [ORSSerialPortManager sharedSerialPortManager];
	NSArray *availablePorts = manager.availablePorts;
	
	NSInteger index = [selectionString integerValue];
	index = MIN(MAX(index, 0), [availablePorts count]-1);
	
	ORSSerialPort *port = [availablePorts objectAtIndex:index];
	serialPortHelper = [[ORSSerialPortHelper alloc] init];
	serialPortHelper.serialPort = port;
	port.delegate = serialPortHelper;
	[port open];
	return YES;
}

BOOL setBaudRateOnPortWithString(NSString *string)
{
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSCharacterSet *invalidChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
	if ([string rangeOfCharacterFromSet:invalidChars].location != NSNotFound) return NO;

	NSInteger baudRate = [string integerValue];
	serialPortHelper.serialPort.baudRate = @(baudRate);
	printf("Baud rate set to %li", (long)baudRate);
	return YES;
}

void handleUserInputData(NSData *dataFromUser)
{
	NSString *string = [[NSString alloc] initWithData:dataFromUser encoding:NSUTF8StringEncoding];
	if ([string rangeOfString:@"exit" options:NSCaseInsensitiveSearch].location == 0 ||
		[string rangeOfString:@"quit" options:NSCaseInsensitiveSearch].location == 0)
	{
		printf("Quitting...\n");
		exit(0);
		return;
	}

	switch (gCurrentApplicationState) {
		case ORSWaitingForPortSelectionState:
			if (!setupAndOpenPortWithSelectionString(string))
			{
				printf("\nError: Invalid port selection.");
				listAvailablePorts();
				return;
			}
			promptForBaudRate();
			gCurrentApplicationState = ORSWaitingForBaudRateInput;
			break;
		case ORSWaitingForBaudRateInput:
			if (!setBaudRateOnPortWithString(string))
			{
				printf("\nError: Invalid baud rate. Baud rate should consist only of numeric digits.");
				promptForBaudRate();
				return;
			}
			gCurrentApplicationState = ORSWaitingForUserInputState;
			printPrompt();
			break;
		case ORSWaitingForUserInputState:
			[serialPortHelper.serialPort sendData:dataFromUser];
			printPrompt();
			break;
		default:
			break;
	}
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		
		printIntroduction();
		
		if ([[[ORSSerialPortManager sharedSerialPortManager] availablePorts] count] == 0)
		{
			printf("No connected serial ports found. Please connect your USB to serial adapter(s) and run the program again.\n\n");
			return 0;
		}
		
		listAvailablePorts();
		gCurrentApplicationState = ORSWaitingForPortSelectionState;
		
		NSFileHandle *standardInputHandle = [NSFileHandle fileHandleWithStandardInput];
		standardInputHandle.readabilityHandler = ^(NSFileHandle *fileHandle) { handleUserInputData([fileHandle availableData]); };
		
		[[NSRunLoop currentRunLoop] run]; // Required to receive data from ORSSerialPort and to process user input
		
		// Cleanup
		standardInputHandle.readabilityHandler = nil;
		serialPortHelper = nil;
	}
	
    return 0;
}

@implementation ORSSerialPortHelper

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	printf("\nReceived: \"%s\" %s", [string UTF8String], [[data description] UTF8String]);
	printPrompt();
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort
{
	self.serialPort = nil;
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, serialPort, error);
}

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
	printf("Serial port %s was opened", [serialPort.name UTF8String]);
	printPrompt();
}

@end