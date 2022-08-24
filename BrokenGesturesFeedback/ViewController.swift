// Created by eric_horacek on 8/23/22.
// Copyright © 2022 Airbnb Inc. All rights reserved.

import UIKit
import SwiftUI

// MARK: - ViewController

class ViewController: UINavigationController {
  override func viewDidLoad() {
    super.viewDidLoad()
    super.isNavigationBarHidden = true
    updateViewControllers()
    delegate = self
  }

  override var isNavigationBarHidden: Bool {
    get { super.isNavigationBarHidden }
    set { super.isNavigationBarHidden = true }
  }

  override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
    super.setNavigationBarHidden(true, animated: animated)
  }

  var showDetail = false {
    didSet {
      updateViewControllers()
    }
  }

  private lazy var root = MyHostingController(content: Step(title: "Go forward") { [weak self] in
    self?.showDetail = true
  })

  private func updateViewControllers() {
    var viewControllers: [UIViewController] = [root]
    if showDetail {
      viewControllers.append(MyHostingController(content: Step(title: "Go back") { [weak self] in
        self?.showDetail = false
      }))
    }
    setViewControllers(viewControllers, animated: true)
  }
}

final class MyHostingController<Content: View>: UIViewController {

  init(content: Content) {
    hostingController = UIHostingController(rootView: content)
    super.init(nibName: nil, bundle: nil)
    addChild(hostingController)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let hostingController: UIHostingController<Content>

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(hostingController.view)
    hostingController.view.frame = view.bounds
    hostingController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    hostingController.view.frame = view.bounds.offsetBy(dx: 1, dy: 0)
    hostingController.view.frame = view.bounds
  }
}

// MARK: UINavigationControllerDelegate

extension ViewController: UINavigationControllerDelegate {
  func navigationController(
    _ navigationController: UINavigationController,
    animationControllerFor operation: UINavigationController.Operation,
    from fromVC: UIViewController,
    to toVC: UIViewController)
    -> UIViewControllerAnimatedTransitioning?
  {
    PushPopAnimatedTransition(operation: operation)
  }
}

// MARK: - PushPopAnimatedTransition

final class PushPopAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
  init(operation: UINavigationController.Operation) {
    self.operation = operation
  }

  var operation: UINavigationController.Operation

  func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?)
    -> TimeInterval
  {
    0.5
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    let duration = transitionDuration(using: transitionContext)

    let container = transitionContext.containerView
    let to = transitionContext.view(forKey: .to)!
    let from = transitionContext.view(forKey: .from)!

    container.addSubview(from)
    container.addSubview(to)
    from.frame = container.bounds
    to.frame = container.bounds
    from.transform = .identity
    switch operation {
    case .none, .push:
      to.transform = CGAffineTransform(translationX: container.bounds.width, y: 0)
    case .pop:
      container.bringSubviewToFront(from)
      to.transform = CGAffineTransform(translationX: -100, y: 0)
    @unknown default:
      break
    }

    // This is the line that breaks gestures in the `UIHostingController`.
    //
    // While this animated transition technically does not need this layout pass, you can easily
    // imagine an animated transition that does, e.g. a transition that's based on some attributes
    // of the "to" view controller that are only known after a layout pass.
    to.layoutIfNeeded()

    let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1)

    animator.addAnimations {
      to.transform = .identity
      switch self.operation {
      case .none, .push:
        from.transform = CGAffineTransform(translationX: -100, y: 0)
      case .pop:
        from.transform = CGAffineTransform(translationX: container.bounds.width, y: 0)
      @unknown default:
        break
      }
    }

    animator.addCompletion { (position) in
      transitionContext.completeTransition(true)
      from.transform = .identity
    }

    animator.startAnimation()
  }
}

// MARK: - Step

struct Step: View {
  var title: String
  var action: () -> Void

  var body: some View {
    ScrollView {
      Button(title, action: action)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.white.shadow(radius: 10).ignoresSafeArea())
  }
}
