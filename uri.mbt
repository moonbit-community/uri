/// URI data structure representing a parsed URI according to RFC3986
/// 
/// A URI has the general form:
/// scheme://authority/path?query#fragment
/// 
/// Where:
/// - scheme: identifies the protocol (e.g., "http", "https", "ftp")
/// - authority: contains user info, host, and port
/// - path: hierarchical path to resource
/// - query: additional parameters
/// - fragment: reference to a secondary resource
pub struct Uri {
  scheme : String?
  authority : Authority?
  path : String
  query : String?
  fragment : String?
} derive(ToJson)

/// Authority component of a URI
/// Contains optional user info, required host, and optional port
pub struct Authority {
  userinfo : String?
  host : String
  port : Int?
} derive(ToJson)

/// Result type for URI parsing operations
pub suberror UriError {
  InvalidScheme(String)
  InvalidAuthority(String)
  InvalidPath(String)
  InvalidQuery(String)
  InvalidFragment(String)
  InvalidPort(String)
  EmptyUri
} derive(ToJson(style="flat"))

/// Create an empty URI with default values.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.empty()
/// inspect(uri.path(), content="")
/// inspect(uri.scheme(), content="None")
/// ```
///
/// # Returns
///
/// A new `Uri` with all components set to their default values.
pub fn empty() -> Uri {
  {
    scheme: None,
    authority: None,
    path: "",
    query: None,
    fragment: None
  }
}

/// Parse a URI string into a Uri structure according to RFC3986.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://user:pass@example.com:8080/path?query=value#fragment")
/// inspect(uri.scheme(), content="Some(\"https\")")
/// inspect(uri.host(), content="Some(\"example.com\")")
/// inspect(uri.port(), content="Some(8080)")
/// ```
///
/// # Parameters
///
/// - `uri_str`: The URI string to parse
///
/// # Returns
///
/// A parsed `Uri` structure
///
/// # Raises
///
/// - `UriError::EmptyUri` if the input string is empty
/// - `UriError::InvalidScheme` if the scheme is malformed
/// - `UriError::InvalidAuthority` if the authority is malformed
/// - Other `UriError` variants for various parsing failures
pub fn parse(uri_str : String) -> Uri raise UriError {
  if uri_str.length() == 0 {
    raise EmptyUri
  }
  
  // Start with an empty URI and parse components
  let uri = empty()
  let remaining = uri_str
  
  // Simple parsing for now - will enhance later
  // For basic HTTP/HTTPS URIs: scheme://host:port/path?query#fragment
  
  // Check for scheme
  if remaining.contains("://") {
    let parts = remaining.split("://").collect()
    if parts.length() >= 2 {
      let scheme_part = parts[0].to_string()
      if is_valid_scheme(scheme_part) {
        let rest = parts[1].to_string()
        // Parse the rest
        return parse_with_scheme(scheme_part, rest)
      } else {
        raise InvalidScheme(scheme_part)
      }
    }
  }
  
  // No scheme found, treat as path-only URI
  { ..uri, path: remaining }
}

