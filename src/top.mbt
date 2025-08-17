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
    println("- Scheme: " + uri.scheme().to_string())
    println("- Host: " + uri.host().to_string())
    println("- Port: " + uri.port().to_string())
    println("- Effective Port: " + uri.effective_port().to_string())
    println("- Path: " + uri.path())
    println("- Query: " + uri.query().to_string())
    println("- Fragment: " + uri.fragment().to_string())
    println("")
    
    // Query parameter manipulation
    println("Query parameter example:")
    let updated_uri = uri.with_query_param("page", "2")
    println("After adding page=2: " + to_string(updated_uri))
    
    match updated_uri.get_query_param("limit") {
      Some(limit) => println("Limit parameter: " + limit)
      None => ()
    }
  } catch {
    _ => println("Failed to parse URI")
  }
}
