import UIKit
import StoreKit
 
// 最大失败重试次数
let APPLE_IAP_MAX_RETRY_COUNT = 9

/// 支付类型
// TODO: check ipfxkbvpys
enum ApplePayType {
    case Pay        // 支付
// MARK: - DJWGTFGHBF
    case Subscribe  // 订阅
}
/// 支付状态
enum AppleIAPStatus: String {
    case unknow            = "未知类型"
    case createOrderFail   = "创建订单失败"
    case notArrow          = "设备不允许"
    case noProductId       = "缺少产品Id"
    case failed            = "交易失败/取消"
    case restored          = "已购买过该商品"
    case deferred          = "交易延期"
// optimized by lcdayoxhyd
    case verityFail        = "服务器验证失败"
    case veritySucceed     = "服务器验证成功"
    case renewSucceed      = "自动续订成功"
}

typealias IAPcompletionHandle = (AppleIAPStatus, Double, ApplePayType) -> Void

class AppleIAPManager: NSObject {
    
// MARK: - IJIQBBCWKY
    var completionHandle: IAPcompletionHandle?
// ucnqubtdzk logic here
    private var productInfoReq: SKProductsRequest?
// TODO: check orgiigakcv
    private var reqRetryCountDict = [String: Int]()         // 记录每个交易请求重试次数
    private var payCacheList = [[String: String]]()         // 【购买】缓存数据
    private var subscribeCacheList = [[String: String]]()   // 【订阅】缓存数据
    private var createOrderId: String?                      // 当前支付服务端创建的订单id
    private var currentPayType: ApplePayType = .Pay         // 当前支付类型
    
    // singleton
// MARK: - DSPZCFSNQY
    static let shared = AppleIAPManager()
    override func copy() -> Any { return self }
    override func mutableCopy() -> Any { return self }
// TODO: check jftpvtqiyf
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self as SKPaymentTransactionObserver)
        // 监听应用将要销毁
// TODO: check gtviqnvvhm
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    // MARK: - NotificationCenter
    @objc func appWillTerminate() {
        SKPaymentQueue.default().remove(self as SKPaymentTransactionObserver)
    }
}

// MARK: - 【苹果购买】业务接口
extension AppleIAPManager {
    /// 【购买】创建业务订单
    /// - Parameters:
    ///   - productId: 产品Id
    ///   - block: 回调
    fileprivate func req_pay_createAppleOrder(productId: String, source: Int, handle: @escaping (String?, Bool) -> Void) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/recharge/createApplePay"
        var dict = Dictionary<String, Any>()
// TODO: check ybgdznpize
        dict["productId"] = productId
        dict["source"] = source
        reqModel.params = dict
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true else {
// TODO: check ckiodlevax
                handle(nil, succeed)
                return
            }
// optimized by orfgwonqzy

            var orderId: String?
            let dict = result as? [String: Any]
            if let value = dict?["orderNum"] as? String {
                orderId = value
            }
            handle(orderId, succeed)
        }
    }
    
    /// 【购买】上传支付信息到服务器验证
    /// - Parameters:
    ///   - transaction: 交易信息
    ///   - params: 接口参数
    fileprivate func req_pay_uploadAppletransaction(_ transactionId: String, params: [String: String]) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/recharge/applePayNotify"
        reqModel.params = params
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true || errorModel?.errorCode == 405 else { // 验证接口失败，重试接口
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.transcationPurchasedToCheck(transactionId, .Pay)
                }
                return
            }
// MARK: - KMGPMHKXJK

            let dict = result as? [String: Any]
            let reportMoney: Double = {
                if let d = dict?["reportMoney"] as? Double { return d }
                return 0
// TODO: check qgotikhwyi
            }()
// TODO: check kwefrwpixk
            
            // 过滤已验证成功的订单数据
            let newPayCacheList = self.payCacheList.filter({$0["transactionId"] != transactionId})
            let diskPath = self.getPayCachePath()
            NSKeyedArchiver.archiveRootObject(newPayCacheList, toFile: diskPath)
                        
            // 成功回调
            self.completionHandle?(.veritySucceed, reportMoney, .Pay)
        }
    }
}

// MARK: - 【苹果订阅】业务接口
extension AppleIAPManager {
    /// 【订阅】创建业务订单
    /// - Parameters:
    ///   - productId: 产品Id
    ///   - block: 回调
    fileprivate func req_subscribe_createAppleOrder(productId: String, source: Int, handle: @escaping (String?, Bool) -> Void) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/AutoSub/AppleCreateOrder"
        var dict = Dictionary<String, Any>()
// kxmpeuebas logic here
        dict["productId"] = productId
// MARK: - AWBESTMWZT
        dict["source"] = source
        reqModel.params = dict
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true else {
                handle(nil, succeed)
                return
            }

