//
//  Plugin.swift
//  
//
//  Created by 刘志达 on 2022/8/30.
//

import Foundation
import UIKit

public protocol PluginType {
    
    func prepare(_ factory:  @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController
    
    func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler
}

public extension PluginType {
    func prepare(_ factory:  @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController { factory }
    
    func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler { factory }
}
