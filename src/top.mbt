// Example usage of the URI library
// This file demonstrates how to use the URI library

/// Example function showing basic URI parsing
pub fn example_parse() -> Unit {
  try {
    let uri = of_string("https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results")
    println("=== URI Parsing Example ===")
    println("Original: https://user:pass@api.example.com:8080/v1/users?limit=10&offset=0#results")
    println("")
    
    // Standard string representation (Show trait)
    println("Standard representation:")
    println(to_string(uri))
    println("")
    
    // Debug representation
    println("Debug representation:")
    println(debug_string(uri))
    println("")
    
    // Pretty representation
    println("Pretty representation:")
    println(pretty_string(uri))
    println("")
    
    // Individual component access
    println("Component access:")
    println("- Scheme: " + scheme(uri).to_string())
    println("- Host: " + host(uri).to_string())
    println("- Port: " + port(uri).to_string())
    println("- Effective Port: " + effective_port(uri).to_string())
    println("- Path: " + path(uri))
    println("- Query: " + query(uri).to_string())
    println("- Fragment: " + fragment(uri).to_string())
    println("")
    
    // Query parameter manipulation
    println("Query parameter example:")
    let updated_uri = with_query_param(uri, "page", "2")
    println("After adding page=2: " + to_string(updated_uri))
    
    match get_query_param(updated_uri, "limit") {
      Some(limit) => println("Limit parameter: " + limit)
      None => ()
    }
  } catch {
    _ => println("Failed to parse URI")
  }
}
