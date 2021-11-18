import UIKit

public protocol NavigatorRegistering {
    static func registerAllURLs()
}

public protocol Navigating {
    var navigator: Navigator { get }
}

extension Navigating {
    public var navigator: Navigator {
        Navigator.root
    }
}

public typealias URLPattern = String
public typealias NavigatorFactoryViewController = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?
public typealias NavigatorFactoryOpenHandler = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
public typealias NavigatorOpenHandler = () -> Bool

public final class Navigator {
    
    public static var main: Navigator = Navigator()
    public static var root: Navigator = main
    
    /// 调用函数以强制一次性初始化解析器注册表。 通常不需要主动调用
    /// 第一次调用解析函数时会自动解析
    public final func registerServices() {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
    }
    
    /// 调用函数以强制一次性初始化解析器注册表。 通常不需要主动调用
    /// 第一次调用解析函数时会自动解析
    public static var registerServices: (() -> Void)? = {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
    }
    
    /// 调用以有效地将解析器重置为其初始状态，包括调用 `registerAllServices`（如果提供）
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        main = Navigator()
        root = main
        registrationNeeded = true
    }
    
    public static func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
        main.register(pattern, factory)
    }
    
    public static func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
        main.handle(pattern, factory)
    }
    
    public static func viewController(for url: URLConvertible, context: Any? = nil) -> UIViewController? {
        main.viewController(for: url, context: context)
    }
    
    public static func handler(for url: URLConvertible, context: Any?) -> NavigatorOpenHandler? {
        main.handler(for: url, context: context)
    }
    
    @discardableResult
    public static func push(_ url: URLConvertible, context: Any? = nil, from: UINavigationController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        main.push(url, context: context, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public static func push(_ viewController: UIViewController, from: UINavigationController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        main.push(viewController, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public static func present(_ url: URLConvertible, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        main.present(url, context: context, wrap: wrap, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public static func present(_ viewController: UIViewController, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        main.present(viewController, context: context, wrap: wrap, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public static func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        main.open(url, context: context)
    }
    
    public init() {
        
    }
    
    public func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
        lock.lock()
        defer { lock.unlock() }
        viewControllerFactories[pattern] = factory
    }
    
    public func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlerFactories[pattern] = factory
    }
    
    public func viewController(for url: URLConvertible, context: Any? = nil) -> UIViewController? {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        return lookup(url, context: context)
    }
    
    public func handler(for url: URLConvertible, context: Any?) -> NavigatorOpenHandler? {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        return lookup(url, context: context)
    }
    
    @discardableResult
    public func push(_ url: URLConvertible, context: Any? = nil, from: UINavigationController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        guard let viewController = viewController(for: url, context: context) else { return nil }
        return push(viewController, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public func push(_ viewController: UIViewController, from: UINavigationController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        guard (viewController is UINavigationController) == false else { return nil }
        guard let navigationController = from ?? UIViewController.topMostController?.navigationController else { return nil }
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        navigationController.pushViewController(viewController, animated: animated)
        CATransaction.commit()
        return viewController
    }
    
    @discardableResult
    public func present(_ url: URLConvertible, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        guard let viewController = viewController(for: url, context: context) else { return nil }
        return present(viewController, context: context, wrap: wrap, from: from, animated: animated, completion: completion)
    }
    
    @discardableResult
    public func present(_ viewController: UIViewController, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewController? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        guard let fromViewController = from ?? UIViewController.topMostController else { return nil }
        
        let viewControllerToPresent: UIViewController
        if let navigationControllerClass = wrap, (viewController is UINavigationController) == false {
            viewControllerToPresent = navigationControllerClass.init(rootViewController: viewController)
        } else {
            viewControllerToPresent = viewController
        }
        
        fromViewController.present(viewControllerToPresent, animated: animated, completion: completion)
        return viewController
    }
    
    @discardableResult
    public func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        guard let handler = handler(for: url, context: context) else { return false }
        return handler()
    }
    
    private final func lookup(_ url: URLConvertible, context: Any?) -> UIViewController? {
        let urlPatterns = Array(viewControllerFactories.keys)
        guard let match = matcher.match(url, from: urlPatterns) else { return nil }
        guard let factory = viewControllerFactories[match.pattern] else { return nil }
        return factory(url, match.values, context)
    }
    
    private final func lookup(_ url: URLConvertible, context: Any?) -> NavigatorOpenHandler? {
        let urlPatterns = Array(viewControllerFactories.keys)
        guard let match = matcher.match(url, from: urlPatterns) else { return nil }
        guard let handler = handlerFactories[match.pattern] else { return nil }
        return  { handler(url, match.values, context) }
    }
    
    private let matcher = URLMatcher()
    private let lock = Navigator.lock
    private var viewControllerFactories: [URLPattern: NavigatorFactoryViewController] = [:]
    private var handlerFactories: [URLPattern: NavigatorFactoryOpenHandler] = [:]
}

extension Navigator {
    fileprivate static let lock = NSRecursiveLock()
}

// Registration Internals

private var registrationNeeded: Bool = true

@inline(__always)
private func registrationCheck() {
    guard registrationNeeded else {
        return
    }
    if let registering = (Navigator.root as Any) as? NavigatorRegistering {
        type(of: registering).registerAllURLs()
    }
    registrationNeeded = false
}
