import UIKit

extension UIViewController {
    
    static var topMostController: UIViewController? {
        guard let keyWindow = UIApplication.shared.delegate?.window ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow && $0.rootViewController != nil }) else { return nil }
        return topMost(of: keyWindow.rootViewController)
    }
    
    private static func topMost(of viewController: UIViewController?) -> UIViewController? {
        
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}
