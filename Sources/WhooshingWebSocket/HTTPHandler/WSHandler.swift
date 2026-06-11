import NIOCore
import Logging
import LoggingAdvanced
import WhooshingClient
import ErrorHandle
import NIOAdvanced

public protocol WSIOHandler: Sendable {
    associatedtype Failure: Error
    func send(dataChunk: ByteBuffer, context: ChannelHandlerContext) -> EventLoopResult<ByteBuffer, Failure>
    func get(dataChunk: ByteBuffer, context: ChannelHandlerContext) -> EventLoopResult<ByteBuffer, Failure>
    func connectionStart(context: ChannelHandlerContext) -> EventLoopResult<Void, Failure>
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopResult<Void, Failure>
}

public extension WSIOHandler {
    func connectionStart(context: ChannelHandlerContext) -> EventLoopResult<Void, Failure> { context.eventLoop.makeSucceededVoidResult() }
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopResult<Void, Failure> { context.eventLoop.makeSucceededVoidResult() }
}

final class WSHandler<IOHandler>: ChannelDuplexHandler, Sendable where IOHandler: WSIOHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let logger: Logger?
    private let ioHandler: IOHandler
    
    init(ioHandler: IOHandler, logger: Logger? = nil) {
        self.logger = logger
        self.ioHandler = ioHandler
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.logger?.debug("WebSocket channel 读取数据", metadata: ["data": .string(data.description)])
        
        let data = unwrapInboundIn(data)
        
        self.logger?.debug("取得 buffer 数据，准备进行解密", metadata: ["buffer": .stringConvertible(data)])
        
        let loopBound = context.loopBound
        
        self.ioHandler.get(dataChunk: data, context: context).whenComplete { res in
            switch res {
            case .success(let data):
                self.logger?.debug("buffer 数据解密成功", metadata: ["plain": .stringConvertible(data)])
                loopBound.value.fireChannelRead(self.wrapInboundOut(data))
            case .failure(let err):
                self.errorHappend(context: loopBound.value, error: err)
            }
        }
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        self.logger?.debug("WebSocket channel 写入数据", metadata: ["data": .string(data.description)])
        
        let data = unwrapOutboundIn(data)
        guard data.readableBytes > 0 else {
            self.logger?.info("无任何数据要写入，忽略")
            return
        }

        let loopBound = context.loopBound
        
        self.logger?.debug("取得 buffer 数据，准备进行加密", metadata: ["buffer": .stringConvertible(data)])
        
        let r = self.ioHandler.send(dataChunk: data, context: context).wrapped.flatMap { data in
            self.logger?.debug("buffer 数据加密成功", metadata: ["cipher": .stringConvertible(data)])
            return loopBound.value.writeAndFlush(self.wrapOutboundOut(data))
        }.flatMapErrorThrowing { err in
            self.errorHappend(context: loopBound.value, error: err)
        }
        
        if let p = promise {
            r.cascade(to: p)
        }
    }
    
    func channelRegistered(context: ChannelHandlerContext) {
        let loopBound = context.loopBound
        self.logger?.debug("Channel 被注册", metadata: ["channel": .stringConvertible(context.channel.clientAddrInfo)])
        ioHandler.connectionStart(context: context).whenFailure { err in
            self.errorHappend(context: loopBound.value, error: err)
        }
        context.fireChannelRegistered()
    }
    
    func channelUnregistered(context: ChannelHandlerContext) {
        let loopBound = context.loopBound
        self.logger?.debug("Channel 被注销", metadata: ["channel": .stringConvertible(context.channel.clientAddrInfo)])
        ioHandler.connectionEnd(context: context).whenFailure { err in
            self.errorHappend(context: loopBound.value, error: err)
        }
        context.fireChannelUnregistered()
    }
    
    func errorHappend(context: ChannelHandlerContext, error: any Error) {
        self.logger?.warning("\(error)")
        context.fireErrorCaught(error)
    }
}
