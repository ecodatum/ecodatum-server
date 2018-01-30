import Crypto
import Vapor

final class APIV1PublicOrganizationsRoutes {
  
  let drop: Droplet
  
  let modelManager: ModelManager
  
  init(drop: Droplet,
       modelManager: ModelManager) {
    self.drop = drop
    self.modelManager = modelManager
  }
  
  func build(_ routeBuilder: RouteBuilder) {
    
    routeBuilder.get(
      ":code",
      handler: getOrganizationByCodeRouteHandler)
    
  }
  
  // GET /public/organizations/:code
  private func getOrganizationByCodeRouteHandler(
    _ request: Request)
    throws -> ResponseRepresentable {
      
      guard let code = try? request.parameters.next(String.self),
        let organization = try modelManager.findOrganization(byCode: code) else {
          throw Abort(.notFound)
      }
      
      return organization
      
  }
  
}