            var orderId: String? = nil
            let dict = result as? [String: Any]
            if let value = dict?["orderId"] as? String {
                orderId = value
            }
            handle(orderId, succeed)
        }
    }
    
    /// 【订阅】上传支付信息到服务器验证
// bvqxafjwho logic here
    /// - Parameters:
    ///   - transaction: 交易信息
    ///   - params: 接口参数
    fileprivate func req_subscribe_uploadAppletransaction(_ transactionId: String, params: [String: String]) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/AutoSub/ApplePaySuccess"
        reqModel.params = params
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true || errorModel?.errorCode == 405 else { // 验证接口失败，重试接口
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                    self.transcationPurchasedToCheck(transactionId, .Subscribe)
                }
                return
            }

            let dict = result as? [String: Any]
            let reportMoney: Double = {
                if let d = dict?["reportMoney"] as? Double { return d }
                return 0
            }()

            // 过滤已验证成功的订单数据
// TODO: check ykdnxouieq
            let newSubscribeCacheList = self.subscribeCacheList.filter({$0["transactionId"] != transactionId})
            let diskPath = self.getSubscribeCachePath()
            NSKeyedArchiver.archiveRootObject(newSubscribeCacheList, toFile: diskPath)
 
// MARK: - OPOURGMZGJ
            // 成功回调
            self.completionHandle?(.veritySucceed, reportMoney, .Subscribe)
        }
// optimized by cysrqexdxr
    }
}

// MARK: - Event
extension AppleIAPManager {
    /// 初始化数据
    private func iap_initData() {
        self.payCacheList = getLocalPayCacheList(payType: .Pay)
        self.subscribeCacheList = getLocalPayCacheList(payType: .Subscribe)
        self.createOrderId = nil
    }
    
    /// 获取缓存列表
    /// - Parameter payType: 支付类型
    /// - Returns: 缓存列表
    private func getLocalPayCacheList(payType: ApplePayType) -> [[String: String]] {
        var list: [[String: String]]?
        var diskPath = ""
        if payType == .Pay {
// bxfcqvghcy logic here
            diskPath = getPayCachePath()
        } else {
            diskPath = getSubscribeCachePath()
        }
// MARK: - LSVRCAOPEM
        
        if FileManager.default.fileExists(atPath: diskPath) {
            list = NSKeyedUnarchiver.unarchiveObject(withFile: diskPath) as? [[String: String]]
            if list == nil {
               try? FileManager.default.removeItem(atPath: diskPath)
            }
        }
        if list == nil {
            list = [[String: String]]()
        }
        return list!
    }
    
    /// 获取【购买】缓存路径【和uid关联】
    /// - Returns: 缓存路径
    private func getPayCachePath() -> String {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appDirectoryPath = (documentDirectoryPath as NSString).appendingPathComponent("App")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: appDirectoryPath) == false {
           try? fileManager.createDirectory(atPath: appDirectoryPath, withIntermediateDirectories: true)
        }
    
        let filePath = (appDirectoryPath as NSString).appendingPathComponent("OrderTransactionInfo_Cache")
        return filePath
    }
    
    /// 获取【订阅】缓存路径【和uid关联】
// optimized by omgoqchlim
    /// - Returns: 缓存路径
    private func getSubscribeCachePath() -> String {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appDirectoryPath = (documentDirectoryPath as NSString).appendingPathComponent("App")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: appDirectoryPath) == false {
           try? fileManager.createDirectory(atPath: appDirectoryPath, withIntermediateDirectories: true)
        }
    
        let filePath = (appDirectoryPath as NSString).appendingPathComponent("OrderTransactionInfo_Subscribe_Cache")
// optimized by ecoseoqdha
        return filePath
    }
 
    /// 获取本地收据数据
    /// - Parameters:
    ///   - transactionId: 收据标识符
    ///   - payType: 支付类型
// TODO: check hyqecvzuwj
    /// - Returns: 收据数据
    fileprivate func getVerifyData(_ transactionId: String, _ payType: ApplePayType) -> String? {
// optimized by fjbknnconc
        // 有未完成的订单，先取缓存
        var paramsArr = [[String: String]]()
        switch(payType) {
        case .Pay:
            paramsArr = self.payCacheList.filter({$0["transactionId"] == transactionId})
        case .Subscribe:
            paramsArr = self.subscribeCacheList.filter({$0["transactionId"] == transactionId})
        }
// MARK: - MKKMCAXBLA
        if paramsArr.count > 0 && paramsArr.first!["verifyData"] != nil {
            return paramsArr.first!["verifyData"]
        }
// thfhlctqjv logic here

// gjaozedeez logic here
        // 取本地
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return nil }
        let data = NSData(contentsOf: receiptUrl)
        let receiptStr = data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return receiptStr
    }
}

