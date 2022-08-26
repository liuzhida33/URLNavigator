import Foundation

public final class URLMatcher {
    
    public typealias URLValueConverter = (_ pathComponents: [String], _ index: Int) -> Any?
    
    public var valueConverters: [String: URLValueConverter] = URLMatcher.defaultURLValueConverters
    
    public init() {}
    
    /// 从指定的`URL`和`pattern`中返回匹配结果
    ///
    /// For example:
    ///
    ///     let result = matcher.match("myapp://user/123", from: ["myapp://user/<int:id>"])
    ///
    /// - Parameters:
    ///   - url: 待匹配的url
    ///   - candidates: 匹配规则列表
    /// - Returns: 返回url的规则字符串和参数列表
    public func match(_ url: URLConvertible, from candidates: [URLPattern]) -> URLMatchResult? {
        let url = normalizeURL(url)
        let scheme = url.urlValue?.scheme
        let stringPathComponents = stringPathComponents(from: url)
        
        var results = [URLMatchResult]()
        
        for candidate in candidates {
            guard scheme == candidate.urlValue?.scheme else { continue }
            if let result = match(stringPathComponents, with: candidate) {
                results.append(result)
            }
        }
        
        return results.max {
               self.numberOfPlainPathComponent(in: $0.pattern) < self.numberOfPlainPathComponent(in: $1.pattern)
            }
    }
    
    private func match(_ stringPathComponents: [String], with candidate: URLPattern) -> URLMatchResult? {
        let normalizedCandidate = normalizeURL(candidate).urlStringValue
        let candidatePathComponents = pathComponents(from: normalizedCandidate)
        
        guard ensurePathComponentsCount(stringPathComponents, candidatePathComponents) else { return nil }
        
        var urlValues: [String: Any] = [:]
        
        let pairCount = min(stringPathComponents.count, candidatePathComponents.count)
        for index in 0..<pairCount {
            let result = matchStringPathComponent(at: index, from: stringPathComponents, with: candidatePathComponents)
            
            switch result {
            case let .matches(placeholderValue):
                if let (key, value) = placeholderValue {
                    urlValues[key] = value
                }
            case .notMatches:
                return nil
            }
        }
        
        return URLMatchResult(pattern: candidate, values: urlValues)
    }
    
    private func ensurePathComponentsCount(_ stringPathComponents: [String], _ candidatePathComponents: [URLPathComponent]) -> Bool {
        let hasSameNumberOfComponents = (stringPathComponents.count == candidatePathComponents.count)
        let containsPathPlaceholderComponent = candidatePathComponents.contains {
            if case let .placeholder(type, _) = $0, type == "path" {
                return true
            } else {
                return false
            }
        }
        return hasSameNumberOfComponents || (containsPathPlaceholderComponent && stringPathComponents.count > candidatePathComponents.count)
    }
    
    private func matchStringPathComponent(at index: Int, from stringPathComponents: [String], with candidatePathComponents: [URLPathComponent]) -> URLPathComponentMatchRessult {
        let stringPathComponent = stringPathComponents[index]
        let urlPathComponent = candidatePathComponents[index]
        switch urlPathComponent {
        case let .plain(value):
            guard stringPathComponent == value else { return .notMatches }
            return .matches(nil)
        case let .placeholder(type, key):
            guard let type = type, let converter = valueConverters[type] else { return .matches((key, stringPathComponent)) }
            if let value = converter(stringPathComponents, index) {
                return .matches((key, value))
            } else {
                return .notMatches
            }
        }
    }
    
    private func normalizeURL(_ dirtyURL: URLConvertible) -> URLConvertible {
        guard dirtyURL.urlValue != nil else { return dirtyURL }
        var urlString = dirtyURL.urlStringValue
        urlString = urlString.components(separatedBy: "?")[0].components(separatedBy: "#")[0]
        urlString = self.replaceRegex(":/{3,}", "://", urlString)
        urlString = self.replaceRegex("(?<!:)/{2,}", "/", urlString)
        urlString = self.replaceRegex("(?<!:|:/)/+$", "", urlString)
        return urlString
    }
    
    private func stringPathComponents(from url: URLConvertible) -> [String] {
        url.urlStringValue.components(separatedBy: "/").lazy
            .filter { !$0.isEmpty }
            .filter { !$0.hasSuffix(":") }
    }
    
    private func pathComponents(from url: URLPattern) -> [URLPathComponent] {
        stringPathComponents(from: url).map(URLPathComponent.init)
    }
    
    private func replaceRegex(_ pattern: String, _ repl: String, _ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return string }
        return regex.stringByReplacingMatches(in: string, options: [], range: NSMakeRange(0, string.count), withTemplate: repl)
    }
    
    private func numberOfPlainPathComponent(in pattern: URLPattern) -> Int {
        return self.pathComponents(from: pattern).lazy.filter {
          guard case .plain = $0 else { return false }
          return true
        }.count
      }
    
    private static let defaultURLValueConverters: [String: URLValueConverter] = [
        "string": { pathComponents, index in pathComponents[index] },
        "int": { pathComponents, index in Int(pathComponents[index]) },
        "float": { pathComponents, index in Float(pathComponents[index]) },
        "path": { pathComponents, index in pathComponents[index..<pathComponents.count].joined(separator: "/") }
    ]
}

public struct URLMatchResult {
    public let pattern: String
    public let values: [String: Any]
}

enum URLPathComponentMatchRessult {
    case matches((key: String, value: Any)?)
    case notMatches
}
