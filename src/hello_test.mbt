/// Test basic URI parsing functionality
test "basic_uri_parsing" {
  // Test simple HTTP URI
  let uri = of_string("https://example.com/path")
  @json.inspect(uri, content={
    "scheme": "https",
    "authority": { "host": "example.com" },
    "path": "/path",
  })
}

/// Test empty URI
test "empty_uri" {
  let empty_uri = empty()
  @json.inspect(empty_uri, content=({"path":""}))
}

/// Test URI building
test "uri_building" {
  let uri = empty()
    .with_scheme(Some("https"))
    .with_host(Some("api.example.com"))
    .with_path("/v1/users")
    .with_query(Some("limit=10"))
  
  @json.inspect(uri, content=({"scheme":"https","authority":{"host":"api.example.com"},"path":"/v1/users","query":"limit=10"}))
}

/// Test URI serialization
test "uri_serialization" {
  let uri = empty()
    .with_scheme(Some("http"))
    .with_host(Some("localhost"))
    .with_path("/test")
  
  let uri_string = to_string(uri)
  if not(uri_string.contains("http://")) {
    fail("Expected URI string to contain 'http://'")
  }
  if not(uri_string.contains("localhost")) {
    fail("Expected URI string to contain 'localhost'")
  }
  if not(uri_string.contains("/test")) {
    fail("Expected URI string to contain '/test'")
  }
}

/// Test path-only URI
test "path_only_uri" {
  try {
    let uri = of_string("/path/to/resource")
    if uri.scheme() != None {
      fail("Expected no scheme")
    }
    if uri.host() != None {
      fail("Expected no host")
    }
    if uri.path() != "/path/to/resource" {
      fail("Expected path '/path/to/resource'")
    }
  } catch {
    _ => fail("Failed to parse path-only URI")
  }
}

/// Test empty URI error
test "empty_uri_error" {
  try {
    let _ = of_string("")
    fail("Expected EmptyUri error")
  } catch {
    UriError::EmptyUri => () // Expected
    _ => fail("Expected EmptyUri error")
  }
}

/// Test URI absolute/relative checks
test "uri_absolute_relative" {
  let absolute_uri = empty().with_scheme(Some("https"))
  let relative_uri = empty().with_path("/relative")
  
  if not(absolute_uri.is_absolute()) {
    fail("Expected URI with scheme to be absolute")
  }
  if absolute_uri.is_relative() {
    fail("Expected URI with scheme to not be relative")
  }
  if relative_uri.is_absolute() {
    fail("Expected URI without scheme to not be absolute")
  }
  if not(relative_uri.is_relative()) {
    fail("Expected URI without scheme to be relative")
  }
}

/// Test invalid scheme
test "invalid_scheme" {
  try {
    let _ = of_string("123invalid://example.com")
    fail("Expected InvalidScheme error")
  } catch {
    UriError::InvalidScheme(scheme) => {
      if scheme != "123invalid" {
        fail("Expected scheme '123invalid', got: " + scheme)
      }
    }
    _ => fail("Expected InvalidScheme error")
  }
}

/// Test invalid port
test "invalid_port" {
  try {
    let _ = of_string("http://example.com:abc/path")
    fail("Expected InvalidPort error")
  } catch {
    UriError::InvalidPort(port) => {
      if port != "abc" {
        fail("Expected port 'abc', got: " + port)
      }
    }
    _ => fail("Expected InvalidPort error")
  }
}

/// Test port out of range
test "port_out_of_range" {
  try {
    let _ = of_string("http://example.com:99999/path")
    fail("Expected error for port out of range")
  } catch {
    UriError::InvalidPort(_) => () // Expected
    _ => fail("Expected InvalidPort error")
  }
}

/// Test invalid path with spaces
test "invalid_path_spaces" {
  try {
    let _ = of_string("http://example.com/path with spaces")
    fail("Expected error for path with unescaped spaces")
  } catch {
    UriError::InvalidPath(_) => () // Expected
    _ => fail("Expected InvalidPath error")
  }
}

/// Test invalid query with spaces
test "invalid_query_spaces" {
  try {
    let _ = of_string("http://example.com/path?query with spaces")
    fail("Expected error for query with unescaped spaces")
  } catch {
    UriError::InvalidQuery(_) => () // Expected
    _ => fail("Expected InvalidQuery error")
  }
}

/// Test invalid fragment with spaces
test "invalid_fragment_spaces" {
  try {
    let _ = of_string("http://example.com/path#fragment with spaces")
    fail("Expected error for fragment with unescaped spaces")
  } catch {
    UriError::InvalidFragment(_) => () // Expected
    _ => fail("Expected InvalidFragment error")
  }
}

