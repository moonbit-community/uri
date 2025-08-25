# MoonBit URI Library

A comprehensive RFC3986 compliant URI parsing and manipulation library for MoonBit, ported from the OCaml `ocaml-uri` library with enhanced features and extensive testing.

## Features

- **RFC3986 Compliant**: Full compliance with the URI specification
- **Comprehensive Parsing**: Parse all URI components (scheme, authority, path, query, fragment)
- **Error Handling**: Robust error handling with detailed error types
- **URI Manipulation**: Builder pattern for creating and modifying URIs
- **Normalization**: URI normalization including path normalization and default port removal
- **Resolution**: Resolve relative URIs against base URIs
- **Query Parsing**: Parse and build query strings
- **URL Encoding**: Basic URL encoding support
- **IPv6 Support**: Handle IPv6 addresses in URIs
- **Extensive Testing**: Comprehensive test suite with edge cases

## Installation

Add this library to your MoonBit project by including it in your `moon.mod.json`:

```json
{
  "deps": {
    "username/uri": "^0.1.0"
  }
}
```

## Quick Start

```moonbit
test "quick_start_example" {
  // Parse a URI
  let uri = @uri.of_string("https://example.com:8080/path?query=value#fragment")
  inspect(uri.scheme(), content="Some(\"https\")")
  inspect(uri.host(), content="Some(\"example.com\")")
  inspect(uri.port(), content="Some(8080)")
  inspect(uri.path(), content="/path")
  inspect(uri.query(), content="Some(\"query=value\")")
  inspect(uri.fragment(), content="Some(\"fragment\")")

  // Build a URI using the builder methods
  let built_uri = @uri.empty()
    .with_scheme(Some("https"))
    .with_host(Some("api.example.com"))
    .with_path("/v1/users")
    .with_query(Some("limit=10&offset=0"))
  inspect(@uri.to_string(built_uri), content="https://api.example.com/v1/users?limit=10&offset=0")
}
```

## API Reference

### Core Types

#### `Uri`
The main URI data structure containing all URI components:
- `scheme: String?` - The URI scheme (e.g., "http", "https")
- `authority: Authority?` - The authority component
- `path: String` - The path component
- `query: String?` - The query string
- `fragment: String?` - The fragment identifier

#### `Authority`
The authority component of a URI:
- `userinfo: String?` - User information (username:password)
- `host: String` - The host (domain name or IP address)
- `port: Int?` - The port number

#### `UriError`
Error types for URI operations:
- `InvalidScheme(String)` - Invalid scheme format
- `InvalidAuthority(String)` - Invalid authority format
- `InvalidPath(String)` - Invalid path format
- `InvalidQuery(String)` - Invalid query format
- `InvalidFragment(String)` - Invalid fragment format
- `InvalidPort(String)` - Invalid port number
- `EmptyUri` - Empty URI string

### Parsing and Serialization

#### `of_string(uri_str: String) -> Result[Uri, UriError]`
Parse a URI string into a `Uri` structure.

```moonbit
test "of_string_example" {
  let uri = @uri.of_string("https://example.com/path")
  inspect(uri.host(), content="Some(\"example.com\")")
}
```

#### `to_string(uri: Uri) -> String`
Convert a `Uri` structure back to a string representation.

```moonbit
test "to_string_example" {
  let uri = @uri.of_string("https://example.com/path")
  let uri_string = @uri.to_string(uri)
  inspect(uri_string, content="https://example.com/path")
}
```

### Component Accessors

#### `scheme(uri: Uri) -> String?`
Get the scheme component.

#### `host(uri: Uri) -> String?`
Get the host component.

#### `port(uri: Uri) -> Int?`
Get the port component.

#### `path(uri: Uri) -> String`
Get the path component.

#### `query(uri: Uri) -> String?`
Get the query component.

#### `fragment(uri: Uri) -> String?`
Get the fragment component.

