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

/// Standard API response model
struct AppBaseResponse: HandyJSON {
    var errno: Int!
    var msg: String?
    var data: Any?
}

/// Error response model
public struct AppErrorResponse {
    let errorCode: Int
    let errorMsg: String
    init(errorCode: Int, errorMsg: String) {
        self.errorCode = errorCode
        self.errorMsg = errorMsg
    }
}

/// API result status codes
enum RequestResultCode: Int {
    case Normal         = 0
    case NetError       = -10000
    case NeedReLogin    = -100
}
