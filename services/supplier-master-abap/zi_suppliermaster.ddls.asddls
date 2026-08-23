@AbapCatalog.sqlViewName: 'ZISUPPLIERMST'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Supplier Master - Interface View'
@Metadata.ignorePropagatedAnnotations: true

// Interface view - the RAP convention of a thin, unadorned view directly
// on the persistence (zprocureiq_supp - see this folder's README for its
// field list), with the consumption view (zc_suppliermaster.ddls.asddls)
// adding the OData/UI-facing annotations on top. Same "API contract vs.
// presentation layer" separation procurement-core's own service.cds /
// service-ui.cds split already follows for the CAP side.
define root view entity ZI_SupplierMaster
  as select from zprocureiq_supp
{
  key supplier_uuid    as SupplierUUID,
      external_id      as ExternalID,
      source_system    as SourceSystem,
      company_name     as CompanyName,
      country          as Country,
      tax_number       as TaxNumber,
      email            as Email,
      risk_rating      as RiskRating,
      lifecycle_status as LifecycleStatus,

      @Semantics.systemDateTime.createdAt: true
      local_created_at as LocalCreatedAt,
      @Semantics.user.createdBy: true
      local_created_by as LocalCreatedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy
}
