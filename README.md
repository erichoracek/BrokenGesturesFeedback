# BrokenGesturesFeedback

SwiftUI gestures break when contained in a `UIHostingController` that had a layout pass in a UIKit animated transition

## Description

When a newly instantiated `UIHostingController` is animated as part of a `UIViewControllerAnimatedTransitioning` within a `UINavigationController` that has a call to `view.layoutIfNeeded()` on the `UIHostingController`'s view, SwiftUI gestures stop being processed, resulting in an unresponsive application. 

Notably, gestures for embedded UIKit `UIView`s are still processed correctly; the only gestures that break are those implemented in SwiftUI, e.g. the tap gesture of a Button. There is an attached project that minimally reproduces this issue. 

This issue reproduces on iOS 15 and iOS 16 Beta 6.

From poking around under the hood, it appears that when this occurs the `SwiftUI.EventBindingManager` never goes into the `isActive = true` state when the touches begin, and the `SwiftUI.UIKitGestureRecognizer` does not transition to the `ended` state on `UIGestureRecognizer.touchesEnded(…)`. A mitigation for this behavior is removing and re-adding the UIHostingController's view to the view hierarchy.

## Recording

https://user-images.githubusercontent.com/438313/186284534-5a59bd13-465d-4598-90d0-3c8380fd7c27.mov
