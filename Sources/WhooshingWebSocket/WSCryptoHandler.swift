import NIOCore
import WhooshingClient
import Cryptos
import ErrorHandle
import NIOFoundationCompat
import Logging
import NIOWebSocket
import NIOAdvanced

struct WSCryptoHandler: WSIOHandler, Sendable {
    
    @frozen
    public enum Errcase: String, ErrList {
        var domain: String { "woo.sys.websocket.crypto.err" }
        case responseDecryptFailed = "对响应解密时发生错误"
        case requestEncryptFailed = "对请求加密时发生错误"
    }
    
    let key: Crypto.Symm.Key
    let logger: Logger?
    
    /// 发送请求时，进行编码并加密
    func send(dataChunk: ByteBuffer, context: ChannelHandlerContext) -> EventLoopRes<ByteBuffer, Errcase> {
        let loopBound = context.loopBound
        return context.eventLoop.submitResult { () throws(Failure) in
            logger?.debug("发送数据中，进行加密", metadata: [
                "data": .stringConvertible(dataChunk),
                "client_addr": .string(loopBound.value.channel.clientAddrInfo)
            ])
            return try required(throws: Errcase.requestEncryptFailed) {
                try loopBound.value.channel.allocator.buffer(data: Crypto.Symm.encrypt(dataChunk, key: key).get())
            }
        }
    }
    
    /// 收到响应时，进行解密并解码
    func get(dataChunk: ByteBuffer, context: ChannelHandlerContext) -> EventLoopRes<ByteBuffer, Errcase> {
        let loopBound = context.loopBound
        return context.eventLoop.submitResult { () throws(Failure) in
            logger?.debug("接收数据中，进行解密", metadata: [
                "data": .stringConvertible(dataChunk),
                "client_addr": .string(loopBound.value.channel.clientAddrInfo)
            ])
            return try required(throws: Errcase.responseDecryptFailed) {
                try Crypto.Symm.decrypt(.init(buffer: dataChunk), key: key).get()
            }
        }
    }
    
    func connectionStart(context: ChannelHandlerContext) -> EventLoopRes<Void, Errcase> {
        logger?.debug("连线建立", metadata: ["client_addr": .string(context.channel.clientAddrInfo)])
        return context.eventLoop.makeSucceededVoidResult()
    }
    
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopRes<Void, Errcase> {
        logger?.debug("连线结束", metadata: ["client_addr": .string(context.channel.clientAddrInfo)])
        return context.eventLoop.makeSucceededVoidResult()
    }
}
