import XCTest
@testable import URLNavigator

final class URLNavigatorTests: XCTestCase, Navigating {
    
    func testBuild() throws {
        
        Navigator.root = Navigator.parent
        
        let result = navigator.build(for: "navigator://user/333")
        switch result {
        case .success(let vc):
            print("vc: \(type(of: vc)) title: \(vc.title)")
            XCTAssertNotNil(vc, vc.description)
        case .failure(let error):
            XCTAssertTrue(false, error.localizedDescription)
        }
        let flag = navigator.open("navigator://user/123", context: ["errCode": 0, "errMsg": "支付成功"])
        XCTAssertTrue(flag)
        let result2 =  Navigator.parent.build(for: "navigator://user/444")
        switch result2 {
        case .success(let vc):
            print("vc: \(type(of: vc)) title: \(vc.title)")
            XCTAssertNotNil(vc, vc.description)
        case .failure(let error):
            XCTAssertTrue(false, error.localizedDescription)
        }
    }
    
    func testBuildWithContext() throws {
        let vc = navigator.build(for: "navigator://user/321", context: ["username": "zhangsan"])
        XCTAssertNotNil(vc)
    }
    
    func testHandle() throws {
        let flag = navigator.open("navigator://pay/callback", context: ["errCode": 0, "errMsg": "支付成功"])
        XCTAssertTrue(flag)
    }
    
    func testHttps() throws {
        let flag = navigator.open("https://shop.zlj365.com/pages/score/score-list?action=redirect")
        XCTAssertTrue(flag)
    }
    
    func testSystem() throws {
        Navigator.root = Navigator.mock
        let flag = navigator.open("tel://10086")
        XCTAssertTrue(flag)
    }
}

extension Navigator {
    static let mock = Navigator(child: main, plugins: [NavigatorLoggerPlugin()])
    static let parent = Navigator(child: mock, plugins: [Test1Plugin(), Test2Plugin()])
}

extension Navigator: NavigatorRegistering {
    
    public static func registerAllURLs() {
        
        register("navigator://user/123") { url, values, context in
            .success(UIViewController())
        }

        handle("https://<path:path>") { url, values, context in
            print(values)
            return true
        }
        
        handle("navigator://<appId>/<*:_>") { url, values, context in
            print("💛: \(values)")
            guard let appId = values["appId"] as? String else { return false }
            let path = url.queryParameters.reduce("/\(values["_"] as? String ?? "")\(url.queryParameters.isEmpty ? "" : "?")", { $0 + "\($1.key)=\($1.value)" })
            print(appId, path)
            return true
        }

        handle("navigator://pay/<path>") { url, values, context in
            print(values)
            return true
        }

        handle("tel://<int:phone>") { url, values, context in
            print(url)
            return true
        }
                
        mock.register("navigator://user/<int:id>") { url, values, context in
            let vc = MainViewController()
            vc.uid = values["id"] as? Int
            return .success(vc)
        }
        mock.handle("navigator://user/<int:id>") { url, values, context in
            return true
        }
    }
}

class MainViewController: UIViewController {
    var uid: Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("uid: \(uid)")
    }
}

struct TestPlugin: PluginType {
    
    func prepare(_ factory: @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController {
        { url, values, context in
            switch factory(url, values, context) {
            case .success(let viewController):
                viewController.title = "测试标题"
                return .success(viewController)
            case .failure(let error):
                return .failure(error)
            }
        }
    }
}

struct Test1Plugin: PluginType {
    
    func prepare(_ factory: @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController {
        { url, values, context in
            print("测试顺序1")
            return factory(url, values, context)
        }
    }
    
    func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler {
        { url, values, context in
            print("测试顺序1")
            return factory(url, values, context)
        }
    }
}

struct Test2Plugin: PluginType {
    
    func prepare(_ factory: @escaping NavigatorFactoryViewController, matchResult: URLMatchResult) -> NavigatorFactoryViewController {
        { url, values, context in
            print("测试顺序2")
            return factory(url, values, context)
        }
    }
    
    func prepare(_ factory: @escaping NavigatorFactoryOpenHandler, matchResult: URLMatchResult) -> NavigatorFactoryOpenHandler {
        { url, values, context in
            print("测试顺序2")
            return factory(url, values, context)
        }
    }
}