/// Parse URI with known scheme
fn parse_with_scheme(scheme : String, rest : String) -> Uri raise UriError {
  let mut uri = empty()
  uri = { ..uri, scheme: Some(scheme) }
  
  // Split by fragment first
  let parts_fragment = rest.split("#").collect()
  let main_part = parts_fragment[0].to_string()
  let fragment_part = if parts_fragment.length() > 1 { 
    let frag = parts_fragment[1].to_string()
    // Basic fragment validation - no spaces allowed
    if frag.contains(" ") {
      raise InvalidFragment(frag)
    }
    Some(frag)
  } else { None }
  uri = { ..uri, fragment: fragment_part }
  
  // Split by query
  let parts_query = main_part.split("?").collect()
  let path_authority_part = parts_query[0].to_string()
  let query_part = if parts_query.length() > 1 { 
    let q = parts_query[1].to_string()
    // Basic query validation - no unescaped spaces
    if q.contains(" ") {
      raise InvalidQuery(q)
    }
    Some(q)
  } else { None }
  uri = { ..uri, query: query_part }
  
  // Split authority and path
  let parts_path = path_authority_part.split("/").collect()
  if parts_path.length() > 0 {
    let authority_part = parts_path[0].to_string()
    if authority_part.length() > 0 {
      let auth = parse_authority(authority_part)
      uri = { ..uri, authority: Some(auth) }
    }
    
    // Reconstruct path from remaining parts
    if parts_path.length() > 1 {
      let path_parts : Array[String] = []
      for i = 1; i < parts_path.length(); i = i + 1 {
        path_parts.push(parts_path[i].to_string())
      }
      let path = "/" + path_parts.join("/")
      // Basic path validation - no unescaped spaces
      if path.contains(" ") {
        raise InvalidPath(path)
      }
      uri = { ..uri, path }
    } else {
      uri = { ..uri, path: "" }
    }
  } else {
    // No authority, remaining is path
    if path_authority_part.contains(" ") {
      raise InvalidPath(path_authority_part)
    }
    uri = { ..uri, path: path_authority_part }
  }
  
  uri
}

/// Convert a Uri structure back to a string representation
pub fn Uri::to_string(self : Uri) -> String {
  let mut result = ""
  
  // Add scheme
  match self.scheme {
    Some(scheme) => {
      result = result + scheme
      match self.authority {
        Some(_) => result = result + "://"
        None => result = result + ":"
      }
    }
    None => ()
  }
  
  // Add authority
  match self.authority {
    Some(auth) => {
      match auth.userinfo {
        Some(userinfo) => result = result + userinfo + "@"
        None => ()
      }
      result = result + auth.host
      match auth.port {
        Some(port) => result = result + ":" + port.to_string()
        None => ()
      }
    }
    None => ()
  }
  
  // Add path
  result = result + self.path
  
  // Add query
  match self.query {
    Some(query) => result = result + "?" + query
    None => ()
  }
  
  // Add fragment
  match self.fragment {
    Some(fragment) => result = result + "#" + fragment
    None => ()
  }
  
  result
}

/// Implement Show trait for Uri to provide standard string representation
pub impl Show for Uri with output(self, logger) {
  // Use our existing to_string method for the Show implementation
  logger.write_string(self.to_string())
}





/// Get the scheme component of the URI.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://example.com")
/// inspect(uri.scheme(), content="Some(\"https\")")
/// ```
///
/// # Returns
///
/// The scheme as `Some(String)` if present, `None` otherwise.
pub fn Uri::scheme(self : Uri) -> String? {
  self.scheme
}

/// Get the host component of the URI.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://example.com:8080/path")
/// inspect(uri.host(), content="Some(\"example.com\")")
/// ```
///
/// # Returns
///
/// The host as `Some(String)` if present, `None` otherwise.
pub fn Uri::host(self : Uri) -> String? {
  match self.authority {
    Some(auth) => Some(auth.host)
    None => None
  }
}

/// Get the explicit port component of the URI.
///
/// Note: This returns only explicitly specified ports. Use `effective_port()`
/// to get the effective port including defaults.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://example.com:8080/path")
/// inspect(uri.port(), content="Some(8080)")
/// ```
///
/// # Returns
///
/// The port as `Some(Int)` if explicitly specified, `None` otherwise.
pub fn Uri::port(self : Uri) -> Int? {
  match self.authority {
    Some(auth) => auth.port
    None => None
  }
}

/// Get the path component of the URI.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://example.com/path/to/resource")
/// inspect(uri.path(), content="/path/to/resource")
/// ```
///
/// # Returns
///
/// The path as a `String`. Empty string if no path is specified.
pub fn Uri::path(self : Uri) -> String {
  self.path
}

