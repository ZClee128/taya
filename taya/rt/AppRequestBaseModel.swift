import Foundation
import HandyJSON

// MARK: - Request Configuration

/// Encapsulates parameters for a single API request.
class NetworkRequest: NSObject {
    @objc var endpoint: String = ""
    var baseURL: String
    var parameters: [String: Any] = [:]

    override init() {
        self.baseURL = "http://app.\(ReplaceUrlDomain).com"
    }

    // Legacy property mapping
    @objc var requestPath: String {
        get { endpoint }
        set { endpoint = newValue }
    }
    var requestServer: String {
        get { baseURL }
        set { baseURL = newValue }
    }
    var params: [String: Any] {
        get { parameters }
        set { parameters = newValue }
    }
}

// MARK: - Response Models

/// Parsed API response envelope.
struct APIResponse: HandyJSON {
    var errno: Int!
    var msg: String?
    var data: Any?
}

/// Represents an API error with code and message.
struct APIError {
    let code: Int
    let message: String
}

/// Standard API result codes.
enum APIResultCode: Int {
    case success    = 0
    case networkErr = -10000
    case relogin    = -100
}

// MARK: - Legacy Type Aliases

typealias AppRequestModel = NetworkRequest
typealias AppBaseResponse = APIResponse
typealias AppErrorResponse = APIError

extension AppErrorResponse {
    var errorCode: Int { code }
    var errorMsg: String { message }

    init(errorCode: Int, errorMsg: String) {
        self.init(code: errorCode, message: errorMsg)
    }
}

typealias RequestResultCode = APIResultCode
extension APIResultCode {
    static let Normal = APIResultCode.success
    static let NetError = APIResultCode.networkErr
    static let NeedReLogin = APIResultCode.relogin
}