/// Test URI normalization
test "uri_normalization" {
  // Test default port removal
  let uri1 = of_string("https://example.com:443/path")
  let normalized1 = uri1.normalize()
  @json.inspect(normalized1, content=({"scheme":"https","authority":{"host":"example.com"},"path":"/path"}))
  
  // Test path normalization
  let uri2 = of_string("http://example.com/./path/../other/./file.html")
  let normalized2 = uri2.normalize()
  @json.inspect(normalized2.path(), content=("/other/file.html"))
}

/// Test URI resolution
test "uri_resolution" {
  let base = of_string("https://example.com/docs/guide/")
  let relative = of_string("../api/reference.html")
  
  try {
    let resolved = resolve(base, relative)
    let expected = "https://example.com/docs/api/reference.html"
    let actual = to_string(resolved)
    if actual != expected {
      fail("Expected '" + expected + "', got: '" + actual + "'")
    }
  } catch {
    _ => fail("Failed to resolve relative URI")
  }
  
  // Test absolute relative URI
  let absolute_relative = of_string("https://other.com/path")
  try {
    let resolved = resolve(base, absolute_relative)
    if to_string(resolved) != "https://other.com/path" {
      fail("Expected absolute URI to be returned as-is")
    }
  } catch {
    _ => fail("Failed to resolve absolute URI")
  }
}

/// Test query parameter parsing
test "query_parameter_parsing" {
  let query = "name=John&age=30&city=New%20York"
  let params = parse_query(query)
  @json.inspect(params, content=[
    ["name", "John"],
    ["age", "30"], 
    ["city", "New%20York"]
  ])
}

/// Test query parameter building
test "query_parameter_building" {
  let params = [("name", "John"), ("age", "30"), ("active", "")]
  let query = build_query(params)
  @json.inspect(query, content=("name=John&age=30&active"))
}

/// Test get query parameter
test "get_query_parameter" {
  let uri = of_string("https://example.com/search?q=moonbit&lang=en&safe=on")
  
  let param_q = uri.get_query_param("q")
  @json.inspect(param_q, content=(["moonbit"]))
  
  let param_nonexistent = uri.get_query_param("nonexistent")
  // FIXME(ups): This is a workaround to fix the test.
  @json.inspect(param_nonexistent, content=Json::null())
}

/// Test with query parameter
test "with_query_parameter" {
  let uri = of_string("https://example.com/search?q=test")
  
  // Update existing parameter
  let updated = uri.with_query_param("q", "moonbit")
  let updated_param = updated.get_query_param("q")
  @json.inspect(updated_param, content=(["moonbit"]))
  
  // Add new parameter
  let with_new = updated.with_query_param("lang", "en")
  let new_param = with_new.get_query_param("lang")
  @json.inspect(new_param, content=(["en"]))
}

/// Test remove query parameter
test "remove_query_parameter" {
  let uri = of_string("https://example.com/search?q=test&lang=en&safe=on")
  
  let without_lang = uri.remove_query_param("lang")
  match without_lang.get_query_param("lang") {
    Some(_) => fail("Expected parameter 'lang' to be removed")
    None => () // Expected
  }
  
  // Check other parameters still exist
  match without_lang.get_query_param("q") {
    Some(value) => {
      if value != "test" {
        fail("Expected 'q' parameter to remain")
      }
    }
    None => fail("Expected 'q' parameter to remain")
  }
}

/// Test URL encoding
test "url_encoding" {
  let input = "hello world!"
  let encoded = encode(input)
  @json.inspect(encoded, content="hello%20world%21")
  
  // Test unreserved characters
  let unreserved = "hello-world_123.test~"
  let encoded_unreserved = encode(unreserved)
  @json.inspect(encoded_unreserved, content="hello-world_123.test~")
}

/// Test URL decoding
test "url_decoding" {
  let decoded_result = decode("hello%20world%21")
  @json.inspect(decoded_result, content=("hello world!"))
  
  // Test invalid hex
  let invalid_hex_result = decode("hello%ZZ")
  @json.inspect(invalid_hex_result, content=("hello%ZZ"))
}

/// Test complex URI with userinfo
test "complex_uri_with_userinfo" {
  let uri = of_string("https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results")
  @json.inspect(uri, content={
    "scheme": "https",
    "authority": {
      "userinfo": "user:pass",
      "host": "api.example.com",
      "port": 8080
    },
    "path": "/v1/users",
    "query": "limit=10&offset=0",
    "fragment": "results"
  })
}

/// Test URL encoding round trip
test "url_encoding_round_trip" {
  let original = "Hello World! @#$%^&*()"
  let encoded = encode(original)
  try {
    let decoded = decode(encoded)
    if decoded != original {
      fail("Round trip encoding/decoding failed")
    }
  } catch {
    _ => fail("Failed to decode encoded string")
  }
}

