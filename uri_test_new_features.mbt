/// Test URL encoding functionality
test "url_encoding" {
  // Test basic encoding
  let encoded = Uri::encode("hello world!")
  @json.inspect(encoded, content="hello%20world%21")
  
  // Test unreserved characters (should not be encoded)
  let unreserved = "hello-world_123.test~"
  let encoded_unreserved = Uri::encode(unreserved)
  @json.inspect(encoded_unreserved, content="hello-world_123.test~")
  
  // Test special characters
  let special = "user@domain.com:password"
  let encoded_special = Uri::encode(special)
  @json.inspect(encoded_special, content="user%40domain.com%3Apassword")
}

/// Test URL decoding functionality
test "url_decoding" {
  // Test basic decoding
  let decoded = Uri::decode("hello%20world%21")
  @json.inspect(decoded, content="hello world!")
  
  // Test invalid hex sequences (should be left as-is)
  let invalid_hex = Uri::decode("hello%ZZ")
  @json.inspect(invalid_hex, content="hello%ZZ")
  
  // Test incomplete percent encoding
  let incomplete = Uri::decode("hello%2")
  @json.inspect(incomplete, content="hello%2")
  
  // Test mixed content
  let mixed = Uri::decode("user%40domain.com%3Apass%20word")
  @json.inspect(mixed, content="user@domain.com:pass word")
}

/// Test URL encoding/decoding round trip
test "url_encoding_round_trip" {
  let original = "Hello World! @#$%^&*()"
  let encoded = Uri::encode(original)
  let decoded = Uri::decode(encoded)
  @json.inspect(decoded, content=("Hello World! @#$%^&*()"))
  
  // Test with Unicode-like content
  let unicode_like = "café naïve résumé"
  let encoded_unicode = Uri::encode(unicode_like)
  let decoded_unicode = Uri::decode(encoded_unicode)
  @json.inspect(decoded_unicode, content=("café naïve résumé"))
}

/// Test query string parsing
test "query_string_parsing" {
  // Test basic query parsing
  let query = "name=John&age=30&city=New%20York"
  let params = Uri::parse_query(query)
  @json.inspect(params, content=[
    ["name", "John"],
    ["age", "30"],
    ["city", "New York"]
  ])
  
  // Test empty query
  let empty_params = Uri::parse_query("")
  @json.inspect(empty_params.length(), content=0)
  
  // Test query with empty values
  let empty_value_query = "key1=&key2=value2&key3"
  let empty_value_params = Uri::parse_query(empty_value_query)
  @json.inspect(empty_value_params, content=[
    ["key1", ""],
    ["key2", "value2"],
    ["key3", ""]
  ])
}

/// Test query string building
test "query_string_building" {
  // Test basic query building
  let params = [("name", "John Doe"), ("age", "30"), ("active", "")]
  let query = Uri::build_query(params)
  @json.inspect(query, content="name=John%20Doe&age=30&active")
  
  // Test empty params
  let empty_query = Uri::build_query([])
  @json.inspect(empty_query, content="")
  
  // Test special characters in keys and values
  let special_params = [("user@email", "test+value"), ("key with spaces", "value&more")]
  let special_query = Uri::build_query(special_params)
  @json.inspect(special_query, content="user%40email=test%2Bvalue&key%20with%20spaces=value%26more")
}

/// Test path segments functionality
test "path_segments" {
  // Test basic path segments
  let uri = parse("/path/to/resource")
  let segments = uri.path_segments()
  @json.inspect(segments, content=["path", "to", "resource"])
  
  // Test empty path
  let empty_uri = empty()
  let empty_segments = empty_uri.path_segments()
  @json.inspect(empty_segments.length(), content=0)
  
  // Test path with encoded segments
  let encoded_uri = parse("/path/with%20spaces/and%2Bplus")
  let encoded_segments = encoded_uri.path_segments()
  @json.inspect(encoded_segments, content=["path", "with spaces", "and+plus"])
  
  // Test root path
  let root_uri = parse("/")
  let root_segments = root_uri.path_segments()
  @json.inspect(root_segments.length(), content=0)
}

/// Test path segments building
test "path_segments_building" {
  // Test basic path building
  let uri = empty().with_path_segments(["api", "v1", "users"])
  @json.inspect(uri.path(), content="/api/v1/users")
  
  // Test empty segments
  let empty_path_uri = empty().with_path_segments([])
  @json.inspect(empty_path_uri.path(), content="")
  
  // Test segments with special characters
  let special_uri = empty().with_path_segments(["path with spaces", "file+name", "resource@id"])
  @json.inspect(special_uri.path(), content="/path%20with%20spaces/file%2Bname/resource%40id")
  
  // Test single segment
  let single_uri = empty().with_path_segments(["resource"])
  @json.inspect(single_uri.path(), content="/resource")
}

