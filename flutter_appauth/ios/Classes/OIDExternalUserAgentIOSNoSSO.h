/*! @file OIDExternalUserAgentIOSNoSSO.h
    @brief OIDExternalUserAgentIOSNoSSO is a custom user agent based on the default user agent in the AppAuth iOS SDK found here:
            https://github.com/openid/AppAuth-iOS/blob/master/Source/iOS/OIDExternalUserAgentIOS.h
            Ths user agent allows setting `prefersEphemeralSession` flag on iOS 13 or newer to avoid cookies being shared across the device.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <AppAuth/AppAuth.h>

@class SFSafariViewController;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(macCatalyst)
@interface OIDExternalUserAgentIOSNoSSO : NSObject<OIDExternalUserAgent>

- (nullable instancetype)init API_AVAILABLE(ios(11))
    __deprecated_msg("This method will not work on iOS 13, use "
                     "initWithPresentingViewController:presentingViewController");

/*! @brief The designated initializer.
    @param presentingViewController The view controller from which to present the
        \SFSafariViewController.
 */
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
