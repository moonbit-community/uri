// Example usage of the URI library
// This file demonstrates how to use the URI library

/// Example function showing basic URI parsing
pub fn example_parse() -> Unit {
  match @lib.of_string("https://example.com:8080/path?query=value#fragment") {
    Ok(uri) => {
      println("Parsed URI successfully:")
      println("Scheme: " + @lib.scheme(uri).to_string())
      println("Host: " + @lib.host(uri).to_string())
      println("Port: " + @lib.port(uri).to_string())
      println("Path: " + @lib.path(uri))
      println("Query: " + @lib.query(uri).to_string())
      println("Fragment: " + @lib.fragment(uri).to_string())
    }
    Err(_) => println("Failed to parse URI")
  }
}
