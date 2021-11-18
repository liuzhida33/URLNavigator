import Foundation

public protocol URLConvertible {
    var urlValue: URL? { get }
    var urlStringValue: String { get }
    var queryItems: [URLQueryItem]? { get }
}

extension URLConvertible {
    public var queryItems: [URLQueryItem]? { URLComponents(string: urlStringValue)?.queryItems }
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
