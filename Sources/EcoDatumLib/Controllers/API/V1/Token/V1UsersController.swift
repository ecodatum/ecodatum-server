import HTTP
import Vapor

final class V1UsersController: ResourceRepresentable {
  
  let drop: Droplet
  
  init(_ drop: Droplet) {
    self.drop = drop
  }
  
  // GET /users
  func index(_ request: Request) throws -> ResponseRepresentable {
    
    try request.assertUserIsAdmin()
    return try User.all().makeJSON()
  
  }
  
  // GET /users/:id
  func show(_ request: Request,
            _ user: User) throws -> ResponseRepresentable {
    
    try assertRequestUserIsUserOrIsAdmin(request, user)
    return user
    
  }

  // POST /users
  func store(_ request: Request) throws -> ResponseRepresentable {
    
    try request.assertUserIsAdmin()
    
    let user = try User(json: try request.assertJson())
    user.password = try drop.hash.make(user.password.makeBytes()).makeString()
    try user.save()
    
    return user
    
  }
  
  func makeResource() -> Resource<User> {
    return Resource(index: index,
                    store: store,
                    show: show)
  }
  
  private func assertRequestUserIsUserOrIsAdmin(_ request: Request, _ user: User) throws {
    
    let requestUserIsUser = try request.checktRequestUserIsUser(user)
    let userIsAdmin = try request.checkUserIsAdmin()
    if requestUserIsUser || userIsAdmin {
      // Do nothing
    } else {
      throw Abort(.unauthorized)
    }
    
  }
  
}


