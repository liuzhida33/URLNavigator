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
    
    @discardableResult
    public static func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        main.open(url, context: context)
    }
    
    public static func viewControllerPatterns() -> [URLPattern] {
        main.viewControllerPatterns()
    }
    
    public static func handlerPatterns() -> [URLPattern] {
        main.handlerPatterns()
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
    
    @discardableResult
    public func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        _open(url, context)
    }
    
    public func viewControllerPatterns() -> [URLPattern] {
        _viewControllerPatterns()
    }
    
    public func handlerPatterns() -> [URLPattern] {
        _handlerPatterns()
    }
    
    private let _register: (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) -> Void
    private let _handle: (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) -> Void
    private let _build: (_ url: URLConvertible, _ context: Any?) -> Result<UIViewController, Error>
    private let _open: (_ url: URLConvertible, _ context: Any?) -> Bool
    private let _viewControllerPatterns: () -> [URLPattern]
    private let _handlerPatterns: () -> [URLPattern]
    
    init(
        register: @escaping (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) -> Void,
        handle: @escaping (_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) -> Void,
        build: @escaping (_ url: URLConvertible, _ context: Any?) -> Result<UIViewController, Error>,
        open: @escaping (_ url: URLConvertible, _ context: Any?) -> Bool,
        viewControllerPatterns: @escaping () -> [URLPattern],
        handlerPatterns: @escaping () -> [URLPattern]
    ) {
        self._register = register
        self._handle = handle
        self._build = build
        self._open = open
        self._viewControllerPatterns = viewControllerPatterns
        self._handlerPatterns = handlerPatterns
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
            viewControllerPatterns: {
                dataSource.viewControllerFactories.keys
            },
            handlerPatterns: {
                dataSource.handlerFactories.keys
            }
        )
    }
}

public extension Navigator {
    
    struct Registration<Key: Hashable, Value> {
        var keys: Array<Key> = []
        var values: Dictionary<Key, Value> = [:]
        
        init() {}
        
        subscript(key: Key) -> Value? {
            get {
                return self.values[key]
            }
            set {
                if let newValue = newValue {
                    let oldValue = self.values.updateValue(newValue, forKey: key)
                    if oldValue == nil {
                        self.keys.append(key)
                    }
                } else {
                    self.values.removeValue(forKey: key)
                    self.keys.removeAll(where: { $0 == key })
                }
            }
        }
    }
    
    final class Datasource {
        
        public let matcher: URLMatcher
        public private(set) var viewControllerFactories: Registration<URLPattern, NavigatorFactoryViewController> = Registration()
        public private(set) var handlerFactories: Registration<URLPattern, NavigatorFactoryOpenHandler> = Registration()
        
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
            let urlPatterns = viewControllerFactories.keys
            // 匹配采用“倒置”原则，即重复注册相同规则下优先匹配后者
            guard let match = matcher.match(url, from: urlPatterns.reversed()) else { return .failure(NavigatorError.notMatch) }
            guard let factory = viewControllerFactories[match.pattern] else { return .failure(NavigatorError.notFactory) }
            return factory(url, match.values, context)
        }
        
        fileprivate func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
            registrationCheck()
            let urlPatterns = handlerFactories.keys
            // 匹配采用“倒置”原则，即重复注册相同规则下优先匹配后者
            guard let match = matcher.match(url, from: urlPatterns.reversed()) else { return false }
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
