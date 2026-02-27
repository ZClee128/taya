import UIKit
import Alamofire
import HandyJSON

/// Completion handler for network requests.
typealias FinishBlock = (_ succeed: Bool, _ result: Any?, _ error: APIError?) -> Void

/// Handles outgoing HTTP requests to the backend API.
/// Builds URLs with standard query parameters and processes JSON responses.
enum NetworkClient {

    /// Sends a POST request using the given configuration.
    static func post(request model: NetworkRequest, completion: @escaping FinishBlock) {
        let url = buildURL(for: model)
        let headers = buildHeaders(for: model)

        AF.request(url,
                   method: .post,
                   parameters: model.parameters,
                   headers: headers,
                   requestModifier: { $0.timeoutInterval = 10.0 }
        ).responseData { response in
            switch response.result {
            case .success(let data):
                guard let httpResponse = response.response else {
                    completion(false, nil, APIError(code: APIResultCode.networkErr.rawValue, message: "No HTTP response"))
                    return
                }
                handleSuccess(model: model, httpResponse: httpResponse, body: data, completion: completion)

            case .failure:
                completion(false, nil, APIError(code: APIResultCode.networkErr.rawValue, message: "Network error, please try again"))
            }
        }
    }

    // MARK: - Internal

    private static func handleSuccess(model: NetworkRequest, httpResponse: HTTPURLResponse, body: Data, completion: @escaping FinishBlock) {
        var json = String(data: body, encoding: .utf8) ?? ""
        json = json.replacingOccurrences(of: "\"data\":null", with: "\"data\":{}")

        guard let envelope = JSONDeserializer<APIResponse>.deserializeFrom(json: json) else {
            completion(false, nil, APIError(code: APIResultCode.networkErr.rawValue, message: "JSON parse error"))
            return
        }

        if envelope.errno == APIResultCode.success.rawValue {
            completion(true, envelope.data, nil)
        } else {
            completion(false, envelope.data, APIError(code: envelope.errno, message: envelope.msg ?? ""))
        }
    }

    private static func buildURL(for model: NetworkRequest) -> String {
        var url = model.baseURL
        if !model.endpoint.isEmpty {
            url += "/\(model.endpoint)"
        }
        let query = "platform=iphone&version=\(AppNetVersion)&packageId=\(AppInternalIdentifier)&bundleId=\(AppBundle)&lang=\(UIDevice.interfaceLang)"
        url += "?\(query)"
        return url
    }

    private static func buildHeaders(for model: NetworkRequest) -> HTTPHeaders {
        let ua = "\(AppName)/\(AppVersion) (\(AppBundle); build:\(AppBuildNumber); iOS \(UIDevice.current.systemVersion); \(UIDevice.modelName))"
        return HTTPHeaders([.userAgent(ua)])
    }
}

// MARK: - Legacy Compatibility

/// Preserves existing call sites that use `AppRequestTool.startPostRequest(...)`.
@objc class AppRequestTool: NSObject {
    class func startPostRequest(model: AppRequestModel, completion: @escaping FinishBlock) {
        NetworkClient.post(request: model, completion: completion)
    }

    class func buildServerUrl(model: AppRequestModel) -> String {
        // Kept for any external references
        var url = model.baseURL
        let query = "platform=iphone&version=\(AppNetVersion)&packageId=\(AppInternalIdentifier)&bundleId=\(AppBundle)&lang=\(UIDevice.interfaceLang)"
        if !model.endpoint.isEmpty {
            url += "/\(model.endpoint)"
        }
        url += "?\(query)"
        return url
    }

    class func getRequestHeader(model: AppRequestModel) -> HTTPHeaders {
        let ua = "\(AppName)/\(AppVersion) (\(AppBundle); build:\(AppBuildNumber); iOS \(UIDevice.current.systemVersion); \(UIDevice.modelName))"
        return HTTPHeaders([.userAgent(ua)])
    }
}
