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
import std.net.http.server (Response, Status)

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
Response.unauthorized          # 401
Response.forbidden             # 403
Response.not_found             # 404
Response.internal_server_error # 500
```

### Chaining Response Methods

```inko
import std.net.http.server (Header)

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
import std.net.http.websocket (WebSocket)

# WebSocket support is built into the HTTP server
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

## Signal Handling

```inko
import std.net.os (Signal)
import std.net.os.signal (SignalKind)
import std.time.duration (Duration)

match Signal.subscribe(SignalKind.interrupt) {
  case Ok(_) -> {
    # Handler registered successfully
  }
  case Error(e) -> {
    # Handle error
  }
}

# Non-blocking signal receive
loop {
  match Signal.receive(timeout: Duration.from_seconds(1)) {
    case Ok(signal) -> {
      match signal.kind {
        case SignalKind.interrupt -> {
          # Handle SIGINT
        }
        case SignalKind.terminate -> {
          # Handle SIGTERM
        }
        case _ -> {}
      }
    }
    case Error(_) -> {
      # Timeout or no signal, continue
    }
  }
}
```