/// Test effective port
test "effective_port" {
  // Explicit port
  let uri1 = of_string("https://example.com:8080/path")
  match uri1.effective_port() {
    Some(port_val) => {
      if port_val != 8080 {
        fail("Expected explicit port 8080")
      }
    }
    None => fail("Expected to find explicit port")
  }
  
  // Default port
  let uri2 = of_string("https://example.com/path")
  match uri2.effective_port() {
    Some(port_val) => {
      if port_val != 443 {
        fail("Expected default HTTPS port 443")
      }
    }
    None => fail("Expected to find default port")
  }
  
  // No authority
  let uri3 = of_string("/path")
  match uri3.effective_port() {
    Some(_) => fail("Expected no port for URI without authority")
    None => () // Expected
  }
}

/// Test Show trait implementation
test "show_trait_implementation" {
  let uri = of_string("https://user:pass@example.com:8080/path?query=value#fragment")
  
  // Test that Show trait works by checking the string representation
  let direct_output = to_string(uri) // Direct function call
  
  // The Show trait should provide consistent output
  if not(direct_output.contains("https://")) {
    fail("Show output should contain the URI string")
  }
  
  if not(direct_output.contains("example.com:8080")) {
    fail("Show output should contain host and port")
  }
}

/// Test debug string representation
test "debug_string_representation" {
  let uri = of_string("https://user:pass@example.com:8080/path?query=value#fragment")
  let debug_output = debug_string(uri)
  
  // Check that all components are present in debug output
  if not(debug_output.contains("scheme: Some(\"https\")")) {
    fail("Debug output should show scheme")
  }
  if not(debug_output.contains("host: \"example.com\"")) {
    fail("Debug output should show host")
  }
  if not(debug_output.contains("port: Some(8080)")) {
    fail("Debug output should show port")
  }
  if not(debug_output.contains("path: \"/path\"")) {
    fail("Debug output should show path")
  }
  if not(debug_output.contains("query: Some(\"query=value\")")) {
    fail("Debug output should show query")
  }
  if not(debug_output.contains("fragment: Some(\"fragment\")")) {
    fail("Debug output should show fragment")
  }
}

/// Test pretty string representation
test "pretty_string_representation" {
  let uri = of_string("https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results")
  let pretty_output = pretty_string(uri)
  
  // Check for visual indicators
  if not(pretty_output.contains("📋 Scheme: https")) {
    fail("Pretty output should show scheme with icon")
  }
  if not(pretty_output.contains("👤 User: user:pass")) {
    fail("Pretty output should show user info with icon")
  }
  if not(pretty_output.contains("🏠 Host: api.example.com")) {
    fail("Pretty output should show host with icon")
  }
  if not(pretty_output.contains("🔌 Port: 8080")) {
    fail("Pretty output should show port with icon")
  }
  if not(pretty_output.contains("📁 Path: /v1/users")) {
    fail("Pretty output should show path with icon")
  }
  if not(pretty_output.contains("❓ Query: limit=10&offset=0")) {
    fail("Pretty output should show query with icon")
  }
  if not(pretty_output.contains("🔗 Fragment: results")) {
    fail("Pretty output should show fragment with icon")
  }
  
  // Check for query parameter breakdown
  if not(pretty_output.contains("Parameters:")) {
    fail("Pretty output should show parameter breakdown")
  }
  if not(pretty_output.contains("limit = \"10\"")) {
    fail("Pretty output should show individual parameters")
  }
}

/// Test pretty string with minimal URI
test "pretty_string_minimal_uri" {
  let uri = of_string("/simple/path")
  let pretty_output = pretty_string(uri)
  
  if not(pretty_output.contains("📁 Path: /simple/path")) {
    fail("Pretty output should show path for minimal URI")
  }
  
  // Should not contain other components
  if pretty_output.contains("Scheme:") {
    fail("Pretty output should not show scheme for path-only URI")
  }
}

/// Test pretty string with default port
test "pretty_string_default_port" {
  let uri = of_string("https://example.com/path")
  let pretty_output = pretty_string(uri)
  
  // Should show default port
  if not(pretty_output.contains("🔌 Port: 443 (default)")) {
    fail("Pretty output should show default port for HTTPS")
  }
}

/// Test debug string with empty components
test "debug_string_empty_components" {
  let uri = of_string("/path")
  let debug_output = debug_string(uri)
  
  if not(debug_output.contains("scheme: None")) {
    fail("Debug output should show None for missing scheme")
  }
  if not(debug_output.contains("authority: None")) {
    fail("Debug output should show None for missing authority")
  }
  if not(debug_output.contains("query: None")) {
    fail("Debug output should show None for missing query")
  }
  if not(debug_output.contains("fragment: None")) {
    fail("Debug output should show None for missing fragment")
  }
}