/// Get the query component of the URI.
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://example.com/path?key=value&foo=bar")
/// inspect(uri.query(), content="Some(\"key=value&foo=bar\")")
/// ```
///
/// # Returns
///
/// The query string as `Some(String)` if present, `None` otherwise.
pub fn Uri::query(self : Uri) -> String? {
  self.query
}

/// Get the fragment component of the URI
pub fn Uri::fragment(self : Uri) -> String? {
  self.fragment
}

/// Check if a scheme string is valid according to RFC3986
fn is_valid_scheme(scheme : String) -> Bool {
  if scheme.length() == 0 {
    return false
  }
  
  // First character must be a letter
  match scheme.get(0) {
    Some(first_char_code) => {
      let first_char = first_char_code.unsafe_to_char()
      if not(is_alpha(first_char)) {
        return false
      }
    }
    None => return false
  }
  
  // Remaining characters must be letters, digits, +, -, or .
  for i = 1; i < scheme.length(); i = i + 1 {
    match scheme.get(i) {
      Some(char_code) => {
        let c = char_code.unsafe_to_char()
        if not(is_alpha(c) || is_digit(c) || c == '+' || c == '-' || c == '.') {
          return false
        }
      }
      None => return false
    }
  }
  
  true
}

/// Parse authority component
fn parse_authority(auth_str : String) -> Authority raise UriError {
  let mut userinfo : String? = None
  let mut port : Int? = None
  let mut remaining = auth_str
  
  // Check for userinfo (contains @)
  if remaining.contains("@") {
    let parts = remaining.split("@").collect()
    if parts.length() >= 2 {
      userinfo = Some(parts[0].to_string())
      remaining = parts[1].to_string()
    }
  }
  
  // Now parse host and port from remaining
  let host_part = if remaining.contains(":") && remaining.strip_prefix("[") == None {
    // Regular host with port (not IPv6)
    let parts = remaining.split(":").collect()
    if parts.length() >= 2 {
      let potential_port = parts[parts.length() - 1].to_string() // Take the last part as port
      // Validate port is numeric
      if potential_port.length() > 0 {
        let mut is_numeric = true
        for i = 0; i < potential_port.length(); i = i + 1 {
          match potential_port.get(i) {
            Some(char_code) => {
              let c = char_code.unsafe_to_char()
              if not(is_digit(c)) {
                is_numeric = false
                break
              }
            }
            None => {
              is_numeric = false
              break
            }
          }
        }
        if is_numeric {
          // Convert to int
          let mut port_value = 0
          for i = 0; i < potential_port.length(); i = i + 1 {
            match potential_port.get(i) {
              Some(char_code) => {
                let digit = char_code - 48 // '0' = 48
                port_value = port_value * 10 + digit
              }
              None => break
            }
          }
          if port_value < 0 || port_value > 65535 {
            raise InvalidPort(potential_port)
          }
          port = Some(port_value)
          
          // Reconstruct host without the port
          let host_parts : Array[String] = []
          for i = 0; i < parts.length() - 1; i = i + 1 {
            host_parts.push(parts[i].to_string())
          }
          host_parts.join(":")
        } else {
          // Invalid port format - should be an error
          raise InvalidPort(potential_port)
        }
      } else {
        remaining
      }
    } else {
      remaining
    }
  } else if remaining.strip_prefix("[") != None {
    // IPv6 literal - handle specially
    if remaining.contains("]:") {
      let bracket_parts = remaining.split("]:").collect()
      if bracket_parts.length() >= 2 {
        let ipv6_part = bracket_parts[0].to_string() + "]"
        let port_part = bracket_parts[1].to_string()
        // Validate and parse port
        let mut is_numeric = true
        for i = 0; i < port_part.length(); i = i + 1 {
          match port_part.get(i) {
            Some(char_code) => {
              let c = char_code.unsafe_to_char()
              if not(is_digit(c)) {
                is_numeric = false
                break
              }
            }
            None => {
              is_numeric = false
              break
            }
          }
        }
        if is_numeric && port_part.length() > 0 {
          let mut port_value = 0
          for i = 0; i < port_part.length(); i = i + 1 {
            match port_part.get(i) {
              Some(char_code) => {
                let digit = char_code - 48
                port_value = port_value * 10 + digit
              }
              None => break
            }
          }
          if port_value < 0 || port_value > 65535 {
            raise InvalidPort(port_part)
          }
          port = Some(port_value)
        }
        ipv6_part
      } else {
        remaining
      }
    } else {
      remaining
    }
  } else {
    remaining
  }
  
  if host_part.length() == 0 {
    raise InvalidAuthority(auth_str)
  }
  
  { userinfo, host: host_part, port }
}

