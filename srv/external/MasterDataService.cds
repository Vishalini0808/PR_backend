/* checksum : 131b4ca29278bc3d1a0f69e47c58ac56 */
@cds.external : true
service MasterDataService {
  @cds.external : true
  @cds.persistence.skip : true
  entity OrganizationalUnits {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    unitCode : String(20) not null;
    unitName : String(100) not null;
    description : String(255);
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity CostCentres {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    costCentreCode : String(30) not null;
    costCentreName : String(100) not null;
    description : String(255);
    organizationalUnit_ID : UUID not null;
    organizationalUnit : Association to one OrganizationalUnits on organizationalUnit.ID = organizationalUnit_ID;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity PurchaseCategories {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    categoryCode : String(20) not null;
    categoryName : String(100) not null;
    description : String(255);
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Budgets {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    budgetCode : String(30) not null;
    financialYear : Integer not null;
    @Validation.Minimum : 0
    @Validation.Maximum : 9999999999999.99
    allocatedAmount : Decimal(15, 2) not null;
    @Validation.Minimum : 0
    @Validation.Maximum : 9999999999999.99
    committedAmount : Decimal(15, 2) default 0;
    @Validation.Minimum : 0
    @Validation.Maximum : 9999999999999.99
    actualSpentAmount : Decimal(15, 2) default 0;
    currency : String(3) default 'INR';
    costCentre_ID : UUID not null;
    costCentre : Association to one CostCentres on costCentre.ID = costCentre_ID;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity ApprovalMatrix {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    matrixCode : String(30) not null;
    @Validation.Minimum : 1
    @Validation.Maximum : 10
    approvalLevel : Integer not null;
    @Validation.Minimum : 1
    @Validation.Maximum : 10
    sequenceNumber : Integer not null;
    @Validation.Minimum : 0
    @Validation.Maximum : 9999999999999.99
    minimumAmount : Decimal(15, 2) not null;
    @Validation.Minimum : 0
    @Validation.Maximum : 9999999999999.99
    maximumAmount : Decimal(15, 2);
    currency : String(3) default 'INR';
    approverRole : String(50) not null;
    organizationalUnit_ID : UUID;
    purchaseCategory_ID : UUID;
    organizationalUnit : Association to one OrganizationalUnits on organizationalUnit.ID = organizationalUnit_ID;
    purchaseCategory : Association to one PurchaseCategories on purchaseCategory.ID = purchaseCategory_ID;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity DeliveryLocations {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    locationCode : String(20) not null;
    locationName : String(100) not null;
    address : String(255);
    city : String(100);
    state : String(100);
    postalCode : String(20);
    country : String(100);
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity ProjectReferences {
    @Core.ComputedDefaultValue : true
    key ID : UUID not null;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created On'
    createdAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Immutable : true
    @Core.Computed : true
    @Common.Label : 'Created By'
    createdBy : String(255);
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed On'
    modifiedAt : Timestamp;
    /** User's unique ID */
    @UI.HiddenFilter : true
    @UI.ExcludeFromNavigationContext : true
    @Core.Computed : true
    @Common.Label : 'Changed By'
    modifiedBy : String(255);
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACTIVE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Inactive',
        Value: 'INACTIVE'
      }
    ]
    status : String default 'ACTIVE';
    projectCode : String(30) not null;
    projectName : String(150) not null;
    description : String(500);
  };
};

