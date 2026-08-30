/*! @file OIDExternalUserAgentIOSNoSSO.h
    @brief OIDExternalUserAgentIOSNoSSO is a custom user agent based on the
   default user agent in the AppAuth iOS SDK found here:
            https://github.com/openid/AppAuth-iOS/blob/master/Source/iOS/OIDExternalUserAgentIOS.h
            This user agent allows setting the `prefersEphemeralSession` flag on
   iOS 13 or newer to avoid cookies being shared across the device. It also
   supports `https` redirect URIs on iOS 17.4 or newer by
   using `ASWebAuthenticationSession`'s `callbackWithHTTPSHost:path:` API when
   the redirect URL passed to the designated initializer uses the `https`
   scheme.
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

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif
#import <UIKit/UIKit.h>

@class SFSafariViewController;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(macCatalyst)
@interface OIDExternalUserAgentIOSNoSSO : NSObject <OIDExternalUserAgent>

- (nullable instancetype)init API_AVAILABLE(ios(11))__deprecated_msg(
    "This method will not work on iOS 13, use "
    "initWithPresentingViewController:presentingViewController");

/*! @brief Convenience initializer that prefers an ephemeral session and does
   not enable `https` redirect URI handling.
    @param presentingViewController The view controller from which to present
   the \SFSafariViewController.
 */
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController;

/*! @brief The designated initializer.
    @param presentingViewController The view controller from which to present
   the \SFSafariViewController.
    @param prefersEphemeralSession Whether the underlying
   `ASWebAuthenticationSession` should use a private (ephemeral) browser session
   so cookies are not shared across the device.
    @param redirectURL The redirect URL of the request. When this uses the
   `https` scheme, the `ASWebAuthenticationSession` is started with a
   `callbackWithHTTPSHost:path:` callback on iOS 17.4 or newer so that HTTPS
   URLs can be used as redirect URIs. May be nil, in which case the legacy
   `callbackURLScheme:` behaviour is used.
 */
- (nullable instancetype)
    initWithPresentingViewController:
        (UIViewController *)presentingViewController
             prefersEphemeralSession:(BOOL)prefersEphemeralSession
                         redirectURL:(nullable NSURL *)redirectURL
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