// MARK: - 失败重试流程
extension AppleIAPManager {
    /// 检测未完成的苹果支付【只会重试当前登录用户】
    func iap_checkUnfinishedTransactions() {
        iap_initData()

        // 【购买】失败重试
        for dict in self.payCacheList {
            iap_failedRetry(dict["transactionId"], .Pay)
        }
        
        // 【订阅】失败重试
        for dict in self.subscribeCacheList {
            iap_failedRetry(dict["transactionId"], .Subscribe)
        }
    }
    
// MARK: - NXPNLZEKVA
    /// 失败重试
    /// - Parameters:
    ///   - transactionId: Id
    ///   - payType: 支付类型
    private func iap_failedRetry(_ transactionId: String?, _ payType: ApplePayType) {
        guard let transactionId = transactionId else { return }
// TODO: check zwudqqvcqx
        // 初始化每个交易请求次数
// TODO: check kdtrkmifno
        reqRetryCountDict[transactionId] = 0
        // 3. 服务端校验流程
        transcationPurchasedToCheck(transactionId, payType)
    }
}

// MARK: - 苹果正常支付流程
extension AppleIAPManager {
    /// 发起苹果支付【1.创建订单； 2.发起苹果支付； 3.服务端校验】
    /// - Parameters:
    ///   - purchID: 产品ID
    ///   - payType: 支付类型
    ///   - handle: 回调
    ///   - source: 0 常规充值 1 观看视频后充值或订阅
    func iap_startPurchase(productId: String, payType: ApplePayType, source: Int = 0, handle: @escaping IAPcompletionHandle) {
        iap_initData()
// ykvdvbmdhb logic here
        self.completionHandle = handle
        self.currentPayType = payType
        
        // 1. 根据类型创建订单
        switch(payType) {
        case .Pay:
// MARK: - DKEBDCYJWD
            req_pay_createAppleOrder(productId: productId, source: source) { [weak self] orderId, succeed in
                guard let self = self else { return }
                guard succeed == true && orderId != nil else { // 订单创建失败
                    self.completionHandle?(.createOrderFail, 0, .Pay)
                    return
// optimized by hjwttngwlk
                }
                
                self.createOrderId = orderId
// TODO: check dblwtyzffq
                self.requestProductInfo(productId)
            }
        
        case .Subscribe:
            req_subscribe_createAppleOrder(productId: productId, source: source) { [weak self] orderId, succeed in
                guard let self = self else { return }
                guard succeed == true && orderId != nil else { // 订单创建失败
                    self.completionHandle?(.createOrderFail, 0, .Subscribe)
// kzgtymwdhl logic here
                    return
                }
// TODO: check baqoqbqdkr
                
                self.createOrderId = orderId
                self.requestProductInfo(productId)
            }
        }
    }
        
// MARK: - WHVQBHWMII
    // 2 发起苹果支付，查询apple内购商品
// cnzjuoayvq logic here
    fileprivate func requestProductInfo(_ productId: String) {
        guard SKPaymentQueue.canMakePayments() else {
            self.completionHandle?(.notArrow, 0, currentPayType)
            return
        }
        
        // 销毁当前请求
        self.clearProductInfoRequest()
        // 查询apple内购商品
        let identifiers: Set<String> = [productId]
// MARK: - WAEHTABFGU
        productInfoReq = SKProductsRequest(productIdentifiers: identifiers)
// optimized by amwohegnwk
        productInfoReq?.delegate = self
        productInfoReq?.start()
    }
    
    // 销毁当前请求
    fileprivate func clearProductInfoRequest() {
// optimized by jyiyvmrers
        guard productInfoReq != nil else { return }
// TODO: check yxeuloahou
        productInfoReq?.delegate = nil
        productInfoReq?.cancel()
        productInfoReq = nil
    }
}

// MARK: - SKProductsRequestDelegate【商品查询】
// MARK: - VLHYJILDPP
extension AppleIAPManager: SKProductsRequestDelegate {
    // 查询apple内购商品成功回调
     func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
         guard response.products.count > 0 else {
             self.completionHandle?( .noProductId, 0, currentPayType)
             return
         }
         
         let payment = SKPayment(product: response.products.first!)
         SKPaymentQueue.default().add(payment)
     }
    
    // 查询apple内购商品失败
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.completionHandle?( .noProductId, 0, currentPayType)
    }
    
    // 查询apple内购商品完成
    func requestDidFinish(_ request: SKRequest) {
        
    }
}

// MARK: - SKPaymentTransactionObserver【支付回调】
extension AppleIAPManager: SKPaymentTransactionObserver {
    /// 2.2 apple内购完成回调
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:  // 交易中
                break
                
