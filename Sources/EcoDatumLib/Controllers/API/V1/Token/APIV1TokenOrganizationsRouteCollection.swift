import Crypto
import Vapor

final class APIV1TokenOrganizationsRouteCollection: RouteCollection {

  let drop: Droplet

  let modelManager: ModelManager

  init(drop: Droplet,
       modelManager: ModelManager) {
    self.drop = drop
    self.modelManager = modelManager
  }

  func build(_ routeBuilder: RouteBuilder) {

    // GET /organizations
    routeBuilder.get(
      handler: getOrganizationsByUser)

    // GET /organizations/:id
    routeBuilder.get(
      Organization.parameter,
      handler: getOrganizationById)

    // GET /organizations/:id/members
    routeBuilder.get(
      Organization.parameter,
      "members",
      handler: getOrganizationMembers)

    // GET /organizations/:id/sites
    routeBuilder.get(
      Organization.parameter,
      "sites",
      handler: getSitesByOrganization)

    // POST /organizations
    routeBuilder.post(
      handler: createNewOrganization)

    // DELETE /organizations
    routeBuilder.delete(
      handler: deleteAllOrganizations)

    // DELETE /organizations/:id
    routeBuilder.delete(
      Organization.parameter,
      handler: deleteOrganizationById)

  }

  private func getOrganizationsByUser(_ request: Request)
  throws -> ResponseRepresentable {

    if try modelManager.isRootUser(request.user()) {

      return try modelManager.getAllOrganizations()
        .makeJSON()

    } else {

      return try modelManager.findOrganizations(
          byUser: request.user())
        .makeJSON()

    }

  }
  
  private func getOrganizationById(_ request: Request)
    throws -> ResponseRepresentable {
      
      let (organization, isRootUser, doesUserBelongToOrganization) =
        try isRootOrOrganizationUser(request)
      
      if isRootUser || doesUserBelongToOrganization {
        
        return organization
        
      } else {
        
        throw Abort(.notFound)
        
      }
      
  }

  private func getOrganizationMembers(_ request: Request)
  throws -> ResponseRepresentable {

    let (organization, isRootUser, doesUserBelongToOrganization) =
      try isRootOrOrganizationUser(request)

    if isRootUser || doesUserBelongToOrganization {
      
      let usersAndRoles: [UserAndRole] = try organization.userOrganizationRoles
        .all()
        .map {
        
        guard let user = try $0.user.get(), let role = try $0.role.get() else {
          throw Abort(.internalServerError)
        }
        
        return try UserAndRole(user: user, role: role)
      
      }
      
      return try JSON(node: usersAndRoles)

    } else {

      throw Abort(.notFound)

    }

  }

  private func getSitesByOrganization(_ request: Request)
  throws -> ResponseRepresentable {

    let (organization, isRootUser, doesUserBelongToOrganization) =
      try isRootOrOrganizationUser(request)

    if isRootUser || doesUserBelongToOrganization {

      return try organization.sites.all().makeJSON()

    } else {

      throw Abort(.notFound)

    }

  }

  private func createNewOrganization(_ request: Request)
  throws -> ResponseRepresentable {

    let json = try request.assertJson()

    guard let name: String = try json.get(Organization.Keys.name) else {
      throw Abort(.badRequest, reason: "Organization must have a name.")
    }

    var description: String? = nil
    if let _description: String = try json.get(Organization.Keys.description),
       !_description.isEmpty {
      description = _description
    }

    return try modelManager.createOrganization(
      user: try request.user(),
      name: name,
      description: description)

  }

  private func deleteOrganizationById(_ request: Request)
  throws -> ResponseRepresentable {

    let organization = try request.parameters.next(Organization.self)

    if try modelManager.isRootUser(request.user()) {

      try modelManager.deleteOrganization(organization: organization)
      return Response(status: .ok)

    } else if try modelManager.doesUserBelongToOrganization(
      user: request.user(),
      organization: organization) {

      try modelManager.deleteOrganization(organization: organization)
      return Response(status: .ok)

    } else {

      throw Abort(.notFound)

    }

  }

  private func deleteAllOrganizations(_ request: Request)
  throws -> ResponseRepresentable {

    try modelManager.assertRootUser(request.user())
    try modelManager.deleteAllOrganizations()

    return Response(status: .ok)

  }

  private func isRootOrOrganizationUser(_ request: Request) throws -> (Organization, Bool, Bool) {

    let organization = try request.parameters.next(Organization.self)
    let user = try request.user()
    let isRootUser = try modelManager.isRootUser(user)
    let doesUserBelongToOrganization = try modelManager.doesUserBelongToOrganization(
      user: user,
      organization: organization)

    return (organization, isRootUser, doesUserBelongToOrganization)

  }

}