/// Helper function to check if character is alphabetic
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

/// Helper function to check if character is numeric
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

/// Create a new URI with the specified scheme
pub fn Uri::with_scheme(self : Uri, new_scheme : String?) -> Uri {
  { ..self, scheme: new_scheme }
}

/// Create a new URI with the specified host
pub fn Uri::with_host(self : Uri, new_host : String?) -> Uri {
  match new_host {
    Some(host) => {
      let new_authority = match self.authority {
        Some(auth) => Some({ ..auth, host })
        None => Some({ userinfo: None, host, port: None })
      }
      { ..self, authority: new_authority }
    }
    None => { ..self, authority: None }
  }
}

/// Create a new URI with the specified port
pub fn Uri::with_port(self : Uri, new_port : Int?) -> Uri {
  match self.authority {
    Some(auth) => {
      let new_authority = Some({ ..auth, port: new_port })
      { ..self, authority: new_authority }
    }
    None => {
      match new_port {
        Some(port) => {
          let new_authority = Some({ userinfo: None, host: "", port: Some(port) })
          { ..self, authority: new_authority }
        }
        None => self
      }
    }
  }
}

/// Create a new URI with the specified path
pub fn Uri::with_path(self : Uri, new_path : String) -> Uri {
  { ..self, path: new_path }
}

/// Create a new URI with the specified query
pub fn Uri::with_query(self : Uri, new_query : String?) -> Uri {
  { ..self, query: new_query }
}

/// Create a new URI with the specified fragment
pub fn Uri::with_fragment(self : Uri, new_fragment : String?) -> Uri {
  { ..self, fragment: new_fragment }
}

/// Check if the URI is absolute (has a scheme)
pub fn Uri::is_absolute(self : Uri) -> Bool {
  match self.scheme {
    Some(_) => true
    None => false
  }
}

/// Check if the URI is relative (no scheme)
pub fn Uri::is_relative(self : Uri) -> Bool {
  !(self.is_absolute())
}

/// Get the default port for a given scheme
fn default_port(scheme : String) -> Int? {
  match scheme {
    "http" => Some(80)
    "https" => Some(443)
    "ftp" => Some(21)
    "ssh" => Some(22)
    "telnet" => Some(23)
    "smtp" => Some(25)
    "dns" => Some(53)
    "pop3" => Some(110)
    "imap" => Some(143)
    "ldap" => Some(389)
    "imaps" => Some(993)
    "pop3s" => Some(995)
    _ => None
  }
}

/// Get the effective port (explicit port or default port for scheme)
pub fn Uri::effective_port(self : Uri) -> Int? {
  match self.authority {
    Some(auth) => {
      match auth.port {
        Some(port) => Some(port)
        None => {
          match self.scheme {
            Some(scheme) => default_port(scheme)
            None => None
          }
        }
      }
    }
    None => None
  }
}

/// Normalize a URI (remove default ports, normalize path, etc.)
pub fn Uri::normalize(self : Uri) -> Uri {
  let mut normalized = self
  
  // Remove default port if present
  match self.authority {
    Some(auth) => {
      match (self.scheme, auth.port) {
        (Some(scheme), Some(port)) => {
          match default_port(scheme) {
            Some(default) => {
              if port == default {
                let new_auth = { ..auth, port: None }
                normalized = { ..normalized, authority: Some(new_auth) }
              }
            }
            None => ()
          }
        }
        _ => ()
      }
    }
    None => ()
  }
  
  // Normalize path (remove redundant slashes, resolve . and ..)
  normalized = { ..normalized, path: normalize_path(normalized.path) }
  
  normalized
}

