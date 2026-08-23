CLASS zbp_i_suppliermaster DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_suppliermaster.

  PRIVATE SECTION.

    " Same two enums legacy-supplier-mapper.js's RISK_MAP/STATUS_MAP
    " encode on the CAP side - kept as literal constants here rather than
    " a real ABAP domain with fixed values, matching this artifact's
    " "not yet run against a real ABAP Environment" scope (a domain would
    " be the more idiomatic real choice, verified in ADT).
    CONSTANTS:
      BEGIN OF risk_rating,
        low    TYPE char6 VALUE 'LOW',
        medium TYPE char6 VALUE 'MEDIUM',
        high   TYPE char6 VALUE 'HIGH',
      END OF risk_rating,
      BEGIN OF lifecycle_status,
        active   TYPE char8 VALUE 'ACTIVE',
        inactive TYPE char8 VALUE 'INACTIVE',
        blocked  TYPE char8 VALUE 'BLOCKED',
      END OF lifecycle_status.

    METHODS validateRiskRating FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierMaster~validateRiskRating.

    METHODS validateLifecycleStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierMaster~validateLifecycleStatus.

ENDCLASS.


CLASS zbp_i_suppliermaster IMPLEMENTATION.

  METHOD validateRiskRating.
    READ ENTITIES OF zi_suppliermaster IN LOCAL MODE
      ENTITY SupplierMaster
        FIELDS ( RiskRating )
        WITH CORRESPONDING #( keys )
      RESULT DATA(suppliers).

    LOOP AT suppliers INTO DATA(supplier)
      WHERE RiskRating <> risk_rating-low
        AND RiskRating <> risk_rating-medium
        AND RiskRating <> risk_rating-high.

      APPEND VALUE #( %tky = supplier-%tky ) TO failed-suppliermaster.

      " new_message_text() - the simplest real RAP message mechanism, no
      " custom message class needed (a real message class, created via
      " ADT's wizard, would be the more idiomatic choice for a
      " production-grade object; kept simple here on purpose, same
      " "no tool available to verify a hand-authored message class"
      " reasoning this folder's README gives for the underlying table).
      APPEND VALUE #( %tky = supplier-%tky
                       %msg = new_message_text(
                                severity = if_abap_behv=>severity-error
                                text     = |Risk rating "{ supplier-RiskRating }" is invalid - | &&
                                           |must be LOW, MEDIUM, or HIGH| )
                       %element-RiskRating = if_abap_behv=>mk-on )
             TO reported-suppliermaster.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateLifecycleStatus.
    READ ENTITIES OF zi_suppliermaster IN LOCAL MODE
      ENTITY SupplierMaster
        FIELDS ( LifecycleStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(suppliers).

    LOOP AT suppliers INTO DATA(supplier)
      WHERE LifecycleStatus <> lifecycle_status-active
        AND LifecycleStatus <> lifecycle_status-inactive
        AND LifecycleStatus <> lifecycle_status-blocked.

      APPEND VALUE #( %tky = supplier-%tky ) TO failed-suppliermaster.
      APPEND VALUE #( %tky = supplier-%tky
                       %msg = new_message_text(
                                severity = if_abap_behv=>severity-error
                                text     = |Status "{ supplier-LifecycleStatus }" is invalid - | &&
                                           |must be ACTIVE, INACTIVE, or BLOCKED| )
                       %element-LifecycleStatus = if_abap_behv=>mk-on )
             TO reported-suppliermaster.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
