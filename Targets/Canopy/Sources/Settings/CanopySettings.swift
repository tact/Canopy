/// Default Canopy settings.
///
/// These are reasonable to use as the starting point in most applications.
public struct CanopySettings: CanopySettingsType {
  public var modifyRecordsBehavior: RequestBehavior
  public var fetchDatabaseChangesBehavior: RequestBehavior
  public var fetchZoneChangesBehavior: RequestBehavior
  public var autoBatchTooLargeModifyOperations: Bool
  public var autoRetryForRetriableErrors: Bool
  
  public init(
    modifyRecordsBehavior: RequestBehavior = .regular(nil),
    fetchDatabaseChangesBehavior: RequestBehavior = .regular(nil),
    fetchZoneChangesBehavior: RequestBehavior = .regular(nil),
    autoBatchTooLargeModifyOperations: Bool = true,
    autoRetryForRetriableErrors: Bool = true
  ) {
    self.modifyRecordsBehavior = modifyRecordsBehavior
    self.fetchDatabaseChangesBehavior = fetchDatabaseChangesBehavior
    self.fetchZoneChangesBehavior = fetchZoneChangesBehavior
    self.autoBatchTooLargeModifyOperations = autoBatchTooLargeModifyOperations
    self.autoRetryForRetriableErrors = autoRetryForRetriableErrors
  }
}