### URI Construction and Modification

#### `empty() -> Uri`
Create an empty URI with default values.

#### `with_scheme(uri: Uri, scheme: String?) -> Uri`
Create a new URI with the specified scheme.

#### `with_host(uri: Uri, host: String?) -> Uri`
Create a new URI with the specified host.

#### `with_port(uri: Uri, port: Int?) -> Uri`
Create a new URI with the specified port.

#### `with_path(uri: Uri, path: String) -> Uri`
Create a new URI with the specified path.

#### `with_query(uri: Uri, query: String?) -> Uri`
Create a new URI with the specified query.

#### `with_fragment(uri: Uri, fragment: String?) -> Uri`
Create a new URI with the specified fragment.

### URI Analysis

#### `is_absolute(uri: Uri) -> Bool`
Check if the URI is absolute (has a scheme).

#### `is_relative(uri: Uri) -> Bool`
Check if the URI is relative (no scheme).

#### `effective_port(uri: Uri) -> Int?`
Get the effective port (explicit port or default port for scheme).

### URI Utilities

#### `normalize(uri: Uri) -> Uri`
Normalize a URI by removing default ports and normalizing the path.

```moonbit
test "normalize_example" {
  let uri = @uri.of_string("https://example.com:443/path")
  let normalized = uri.normalize()
  // Default HTTPS port (443) should be removed
  inspect(normalized.port(), content="None")
  inspect(normalized.host(), content="Some(\"example.com\")")
}
```

#### `resolve(base: Uri, relative: Uri) -> Result[Uri, UriError]`
Resolve a relative URI against a base URI.

```moonbit
test "resolve_example" {
  let base = @uri.of_string("https://example.com/dir/")
  let relative = @uri.of_string("../other/file.html")
  let resolved = @uri.resolve(base, relative)
  inspect(@uri.to_string(resolved), content="https://example.com/other/file.html")
}
```

### Query String Handling

#### `parse_query(query_string: String) -> Array[(String, String)]`
Parse a query string into key-value pairs.

```moonbit
test "parse_query_example" {
  let pairs = @uri.parse_query("name=John&age=30&city=NYC")
  // Returns [("name", "John"), ("age", "30"), ("city", "NYC")]
  inspect(pairs.length(), content="3")
  inspect(pairs[0], content="(\"name\", \"John\")")
}
```

#### `build_query(pairs: Array[(String, String)]) -> String`
Build a query string from key-value pairs.

```moonbit
test "build_query_example" {
  let query = @uri.build_query([("search", "moonbit"), ("limit", "10")])
  // Returns "search=moonbit&limit=10"
  inspect(query, content="search=moonbit&limit=10")
}
```

### URL Encoding

#### `encode(input: String) -> String`
URL encode a string (basic implementation).

```moonbit
test "encode_example" {
  let encoded = @uri.encode("hello world!")
  // Returns "hello%20world%21"
  inspect(encoded, content="hello%20world%21")
}
```

## Examples

### Basic URI Parsing

```moonbit
test "parse_http_uri" {
  let uri = @uri.of_string("https://user:pass@example.com:8080/path?query=value#section")
  inspect(uri.scheme(), content="Some(\"https\")")
  inspect(uri.host(), content="Some(\"example.com\")")
  inspect(uri.port(), content="Some(8080)")
  inspect(uri.path(), content="/path")
  inspect(uri.query(), content="Some(\"query=value\")")
  inspect(uri.fragment(), content="Some(\"section\")")
}
```

### Building URIs

```moonbit
test "build_api_uri" {
  let api_uri = @uri.empty()
    .with_scheme(Some("https"))
    .with_host(Some("api.github.com"))
    .with_path("/repos/owner/repo/issues")
    .with_query(Some("state=open&per_page=50"))
  
  inspect(@uri.to_string(api_uri), content="https://api.github.com/repos/owner/repo/issues?state=open&per_page=50")
}
```

