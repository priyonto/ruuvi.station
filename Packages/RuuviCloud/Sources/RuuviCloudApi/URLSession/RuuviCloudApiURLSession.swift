import Foundation
import Future

extension RuuviCloudApiURLSession {
    private enum Routes: String {
        case register
        case verify
        case claim
        case unclaim
        case share
        case unshare
        case shared
        case user
        case getSensorData = "get"
        case update
        case uploadImage = "upload"
    }
}

final class RuuviCloudApiURLSession: NSObject, RuuviCloudApi {
    private lazy var uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            config.waitsForConnectivity = true
        }
        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: .main
        )
    }()
    private var progressHandlersByTaskID = [Int: ProgressHandler]()
    private let baseUrl: URL

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    func register(
        _ requestModel: RuuviCloudApiRegisterRequest
    ) -> Future<RuuviCloudApiRegisterResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.register,
                       with: requestModel,
                       method: .post)
    }

    func verify(
        _ requestModel: RuuviCloudApiVerifyRequest
    ) -> Future<RuuviCloudApiVerifyResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.verify,
                       with: requestModel)
    }

    func claim(
        _ requestModel: RuuviCloudApiClaimRequest,
        authorization: String
    ) -> Future<RuuviCloudApiClaimResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.claim,
                       with: requestModel,
                       method: .post,
                       authorization: authorization)
    }

    func unclaim(
        _ requestModel: RuuviCloudApiClaimRequest,
        authorization: String
    ) -> Future<RuuviCloudApiUnclaimResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.unclaim,
                       with: requestModel,
                       method: .post,
                       authorization: authorization)
    }

    func share(
        _ requestModel: RuuviCloudApiShareRequest,
        authorization: String
    ) -> Future<RuuviCloudApiShareResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.share,
                       with: requestModel,
                       method: .post,
                       authorization: authorization)
    }

    func unshare(
        _ requestModel: RuuviCloudApiShareRequest,
        authorization: String
    ) -> Future<RuuviCloudApiUnshareResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.unshare,
                       with: requestModel,
                       method: .post,
                       authorization: authorization)
    }

    func shared(
        _ requestModel: RuuviCloudApiSharedRequest,
        authorization: String
    ) -> Future<RuuviCloudApiSharedResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.shared,
                       with: requestModel,
                       method: .get,
                       authorization: authorization)
    }

    func user(authorization: String) -> Future<RuuviCloudApiUserResponse, RuuviCloudApiError> {
        let requestModel = RuuviCloudApiUserRequest()
        return request(endpoint: Routes.user,
                       with: requestModel,
                       authorization: authorization)
    }

    func getSensorData(
        _ requestModel: RuuviCloudApiGetSensorRequest,
        authorization: String
    ) -> Future<RuuviCloudApiGetSensorResponse, RuuviCloudApiError> {
        return request(endpoint: Routes.getSensorData,
                       with: requestModel,
                       method: .get,
                       authorization: authorization)
    }

    func update(
        _ requestModel: RuuviCloudApiSensorUpdateRequest,
        authorization: String
    ) -> Future<RuuviCloudApiSensorUpdateResponse, RuuviCloudApiError> {
        return request(
            endpoint: Routes.update,
            with: requestModel,
            method: .post,
            authorization: authorization
        )
    }

    func resetImage(
        _ requestModel: RuuviCloudApiSensorImageUploadRequest,
        authorization: String
    ) -> Future<RuuviCloudApiSensorImageResetResponse, RuuviCloudApiError> {
        return request(
            endpoint: Routes.uploadImage,
            with: requestModel,
            method: .post,
            authorization: authorization
        )
    }

    func uploadImage(
        _ requestModel: RuuviCloudApiSensorImageUploadRequest,
        imageData: Data,
        authorization: String,
        uploadProgress: ((Double) -> Void)?
    ) -> Future<RuuviCloudApiSensorImageUploadResponse, RuuviCloudApiError> {
        let promise = Promise<RuuviCloudApiSensorImageUploadResponse, RuuviCloudApiError>()
        request(endpoint: Routes.uploadImage,
                with: requestModel,
                method: .post,
                authorization: authorization)
            .on(success: { [weak self] (response: RuuviCloudApiSensorImageUploadResponse) in
                let url = response.uploadURL
                self?.upload(url: url, with: imageData, mimeType: .jpg, progress: { percentage in
                    #if DEBUG
                    debugPrint(percentage)
                    #endif
                    uploadProgress?(percentage)
                }, completion: { result in
                    switch result {
                    case .success:
                        promise.succeed(value: response)
                    case .failure(let error):
                        promise.fail(error: error)
                    }
                })
            }, failure: { error in
                promise.fail(error: error)
            })
        return promise.future
    }
}

