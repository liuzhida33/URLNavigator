import UIKit

public protocol NavigatorRegistering {
    static func registerAllURLs()
}

public protocol Navigating {
    var navigator: Navigator { get }
}

extension Navigating {
    public var navigator: Navigator {
        Navigator.main
    }
}

public typealias URLPattern = String
public typealias NavigatorFactoryViewController = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Result<UIViewController, Error>
public typealias NavigatorFactoryOpenHandler = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
public typealias NavigatorOpenHandler = () -> Bool

public struct Navigator {
    
    public static var main: Navigator = Navigator(dataSource: .init(matcher: URLMatcher()))
    
    public static func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
        main.register(pattern, factory)
    }
    
    public static func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
        main.handle(pattern, factory)
    }
    
    public static func build(for url: URLConvertible, context: Any? = nil) -> Result<UIViewController, Error> {
        main.build(for: url, context: context)
    }
    
    public static func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        main.open(url, context: context)
    }
    
    public static func viewControllerFactories() -> [URLPattern: NavigatorFactoryViewController] {
        main.viewControllerFactories()
    }
    
    public static func handlerFactories() -> [URLPattern: NavigatorFactoryOpenHandler] {
        main.handlerFactories()
    }
    
    public func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
        _register(pattern, factory)
    }
    
    public func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
        _handle(pattern, factory)
    }
    
    public func build(for url: URLConvertible, context: Any? = nil) -> Result<UIViewController, Error> {
        _build(url, context)
    }
    
    public func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        _open(url, context)
    }
    
    public func viewControllerFactories() -> [URLPattern: NavigatorFactoryViewController] {
        _viewControllerFactories()
    }
    
    public func handlerFactories() -> [URLPattern: NavigatorFactoryOpenHandler] {
        _handlerFactories()
    }
    
    private let _register: (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) -> Void
    private let _handle: (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) -> Void
    private let _build: (_ url: URLConvertible, _ context: Any?) -> Result<UIViewController, Error>
    private let _open: (_ url: URLConvertible, _ context: Any?) -> Bool
    private let _viewControllerFactories: () -> [URLPattern: NavigatorFactoryViewController]
    private let _handlerFactories: () -> [URLPattern: NavigatorFactoryOpenHandler]
    
    init(
        register: @escaping (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) -> Void,
        handle: @escaping (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) -> Void,
        build: @escaping (_ url: URLConvertible, _ context: Any?) -> Result<UIViewController, Error>,
        open: @escaping (_ url: URLConvertible, _ context: Any?) -> Bool,
        viewControllerFactories: @escaping () -> [URLPattern: NavigatorFactoryViewController],
        handlerFactories: @escaping () -> [URLPattern: NavigatorFactoryOpenHandler]
    ) {
        self._register = register
        self._handle = handle
        self._build = build
        self._open = open
        self._viewControllerFactories = viewControllerFactories
        self._handlerFactories = handlerFactories
    }
}

public extension Navigator {
    
    init(dataSource: Navigator.Datasource) {
        self.init(
            register: { pattern, factory in
                dataSource.register(pattern, factory)
            },
            handle: { pattern, factory in
                dataSource.handle(pattern, factory)
            },
            build: { url, context in
                dataSource.build(for: url, context: context)
            },
            open: { url, context in
                dataSource.open(url, context: context)
            },
            viewControllerFactories: {
                dataSource.viewControllerFactories
            },
            handlerFactories: {
                dataSource.handlerFactories
            }
        )
    }
}

public extension Navigator {
    
    final class Datasource {
        
        public let matcher: URLMatcher
        public private(set) var viewControllerFactories: [URLPattern: NavigatorFactoryViewController] = [:]
        public private(set) var handlerFactories: [URLPattern: NavigatorFactoryOpenHandler] = [:]
        
        public init(matcher: URLMatcher) {
            self.matcher = matcher
        }
        
        fileprivate func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
            viewControllerFactories[pattern] = factory
        }
        
        fileprivate func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
            handlerFactories[pattern] = factory
        }
        
        fileprivate func build(for url: URLConvertible, context: Any?) -> Result<UIViewController, Error> {
            registrationCheck()
            let urlPatterns = Array(viewControllerFactories.keys)
            guard let match = matcher.match(url, from: urlPatterns) else { return .failure(NavigatorError.notMatch) }
            guard let factory = viewControllerFactories[match.pattern] else { return .failure(NavigatorError.notFactory) }
            return factory(url, match.values, context)
        }
        
        fileprivate func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
            registrationCheck()
            let urlPatterns = Array(handlerFactories.keys)
            guard let match = matcher.match(url, from: urlPatterns) else { return false }
            guard let handler = handlerFactories[match.pattern] else { return false }
            return handler(url, match.values, context)
        }
    }
}

// Registration Internals

private var registrationNeeded: Bool = true

@inline(__always)
private func registrationCheck() {
    guard registrationNeeded else {
        return
    }
    if let registering = (Navigator.main as Any) as? NavigatorRegistering {
        type(of: registering).registerAllURLs()
    }
    registrationNeeded = false
}
