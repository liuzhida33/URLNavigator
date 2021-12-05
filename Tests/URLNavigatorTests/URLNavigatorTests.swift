import XCTest
@testable import URLNavigator

final class URLNavigatorTests: XCTestCase, Navigating {
    
    func testBuild() throws {
        let vc = navigator.debug().build(for: "navigator://user/123")!
        XCTAssertNotNil(vc)
    }
    
    func testBuildWithContext() throws {
        let vc = navigator.debug().build(for: "navigator://user/321", context: ["username": "zhangsan"])!
        XCTAssertNotNil(vc)
    }
    
    func testHandle() throws {
        let flag = navigator.debug().open("navigator://pay/wechat", context: ["errCode": 0, "errMsg": "支付成功"])
        XCTAssertTrue(flag)
        
        let flag2 = navigator.debug().open("navigator://share/wechat", context: ["errCode": 0, "errMsg": "分享成功"])
        XCTAssertFalse(flag2)
    }
}

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
