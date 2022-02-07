import Foundation

public extension Navigator {
    
    func debug(
        log: @escaping (String) -> Void = { print($0) },
        dumpPath: @escaping (Any) -> Void = { dump($0) }
    ) -> Navigator {
        Navigator(
            register: { pattern, factory in
                defer {
                    log("⚡️ Sent register(\(pattern), \(String(describing: factory))).\n♻️ viewControllerFactories:")
                    dumpPath(viewControllerPatterns())
                }
                register(pattern, factory)
            },
            handle: { pattern, factory in
                defer {
                    log("⚡️ Sent handle(\(pattern), \(String(describing: factory))).\n♻️ handlerFactories:")
                    dumpPath(handlerPatterns())
                }
                handle(pattern, factory)
            },
            build: { url, context in
                defer {
                    log("⚡️ Sent build(for: \(dump(url)), context: \(String(describing: context))).\n♻️ viewControllerFactories:")
                    dumpPath(viewControllerPatterns())
                }
                return build(for: url, context: context)
            },
            open: { url, context in
                defer {
                    log("⚡️ Sent open(\(dump(url)), \(String(describing: context))).\n♻️ handlerFactories:")
                    dumpPath(handlerPatterns())
                }
                return open(url, context: context)
            },
            viewControllerPatterns: viewControllerPatterns,
            handlerPatterns: handlerPatterns
        )
    }
}
