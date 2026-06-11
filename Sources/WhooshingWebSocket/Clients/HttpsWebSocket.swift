import WhooshingClient
import Logging
import LoggingAdvanced
import ErrorHandle

/// 基于 WhooshingClient 实现的 HTTPS 模块 WebSocket 客户端封装，
/// 提供通用的 WebSocket 连接支持
///
/// 另见 ``WhooshingWebSocket`` 协议
public final class HttpsWebSocket: WhooshingWebSocket, Sendable {
    
    @inlinable
    public var client: HttpsClient { fatalError("永远不应当调用该属性") }
    
    public static let loggerLabel: String = "HTTPS.WS.Client"
    
    public let logger: Logging.Logger?
    
    public let eventLoop: any EventLoop
    
    /// 使用凭证和 token 初始化 WebSocket 客户端。
    /// - Parameters:
    ///   - eventLoop: 所使用的事件循环。
    ///   - logger: 可选日志记录器。
    @inlinable
    public init(in eventLoop: any EventLoop, logger: Logger? = nil) {
        self.logger = logger
        self.eventLoop = eventLoop
    }
    
    /// 异步建立 WebSocket 连接。
    /// - Parameters:
    ///   - url: WebSocket 地址。
    ///   - headers: HTTP 请求头。
    ///   - configuration: WebSocket 配置。
    ///   - onUpgrade: 成功建立连接时的回调。
    /// - Throws: 请求过程中可能抛出的错误。
    @inlinable
    @preconcurrency
    public func connect(
        to url: WebURI,
        headers: HTTPHeaders = [:],
        configuration: WebSocketClient.Configuration = .init(),
        onUpgrade: @Sendable @escaping (WebSocket) -> ()
    ) async throws(Failure) {
        logger?.info("HTTPS.WS.Client-建立连线中", metadata: ["url": .data(url)])
        logger?.debug("操作参数", metadata: [
            "headers": .stringConvertible(headers),
            "configs": .stringConvertible(configuration)
        ])
        
        try await required(throws: Errcase.wsConnectFailed) {
            try await WebSocket.connect(
                to: url.string,
                headers: headers,
                configuration: configuration,
                on: eventLoop,
                onUpgrade: onUpgrade
            ).get()
        }
        
        logger?.info("连线建立成功")
    }
    
    @inlinable
    public func shutdown() async throws {}
    
    @inlinable
    public func syncShutdown() throws {}
}
