# Standard Library Reference (0.20.0)

**Official Documentation:** [https://docs.inko-lang.org/std/main/](https://docs.inko-lang.org/std/main/)

Module documentation follows the URL pattern: `https://docs.inko-lang.org/std/main/module/std/[module-name]/`

Example: [std.array documentation](https://docs.inko-lang.org/std/main/module/std/array/)

## Collections

- **std.array** - An ordered, integer-indexed generic collection of values
- **std.map** - A hash map using linear probing and Robin Hood entry stealing
- **std.set** - A hash set implemented using a Map
- **std.deque** - A double-ended queue

## Concurrency

- **std.sync** - Synchronization primitives including `Promise` and `Future`
- **std.sync.AtomicBool** - Atomically operated boolean (NEW in 0.20.0)
- **std.sync.AtomicInt** - Atomically operated integer (NEW in 0.20.0)

Both `AtomicBool` and `AtomicInt` use acquire and release semantics for atomic operations. Useful for cross-process synchronization when message-passing cost is too high.

## Types

- **std.int** - The Int type
- **std.float** - The Float type
- **std.string** - A UTF-8 encoded and immutable string
- **std.bool** - Boolean true and false
- **std.option** - Optional values (`Some` and `None`)
- **std.result** - Types for error handling (`Ok` and `Error`)

## Networking

- **std.net.http** - HTTP 1.1 clients and servers (pure Inko!)
  - **std.net.http.client** - HTTP 1.1 client support
  - **std.net.http.server** - HTTP 1.1 server support
  - **std.net.http.websocket** - WebSockets (NEW in 0.19.1)
  - **std.net.http.cookie** - RFC 6265 cookies
- **std.net.socket** - IP and Unix domain sockets
- **std.net.ip** - IPv4 and IPv6 address types
- **std.net.tls** - TLS support for sockets
- **std.net.dns** - Types for performing DNS queries

## Cryptography (0.19.1 uses graviola backend)

- **std.crypto.hash** - Types for cryptographic hash functions
- **std.crypto.sha2** - SHA256 and SHA512 hash functions
- **std.crypto.md5** - MD5 hash function
- **std.crypto.sha1** - SHA1 hash function
- **std.crypto.chacha** - ChaCha family of stream ciphers
- **std.crypto.poly1305** - Poly1305 universal hash function

## Compression

- **std.compress.gzip** - Compression and decompression using gzip (NEW in 0.20.0)

```inko
import std.compress.gzip (Encoder)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let enc = Encoder.new(Stdout.new)
    enc.write('hello world').or_panic
    enc.finish.or_panic
  }
}
```

Built on libz-rs-sys (pure Rust zlib) — no extra C dependencies.

## Random Numbers

- **std.rand** - Cryptographically secure random number generation (pure Inko using ChaCha20!)

## I/O and Filesystem

- **std.io** - Types for core IO functionality
- **std.fs** - General types for filesystem operations
- **std.fs.file** - Types and methods for manipulating files
- **std.fs.path** - Cross-platform path manipulation
- **std.stdio** - Standard input and output streams

## Data Formats

- **std.json** - Parsing and generating of JSON
- **std.csv** - Parsing and generating of CSV data
- **std.xml** - Generating of XML documents
- **std.html** - Generating of HTML documents
- **std.uri** - RFC 3986 and RFC 3987 URIs
- **std.multipart** - multipart/form-data streams

## Utilities

- **std.time** - Types and methods for dealing with time
- **std.env** - Methods for inspecting the OS process environment
- **std.process** - Lightweight Inko processes
- **std.test** - A simple unit testing library
- **std.fmt** - Formatting of Inko values for debugging
- **std.log** - Structured logging of wide events (NEW in 0.20.0)

### Structured Logging (std.log)

Events are queryable names rather than arbitrary text. Formatting is asynchronous so producer cost is consistent regardless of output format complexity.

```inko
import std.log (Logger)

type async Main {
  fn async main {
    let logger = Logger.text

    logger.event('user_login_failed').with('name', 'Alice').with('attempts', 3).submit
  }
}
# Output: 2026-04-21T16:44:07.557Z user_login_failed name="Alice" attempts=3
```

JSON output is also supported (use `Logger.json`).

## Common Import Patterns

```inko
# HTTP Server
import std.net.http.server (Handle, Request, Response, Server, Status, Header)

# File I/O
import std.fs.file (File)
import std.io (Read, Write)

# JSON
import std.json (Json)

# Environment
import std.env
import std.env (arguments)

# Integers
import std.int (Int, Format)

# Time
import std.time.duration (Duration)

# Testing
import std.test (Tests)

# String manipulation
import std.string (StringBuffer, ToString)

# Bytes
import std.bytes (ByteArray, Bytes, ToSlice)

# Concurrency
import std.sync (Promise)

# Structured logging
import std.log (Logger)

# Atomic operations
import std.sync (AtomicBool, AtomicInt)

# Gzip compression
import std.compress.gzip (Encoder)
```
