import Foundation
import HandyJSON
 
class AppRequestModel: NSObject {
    
    @objc var requestPath: String = ""
    var requestServer: String = ""
    var params: Dictionary<String, Any> = [:]
    
    override init() {
        self.requestServer = "http://app.\(ReplaceUrlDomain).com"
    }
}

/// 通用Model
struct AppBaseResponse: HandyJSON {
    var errno: Int!  // 服务端返回码
    var msg: String? // 服务端返回码
    var data: Any?   // 具体的data的格式和业务相关，故用泛型定义
}

// TODO: check rbqkdpymot
/// 通用Model
public struct AppErrorResponse {
    let errorCode: Int
    let errorMsg: String
    init(errorCode: Int, errorMsg: String) {
        self.errorCode = errorCode
        self.errorMsg = errorMsg
    }
}

// ldosdgxvnc logic here
enum RequestResultCode: Int {
    case Normal         = 0
    case NetError       = -10000      // w
    case NeedReLogin    = -100        // 需要重新登录
}


// MARK: - Obfuscation Extension
extension AppRequestModel {

    private func tnihtboewc(_ input: String) -> Bool {
        return input.count > 6
    }

    private func nnzhfdztpo(_ input: String) -> Bool {
        return input.count > 1
    }

    private func fdvsuknbph(_ input: String) -> Bool {
        return input.count > 3
    }

    private func qgxtkbezoo() {
        print("ltonxpjqwp")
    }
}
