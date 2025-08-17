// Example usage of the URI library
// This file demonstrates how to use the URI library

/// Example function showing basic URI parsing
pub fn example_parse() -> Unit {
  match of_string("https://example.com:8080/path?query=value#fragment") {
    Ok(uri) => {
      println("Parsed URI successfully:")
      println("Scheme: " + scheme(uri).to_string())
      println("Host: " + host(uri).to_string())
      println("Port: " + port(uri).to_string())
      println("Path: " + path(uri))
      println("Query: " + query(uri).to_string())
      println("Fragment: " + fragment(uri).to_string())
    }
    Err(_) => println("Failed to parse URI")
  }
}
