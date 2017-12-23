import HTTP

struct Constants {
  
  static let ROOT_USER_ID = 1
  
  static let AUTHORIZATION_HEADER_KEY: HeaderKey = HeaderKey("Authorization")
  static let CONTENT_TYPE_HEADER_KEY: HeaderKey = HeaderKey("Content-Type")
  
  static let BASIC_AUTHORIZATION_PREFIX = "Basic"
  static let BEARER_AUTHORIZATION_PREFIX = "Bearer"
  
  static let JSON_CONTENT_TYPE = "application/json"
   
}
