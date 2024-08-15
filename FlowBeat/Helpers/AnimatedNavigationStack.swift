//
//  AnimatedNavigationStack.swift
//  FlowBeat
//
//  Created by Ostap Artym on 15.08.2024.
//

import SwiftUI

/// Note that the default Navigation Bar will be hidden when using this View!
struct AnimatedNavigationStack<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            content
                .background(AttachAnimationToNavigationController())
        }
    }
}

fileprivate struct AttachAnimationToNavigationController: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let navController = view.parentViewController?.navigationController as? UINavigationController {
                /// Saving the pre-defined delegate class
                context.coordinator.delegate = navController.delegate
                /// Setting up new delegate
                navController.delegate = context.coordinator
                
                let edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
                edgeSwipeGestureRecognizer.edges = .left
                navController.view.addGestureRecognizer(edgeSwipeGestureRecognizer)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {  }
    
    class Coordinator: NSObject, UINavigationControllerDelegate {
        var delegate: UINavigationControllerDelegate?
        
        private var interactionController: FadeInteractiveAnimator?
        
        /// Calling already defined delegates methods by Navigation Stack
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            delegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
        
        func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
            navigationController.setNavigationBarHidden(true, animated: false)
            delegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
        
        /// Animation Controller for push and pop aactions
        func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
            if operation == .pop {
                return FadeAnimator(presenting: false)
            } else {
                return FadeAnimator(presenting: true)
            }
        }
        
        func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return interactionController
        }
        
        @objc func handleSwipe(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
            let percent = gestureRecognizer.translation(in: gestureRecognizer.view!).x / gestureRecognizer.view!.bounds.size.width
            
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view!).x / gestureRecognizer.view!.bounds.size.width
            let total = max(min(percent + velocity, 1), 0)

            if let navController = gestureRecognizer.view?.parentViewController as? UINavigationController {
                if gestureRecognizer.state == .began {
                    interactionController = FadeInteractiveAnimator()
                    navController.popViewController(animated: true)
                } else if gestureRecognizer.state == .changed {
                    interactionController?.update(percent)
                } else if gestureRecognizer.state == .ended {
                    if total > 0.5 && gestureRecognizer.state != .cancelled {
                        interactionController?.finish()
                    } else {
                        interactionController?.cancel()
                    }
                    interactionController = nil
                }
            }
        }
    }
}

// MARK: Fade In/Out Animator (Not Interactive)
fileprivate class FadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let presenting: Bool
    
    init(presenting: Bool) {
        self.presenting = presenting
    }

    var isCompleted: Bool = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }

        fromView.backgroundColor = .clear
        toView.backgroundColor = .clear
        
        let shirnkScale = CATransform3DMakeScale(0.9, 0.9, 0.9)
        let largeScale = CATransform3DMakeScale(1.1, 1.1, 1.1)
        
        guard !transitionContext.isInteractive else { return }
        
        let container = transitionContext.containerView
        if presenting {
            container.addSubview(toView)
            toView.alpha = 0.0
            
            toView.layer.transform = shirnkScale
        } else {
            toView.layer.transform = largeScale
            container.insertSubview(toView, belowSubview: fromView)
        }
        
        let duration = transitionDuration(using: transitionContext) / 2
        
        UIView.animate(withDuration: duration, animations: {
            if self.presenting {
                fromView.layer.transform = largeScale
                fromView.alpha = 0
            } else {
                fromView.layer.transform = shirnkScale
                fromView.alpha = 0.0
            }
        }, completion: nil)
        
        /// The Push/pop only happens when previous view has been faded out.
        UIView.animate(withDuration: duration, delay: duration / 2.5) {
            if self.presenting {
                toView.layer.transform = CATransform3DIdentity
                toView.alpha = 1.0
            } else {
                toView.layer.transform = CATransform3DIdentity
                toView.alpha = 1.0
            }
        } completion: { _ in
            let success = !transitionContext.transitionWasCancelled
            if !success { toView.removeFromSuperview() }
            transitionContext.completeTransition(success)
        }
    }
}

// MARK: Interactive Fade In/Out Animator
fileprivate class FadeInteractiveAnimator: UIPercentDrivenInteractiveTransition {
    private var context: UIViewControllerContextTransitioning?
    
    override func update(_ percentComplete: CGFloat) {
        super.update(percentComplete)
        updateView(percentComplete)
    }
    
    override func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        
        self.context = transitionContext
        let containerView = transitionContext.containerView
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        containerView.insertSubview(toView, belowSubview: fromView)
    }
    
    override func finish() {
        super.finish()
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.updateView(1.0)
        } completion: { [weak self] _ in
            self?.removeView()
        }
    }
    
    override func cancel() {
        super.cancel()
        
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.updateView(0.0)
        } completion: { [weak self] _ in
            self?.context?.completeTransition(false)
        }
    }
    
    private func updateView(_ percentComplete: CGFloat) {
        guard let context = context else { return }
        guard let fromView = context.view(forKey: .from) else { return }
        guard let toView = context.view(forKey: .to) else { return }
        
        let fromProgress = max(min((percentComplete * 1.1) / 0.5, 1), 0)
        let fromScale = 1 - (0.1 * fromProgress)
        let shirnkScale = CATransform3DMakeScale(fromScale, fromScale, fromScale)
        
        fromView.alpha = 1 - fromProgress
        fromView.layer.transform = shirnkScale
        
        let toProgress = max(min(((percentComplete * 1.1) - 0.5) / 0.5, 1), 0)
        let toScale = 1.1 - (0.1 * toProgress)
        let regularScale = CATransform3DMakeScale(toScale, toScale, toScale)
        
        toView.alpha = toProgress
        toView.layer.transform = regularScale
    }
    
    private func removeView() {
        guard let context = context else { return }
        
        guard let toView = context.view(forKey: .from) else { return }
        toView.removeFromSuperview()
        context.completeTransition(true)
    }
}

/// Find's the Parent UIViewController from UIView
fileprivate extension UIView {
    var parentViewController: UIViewController? {
        sequence(first: self) { $0.next }
            .compactMap{ $0 as? UIViewController }
            .first
    }
}