/// Test userinfo components parsing
test "userinfo_components" {
  // Test username and password
  let uri_with_pass = parse("https://user:pass@example.com")
  match uri_with_pass.userinfo_components() {
    Some((user, Some(pass))) => {
      @json.inspect(user, content="user")
      @json.inspect(pass, content="pass")
    }
    _ => fail("Expected username and password")
  }
  
  // Test username only
  let uri_user_only = parse("https://user@example.com")
  match uri_user_only.userinfo_components() {
    Some((user, None)) => {
      @json.inspect(user, content="user")
    }
    _ => fail("Expected username only")
  }
  
  // Test no userinfo
  let uri_no_user = parse("https://example.com")
  match uri_no_user.userinfo_components() {
    None => () // Expected
    _ => fail("Expected no userinfo")
  }
  
  // Test encoded userinfo
  let uri_encoded = parse("https://user%40domain:pass%20word@example.com")
  match uri_encoded.userinfo_components() {
    Some((user, Some(pass))) => {
      @json.inspect(user, content="user@domain")
      @json.inspect(pass, content="pass word")
    }
    _ => fail("Expected encoded userinfo")
  }
}

/// Test userinfo building
test "userinfo_building" {
  // Test setting username and password
  let uri = empty()
    .with_host(Some("example.com"))
    .with_userinfo(Some("user"), Some("pass"))
  
  match uri.userinfo_components() {
    Some((user, Some(pass))) => {
      @json.inspect(user, content="user")
      @json.inspect(pass, content="pass")
    }
    _ => fail("Expected username and password")
  }
  
  // Test setting username only
  let uri_user_only = empty()
    .with_host(Some("example.com"))
    .with_userinfo(Some("user"), None)
  
  match uri_user_only.userinfo_components() {
    Some((user, None)) => {
      @json.inspect(user, content="user")
    }
    _ => fail("Expected username only")
  }
  
  // Test removing userinfo
  let uri_removed = uri.with_userinfo(None, None)
  match uri_removed.userinfo_components() {
    None => () // Expected
    _ => fail("Expected no userinfo")
  }
  
  // Test special characters in userinfo
  let uri_special = empty()
    .with_host(Some("example.com"))
    .with_userinfo(Some("user@domain"), Some("pass word"))
  
  let uri_string = uri_special.to_string()
  if not(uri_string.contains("user%40domain:pass%20word@")) {
    fail("Expected encoded userinfo in URI string")
  }
}

/// Test comprehensive URI building with all components
test "comprehensive_uri_building" {
  let uri = empty()
    .with_scheme(Some("https"))
    .with_userinfo(Some("admin"), Some("secret"))
    .with_host(Some("api.example.com"))
    .with_port(Some(8443))
    .with_path_segments(["v2", "users", "profile"])
    .with_query_param("format", "json")
    .with_query_param("include", "permissions")
    .with_fragment(Some("section1"))
  
  let uri_string = uri.to_string()
  @json.inspect(uri_string, content="https://admin:secret@api.example.com:8443/v2/users/profile?format=json&include=permissions#section1")
  
  // Verify all components
  @json.inspect(uri.scheme(), content=["https"])
  @json.inspect(uri.host(), content=["api.example.com"])
  @json.inspect(uri.port(), content=[8443])
  @json.inspect(uri.path_segments(), content=["v2", "users", "profile"])
  @json.inspect(uri.get_query_param("format"), content=["json"])
  @json.inspect(uri.get_query_param("include"), content=["permissions"])
  @json.inspect(uri.fragment(), content=["section1"])
}

/// Test edge cases and error conditions
test "edge_cases" {
  // Test malformed percent encoding in existing functions
  let malformed_uri = parse("https://example.com/path%ZZ")
  // Should parse successfully but keep malformed encoding
  @json.inspect(malformed_uri.path(), content="/path%ZZ")
  
  // Test very long URI components
  let long_segment = "a".repeat(1000)
  let long_uri = empty().with_path_segments([long_segment])
  let segments = long_uri.path_segments()
  @json.inspect(segments[0].length(), content=1000)
  
  // Test empty components
  let empty_components_uri = empty()
    .with_scheme(Some(""))
    .with_host(Some(""))
    .with_path("")
  
  @json.inspect(empty_components_uri.scheme(), content=[""])
  @json.inspect(empty_components_uri.host(), content=[""])
  @json.inspect(empty_components_uri.path(), content="")
}

/// Test RFC 3986 compliance scenarios
test "rfc3986_compliance" {
  // Test reserved characters in different components
  let uri = parse("https://example.com/path?query=value%3Dwith%26special&other=normal#frag%23ment")
  
  // Query should be parsed correctly
  let query_params = Uri::parse_query(uri.query().unwrap_or(""))
  @json.inspect(query_params, content=[
    ["query", "value=with&special"],
    ["other", "normal"]
  ])
  
  // Test case sensitivity in scheme (should be case-insensitive in practice, but we store as-is)
  let upper_scheme = parse("HTTPS://example.com")
  @json.inspect(upper_scheme.scheme(), content=["HTTPS"])
  
  // Test IPv6 addresses (basic support)
  let ipv6_uri = parse("http://[2001:db8::1]:8080/path")
  @json.inspect(ipv6_uri.host(), content=["[2001:db8::1]"])
  @json.inspect(ipv6_uri.port(), content=[8080])
}