/// Normalize a path by removing redundant elements
fn normalize_path(path : String) -> String {
  if path.length() == 0 {
    return path
  }
  
  // Split path into segments
  let segments = path.split("/").collect()
  let normalized_segments : Array[String] = []
  
  for segment in segments {
    let seg_str = segment.to_string()
    match seg_str {
      "." => () // Skip current directory references
      ".." => {
        // Remove last segment if possible (go up one directory)
        if normalized_segments.length() > 0 && normalized_segments[normalized_segments.length() - 1] != ".." {
          let _ = normalized_segments.pop()
        } else if path.strip_prefix("/") == None {
          // Only add .. for relative paths
          normalized_segments.push("..")
        }
      }
      _ => normalized_segments.push(seg_str)
    }
  }
  
  // Reconstruct path
  let result = normalized_segments.join("/")
  
  // Preserve leading slash for absolute paths
  if path.strip_prefix("/") != None && result.strip_prefix("/") == None {
    "/" + result
  } else {
    result
  }
}

/// Resolve a relative URI against a base URI
pub fn resolve(base : Uri, relative : Uri) -> Uri raise UriError {
  // If relative URI is absolute, return it as-is
  if relative.is_absolute() {
    return relative
  }
  
  // Base URI must be absolute
  if base.is_relative() {
    raise InvalidPath("Base URI must be absolute")
  }
  
  let mut resolved = base
  
  // If relative has authority, use it and its path/query/fragment
  match relative.authority {
    Some(_) => {
      resolved = {
        scheme: base.scheme,
        authority: relative.authority,
        path: relative.path,
        query: relative.query,
        fragment: relative.fragment
      }
    }
    None => {
      // No authority in relative, use base authority
      if relative.path == "" {
        // Empty path, use base path
        resolved = {
          scheme: base.scheme,
          authority: base.authority,
          path: base.path,
          query: match relative.query {
            Some(_) => relative.query
            None => base.query
          },
          fragment: relative.fragment
        }
      } else {
        // Non-empty path
        let resolved_path = if relative.path.strip_prefix("/") != None {
          // Absolute path, use as-is
          relative.path
        } else {
          // Relative path, resolve against base
          resolve_relative_path(base.path, relative.path)
        }
        
        resolved = {
          scheme: base.scheme,
          authority: base.authority,
          path: resolved_path,
          query: relative.query,
          fragment: relative.fragment
        }
      }
    }
  }
  
  resolved.normalize()
}

/// Resolve a relative path against a base path
fn resolve_relative_path(base_path : String, relative_path : String) -> String {
  // Remove filename from base path (keep directory part)
  let base_dir = if base_path.contains("/") {
    let parts = base_path.split("/").collect()
    if parts.length() > 1 {
      let dir_parts : Array[String] = []
      for i = 0; i < parts.length() - 1; i = i + 1 {
        dir_parts.push(parts[i].to_string())
      }
      dir_parts.join("/") + "/"
    } else {
      ""
    }
  } else {
    ""
  }
  
  normalize_path(base_dir + relative_path)
}

/// Parse query string into key-value pairs
fn parse_query(query_string : String) -> Array[(String, String)] {
  if query_string.length() == 0 {
    return []
  }
  
  let pairs = query_string.split("&").collect()
  let result : Array[(String, String)] = []
  
  for pair in pairs {
    let pair_str = pair.to_string()
    if pair_str.contains("=") {
      let parts = pair_str.split("=").collect()
      if parts.length() >= 2 {
        let key = parts[0].to_string()
        let value = parts[1].to_string()
        result.push((key, value))
      } else {
        // No equals sign, treat as key with empty value
        result.push((pair_str, ""))
      }
    } else {
      // No equals sign, treat as key with empty value
      result.push((pair_str, ""))
    }
  }
  
  result
}

