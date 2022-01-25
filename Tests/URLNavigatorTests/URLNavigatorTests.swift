import XCTest
@testable import URLNavigator

final class URLNavigatorTests: XCTestCase, Navigating {
    
    func testBuild() throws {
        let vc = navigator.build(for: "navigator://user/123")
        XCTAssertNotNil(vc)
    }
    
    func testBuildWithContext() throws {
        let vc = navigator.debug().build(for: "navigator://user/321", context: ["username": "zhangsan"])
        XCTAssertNotNil(vc)
    }
    
    func testBuildWithPath() throws {
        let vc = navigator.build(for: "navigator://inspection/path", context: ["username": "zhangsan"])
        XCTAssertNotNil(vc)
        
        let vc2 = navigator.build(for: "navigator://inspection/", context: ["username": "zhangsan"])
        XCTAssertNotNil(vc2)
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
        register("navigator://user/123") { url, values, context in
                .success(UIViewController())
        }
        
//        main.debug().register("navigator://user/<int:id>") { url, values, context in
//            return UIViewController()
//        }
        
        main.register("navigator://main/<int:id>") { url, values, context in
                .success(UIViewController())
        }
        
        main.register("navigator://mall/<int:id>") { url, values, context in
                .success(UIViewController())
        }
        
        main.register("navigator://inspection/<path>") { url, values, context in
            print(values)
            return .success(UIViewController())
        }
        
//        main.register("navigator://inspection") { url, values, context in
//            print(context)
//            return UIViewController()
//        }
        
        main.handle("navigator://pay/<path>") { url, values, context in
            print(values)
            return true
        }
    }
}
