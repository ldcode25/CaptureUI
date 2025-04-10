//
//  SimulatorResources.h
//  SimulatorResources
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

@import Foundation;

#if TARGET_IPHONE_SIMULATOR

NS_ASSUME_NONNULL_BEGIN

@interface SimulatorResources : NSObject

@property (class, nonatomic, readonly) NSData *frontPhotoData;
@property (class, nonatomic, readonly) NSData *backPhotoData;
@property (class, nonatomic, readonly) NSData *videoData;

@end

NS_ASSUME_NONNULL_END

#endif