### URI Resolution

```moonbit
test "resolve_relative_uri" {
  let base = @uri.of_string("https://example.com/docs/guide/")
  let relative = @uri.of_string("../api/reference.html")
  
  let resolved = @uri.resolve(base, relative)
  inspect(@uri.to_string(resolved), content="https://example.com/docs/api/reference.html")
}
```

### Query Parameter Handling

```moonbit
test "query_parameters" {
  let uri = @uri.of_string("https://search.example.com/?q=moonbit&lang=en&safe=on")
  
  match uri.query() {
    Some(query_str) => {
      let params = @uri.parse_query(query_str)
      inspect(params.length(), content="3")
      inspect(params[0], content="(\"q\", \"moonbit\")")
      inspect(params[1], content="(\"lang\", \"en\")")
      inspect(params[2], content="(\"safe\", \"on\")")
      
      // Rebuild query
      let rebuilt = @uri.build_query(params)
      inspect(rebuilt, content="q=moonbit&lang=en&safe=on")
    }
    None => inspect("Should have query", content="\"Should have query\"")
  }
}
```

### IPv6 Support

```moonbit
test "ipv6_uri" {
  let uri = @uri.of_string("http://[2001:db8::1]:8080/path")
  inspect(uri.scheme(), content="Some(\"http\")")
  inspect(uri.host(), content="Some(\"[2001:db8::1]\")")
  inspect(uri.port(), content="Some(8080)")
  inspect(uri.path(), content="/path")
}
```

### URI Normalization

```moonbit
test "uri_normalization" {
  let uri = @uri.of_string("https://example.com:443/./path/../other/./file.html")
  let normalized = uri.normalize()
  
  // Default HTTPS port (443) should be removed
  inspect(normalized.port(), content="None")
  // Path should be normalized
  inspect(normalized.path(), content="/other/file.html")
  
  inspect(@uri.to_string(normalized), content="https://example.com/other/file.html")
}
```

## Supported URI Schemes

The library recognizes default ports for common schemes:

- `http` → 80
- `https` → 443
- `ftp` → 21
- `ssh` → 22
- `telnet` → 23
- `smtp` → 25
- `dns` → 53
- `pop3` → 110
- `imap` → 143
- `ldap` → 389
- `imaps` → 993
- `pop3s` → 995

## Error Handling

The library uses MoonBit's `Result` type for error handling. All parsing operations return `Result[Uri, UriError]` where `UriError` provides detailed information about parsing failures:

```moonbit
test "error_handling_example" {
  // Test with a valid but unusual URI
  let uri = @uri.of_string("custom://example.com")
  inspect(uri.scheme(), content="Some(\"custom\")")
  inspect(uri.host(), content="Some(\"example.com\")")
}
```

## RFC3986 Compliance

This library implements the URI specification as defined in [RFC3986](https://tools.ietf.org/html/rfc3986). Key compliance features include:

- Proper parsing of all URI components
- Scheme validation (must start with letter, contain only alphanumeric, +, -, .)
- Authority parsing with IPv6 support
- Path normalization (resolving . and .. segments)
- Query and fragment handling
- Percent-encoding support
- Relative URI resolution

## Testing

The library includes comprehensive tests covering:

- Basic URI parsing and serialization
- All URI components (scheme, authority, path, query, fragment)
- Edge cases (empty components, special characters)
- IPv6 addresses
- URI normalization
- Relative URI resolution
- Query parameter parsing
- Error conditions
- RFC3986 compliance

Run tests with:

```bash
moon test
```

## Contributing

Contributions are welcome! Please ensure that:

1. All tests pass
2. New features include comprehensive tests
3. Code follows MoonBit style guidelines
4. Documentation is updated for new features

## License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

This library is ported from the excellent [OCaml URI library](https://github.com/mirage/ocaml-uri) by the Mirage team, with enhancements for MoonBit's type system and additional utility functions.