/// Build query string from key-value pairs
fn build_query(pairs : Array[(String, String)]) -> String {
  let parts : Array[String] = []
  
  for i = 0; i < pairs.length(); i = i + 1 {
    let (key, value) = pairs[i]
    if value.length() == 0 {
      parts.push(key)
    } else {
      parts.push(key + "=" + value)
    }
  }
  
  parts.join("&")
}

/// Get a specific query parameter value
pub fn Uri::get_query_param(self : Uri, param_name : String) -> String? {
  match self.query {
    Some(query_str) => {
      let params = parse_query(query_str)
      for i = 0; i < params.length(); i = i + 1 {
        let (key, value) = params[i]
        if key == param_name {
          return Some(value)
        }
      }
      None
    }
    None => None
  }
}

/// Add or update a query parameter
pub fn Uri::with_query_param(self : Uri, param_name : String, param_value : String) -> Uri {
  let current_params = match self.query {
    Some(query_str) => parse_query(query_str)
    None => []
  }
  
  let new_params : Array[(String, String)] = []
  let mut found = false
  
  // Update existing parameter or collect others
  for i = 0; i < current_params.length(); i = i + 1 {
    let (key, value) = current_params[i]
    if key == param_name {
      new_params.push((param_name, param_value))
      found = true
    } else {
      new_params.push((key, value))
    }
  }
  
  // Add new parameter if not found
  if not(found) {
    new_params.push((param_name, param_value))
  }
  
  let new_query = if new_params.length() > 0 {
    Some(build_query(new_params))
  } else {
    None
  }
  
  { ..self, query: new_query }
}

/// Remove a query parameter
pub fn Uri::remove_query_param(self : Uri, param_name : String) -> Uri {
  match self.query {
    Some(query_str) => {
      let current_params = parse_query(query_str)
      let new_params : Array[(String, String)] = []
      
      // Keep all parameters except the one to remove
      for i = 0; i < current_params.length(); i = i + 1 {
        let (key, value) = current_params[i]
        if key != param_name {
          new_params.push((key, value))
        }
      }
      
      let new_query = if new_params.length() > 0 {
        Some(build_query(new_params))
      } else {
        None
      }
      
      { ..self, query: new_query }
    }
    None => self // No query to modify
  }
}

/// URL encode a string using percent encoding according to RFC3986.
///
/// Encodes unsafe characters as %XX where XX is the hexadecimal representation.
/// This is essential for proper URI component handling.
///
/// # Example
///
/// ```moonbit
/// let encoded = @uri.Uri::encode("hello world!")
/// inspect(encoded, content="hello%20world%21")
/// ```
///
/// # Parameters
///
/// - `input`: The string to encode
///
/// # Returns
///
/// The percent-encoded string
pub fn Uri::encode(input : String) -> String {
  let mut result = ""
  
  for i = 0; i < input.length(); i = i + 1 {
    match input.get(i) {
      Some(char_code) => {
        let c = char_code.unsafe_to_char()
        if is_unreserved(c) {
          result = result + c.to_string()
        } else {
          // Percent encode the character
          let hex = int_to_hex(char_code)
          result = result + "%" + (if hex.length() == 1 { "0" + hex } else { hex })
        }
      }
      None => ()
    }
  }
  
  result
}

