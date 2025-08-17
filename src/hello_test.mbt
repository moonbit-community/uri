/// Test basic URI parsing functionality
test "basic_uri_parsing" {
  // Test simple HTTP URI
  let uri_result = of_string("https://example.com/path")
  match uri_result {
    Ok(uri) => {
      if scheme(uri) != Some("https") {
        fail("Expected scheme 'https'")
      }
      if host(uri) != Some("example.com") {
        fail("Expected host 'example.com'")
      }
      if path(uri) != "/path" {
        fail("Expected path '/path'")
      }
    }
    Err(_) => fail("Failed to parse valid URI")
  }
}

/// Test empty URI
test "empty_uri" {
  let empty_uri = empty()
  if scheme(empty_uri) != None {
    fail("Expected no scheme in empty URI")
  }
  if host(empty_uri) != None {
    fail("Expected no host in empty URI")
  }
  if path(empty_uri) != "" {
    fail("Expected empty path in empty URI")
  }
}

/// Test URI building
test "uri_building" {
  let uri = empty()
    |> with_scheme(Some("https"))
    |> with_host(Some("api.example.com"))
    |> with_path("/v1/users")
    |> with_query(Some("limit=10"))
  
  if scheme(uri) != Some("https") {
    fail("Expected scheme 'https'")
  }
  if host(uri) != Some("api.example.com") {
    fail("Expected host 'api.example.com'")
  }
  if path(uri) != "/v1/users" {
    fail("Expected path '/v1/users'")
  }
  if query(uri) != Some("limit=10") {
    fail("Expected query 'limit=10'")
  }
}

/// Test URI serialization
test "uri_serialization" {
  let uri = empty()
    |> with_scheme(Some("http"))
    |> with_host(Some("localhost"))
    |> with_path("/test")
  
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
  match of_string("/path/to/resource") {
    Ok(uri) => {
      if scheme(uri) != None {
        fail("Expected no scheme")
      }
      if host(uri) != None {
        fail("Expected no host")
      }
      if path(uri) != "/path/to/resource" {
        fail("Expected path '/path/to/resource'")
      }
    }
    Err(_) => fail("Failed to parse path-only URI")
  }
}

/// Test empty URI error
test "empty_uri_error" {
  match of_string("") {
    Ok(_) => fail("Expected error for empty URI")
    Err(EmptyUri) => () // Expected
    Err(_) => fail("Expected EmptyUri error")
  }
}

/// Test URI absolute/relative checks
test "uri_absolute_relative" {
  let absolute_uri = empty() |> with_scheme(Some("https"))
  let relative_uri = empty() |> with_path("/relative")
  
  if not(is_absolute(absolute_uri)) {
    fail("Expected URI with scheme to be absolute")
  }
  if is_relative(absolute_uri) {
    fail("Expected URI with scheme to not be relative")
  }
  if is_absolute(relative_uri) {
    fail("Expected URI without scheme to not be absolute")
  }
  if not(is_relative(relative_uri)) {
    fail("Expected URI without scheme to be relative")
  }
}

/// Test invalid scheme
test "invalid_scheme" {
  match of_string("123invalid://example.com") {
    Ok(_) => fail("Expected error for invalid scheme")
    Err(InvalidScheme(_)) => () // Expected
    Err(_) => fail("Expected InvalidScheme error")
  }
}

/// Test invalid port
test "invalid_port" {
  match of_string("http://example.com:abc/path") {
    Ok(_) => fail("Expected error for invalid port")
    Err(InvalidPort(_)) => () // Expected
    Err(_) => fail("Expected InvalidPort error")
  }
}

/// Test port out of range
test "port_out_of_range" {
  match of_string("http://example.com:99999/path") {
    Ok(_) => fail("Expected error for port out of range")
    Err(InvalidPort(_)) => () // Expected
    Err(_) => fail("Expected InvalidPort error")
  }
}

/// Test invalid path with spaces
test "invalid_path_spaces" {
  match of_string("http://example.com/path with spaces") {
    Ok(_) => fail("Expected error for path with unescaped spaces")
    Err(InvalidPath(_)) => () // Expected
    Err(_) => fail("Expected InvalidPath error")
  }
}