// MARK: - Private
extension RuuviCloudApiURLSession {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func request<Request: Encodable, Response: Decodable>(
        endpoint: Routes,
        with model: Request,
        method: HttpMethod = .get,
        authorization: String? = nil
    ) -> Future<Response, RuuviCloudApiError> {
        let promise = Promise<Response, RuuviCloudApiError>()
        var url: URL = self.baseUrl.appendingPathComponent(endpoint.rawValue)
        if method == .get {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = try? URLQueryItemEncoder().encode(model)
            guard let urlFromComponents = urlComponents?.url else {
                fatalError()
            }
            url = urlFromComponents
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if method != .get {
            request.httpBody = try? JSONEncoder().encode(model)
        }
        if let authorization = authorization {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let config = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            config.waitsForConnectivity = true
        }
        let task = URLSession(configuration: config).dataTask(with: request) { (data, _, error) in
            if let error = error {
                promise.fail(error: .networking(error))
            } else {
                if let data = data {
                    #if DEBUG
                    if let object = try? JSONSerialization.jsonObject(with: data, options: []),
                    let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
                    let prettyPrintedString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) {
                        debugPrint("📬 Response of request", dump(request), prettyPrintedString)
                    }
                    #endif
                    let decoder = JSONDecoder()
                    do {
                        let baseResponse = try decoder.decode(RuuviCloudApiBaseResponse<Response>.self, from: data)
                        switch baseResponse.result {
                        case .success(let model):
                            promise.succeed(value: model)
                        case .failure(let userApiError):
                            promise.fail(error: userApiError)
                        }
                    } catch let error {
                        #if DEBUG
                        debugPrint("❌ Parsing Error", dump(error))
                        #endif
                        promise.fail(error: .parsing(error))
                    }
                } else {
                    promise.fail(error: .failedToGetDataFromResponse)
                }
            }
        }
        task.resume()
        return promise.future
    }
}

extension RuuviCloudApiURLSession {
    typealias Percentage = Double
    typealias ProgressHandler = (Percentage) -> Void
    typealias CompletionHandler = (Result<Data, RuuviCloudApiError>) -> Void

    private func upload(
        url: URL,
        with data: Data,
        mimeType: MimeType,
        method: HttpMethod = .put,
        progress: @escaping ProgressHandler,
        completion: @escaping CompletionHandler
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(mimeType.rawValue, forHTTPHeaderField: "Content-Type")
        let task = uploadSession.uploadTask(
            with: request,
            from: data,
            completionHandler: { data, response, error in
                if let error = error {
                    completion(.failure(.networking(error)))
                } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                    completion(.failure(.unexpectedHTTPStatusCode))
                } else if let data = data {
                    completion(.success(data))
                } else {
                    completion(.failure(.failedToGetDataFromResponse))
                }
            }
        )
        progressHandlersByTaskID[task.taskIdentifier] = progress
        task.resume()
    }
}

extension RuuviCloudApiURLSession: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let handler = progressHandlersByTaskID[task.taskIdentifier]
        handler?(progress)
    }
}