/// URL decode a percent-encoded string according to RFC3986.
///
/// Decodes %XX sequences back to their original characters.
///
/// # Example
///
/// ```moonbit
/// let decoded = @uri.Uri::decode("hello%20world%21")
/// inspect(decoded, content="hello world!")
/// ```
///
/// # Parameters
///
/// - `input`: The percent-encoded string to decode
///
/// # Returns
///
/// The decoded string
pub fn Uri::decode(input : String) -> String {
  let mut result = ""
  let mut i = 0
  
  while i < input.length() {
    match input.get(i) {
      Some(char_code) => {
        let c = char_code.unsafe_to_char()
        if c == '%' {
          // Check if we have at least 2 more characters
          if i + 2 < input.length() {
            // Get the next two characters for hex decoding
            let hex_str = input.substring(start=i + 1, end=i + 3)
            match hex_to_int(hex_str) {
              Some(decoded_value) => {
                result = result + decoded_value.unsafe_to_char().to_string()
                i = i + 3
              }
              None => {
                // Invalid hex sequence, treat % as literal
                result = result + "%"
                i = i + 1
              }
            }
          } else {
            // Not enough characters for percent encoding
            result = result + "%"
            i = i + 1
          }
        } else {
          result = result + c.to_string()
          i = i + 1
        }
      }
      None => {
        i = i + 1
      }
    }
  }
  
  result
}

/// Parse query string into key-value pairs
///
/// # Example
///
/// ```moonbit
/// let params = @uri.Uri::parse_query("name=John&age=30&city=New%20York")
/// inspect(params.length(), content="3")
/// ```
///
/// # Parameters
///
/// - `query_string`: The query string to parse
///
/// # Returns
///
/// Array of key-value pairs
pub fn Uri::parse_query(query_string : String) -> Array[(String, String)] {
  if query_string.length() == 0 {
    return []
  }
  
  let pairs = query_string.split("&").collect()
  let result : Array[(String, String)] = []
  
  for pair in pairs {
    let pair_str = pair.to_string()
    if pair_str.contains("=") {
      let parts = pair_str.split("=").collect()
      if parts.length() >= 2 {
        let key = Uri::decode(parts[0].to_string())
        let value = Uri::decode(parts[1].to_string())
        result.push((key, value))
      } else {
        // No equals sign, treat as key with empty value
        result.push((Uri::decode(pair_str), ""))
      }
    } else {
      // No equals sign, treat as key with empty value
      result.push((Uri::decode(pair_str), ""))
    }
  }
  
  result
}

/// Build query string from key-value pairs
///
/// # Example
///
/// ```moonbit
/// let query = @uri.Uri::build_query([("name", "John Doe"), ("age", "30")])
/// inspect(query, content="name=John%20Doe&age=30")
/// ```
///
/// # Parameters
///
/// - `pairs`: Array of key-value pairs
///
/// # Returns
///
/// Encoded query string
pub fn Uri::build_query(pairs : Array[(String, String)]) -> String {
  let parts : Array[String] = []
  
  for i = 0; i < pairs.length(); i = i + 1 {
    let (key, value) = pairs[i]
    let encoded_key = Uri::encode(key)
    if value.length() == 0 {
      parts.push(encoded_key)
    } else {
      let encoded_value = Uri::encode(value)
      parts.push(encoded_key + "=" + encoded_value)
    }
  }
  
  parts.join("&")
}

/// Get path segments as an array
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("/path/to/resource")
/// let _segments = uri.path_segments()
/// // _segments will contain ["path", "to", "resource"]
/// ```
///
/// # Returns
///
/// Array of path segments (excluding empty segments from leading/trailing slashes)
pub fn Uri::path_segments(self : Uri) -> Array[String] {
  if self.path.length() == 0 {
    return []
  }
  
  let segments = self.path.split("/").collect()
  let result : Array[String] = []
  
  for segment in segments {
    let seg_str = segment.to_string()
    if seg_str.length() > 0 {
      result.push(Uri::decode(seg_str))
    }
  }
  
  result
}

/// Create a new URI with the specified path segments
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.empty().with_path_segments(["api", "v1", "users"])
/// inspect(uri.path(), content="/api/v1/users")
/// ```
///
/// # Parameters
///
/// - `segments`: Array of path segments
///
/// # Returns
///
/// New URI with the specified path segments
pub fn Uri::with_path_segments(self : Uri, segments : Array[String]) -> Uri {
  if segments.length() == 0 {
    return { ..self, path: "" }
  }
  
  let encoded_segments : Array[String] = []
  for segment in segments {
    encoded_segments.push(Uri::encode(segment.to_string()))
  }
  
  let path = "/" + encoded_segments.join("/")
  { ..self, path }
}

