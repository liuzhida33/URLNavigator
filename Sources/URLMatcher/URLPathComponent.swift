/// 从URL中`path`转换成参数
/// - plain:    纯文本
/// - placeholder:  占位符
///     - type: 参数类型
///     - key:  参数键
///
/// For example:
///
///     let component = URLPathComponent("<int:id>")
///     // URLPathComponent.placeholder(type: "int", key: "id")
///
enum URLPathComponent {
    case plain(String)
    case placeholder(type: String?, key: String)
}

extension URLPathComponent {
    
    init(_ value: String) {
        if value.hasPrefix("<") && value.hasSuffix(">") {
            let start = value.index(after: value.startIndex)
            let end = value.index(before: value.endIndex)
            // e.g. "<int:id>" -> "int:id"
            let placeholder = value[start..<end]
            // e.g. "int:id" -> ["int", "id"]
            let typeAndKey = placeholder.components(separatedBy: ":")
            if typeAndKey.count == 1 {
                // 未指定具体类型
                self = .placeholder(type: nil, key: typeAndKey[0])
            } else if typeAndKey.count == 2 {
                self = .placeholder(type: typeAndKey[0], key: typeAndKey[1])
            } else {
                self = .plain(value)
            }
        } else {
            self = .plain(value)
        }
    }
}
