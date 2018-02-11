import HTTP
import Vapor

final class APIV1TokenMeasurementsRouteCollection: RouteCollection {
  
  let drop: Droplet
  
  let modelManager: ModelManager
  
  init(drop: Droplet,
       modelManager: ModelManager) {
    self.drop = drop
    self.modelManager = modelManager
  }
  
  func build(_ routeBuilder: RouteBuilder) {
    
    // GET /measurements/:id
    routeBuilder.get(
      Measurement.parameter,
      handler: getMeasurementById)
    
    // POST /measurements
    routeBuilder.post(
      handler: createNewMeasurement)
    
  }
  
  private func getMeasurementById(_ request: Request) throws -> ResponseRepresentable {

    let (measurement, isRootUser, doesUserBelongToOrganization) =
      try isRootOrMeasurementUser(request)

    if isRootUser || doesUserBelongToOrganization {

      return measurement

    } else {

      throw Abort(.notFound)

    }
    
  }
  
  private func createNewMeasurement(_ request: Request) throws -> ResponseRepresentable {
      
    let json = try request.assertJson()
    
    guard let surveyId: Identifier = try json.get(Measurement.Json.surveyId),
      let survey = try modelManager.findSurvey(byId: Identifier(surveyId)) else {
        throw Abort(.notFound, reason: "Survey not found")
    }
    
    guard let abioticFactorId: Identifier = try json.get(Measurement.Json.abioticFactorId),
      let abioticFactor = try modelManager.findAbioticFactor(byId: abioticFactorId) else {
        throw Abort(.notFound, reason: "Abiotic Factor not found")
    }
    
    guard let measurementUnitId: Identifier = try json.get(Measurement.Json.measurementUnitId),
      let measurementUnit = try modelManager.findMeasurementUnit(byId: measurementUnitId) else {
        throw Abort(.notFound, reason: "Measurement Unit not found")
    }
    
    guard let value: Double = try json.get(Measurement.Json.value) else {
        throw Abort(.notFound, reason: "Measurement Value not found")
    }
    
    return try modelManager.createMeasurement(
      value: value,
      abioticFactor: abioticFactor.name,
      measurementUnit: measurementUnit.name,
      survey: survey)
    
  }

  private func isRootOrMeasurementUser(_ request: Request) throws -> (Measurement, Bool, Bool) {

    let measurement = try request.parameters.next(Measurement.self)
    guard let organization = try measurement.survey.get()?.site.get()?.organization.get() else {
      throw Abort(.internalServerError)
    }
    let user = try request.user()
    let isRootUser = try modelManager.isRootUser(user)
    let doesUserBelongToOrganization = try modelManager.doesUserBelongToOrganization(
      user: user,
      organization: organization)

    return (measurement, isRootUser, doesUserBelongToOrganization)

  }
  
}
