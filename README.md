# Whooshing 项目的 WebSocket 模块依赖库

WhooshingWebSocket 是 Whooshing 系统中的 **WebSocket 客户端封装模块**，为 API、HTTPS 等服务子模块提供通用、可扩展的 WebSocket 客户端能力，基于 Vapor 与 Vapor 的  [websocket-kit](https://github.com/vapor/websocket-kit) 构建，集成了认证、日志、加密通信、连接升级、异常处理等机制。

-----

### 特性

-  **加密通信支持**：集成自定义 Cryptos 模块，实现 WebSocket 通道的数据加密解密。
-  **统一协议抽象**：使用 `WhooshingWebSocket` 协议规范各类客户端
-  **自动协议升级**：支持标准的 HTTP → WebSocket 协议升级流程。
-  **日志集成**：内建 Logger，支持全流程追踪。
-  **错误封装**：提供标准化的错误类型 `WhooshingWebSocketErr`，便于调试和用户提示。
-  **模块适配**：提供 `ApiWebSocket` 与 `HttpsWebSocket` 两种具体实现，分别服务于内部 API 通信与通用 HTTPS 使用场景。

----

### 模块说明

- **ApiWebSocket:** 用于与任意 Whooshing API 子模块建立 WebSocket 连接，需要提供用户认证信息
- **HttpsWebSocket:** 用于与任意 Whooshing HTTPS 子模块建立 WebSocket 连接

关于模块与子模块，见 [whooshing.toolbox-server](https://github.com/whooshing-workshop/whooshing.toolbox-server)

-----

### 引入依赖

在你的 Package.swift 加入：

``` swift
.package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-websocket.git", from: "1.1.6")
```

并在 target 中添加：

```swift
.product(name: "WhooshingWebSocket", package: "whooshing.toolbox-websocket")
```

在需要使用的地方

```swift
import WhooshingWebSocket
```

-------

### 使用介绍

##### 创建 WebSocket

对于 **ApiWebSocket**，需要提供用户认证信息，包括用户凭据和用户密钥。关于认证机制，见 [whooshing.system-authentication](https://github.com/whooshing-workshop/whooshing.system-authentication)

```swift
let socket = ApiWebSocket(credential: "bRRPIiYbt0t4RzfqeeHSkg==", token: "jXTz4vTQk0O/XFIjWQIHLC7z9/E0/4VtEb+LkF8IcA4=", eventLoop: eventLoop, logger: logger)
```

对于 **HttpsWebSocket**，无需提供额外信息

```swift
let socket = HttpsWebSocket(in: eventLoop, logger: logger)
```

> 创建一个 client 时，eventLoop 是必须的，可见 [SwiftNIO](https://github.com/apple/swift-nio) 对 EventLoop 的文档
>
> 一般来说，你可以简单地创建一个以系统核心数创建的线程池：
>
> ```swift
> import NIOCore
> 
> let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
> let eventLoop = eventLoopGroup.next()
> ```
>
> logger 是可选的，推荐为其设置 logger



##### 连接到服务器开启 WebSocket 连线

建立一个简单的 WebSocket 连线：

```swift
try await socket.connect(to: "ws://localhost:8080/ws") { ws in
    print("WebSocket 已连接")
    ws.send("Hello World!")

    ws.onText { ws, text in
        print("收到消息: \(text)")
    }
}
```

或者，建立一个 echo 连接(回显客户端)

```swift
try await socket.connect(to: WebURI("ws://localhost:8080/echo")) { ws in
    ws.onText { ws, text in
        ws.send(text)
    }
}
```

----

### 运行环境

* **macOS** (> 10.15)
* **iOS** (> 14.0)
* **Linux** (> 20)
* **Swift** (> 6.0)
* **watchOS** (> 6.0) **[未测试]**
* **tvOS**(> 13) **[未测试]**

---------

### 注意事项

- **ApiWebSocket** 仅可用于访问 Whooshing 的 API 模块，不可用于外部服务，由于其有自定加密，永远不应当使用 WSS。
- **HttpsWebSocket** 使用传统的网络加密，因此务必使用 WSS 进行安全访问，避免 WS 明文发送。

如需了解更多，请参阅各模块内的源码注释与文档说明。

-------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/whooshing-workshop/whooshing.toolbox-websocket/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
