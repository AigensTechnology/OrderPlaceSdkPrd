//
//  AigensPresentationController.swift
//  testModalAnima
//
//  Created by 陈培爵 on 2021/2/3.
//  Copyright © 2021 陈培爵. All rights reserved.
//

import UIKit

/**
 usage:
 let aigensPresentationController = AigensPresentationController(presentedViewController: nav, presenting: self)
 nav.transitioningDelegate = aigensPresentationController
 self.present(nav, animated: true, completion: nil)
 */
class AigensPresentationController: UIPresentationController {
    var dimmingView: UIView?
    
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        // 必须设置 presentedViewController 的 modalPresentationStyle
        // 在自定义动画效果的情况下，苹果强烈建议设置为 UIModalPresentationCustom
        presentedViewController.modalPresentationStyle = .custom
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = .black
        dimmingView.isOpaque = false
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.dimmingView = dimmingView
        
        // 添加到动画容器View中。
        self.containerView!.addSubview(dimmingView)
        
        
        self.dimmingView?.alpha = 0.0
        
        
        // 获取presentingViewController 的转换协调器，应该动画期间的一个类？上下文？之类的，负责动画的一个东西
//        let transitionCoordinator = presentingViewController.transitionCoordinator
//        self.dimmingView?.alpha = 0.0
//        transitionCoordinator?.animate(alongsideTransition: { (context) in
//            self.dimmingView?.alpha = 0.0
//        }, completion: nil)
    }
    
    // 在呈现过渡结束时被调用的，并且该方法提供一个布尔变量来判断过渡效果是否完成
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            self.dimmingView = nil
        }
    }
    
    // 消失过渡即将开始的时候被调用的
    override func dismissalTransitionWillBegin() {
         let transitionCoordinator = presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.dimmingView?.alpha = 0.0
        }, completion: nil)
    
    }
    
    // 消失过渡完成之后调用，此时应该将视图移除，防止强引用
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if (completed) {
            self.dimmingView?.removeFromSuperview()
            self.dimmingView = nil
        }
    }
    
    //| --------以下四个方法，是按照苹果官方Demo里的，都是为了计算目标控制器View的frame的----------------
    //  当 presentation controller 接收到
    //  -viewWillTransitionToSize:withTransitionCoordinator: message it calls this
    //  method to retrieve the new size for the presentedViewController's view.
    //  The presentation controller then sends a
    //  -viewWillTransitionToSize:withTransitionCoordinator: message to the
    //  presentedViewController with this size as the first argument.
    //
    //  Note that it is up to the presentation controller to adjust the frame
    //  of the presented view controller's view to match this promised size.
    //  We do this in -containerViewWillLayoutSubviews.
    //
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if (container.isEqual(self.presentedViewController)) {
            return container.preferredContentSize
        }else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
    
    //在我们的自定义呈现中，被呈现的 view 并没有完全完全填充整个屏幕，
    //被呈现的 view 的过渡动画之后的最终位置，是由 UIPresentationViewController 来负责定义的。
    //我们重载 frameOfPresentedViewInContainerView 方法来定义这个最终位置
    override var frameOfPresentedViewInContainerView: CGRect {
        get {
            guard let containerView = self.containerView else {
                return super.frameOfPresentedViewInContainerView
            }
            let containerViewBounds = containerView.bounds
            let presentedViewContentSize = self.size(forChildContentContainer: self.presentedViewController, withParentContainerSize: containerViewBounds.size)
            
            // The presented view extends presentedViewContentSize.height points from
            // the bottom edge of the screen.
            var presentedViewControllerFrame = containerViewBounds;
            
            presentedViewControllerFrame.size.height = presentedViewContentSize.height;
            presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height;
            return presentedViewControllerFrame
        }
        set {
            
        }
    }
    
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let c = self.containerView {
            self.dimmingView?.frame = c.bounds
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if (container.isEqual(self.presentedViewController)) {
            containerView?.setNeedsLayout()
        }
    }
    
    
}
extension AigensPresentationController: UIViewControllerAnimatedTransitioning {


    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return (transitionContext?.isAnimated ?? false) ? 0.55 : 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 1.获取源控制器、目标控制器、动画容器View
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
//        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        let containerView = transitionContext.containerView
        
        // 2. 获取源控制器、目标控制器 的View，但是注意二者在开始动画，消失动画，身份是不一样的：
        // 也可以直接通过上面获取控制器获取，比如：toViewController.view
        // For a Presentation:
        //      fromView = The presenting view.
        //      toView   = The presented view.
        // For a Dismissal:
        //      fromView = The presented view.
        //      toView   = The presenting view.
        
        // 判断是present 还是 dismiss
        let isPresenting = fromViewController == presentingViewController
        
        
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)
        
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
        
        //必须添加到动画容器View上。
        if (toView != nil) {
            containerView.addSubview(toView!)
        }
        
        
        let screenW = containerView.bounds.width
        let screenH = containerView.bounds.height
        
        let x = 0.0
        let y = 0.0
        let w = screenW;
        let h = screenH;
        
        let startFrame = CGRect(x: w, y: CGFloat(y), width: w, height: h)
        let pushFrame = CGRect(x: CGFloat(x), y: CGFloat(y), width: w, height: h)
        let popFrame = CGRect(x: w, y: CGFloat(y), width: w, height: h)
        
        if (isPresenting) {
            toView?.frame = startFrame;
        }
        
        let duration = self.transitionDuration(using: transitionContext)
        // duration： 动画时长
        // delay： 决定了动画在延迟多久之后执行
        // damping：速度衰减比例。取值范围0 ~ 1，值越低震动越强
        // velocity：初始化速度，值越高则物品的速度越快
        // UIViewAnimationOptionCurveEaseInOut 加速，后减速
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveEaseOut , animations: {
            if (isPresenting) {
                toView?.frame = pushFrame
            }else {
                fromView?.frame = popFrame
            }
        }) { (finished) in
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
    }
    
    // This is a convenience and if implemented will be invoked by the system when the transition context's completeTransition: method is invoked.
    func animationEnded(_ transitionCompleted: Bool) {
        // 动画结束...
    }
}


extension AigensPresentationController: UIViewControllerTransitioningDelegate {
    
    // 返回的对象控制Presented时的动画 (开始动画的具体细节负责类)
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    // 由返回的控制器控制dismissed时的动画 (结束动画的具体细节负责类)
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    /*
    * 来告诉控制器，谁是动画主管(UIPresentationController)，因为此类继承了UIPresentationController，就返回了self
    */
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
}
