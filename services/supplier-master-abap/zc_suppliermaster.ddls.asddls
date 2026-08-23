@AbapCatalog.sqlViewName: 'ZCSUPPLIERMST'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Supplier Master'
@Metadata.allowExtensions: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@Search.searchable: true

// Consumption view - what the service definition below actually exposes
// over OData V4. Field labels/value help here are the RAP-side
// equivalent of procurement-core/srv/service-ui.cds's Fiori annotations -
// same idea (API contract vs. presentation), different framework.
define root view entity ZC_SupplierMaster
  as projection on ZI_SupplierMaster
{
  key SupplierUUID,
      @EndUserText.label: 'Legacy Supplier ID'
      ExternalID,
      @EndUserText.label: 'Source System'
      SourceSystem,
      @EndUserText.label: 'Company Name'
      @Search.defaultSearchElement: true
      CompanyName,
      @EndUserText.label: 'Country'
      Country,
      @EndUserText.label: 'Tax Number'
      TaxNumber,
      @EndUserText.label: 'Email'
      Email,
      @EndUserText.label: 'Risk Rating'
      // Same LOW/MEDIUM/HIGH enum legacy-supplier-mapper.js's RISK_MAP
      // produces - kept as a plain CHAR value here rather than a real
      // ABAP domain/value-help object, matching this artifact's own
      // "not run against a real ABAP Environment yet" scope.
      RiskRating,
      @EndUserText.label: 'Status'
      LifecycleStatus,

      LocalCreatedAt,
      LocalCreatedBy,
      LocalLastChangedAt,
      LocalLastChangedBy
}
