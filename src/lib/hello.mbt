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
}

/// Authority component of a URI
/// Contains optional user info, required host, and optional port
pub struct Authority {
  userinfo : String?
  host : String
  port : Int?
}

/// Result type for URI parsing operations
pub enum UriError {
  InvalidScheme(String)
  InvalidAuthority(String)
  InvalidPath(String)
  InvalidQuery(String)
  InvalidFragment(String)
  InvalidPort(String)
  EmptyUri
}

/// Create an empty URI with default values
pub fn empty() -> Uri {
  {
    scheme: None,
    authority: None,
    path: "",
    query: None,
    fragment: None
  }
}

/// Parse a URI string into a Uri structure
/// Returns Result<Uri, UriError> for error handling
pub fn of_string(uri_str : String) -> Result[Uri, UriError] {
  if uri_str.length() == 0 {
    return Err(EmptyUri)
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
        return Err(InvalidScheme(scheme_part))
      }
    }
  }
  
  // No scheme found, treat as path-only URI
  Ok({ ..uri, path: remaining })
}

/// Parse URI with known scheme
fn parse_with_scheme(scheme : String, rest : String) -> Result[Uri, UriError] {
  let mut uri = empty()
  uri = { ..uri, scheme: Some(scheme) }
  
  // Split by fragment first
  let parts_fragment = rest.split("#").collect()
  let main_part = parts_fragment[0].to_string()
  let fragment_part = if parts_fragment.length() > 1 { Some(parts_fragment[1].to_string()) } else { None }
  uri = { ..uri, fragment: fragment_part }
  
  // Split by query
  let parts_query = main_part.split("?").collect()
  let path_authority_part = parts_query[0].to_string()
  let query_part = if parts_query.length() > 1 { Some(parts_query[1].to_string()) } else { None }
  uri = { ..uri, query: query_part }
  
  // Split authority and path
  let parts_path = path_authority_part.split("/").collect()
  if parts_path.length() > 0 {
    let authority_part = parts_path[0].to_string()
    if authority_part.length() > 0 {
      match parse_authority(authority_part) {
        Ok(auth) => uri = { ..uri, authority: Some(auth) }
        Err(e) => return Err(e)
      }
    }
    
    // Reconstruct path from remaining parts
    if parts_path.length() > 1 {
      let path_parts : Array[String] = []
      for i = 1; i < parts_path.length(); i = i + 1 {
        path_parts.push(parts_path[i].to_string())
      }
      uri = { ..uri, path: "/" + path_parts.join("/") }
    } else {
      uri = { ..uri, path: "" }
    }
  }
  
  Ok(uri)
}

/// Convert a Uri structure back to a string representation
pub fn to_string(uri : Uri) -> String {
  let mut result = ""
  
  // Add scheme
  match uri.scheme {
    Some(scheme) => {
      result = result + scheme
      match uri.authority {
        Some(_) => result = result + "://"
        None => result = result + ":"
      }
    }
    None => ()
  }
  
  // Add authority
  match uri.authority {
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
  result = result + uri.path
  
  // Add query
  match uri.query {
    Some(query) => result = result + "?" + query
    None => ()
  }
  
  // Add fragment
  match uri.fragment {
    Some(fragment) => result = result + "#" + fragment
    None => ()
  }
  
  result
}

/// Get the scheme component of the URI
pub fn scheme(uri : Uri) -> String? {
  uri.scheme
}

/// Get the host component of the URI
pub fn host(uri : Uri) -> String? {
  match uri.authority {
    Some(auth) => Some(auth.host)
    None => None
  }
}

/// Get the port component of the URI
pub fn port(uri : Uri) -> Int? {
  match uri.authority {
    Some(auth) => auth.port
    None => None
  }
}

/// Get the path component of the URI
pub fn path(uri : Uri) -> String {
  uri.path
}

/// Get the query component of the URI
pub fn query(uri : Uri) -> String? {
  uri.query
}

/// Get the fragment component of the URI
pub fn fragment(uri : Uri) -> String? {
  uri.fragment
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
fn parse_authority(auth_str : String) -> Result[Authority, UriError] {
  let userinfo : String? = None
  let port : Int? = None
  
  // Simple parsing - just extract host for now
  // TODO: Add proper userinfo and port parsing
  let host_part = auth_str
  
  if host_part.length() == 0 {
    return Err(InvalidAuthority(auth_str))
  }
  
  Ok({ userinfo, host: host_part, port })
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
pub fn with_scheme(uri : Uri, new_scheme : String?) -> Uri {
  { ..uri, scheme: new_scheme }
}

/// Create a new URI with the specified host
pub fn with_host(uri : Uri, new_host : String?) -> Uri {
  match new_host {
    Some(host) => {
      let new_authority = match uri.authority {
        Some(auth) => Some({ ..auth, host })
        None => Some({ userinfo: None, host, port: None })
      }
      { ..uri, authority: new_authority }
    }
    None => { ..uri, authority: None }
  }
}

/// Create a new URI with the specified port
pub fn with_port(uri : Uri, new_port : Int?) -> Uri {
  match uri.authority {
    Some(auth) => {
      let new_authority = Some({ ..auth, port: new_port })
      { ..uri, authority: new_authority }
    }
    None => {
      match new_port {
        Some(port) => {
          let new_authority = Some({ userinfo: None, host: "", port: Some(port) })
          { ..uri, authority: new_authority }
        }
        None => uri
      }
    }
  }
}

/// Create a new URI with the specified path
pub fn with_path(uri : Uri, new_path : String) -> Uri {
  { ..uri, path: new_path }
}

/// Create a new URI with the specified query
pub fn with_query(uri : Uri, new_query : String?) -> Uri {
  { ..uri, query: new_query }
}

/// Create a new URI with the specified fragment
pub fn with_fragment(uri : Uri, new_fragment : String?) -> Uri {
  { ..uri, fragment: new_fragment }
}

/// Check if the URI is absolute (has a scheme)
pub fn is_absolute(uri : Uri) -> Bool {
  match uri.scheme {
    Some(_) => true
    None => false
  }
}

/// Check if the URI is relative (no scheme)
pub fn is_relative(uri : Uri) -> Bool {
  not(is_absolute(uri))
}