/*! @file OIDExternalUserAgentMacNoSSO.h
    @brief  OIDExternalUserAgentMacNoSSO is custom user agent based on the default user agent in the AppAuth iOS SDK found here:
            https://github.com/openid/AppAuth-iOS/blob/master/Source/AppAuth/macOS/OIDExternalUserAgentMac.h
            Ths user agent allows setting `prefersEphemeralSession` flag on macOS 10.15 or newer to avoid cookies being shared across the device
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

#import <AppKit/AppKit.h>
#import <AppAuth/AppAuth.h>

NS_ASSUME_NONNULL_BEGIN

/*! @brief A Mac-specific external user-agent UI Coordinator that uses the default browser to
        present an external user-agent request.
 */
@interface OIDExternalUserAgentMacNoSSO : NSObject <OIDExternalUserAgent>

/*! @brief The designated initializer.
    @param presentingWindow The window from which to present the ASWebAuthenticationSession.
 */
- (instancetype)initWithPresentingWindow:(NSWindow *)presentingWindow NS_DESIGNATED_INITIALIZER;

- (instancetype)init __deprecated_msg("Use initWithPresentingWindow for macOS 10.15 and above.");

@end

NS_ASSUME_NONNULL_END