import Foundation

public extension Navigator {
    
    static func debug(
    ) -> Navigator.Type {
        Navigator.self
    }
    
    func debug(
        log: @escaping (String) -> Void = { print($0) },
        dumpPath: @escaping (Any) -> Void = { dump($0) }
    ) -> Navigator {
        Navigator(
            register: { pattern, factory in
                defer {
                    log("⚡️ Sent register(\(pattern), \(String(describing: factory))).\n♻️ viewControllerFactories:")
                    dumpPath(Array(viewControllerFactories().keys))
                }
                register(pattern, factory)
            },
            handle: { pattern, factory in
                defer {
                    log("⚡️ Sent handle(\(pattern), \(String(describing: factory))).\n♻️ handlerFactories:")
                    dumpPath(Array(handlerFactories().keys))
                }
                handle(pattern, factory)
            },
            build: { url, context in
                defer {
                    log("⚡️ Sent build(for: \(url), context: \(String(describing: context))).\n♻️ viewControllerFactories:")
                    dumpPath(Array(viewControllerFactories().keys))
                }
                return build(for: url, context: context)
            },
            open: { url, context in
                defer {
                    log("⚡️ Sent open(\(url), \(String(describing: context))).\n♻️ handlerFactories:")
                    dumpPath(Array(handlerFactories().keys))
                }
                return open(url, context: context)
            },
            viewControllerFactories: viewControllerFactories,
            handlerFactories: handlerFactories
        )
    }
}
