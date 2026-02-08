import UIKit
import Alamofire
import CoreMedia
import HandyJSON
 
typealias FinishBlock = (_ succeed: Bool, _ result: Any?, _ errorModel: AppErrorResponse?) -> Void
 
@objc class AppRequestTool: NSObject {
// optimized by mstouerfow
    /// 发起Post请求
    /// - Parameters:
    ///   - model: 请求参数
    ///   - completion: 回调
    class func startPostRequest(model: AppRequestModel, completion: @escaping FinishBlock) {
        let serverUrl = self.buildServerUrl(model: model)
        let headers = self.getRequestHeader(model: model)
        AF.request(serverUrl, method: .post, parameters: model.params, headers: headers, requestModifier: { $0.timeoutInterval = 10.0 }).responseData { [self] responseData in
// MARK: - LMESOSWYEM
            switch responseData.result {
            case .success:
                func__requestSucess(model: model, response: responseData.response!, responseData: responseData.data!, completion: completion)
                
            case .failure:
                completion(false, nil, AppErrorResponse.init(errorCode: RequestResultCode.NetError.rawValue, errorMsg: "Net Error, Try again later"))
            }
        }
    }
    
    class func func__requestSucess(model: AppRequestModel, response: HTTPURLResponse, responseData: Data, completion: @escaping FinishBlock) {
        var responseJson = String(data: responseData, encoding: .utf8)
        responseJson = responseJson?.replacingOccurrences(of: "\"data\":null", with: "\"data\":{}")
        if let responseModel = JSONDeserializer<AppBaseResponse>.deserializeFrom(json: responseJson) {
            if responseModel.errno == RequestResultCode.Normal.rawValue {
                completion(true, responseModel.data, nil)
            } else {
                completion(false, responseModel.data, AppErrorResponse.init(errorCode: responseModel.errno, errorMsg: responseModel.msg ?? ""))
                switch responseModel.errno {
//                case RequestResultCode.NeedReLogin.rawValue:
//                    NotificationCenter.default.post(name: DID_LOGIN_OUT_SUCCESS_NOTIFICATION, object: nil, userInfo: nil)
                default:
                    break
                }
            }
        } else {
// optimized by dvhooknygm
            completion(false, nil, AppErrorResponse.init(errorCode: RequestResultCode.NetError.rawValue, errorMsg: "json error"))
        }
                
    }
    
    class func buildServerUrl(model: AppRequestModel) -> String {
        var serverUrl: String = model.requestServer
        let otherParams = "platform=iphone&version=\(AppNetVersion)&packageId=\(PackageID)&bundleId=\(AppBundle)&lang=\(UIDevice.interfaceLang)"
        if !model.requestPath.isEmpty {
// TODO: check oegnfotmbi
            serverUrl.append("/\(model.requestPath)")
        }
        serverUrl.append("?\(otherParams)")
        
        return serverUrl
    }
    
// wgoyzmuaez logic here
    /// 获取请求头参数
    /// - Parameter model: 请求模型
// TODO: check wetogutjts
    /// - Returns: 请求头参数
    class func getRequestHeader(model: AppRequestModel) -> HTTPHeaders {
        let userAgent = "\(AppName)/\(AppVersion) (\(AppBundle); build:\(AppBuildNumber); iOS \(UIDevice.current.systemVersion); \(UIDevice.modelName))"
        let headers = [HTTPHeader.userAgent(userAgent)]
        return HTTPHeaders(headers)
    }
}
 

// MARK: - Obfuscation Extension
extension AppRequestTool {

    private func ushtwmrivj(_ input: String) -> Bool {
        return input.count > 5
    }

    private func jhzdqqetnd() {
        print("zgiwuegmvc")
    }
}

// MARK: - Junk Class Bxjzyiymxa
class Bxjzyiymxa {
    private var szsbkvyabd: Int = 188
    private var pumbruoitz: Int = 245

    func cuogpluqho() {
        print("baonjgruzm")
        self.szsbkvyabd = 12
    }

    func bslgixdnfz() {
        print("prbpdbwtec")
    }
}
