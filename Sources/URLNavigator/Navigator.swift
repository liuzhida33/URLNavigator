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
public typealias NavigatorFactoryViewController = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Result<UIViewController, Error>
public typealias NavigatorFactoryOpenHandler = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
public typealias NavigatorOpenHandler = () -> Bool

public final class Navigator {
    
    public static var root: Navigator = main
    
    public static let main: Navigator = Navigator()
    
    public init(child: Navigator? = nil, matcher: URLMatcher = URLMatcher(), plugins: [PluginType] = []) {
        self.matcher = matcher
        self.plugins = plugins
        if let child = child {
            self.childContainers.append(child)
        }
    }
    
    public func add(child: Navigator) {
        self.childContainers.append(child)
    }
    
    // MARK: - Action
    
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
    
    public final func register(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryViewController) {
        viewControllerFactories[pattern] = factory
    }
    
    public final func handle(_ pattern: URLPattern, _ factory: @escaping NavigatorFactoryOpenHandler) {
        handlerFactories[pattern] = factory
    }
    
    public final func build(for url: URLConvertible, context: Any? = nil) -> Result<UIViewController, Error> {
        registrationCheck()
        // 匹配采用“FIFO”原则，即重复注册相同规则下优先匹配前者
        if let (matchResult, factory) = lookupViewController(for: url, context: context) {
            
            let preparedFactory = prepare(factory, matchResult: matchResult)
            
            return preparedFactory(url, matchResult.values, context)
        }
        return .failure(NavigatorError.notMatch)
    }
    
    @discardableResult
    public final func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        registrationCheck()
        // 匹配采用“FIFO”原则，即重复注册相同规则下优先匹配前者
        if let (matchResult, factory) = lookupOpenHandler(for: url, context: context) {
            
            let preparedFactory = prepare(factory, matchResult: matchResult)
            
            return preparedFactory(url, matchResult.values, context)
        }
        
        return false
    }
    
    // MARK: - Internal
    
    private final func lookupViewController(for url: URLConvertible, context: Any? = nil) -> (URLMatchResult, NavigatorFactoryViewController)? {
        let urlPatterns = viewControllerFactories.keys
        // 匹配采用“FIFO”原则，即重复注册相同规则下优先匹配前者
        if let matchResult = matcher.match(url, from: urlPatterns),
           let factory = viewControllerFactories[matchResult.pattern] {
            return (matchResult, factory)
        }
        for child in childContainers {
            if let (matchResult, factory) = child.lookupViewController(for: url, context: context) {
                return (matchResult, factory)
            }
        }
        return nil
    }
    
    private final func lookupOpenHandler(for url: URLConvertible, context: Any? = nil) -> (URLMatchResult, NavigatorFactoryOpenHandler)? {
        let urlPatterns = handlerFactories.keys
        // 匹配采用“FIFO”原则，即重复注册相同规则下优先匹配前者
        if let matchResult = matcher.match(url, from: urlPatterns),
           let factory = handlerFactories[matchResult.pattern] {
            return (matchResult, factory)
        }
        for child in childContainers {
            if let (matchResult, factory) = child.lookupOpenHandler(for: url, context: context) {
                return (matchResult, factory)
            }
        }
        return nil
    }
    
    // MARK: - Plugins
    
    private final func prepare(_ factory:  @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController {
        let preparedFactory = plugins.reduce(factory) { $1.prepare($0, matchResult: matchResult) }
        return childContainers.reduce(preparedFactory, { $1.prepare($0, matchResult: matchResult) })
    }
    
    private final func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler {
        let preparedFactory = plugins.reduce(factory) { $1.prepare($0, matchResult: matchResult) }
        return childContainers.reduce(preparedFactory, { $1.prepare($0, matchResult: matchResult) })
    }
    
    private let matcher: URLMatcher
    private let plugins: [PluginType]
    private var childContainers: [Navigator] = []
    private var viewControllerFactories: Registration<URLPattern, NavigatorFactoryViewController> = Registration()
    private var handlerFactories: Registration<URLPattern, NavigatorFactoryOpenHandler> = Registration()
}

private extension Navigator {
    
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