/// Test invalid query with spaces
test "invalid_query_spaces" {
  match of_string("http://example.com/path?query with spaces") {
    Ok(_) => fail("Expected error for query with unescaped spaces")
    Err(InvalidQuery(_)) => () // Expected
    Err(_) => fail("Expected InvalidQuery error")
  }
}

/// Test invalid fragment with spaces
test "invalid_fragment_spaces" {
  match of_string("http://example.com/path#fragment with spaces") {
    Ok(_) => fail("Expected error for fragment with unescaped spaces")
    Err(InvalidFragment(_)) => () // Expected
    Err(_) => fail("Expected InvalidFragment error")
  }
}

/// Test URI normalization
test "uri_normalization" {
  // Test default port removal
  let uri1 = of_string("https://example.com:443/path").unwrap()
  let normalized1 = normalize(uri1)
  if port(normalized1) != None {
    fail("Expected default HTTPS port to be removed")
  }
  if to_string(normalized1) != "https://example.com/path" {
    fail("Expected normalized URI without default port")
  }
  
  // Test path normalization
  let uri2 = of_string("http://example.com/./path/../other/./file.html").unwrap()
  let normalized2 = normalize(uri2)
  if path(normalized2) != "/other/file.html" {
    fail("Expected normalized path '/other/file.html', got: " + path(normalized2))
  }
}

/// Test URI resolution
test "uri_resolution" {
  let base = of_string("https://example.com/docs/guide/").unwrap()
  let relative = of_string("../api/reference.html").unwrap()
  
  match resolve(base, relative) {
    Ok(resolved) => {
      let expected = "https://example.com/docs/api/reference.html"
      let actual = to_string(resolved)
      if actual != expected {
        fail("Expected '" + expected + "', got: '" + actual + "'")
      }
    }
    Err(_) => fail("Failed to resolve relative URI")
  }
  
  // Test absolute relative URI
  let absolute_relative = of_string("https://other.com/path").unwrap()
  match resolve(base, absolute_relative) {
    Ok(resolved) => {
      if to_string(resolved) != "https://other.com/path" {
        fail("Expected absolute URI to be returned as-is")
      }
    }
    Err(_) => fail("Failed to resolve absolute URI")
  }
}

/// Test query parameter parsing
test "query_parameter_parsing" {
  let query = "name=John&age=30&city=New%20York"
  let params = parse_query(query)
  
  if params.length() != 3 {
    fail("Expected 3 parameters, got: " + params.length().to_string())
  }
  
  let (key1, value1) = params[0]
  if key1 != "name" || value1 != "John" {
    fail("Expected first param to be name=John")
  }
  
  let (key2, value2) = params[1]
  if key2 != "age" || value2 != "30" {
    fail("Expected second param to be age=30")
  }
  
  let (key3, value3) = params[2]
  if key3 != "city" || value3 != "New%20York" {
    fail("Expected third param to be city=New%20York")
  }
}

/// Test query parameter building
test "query_parameter_building" {
  let params = [("name", "John"), ("age", "30"), ("active", "")]
  let query = build_query(params)
  
  if query != "name=John&age=30&active" {
    fail("Expected 'name=John&age=30&active', got: '" + query + "'")
  }
}

/// Test get query parameter
test "get_query_parameter" {
  let uri = of_string("https://example.com/search?q=moonbit&lang=en&safe=on").unwrap()
  
  match get_query_param(uri, "q") {
    Some(value) => {
      if value != "moonbit" {
        fail("Expected 'moonbit', got: '" + value + "'")
      }
    }
    None => fail("Expected to find query parameter 'q'")
  }
  
  match get_query_param(uri, "nonexistent") {
    Some(_) => fail("Expected None for nonexistent parameter")
    None => () // Expected
  }
}