/// Parse userinfo into username and password components
///
/// # Example
///
/// ```moonbit
/// let uri = @uri.parse("https://user:pass@example.com")
/// match uri.userinfo_components() {
///   Some((user, Some(pass))) => {
///     inspect(user, content="user")
///     inspect(pass, content="pass")
///   }
///   _ => ()
/// }
/// ```
///
/// # Returns
///
/// Optional tuple of (username, optional password)
pub fn Uri::userinfo_components(self : Uri) -> (String, String?)? {
  match self.authority {
    Some(auth) => {
      match auth.userinfo {
        Some(userinfo) => {
          if userinfo.contains(":") {
            let parts = userinfo.split(":").collect()
            if parts.length() >= 2 {
              let username = Uri::decode(parts[0].to_string())
              let password = Uri::decode(parts[1].to_string())
              Some((username, Some(password)))
            } else {
              let username = Uri::decode(userinfo)
              Some((username, None))
            }
          } else {
            let username = Uri::decode(userinfo)
            Some((username, None))
          }
        }
        None => None
      }
    }
    None => None
  }
}

/// Create a new URI with the specified username and password
///
/// # Example
///
/// ```moonbit
/// let _uri = @uri.empty()
///   .with_host(Some("example.com"))
///   .with_userinfo(Some("user"), Some("pass"))
/// // Creates URI with encoded userinfo
/// ```
///
/// # Parameters
///
/// - `username`: Optional username
/// - `password`: Optional password
///
/// # Returns
///
/// New URI with the specified userinfo
pub fn Uri::with_userinfo(self : Uri, username : String?, password : String?) -> Uri {
  match username {
    Some(user) => {
      let userinfo = match password {
        Some(pass) => Uri::encode(user) + ":" + Uri::encode(pass)
        None => Uri::encode(user)
      }
      
      let new_authority = match self.authority {
        Some(auth) => Some({ ..auth, userinfo: Some(userinfo) })
        None => Some({ userinfo: Some(userinfo), host: "", port: None })
      }
      
      { ..self, authority: new_authority }
    }
    None => {
      match self.authority {
        Some(auth) => {
          let new_authority = Some({ ..auth, userinfo: None })
          { ..self, authority: new_authority }
        }
        None => self
      }
    }
  }
}

/// Check if character is unreserved (doesn't need encoding)
fn is_unreserved(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '-' || c == '.' || c == '_' || c == '~'
}

/// Convert hex string to integer
fn hex_to_int(hex_str : String) -> Int? {
  if hex_str.length() != 2 {
    return None
  }
  
  let mut result = 0
  for i = 0; i < 2; i = i + 1 {
    match hex_str.get(i) {
      Some(char_code) => {
        let c = char_code.unsafe_to_char()
        let digit_value = if c >= '0' && c <= '9' {
          char_code - 48 // '0' = 48
        } else if c >= 'A' && c <= 'F' {
          char_code - 55 // 'A' = 65, so 'A' - 55 = 10
        } else if c >= 'a' && c <= 'f' {
          char_code - 87 // 'a' = 97, so 'a' - 87 = 10
        } else {
          return None // Invalid hex character
        }
        result = result * 16 + digit_value
      }
      None => return None
    }
  }
  
  Some(result)
}

/// Convert integer to hex string
fn int_to_hex(value : Int) -> String {
  if value == 0 {
    return "0"
  }
  
  let mut result = ""
  let mut n = value
  let hex_chars = "0123456789ABCDEF"
  
  while n > 0 {
    let digit = n % 16
    match hex_chars.get(digit) {
      Some(char_code) => {
        result = char_code.unsafe_to_char().to_string() + result
      }
      None => break
    }
    n = n / 16
  }
  
  result
}