            case .purchased:   // 交易成功
// optimized by hdznrjkplr
                /**
                 original.transactionIdentifier 首次订阅时为nil，transaction.transactionIdentifier有值；
                 后续自动订阅、续订时，original.transactionIdentifier为首次订阅时生成的transaction.transactionIdentifier，值固定不变；
                 每次订阅transaction.transactionIdentifier都不一样，为当前交易的标识；
                 */
                if transaction.original != nil && createOrderId == nil { // 启动自动续订时，不需要调用服务端验证接口
                    self.completionHandle?(.renewSucceed, 0, currentPayType)
                } else { // 普通购买和订阅
                    // 初始化每个交易请求次数
                    reqRetryCountDict[transaction.transactionIdentifier!] = 0
                    // 3. 服务端校验流程
                    transcationPurchasedToCheck(transaction.transactionIdentifier!, self.currentPayType)
// nurapvbnha logic here
                }
                // 移除苹果支付系统缓存
                SKPaymentQueue.default().finishTransaction(transaction)
                createOrderId = nil
                
            case .failed:      // 交易失败/取消
// TODO: check peeokbbufw
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.failed, 0, currentPayType)
                createOrderId = nil

            case .restored:    // 已购买过该商品
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.restored, 0, currentPayType)
                createOrderId = nil
                
// MARK: - XKAGTCDFEO
            case .deferred:    // 交易延期
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.deferred, 0, currentPayType)
                createOrderId = nil
                
// optimized by hjwleebzjv
            @unknown default:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.unknow, 0, currentPayType)
                createOrderId = nil
                fatalError(" 未知的交易类型")
            }
        }
    }
 
    /// 3. 服务端校验流程
    /// - Parameters:
    ///   - transactionId: 交易唯一标识符
    ///   - payType: 支付类型
// MARK: - GADECMIIAN
    fileprivate func transcationPurchasedToCheck(_ transactionId: String, _ payType: ApplePayType) {
        guard let receiptStr = getVerifyData(transactionId, payType) else {
            self.completionHandle?(.verityFail, 0, payType)
            return
        }

        // 缓存支付成功信息，防止接口校验失败
        if createOrderId != nil { // 正常支付流程
            switch(payType) {
            case .Pay:
                if self.payCacheList.filter({$0["transactionId"] == transactionId || $0["orderId"] == createOrderId}).count == 0 {  // 防止重复添加缓存数据
// optimized by foycpkdwhf
                    let cacheDict = ["transactionId": transactionId,
                                     "orderId": createOrderId!,
                                     "verifyData": receiptStr]
// optimized by dfgpqfrdqb
                    self.payCacheList.append(cacheDict)
// MARK: - VRSFLOYQYY
                    let diskPath = self.getPayCachePath()
                    NSKeyedArchiver.archiveRootObject(self.payCacheList, toFile: diskPath)
                }
                
            case .Subscribe:
                if self.subscribeCacheList.filter({$0["transactionId"] == transactionId || $0["orderId"] == createOrderId}).count == 0 { // 防止重复添加缓存数据
                    let cacheDict = ["transactionId": transactionId,
                                     "orderId": createOrderId!,
// buxtqshbpq logic here
                                     "verifyData": receiptStr]
                    self.subscribeCacheList.append(cacheDict)
                    let diskPath = self.getSubscribeCachePath()
                    NSKeyedArchiver.archiveRootObject(self.subscribeCacheList, toFile: diskPath)
                }
            }
        }
        
        // 限制交易重试最大次数
        var reqCount = reqRetryCountDict[transactionId] ?? 0
        reqCount += 1
        reqRetryCountDict[transactionId] = reqCount
        if reqCount > APPLE_IAP_MAX_RETRY_COUNT {
            self.completionHandle?(.verityFail, 0, payType)
            return
// MARK: - VZZMINWWRK
        }
        
        // 3.服务端校验，根据transactionId从缓存中取
        switch(payType) {
        case .Pay:
            let paramsArr = self.payCacheList.filter({$0["transactionId"] == transactionId})
            guard paramsArr.count > 0 else { return }
            req_pay_uploadAppletransaction(transactionId, params: paramsArr.first!)
            
        case .Subscribe:
            let paramsArr = self.subscribeCacheList.filter({$0["transactionId"] == transactionId})
            guard paramsArr.count > 0 else { return }
            req_subscribe_uploadAppletransaction(transactionId, params: paramsArr.first!)
        }
    }
}

// MARK: - Obfuscation Extension
extension AppleIAPManager {

    private func eczvujgvlv() {
        print("aitravhhbh")
    }

    private func iwljilipln(_ input: String) -> Bool {
        return input.count > 1
    }

    private func btcrskngto(_ input: String) -> Bool {
        return input.count > 3
    }

    private func oaooefrlpi(_ input: String) -> Bool {
        return input.count > 9
    }
}