/// Test with query parameter
test "with_query_parameter" {
  let uri = of_string("https://example.com/search?q=test").unwrap()
  
  // Update existing parameter
  let updated = with_query_param(uri, "q", "moonbit")
  match get_query_param(updated, "q") {
    Some(value) => {
      if value != "moonbit" {
        fail("Expected updated value 'moonbit'")
      }
    }
    None => fail("Expected to find updated parameter")
  }
  
  // Add new parameter
  let with_new = with_query_param(updated, "lang", "en")
  match get_query_param(with_new, "lang") {
    Some(value) => {
      if value != "en" {
        fail("Expected new parameter value 'en'")
      }
    }
    None => fail("Expected to find new parameter")
  }
}

/// Test remove query parameter
test "remove_query_parameter" {
  let uri = of_string("https://example.com/search?q=test&lang=en&safe=on").unwrap()
  
  let without_lang = remove_query_param(uri, "lang")
  match get_query_param(without_lang, "lang") {
    Some(_) => fail("Expected parameter 'lang' to be removed")
    None => () // Expected
  }
  
  // Check other parameters still exist
  match get_query_param(without_lang, "q") {
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
  
  if not(encoded.contains("%20")) {
    fail("Expected space to be encoded as %20")
  }
  if not(encoded.contains("%21")) {
    fail("Expected exclamation mark to be encoded as %21")
  }
  
  // Test unreserved characters
  let unreserved = "hello-world_123.test~"
  let encoded_unreserved = encode(unreserved)
  if encoded_unreserved != unreserved {
    fail("Expected unreserved characters to not be encoded")
  }
}

/// Test URL decoding
test "url_decoding" {
  match decode("hello%20world%21") {
    Ok(decoded) => {
      if decoded != "hello world!" {
        fail("Expected 'hello world!', got: '" + decoded + "'")
      }
    }
    Err(_) => fail("Failed to decode valid URL encoded string")
  }
  
  // Test invalid hex
  match decode("hello%ZZ") {
    Ok(decoded) => {
      if decoded != "hello%ZZ" {
        fail("Expected invalid hex to be treated as literal")
      }
    }
    Err(_) => fail("Expected invalid hex to be handled gracefully")
  }
}

/// Test URL encoding round trip
test "url_encoding_round_trip" {
  let original = "Hello World! @#$%^&*()"
  let encoded = encode(original)
  match decode(encoded) {
    Ok(decoded) => {
      if decoded != original {
        fail("Round trip encoding/decoding failed")
      }
    }
    Err(_) => fail("Failed to decode encoded string")
  }
}

/// Test effective port
test "effective_port" {
  // Explicit port
  let uri1 = of_string("https://example.com:8080/path").unwrap()
  match effective_port(uri1) {
    Some(port_val) => {
      if port_val != 8080 {
        fail("Expected explicit port 8080")
      }
    }
    None => fail("Expected to find explicit port")
  }
  
  // Default port
  let uri2 = of_string("https://example.com/path").unwrap()
  match effective_port(uri2) {
    Some(port_val) => {
      if port_val != 443 {
        fail("Expected default HTTPS port 443")
      }
    }
    None => fail("Expected to find default port")
  }
  
  // No authority
  let uri3 = of_string("/path").unwrap()
  match effective_port(uri3) {
    Some(_) => fail("Expected no port for URI without authority")
    None => () // Expected
  }
}

/// Test Show trait implementation
test "show_trait_implementation" {
  let uri = of_string("https://user:pass@example.com:8080/path?query=value#fragment").unwrap()
  
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
  let uri = of_string("https://user:pass@example.com:8080/path?query=value#fragment").unwrap()
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
  let uri = of_string("https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results").unwrap()
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
  let uri = of_string("/simple/path").unwrap()
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
  let uri = of_string("https://example.com/path").unwrap()
  let pretty_output = pretty_string(uri)
  
  // Should show default port
  if not(pretty_output.contains("🔌 Port: 443 (default)")) {
    fail("Pretty output should show default port for HTTPS")
  }
}

/// Test debug string with empty components
test "debug_string_empty_components" {
  let uri = of_string("/path").unwrap()
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