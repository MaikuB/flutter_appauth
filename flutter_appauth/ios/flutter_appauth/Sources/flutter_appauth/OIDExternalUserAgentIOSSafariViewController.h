/*! @file OIDExternalUserAgentIOSSafariViewController.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2018 Google Inc. All Rights Reserved.
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

NS_ASSUME_NONNULL_BEGIN

/*! @brief Allows library consumers to bootstrap an @c SFSafariViewController as
   they see fit.
    @remarks Useful for customizing tint colors and presentation styles.
 */
@protocol OIDSafariViewControllerFactory

/*! @brief Creates and returns a new @c SFSafariViewController.
    @param URL The URL which the @c SFSafariViewController should load
   initially.
 */
- (SFSafariViewController *)safariViewControllerWithURL:(NSURL *)URL;

@end

/*! @brief A special-case iOS external user-agent that always uses
        \SFSafariViewController (on iOS 9+). Most applications should use
        the more generic @c OIDExternalUserAgentIOS to get the default
        AppAuth user-agent handling with the benefits of Single Sign-on (SSO)
        for all supported versions of iOS.
 */
@interface OIDExternalUserAgentIOSSafariViewController
    : NSObject <OIDExternalUserAgent>

/*! @brief Allows library consumers to change the @c
   OIDSafariViewControllerFactory used to create new instances of @c
   SFSafariViewController.
    @remarks Useful for customizing tint colors and presentation styles.
    @param factory The @c OIDSafariViewControllerFactory to use for creating new
   instances of
        @c SFSafariViewController.
 */
+ (void)setSafariViewControllerFactory:
    (id<OIDSafariViewControllerFactory>)factory;

/*! @internal
    @brief Unavailable. Please use @c initWithPresentingViewController:
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/*! @brief The designated initializer.
    @param presentingViewController The view controller from which to present
   the
        \SFSafariViewController.
 */
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
