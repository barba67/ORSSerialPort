//
//  ORSSerialRequest.h
//  CameraRemote
//
//  Created by Andrew Madsen on 4/21/14.
//  Copyright (c) 2014 Ryan Darton. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^ORSSerialRequestResponseEvaluator)(NSData *inputData);

/**
 *  An ORSSerialRequest encapsulates a generic "request" command sent via the serial
 *  port. 
 *  
 *  An ORSSerialRequest includes data to be sent out via the serial port.
 *  It also can contain a block which is used to evaluate received
 *  data to determine if/when a valid response to the request has been received from
 *  the device on the other end of the port. Arbitrary information can be
 *  associated with the ORSSerialRequest via its userInfo property.
 */
@interface ORSSerialRequest : NSObject

/**
 *  Creates and initializes an ORSSerialRequest instance.
 *
 *  @param dataToSend        The data to be sent on the serial port.
 *  @param userInfo          An arbitrary userInfo object.
 *  @param responseEvaluator A block used to evaluate whether received data constitutes a valid response to the request. May be nil.
 *
 *  @return An initialized ORSSerialRequest instance.
 */
+ (instancetype)requestWithDataToSend:(NSData *)dataToSend
							 userInfo:(id)userInfo
					responseEvaluator:(ORSSerialRequestResponseEvaluator)responseEvaluator;

/**
 *  Initializes an ORSSerialRequest instance.
 *
 *  @param dataToSend        The data to be sent on the serial port.
 *  @param userInfo          An arbitrary userInfo object.
 *  @param responseEvaluator A block used to evaluate whether received data constitutes a valid response to the request. May be nil.
 *
 *  @return An initialized ORSSerialRequest instance.
 */
- (instancetype)initWithDataToSend:(NSData *)dataToSend
						  userInfo:(id)userInfo
				 responseEvaluator:(ORSSerialRequestResponseEvaluator)responseEvaluator;

/**
 *  Can be used to determine if a block of data is a valid response to the request encapsulated
 *  by the receiver. If the receiver doesn't have a response data evaulator block, this method
 *  always returns YES for non-empty input data.
 *
 *  @param responseData Data received from a serial port.
 *
 *  @return YES if the data is a valid response, NO otherwise.
 */
- (BOOL)dataIsValidResponse:(NSData *)responseData;

/**
 *  Data to be sent on the serial port when the receiver is sent.
 */
@property (nonatomic, strong, readonly) NSData *dataToSend;

/**
 *  Arbitrary object (e.g. NSDictionary) used to store additional data
 *  about the request.
 */
@property (nonatomic, strong, readonly) id userInfo;

/**
 *  Unique identifier for the request.
 */
@property (nonatomic, strong, readonly) NSString *UUIDString;

@end
