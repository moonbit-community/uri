/// Test basic URI parsing functionality
test "basic_uri_parsing" {
  // Test simple HTTP URI
  let uri_result = @lib.of_string("https://example.com/path")
  match uri_result {
    Ok(uri) => {
      if @lib.scheme(uri) != Some("https") {
        fail("Expected scheme 'https'")
      }
      if @lib.host(uri) != Some("example.com") {
        fail("Expected host 'example.com'")
      }
      if @lib.path(uri) != "/path" {
        fail("Expected path '/path'")
      }
    }
    Err(_) => fail("Failed to parse valid URI")
  }
}

/// Test empty URI
test "empty_uri" {
  let empty_uri = @lib.empty()
  if @lib.scheme(empty_uri) != None {
    fail("Expected no scheme in empty URI")
  }
  if @lib.host(empty_uri) != None {
    fail("Expected no host in empty URI")
  }
  if @lib.path(empty_uri) != "" {
    fail("Expected empty path in empty URI")
  }
}

/// Test URI building
test "uri_building" {
  let uri = @lib.empty()
    |> @lib.with_scheme(Some("https"))
    |> @lib.with_host(Some("api.example.com"))
    |> @lib.with_path("/v1/users")
    |> @lib.with_query(Some("limit=10"))
  
  if @lib.scheme(uri) != Some("https") {
    fail("Expected scheme 'https'")
  }
  if @lib.host(uri) != Some("api.example.com") {
    fail("Expected host 'api.example.com'")
  }
  if @lib.path(uri) != "/v1/users" {
    fail("Expected path '/v1/users'")
  }
  if @lib.query(uri) != Some("limit=10") {
    fail("Expected query 'limit=10'")
  }
}

/// Test URI serialization
test "uri_serialization" {
  let uri = @lib.empty()
    |> @lib.with_scheme(Some("http"))
    |> @lib.with_host(Some("localhost"))
    |> @lib.with_path("/test")
  
  let uri_string = @lib.to_string(uri)
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
  match @lib.of_string("/path/to/resource") {
    Ok(uri) => {
      if @lib.scheme(uri) != None {
        fail("Expected no scheme")
      }
      if @lib.host(uri) != None {
        fail("Expected no host")
      }
      if @lib.path(uri) != "/path/to/resource" {
        fail("Expected path '/path/to/resource'")
      }
    }
    Err(_) => fail("Failed to parse path-only URI")
  }
}

/// Test empty URI error
test "empty_uri_error" {
  match @lib.of_string("") {
    Ok(_) => fail("Expected error for empty URI")
    Err(@lib.EmptyUri) => () // Expected
    Err(_) => fail("Expected EmptyUri error")
  }
}

/// Test URI absolute/relative checks
test "uri_absolute_relative" {
  let absolute_uri = @lib.empty() |> @lib.with_scheme(Some("https"))
  let relative_uri = @lib.empty() |> @lib.with_path("/relative")
  
  if not(@lib.is_absolute(absolute_uri)) {
    fail("Expected URI with scheme to be absolute")
  }
  if @lib.is_relative(absolute_uri) {
    fail("Expected URI with scheme to not be relative")
  }
  if @lib.is_absolute(relative_uri) {
    fail("Expected URI without scheme to not be absolute")
  }
  if not(@lib.is_relative(relative_uri)) {
    fail("Expected URI without scheme to be relative")
  }
}