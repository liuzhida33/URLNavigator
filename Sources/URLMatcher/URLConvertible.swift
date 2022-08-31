import Foundation
import UIKit

public protocol URLConvertible {
    var urlValue: URL? { get }
    var urlStringValue: String { get }
    var queryParameters: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
}

extension URLConvertible {
    public var queryItems: [URLQueryItem]? { URLComponents(string: urlStringValue)?.queryItems }
    
    public var queryParameters: [String: String] {
        var parameters: [String: String] = [:]
        queryItems?.forEach { parameters[$0.name] = $0.value }
        return parameters
    }
}

extension String: URLConvertible {
    public var urlValue: URL? {
        if let url = URL(string: self) {
            return url
        }
        var set = CharacterSet()
        set.formUnion(.urlHostAllowed)
        set.formUnion(.urlPathAllowed)
        set.formUnion(.urlQueryAllowed)
        set.formUnion(.urlFragmentAllowed)
        return addingPercentEncoding(withAllowedCharacters: set).flatMap { URL(string: $0) }
    }
    
    public var urlStringValue: String { self }
}

extension URL: URLConvertible {
    public var urlValue: URL? { self }
    
    public var urlStringValue: String { absoluteString }
}

extension UIApplicationShortcutItem: URLConvertible {
    
    public var urlValue: URL? {
        URL(string: type)
    }
    
    public var urlStringValue: String {
        type
    }
}

extension NSUserActivity: URLConvertible {
    
    public var urlValue: URL? {
        URL(string: activityType)
    }
    
    public var urlStringValue: String {
        activityType
    }
}

extension NavigatorError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}
