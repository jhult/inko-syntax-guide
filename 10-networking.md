# HTTP Server and TCP Client

## HTTP Server

### Basic Server

```inko
import std.net.http.server (Handle, Request, Response, Server)

type async Main {
  fn async main {
    let server = Server.new(fn { recover MyApp() })

    match server.start(3000) {
      case Ok(_) -> loop { }  # Keep server running
      case Error(e) -> panic("Failed: ${e}")
    }
  }
}

type MyApp {}

impl Handle for MyApp {
  fn pub mut handle(request: mut Request) -> Response {
    match request.target {
      case [] -> Response.new.string("Home")
      case _ -> Response.not_found
    }
  }
}
```

**Key points:**

- HTTP stack is written entirely in Inko (no C code!)
- Complies with HTTP/1.1 RFCs
- Use `Server.new(fn { recover App() })` to create server
- `request: mut Request` - parameter is mutable
- `request.target` returns array of path segments
- Use `recover` keyword when creating app in closure
- Use `loop { }` to keep server running forever

### Response Methods

```inko
import std.net.http (Status)
import std.net.http.server (Response)

# String response
Response.new.string("body")

# JSON response
Response.new.json("{\"status\":\"ok\"}")

# Not found
Response.not_found

# Custom status
Response.new.status(Status.created).string("Created")

# Status shortcuts
Response.bad_request           # 400
Response.forbidden             # 403
Response.not_found             # 404
Response.internal_server_error # 500
```

### Chaining Response Methods

```inko
import std.net.http (Header, Status)
import std.net.http.server (Response)

Response.new
  .status(Status.created)
  .header(Header.content_type, "application/json")
  .json("{\"id\":\"123\"}")
```

### Route Matching with Array Patterns

```inko
impl Handle for MyApp {
  fn pub mut handle(request: mut Request) -> Response {
    match request.target {
      case [] -> Response.new.string("Home")
      case ["health"] -> Response.new.string("OK")
      case ["api", "users"] -> Response.new.json("{\"users\":[]}")
      case ["api", "users", id] -> Response.new.string("User ${id}")
      case _ -> Response.not_found
    }
  }
}
```

### WebSockets (NEW in 0.19.1)

```inko
import std.net.http.websocket (Websocket)

# WebSocket support is built into the HTTP server: upgrade a request with
# Response.websocket(request), which returns a WebsocketResponse
# See std.net.http.websocket documentation
```

---

## TCP Client

### Basic TCP Connection

```inko
import std.net.socket (TcpClient)
import std.net.ip (IpAddress)

fn pub connect_to(host: String, port: Int) -> Result[Bool, String] {
  match IpAddress.parse(host) {
    case Some(addr) -> {
      let addrs = [addr]  # TcpClient expects Array[IpAddress]
      match TcpClient.new(addrs, port) {
        case Ok(client) -> {
          # Use client here
          Result.Ok(true)
        }
        case Error(e) -> Result.Error("Connection failed: ${e}")
      }
    }
    case None -> Result.Error("Invalid address")
  }
}
```

**Key points:**

- `IpAddress.parse()` returns `Option[IpAddress]`
- `TcpClient.new()` expects `Array[IpAddress]`, not single `IpAddress`
- Must wrap address in array: `let addrs = [addr]`
- Returns `Result[TcpClient, std.io.Error]`

---

## Interrupting TcpServer (NEW in 0.20.0)

The previous approach (cloning `TcpServer`, sending to another process, calling
`shutdown`) doesn't work on macOS. Use the `Notifier` API instead:

```inko
import std.net.ip (IpAddress)
import std.net.socket (TcpClient, TcpServer)

fn handle(client: mut TcpClient) {
  # ...
}

fn serve(server: mut TcpServer) {
  loop {
    match server.accept {
      case Ok(client) -> handle(mut client)
      case Error(Interrupted) -> break  # The notifier was triggered
      case Error(_) -> break
    }
  }
}

type async Main {
  fn async main {
    let server = TcpServer.new(IpAddress.v4(0, 0, 0, 0), port: 3_000).or_panic
    let notifier = server.notifier

    # Hand the notifier to another process, or keep it around...
    match notifier {
      case Some(n) -> {
        # ...and call `notify` to make `accept` return `Error.Interrupted`
        n.notify
      }
      case None -> {}
    }

    serve(mut server)
  }
}
```

**Key points:**

- `TcpServer.new(ip, port)` creates the server and returns a `Result`
- `TcpServer.notifier` returns `Option[uni Notifier]`
- `Notifier.notify` makes the current or next `accept` call fail with
  `std.io.Error.Interrupted`
- Unlike `shutdown`, this works across all platforms (Linux, macOS, Windows)

---

## Signal Handling

Signals live in `std.signal` (Unix only):

```inko
import std.signal (Signal, Signals)

# Wait for a single signal in the current process
Signal.Interrupt.wait

# Wait for one of several signals
let signals = Signals.new

signals.add(Signal.Quit)
signals.add(Signal.Terminate)

loop {
  match signals.wait {
    case Quit -> {
      # Handle SIGQUIT
    }
    case Terminate -> {
      # Handle SIGTERM
    }
    case _ -> {
      # Other signals are never delivered here
    }
  }
}
```

**Key points:**

- `Signal` is an `enum` of supported signals (`Interrupt`, `Terminate`, `Quit`,
  `Hangup`, `User1`, `User2`, ...)
- `Signal.wait` blocks until the signal is received
- `Signals` waits for any of the registered signals
- There is no `Signal.subscribe`/`Signal.receive`, and no `SignalKind` type
