import XCTest
@testable import URLNavigator

final class URLNavigatorTests: XCTestCase, Navigating {
    
    func testBuild() throws {
        let result = navigator.build(for: "navigator://mall/32/123")
        switch result {
        case .success(let vc):
            XCTAssert(true, vc.description)
        case .failure(let error):
            XCTAssertTrue(false, error.localizedDescription)
        }
    }
    
    func testBuildWithContext() throws {
        let vc = navigator.debug().build(for: "navigator://user/321", context: ["username": "zhangsan"])
        XCTAssertNotNil(vc)
    }
    
    func testBuildWithPath() throws {
        let result1 = navigator.build(for: "navigator://inspection/test/list/error", context: ["username": "zhangsan"])
        switch result1 {
        case .success(let vc):
            XCTAssert(true, vc.description)
        case .failure(let error):
            XCTAssertTrue(false, error.localizedDescription)
        }
        
        let result2 = navigator.build(for: "navigator://inspection", context: ["username": "zhangsan"])
        switch result2 {
        case .success(let vc):
            XCTAssert(true, vc.description)
        case .failure(let error):
            XCTAssertTrue(false, error.localizedDescription)
        }
    }
    
    func testHandle() throws {
        let flag = navigator.debug().open("navigator://pay/wechat", context: ["errCode": 0, "errMsg": "支付成功"])
        XCTAssertTrue(flag)
        
        let flag2 = navigator.debug().open("navigator://share/wechat", context: ["errCode": 0, "errMsg": "分享成功"])
        XCTAssertFalse(flag2)
    }
    
    func testHttps() throws {
        let flag = navigator.debug().open("https://shop.zlj365.com/pages/score/score-list?action=redirect")
        XCTAssertTrue(flag)
        let flag2 = navigator.debug().open("https://shop.zlj365.com")
        XCTAssertTrue(flag2)
    }
    
    func testSystem() throws {
        let flag = navigator.debug().open("tel://15142101897")
        XCTAssertTrue(flag)
    }
}

extension Navigator: NavigatorRegistering {
    
    public static func registerAllURLs() {
        register("navigator://user/123") { url, values, context in
                .success(UIViewController())
        }
        
        handle("https://<appid>/<path:path>") { url, values, context in
                print(values)
            print(url.queryParameters)
            return true
        }
        
        main.register("navigator://user/<int:id>") { url, values, context in
            return .success(UIViewController())
        }
        
        main.register("navigator://main/<int:id>") { url, values, context in
                .success(UIViewController())
        }
        
        main.register("navigator://mall/<int:id>/<int:pid>") { url, values, context in
            print(values)
            return .success(UIViewController())
        }
        
        main.register("navigator://inspection") { url, values, context in
            print("✅1", url)
            return .success(UIViewController())
        }
        
        main.register("navigator://inspection") { url, values, context in
            print("✅2", url)
            return .success(UIViewController())
        }
        
        main.register("navigator://inspection/test/<path:path>") { url, values, context in
            print("✅", values)
            if let path = values["path"] as? String {
                switch path {
                case "list": return .success(UIViewController())
                case "list/error": return .success(UIViewController())
                default: return .failure(NavigatorError.notMatch)
                }
            } else {
                return .success(UIViewController())
            }
        }
        
        main.register("navigator://inspection/<int:id>") { url, values, context in
            print("❌", values)
            return .success(UIViewController())
        }
        
        main.handle("navigator://pay/<path>") { url, values, context in
            print(values)
            return true
        }
        
        handle("tel://<int:phone>") { url, values, context in
            print(url)
            return true
        }
    }
}

extension NavigatorError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}
