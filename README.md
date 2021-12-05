# URLNavigator

# [URLNavigator](https://github.com/liuzhida33/URLNavigator)

`URLNavigator`提供了一种通过URL浏览视图控制器的优雅方式。URL模式可以通过使用`URLNavigator.register(_:_:)`函数映射。

`URLNavigator`可用于映射具有2种类型的URL工厂模式：`NavigatorFactoryViewController`和`NavigatorFactoryOpenHandler`
`NavigatorFactoryViewController`是返回初始化视图的闭包，`NavigatorFactoryOpenHandler`是一种可以执行的闭包。初始化视图和可执行闭包都会收到URL和占位符值。

## 开始使用

#### 1. URL匹配模式

URL模式可以包含占位符。占位符将被URL中的匹配值替换。使用 `<` 和 `>` 来标记占位符。占位符可以有类型: `string`(默认), `int`, `float`, 和 `path`.

例如, `navigator://user/<int:id>` 与以下匹配:

* `navigator://user/123`
* `navigator://user/87`

但是不会匹配以下几点:

* `navigator://user/routes` (非 int 类型)
* `navigator://user/routes/posts` ( url 结构不同)
* `/user/routes` (缺少 scheme)

#### 2. 映射URL

为`Navigator`创建一个`extension`文件，并遵循`NavigatorRegistering`协议，通常情况下您不需要主动调用`registerAllURLs`，当第一次调用解析函数时会强制一次性初始化解析器注册表

```swift
extension Navigator: NavigatorRegistering {
    
    public static func registerAllURLs() {
        
        main.register("navigator://user/<int:id>") { url, values, context in
            return UIViewController()
        }
        
        main.register("navigator://main/<int:id>") { url, values, context in
            return UIViewController()
        }
        
        main.register("navigator://mall/<int:id>") { url, values, context in
            return UIViewController()
        }
        
        main.handle("navigator://pay/<path>") { url, values, context in
            print(values)
            return true
        }
    }
}
```

#### 3. 解析构建`UIViewController`和`open(url:)`方法

```swift
        let vc = navigator.build(for: "navigator://user/123")
```

```swift
func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
) -> Bool {
  // ...
  if let url = launchOptions?[.url] as? URL {
    if let opened = navigator.open(url)
    if !opened {
      navigator.present(url)
    }
  }
  return true
}

```

```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

  // URLNavigator Handler
  if navigator.open(url) {
    return true
  }

  return false
}
```

#### 传递附加参数

```swift
    let context: [AnyHashable: Any] = [
      "fromViewController": self
    ]
    navigator.build("navigator://user/10", context: context)
    navigator.open("navigator://alert?title=Hi", context: context)
```


## Installation

## License

URLNavigator is under MIT license. See the [LICENSE](LICENSE) file for more info.
