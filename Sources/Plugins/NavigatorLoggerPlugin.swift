//
//  NavigatorLoggerPlugin.swift
//  
//
//  Created by 刘志达 on 2022/8/30.
//

import Foundation
import UIKit

public struct NavigatorLoggerPlugin: PluginType {
    
    public func didBuild(_ result: Result<UIViewController, Error>) -> Result<UIViewController, Error> {
        switch result {
        case .success(let viewController):
            viewController.title = "测试"
            return .success(viewController)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    
    public init(log: @escaping (String) -> Void = { print($0 ) },
                dumpPath: @escaping (Any) -> Void = { dump($0) }) {
        self.log = log
        self.dumpPath = dumpPath
    }
    
    private let log: (String) -> Void
    private let dumpPath: (Any) -> Void
    
    public func prepare(_ factory: @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController {
        { url, values, context in
            log("🎯 Match Result:")
            dumpPath(matchResult)
            log("⚡️ From: \(url)\n context:")
            context != nil ? dumpPath(context!) : dump(nil)
            
            return factory(url, values, context)
        }
    }
    
    
    public func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler {
        { url, values, context in
            log("🎯 Match Result:")
            dumpPath(matchResult)
            log("⚡️ From: \(url)\n context:")
            context != nil ? dumpPath(context!) : dump(nil)
            
            return factory(url, values, context)
        }
    }
}
