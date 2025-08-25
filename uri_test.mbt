/// Test basic URI parsing functionality
test "basic_uri_parsing" {
  // Test simple HTTP URI
  let uri = parse("https://example.com/path")
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
  
  let uri_string = uri.to_string()
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
    let uri = parse("/path/to/resource")
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
    let _ = parse("")
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
    let _ = parse("123invalid://example.com")
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
    let _ = parse("http://example.com:abc/path")
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
    let _ = parse("http://example.com:99999/path")
    fail("Expected error for port out of range")
  } catch {
    UriError::InvalidPort(_) => () // Expected
    _ => fail("Expected InvalidPort error")
  }
}

/// Test invalid path with spaces
test "invalid_path_spaces" {
  try {
    let _ = parse("http://example.com/path with spaces")
    fail("Expected error for path with unescaped spaces")
  } catch {
    UriError::InvalidPath(_) => () // Expected
    _ => fail("Expected InvalidPath error")
  }
}

/// Test invalid query with spaces
test "invalid_query_spaces" {
  try {
    let _ = parse("http://example.com/path?query with spaces")
    fail("Expected error for query with unescaped spaces")
  } catch {
    UriError::InvalidQuery(_) => () // Expected
    _ => fail("Expected InvalidQuery error")
  }
}

/// Test invalid fragment with spaces
test "invalid_fragment_spaces" {
  try {
    let _ = parse("http://example.com/path#fragment with spaces")
    fail("Expected error for fragment with unescaped spaces")
  } catch {
    UriError::InvalidFragment(_) => () // Expected
    _ => fail("Expected InvalidFragment error")
  }
}

/// Test URI normalization
test "uri_normalization" {
  // Test default port removal
  let uri1 = parse("https://example.com:443/path")
  let normalized1 = uri1.normalize()
  @json.inspect(normalized1, content=({"scheme":"https","authority":{"host":"example.com"},"path":"/path"}))
  
  // Test path normalization
  let uri2 = parse("http://example.com/./path/../other/./file.html")
  let normalized2 = uri2.normalize()
  @json.inspect(normalized2.path(), content=("/other/file.html"))
}

/// Test URI resolution
test "uri_resolution" {
  let base = parse("https://example.com/docs/guide/")
  let relative = parse("../api/reference.html")
  
  try {
    let resolved = resolve(base, relative)
    let expected = "https://example.com/docs/api/reference.html"
    let actual = resolved.to_string()
    if actual != expected {
      fail("Expected '" + expected + "', got: '" + actual + "'")
    }
  } catch {
    _ => fail("Failed to resolve relative URI")
  }
  
  // Test absolute relative URI
  let absolute_relative = parse("https://other.com/path")
  try {
    let resolved = resolve(base, absolute_relative)
    if resolved.to_string() != "https://other.com/path" {
      fail("Expected absolute URI to be returned as-is")
    }
  } catch {
    _ => fail("Failed to resolve absolute URI")
  }
}





/// Test get query parameter
test "get_query_parameter" {
  let uri = parse("https://example.com/search?q=moonbit&lang=en&safe=on")
  
  let param_q = uri.get_query_param("q")
  @json.inspect(param_q, content=(["moonbit"]))
  
  let param_nonexistent = uri.get_query_param("nonexistent")
  // FIXME(ups): This is a workaround to fix the test.
  @json.inspect(param_nonexistent, content=Json::null())
}

/// Test with query parameter
test "with_query_parameter" {
  let uri = parse("https://example.com/search?q=test")
  
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
  let uri = parse("https://example.com/search?q=test&lang=en&safe=on")
  
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





/// Test complex URI with userinfo
test "complex_uri_with_userinfo" {
  let uri = parse("https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results")
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



/// Test effective port
test "effective_port" {
  // Explicit port
  let uri1 = parse("https://example.com:8080/path")
  match uri1.effective_port() {
    Some(port_val) => {
      if port_val != 8080 {
        fail("Expected explicit port 8080")
      }
    }
    None => fail("Expected to find explicit port")
  }
  
  // Default port
  let uri2 = parse("https://example.com/path")
  match uri2.effective_port() {
    Some(port_val) => {
      if port_val != 443 {
        fail("Expected default HTTPS port 443")
      }
    }
    None => fail("Expected to find default port")
  }
  
  // No authority
  let uri3 = parse("/path")
  match uri3.effective_port() {
    Some(_) => fail("Expected no port for URI without authority")
    None => () // Expected
  }
}

/// Test Show trait implementation
test "show_trait_implementation" {
  let uri = parse("https://user:pass@example.com:8080/path?query=value#fragment")
  
  // Test that Show trait works by checking the string representation
  let direct_output = uri.to_string() // Direct method call
  
  // The Show trait should provide consistent output
  if not(direct_output.contains("https://")) {
    fail("Show output should contain the URI string")
  }
  
  if not(direct_output.contains("example.com:8080")) {
    fail("Show output should contain host and port")
  }
}









