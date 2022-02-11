public inherited sharing class GPExportBundleService {
  private GP_Export_Bundle__c bundle;
  private Id bundleId;
  private Cash_Batch__c batch;
  private List<Opportunity> opportunities;

  /**
   * Constructor
   * @param bundleId
   * @param opportunities
   */
  public GPExportBundleService(Id bundleId, Cash_Batch__c batch) {
    this.bundleId = bundleId;
    this.bundle = [
      SELECT Fund_GL_Error_Message__c, Id
      FROM GP_Export_Bundle__c
      WHERE Id = :bundleId
    ];
    this.batch = batch;
    this.opportunities = [
      SELECT Amount, Cash_Batch__c, CloseDate, GP_Export_Error__c, Id
      FROM Opportunity
      WHERE Cash_Batch__c = :batch.Id
    ];
  }

  /**
   * Utility method to concatenate error messages onto the GP Export Bundle record.
   * @param errMessage - The custom error message to append.
   */
  private void addBundleError(String errMessage) {
    if (String.isNotBlank(this.bundle.Fund_GL_Error_Message__c)) {
      if (this.bundle.Fund_GL_Error_Message__c.contains(errMessage)) {
        return;
      }
      this.bundle.Fund_GL_Error_Message__c += '\n';
    }
    this.bundle.Fund_GL_Error_Message__c += errMessage;
    this.bundle.Fund_GL_Error_Message__c = this.bundle.Fund_GL_Error_Message__c.abbreviate(13000);
  }

  /**
   * Execute a query to aggregate allocations to obtain the total number of allocations and the sum
   * of the amounts in relation to each opportunity.
   * @return Map<Id, Aggregate> - The aggregate query result map where the keys are opportunity
   * ids and the values are the aggregate results.
   */
  private Map<Id, AggregateResult> fetchAllocationAggregates() {
    return new Map<Id, AggregateResult>(
      [
        SELECT COUNT(Id) totalCount, SUM(npsp__Amount__c) totalAmount, npsp__Opportunity__c Id
        FROM npsp__Allocation__c
        WHERE npsp__Opportunity__c IN :this.opportunities
        GROUP BY npsp__Opportunity__c
      ]
    );
  }

  /**
   * Query gau allocations that are related to the list of opportunities.
   * @return List<npsp__Allocation__c> - The allocation query result related to the list of
   * opportunities.
   */
  private List<npsp__Allocation__c> fetchAllocations() {
    return [
      SELECT
        Fund_GL_Account__c,
        Fund_GL_Account__r.Active__c,
        Fund_GL_Account__r.General_Accounting_Unit__c,
        Fund_GL_Account__r.GL_Account__c,
        Fund_GL_Account__r.GL_Account_Prefix__c,
        GP_Export_Error__c,
        Id,
        npsp__Amount__c,
        npsp__General_Accounting_Unit__c,
        npsp__General_Accounting_Unit__r.npsp__Active__c,
        npsp__General_Accounting_Unit__r.Purpose_Code__c,
        npsp__Opportunity__c,
        npsp__Opportunity__r.Amount,
        npsp__Opportunity__r.CloseDate
      FROM npsp__Allocation__c
      WHERE npsp__Opportunity__c IN :this.opportunities
      ORDER BY npsp__Opportunity__c
    ];
  }

  /**
   * Check that all Opportunities have at least 1 GAU Allocation and that the sum of the
   * allocation amounts matches the total amount on the opportunity
   * @param opp - The opportunity record
   * @param res - The gau allocation aggregate result
   */
  private void validateOpportunities(Opportunity opp, AggregateResult res) {
    opp.GP_Export_Error__c = '';
    if (res != null) {
      Integer totalCount = (Integer) res.get('totalCount');
      Decimal totalAmount = (Decimal) res.get('totalAmount');
      totalAmount = totalAmount != null ? totalAmount.setScale(2) : null;

      if (totalAmount != opp.Amount) {
        // Validation Failed
        opp.GP_Export_Error__c = 'The Opportunity amount does not equal the sum of the GAU Allocations amounts.';
        this.addBundleError('Opportunity: Sum of Allocation Amounts');
      }
    } else {
      // Validation Failed
      opp.GP_Export_Error__c = 'No GAU Allocations found.';
      this.addBundleError('Missing GAU Allocation(s)');
    }
  }

  /**
   * Check the GAU and Fund GL Account related to the GAU Allocation and validate that the
   * fields are set properly.
   * @param alloc - The GAU Allocation with the related records (GAU, Fund GL Account)
   */
  private void validateGAUs(npsp__Allocation__c alloc) {
    alloc.GP_Export_Error__c = '';
    List<String> validationErrors = new List<String>();

    // Validations on GAU and Fund GL Account related to the GAU Allocation
    if (alloc.npsp__General_Accounting_Unit__c == null) {
      // Validation Failed
      validationErrors.add('General accounting unit not found.');
    } else {
      if (String.isBlank(alloc.npsp__General_Accounting_Unit__r.Purpose_Code__c)) {
        // Validation Failed
        validationErrors.add('General accounting unit\'s purpose code is blank.');
      }
    }

    if (alloc.Fund_GL_Account__c == null) {
      // Validation Failed
      validationErrors.add('Fund gl account not found.');
    } else {
      if (String.isBlank(alloc.Fund_GL_Account__r.GL_Account__c)) {
        // Validation Failed
        validationErrors.add('Fund gl account\'s gl account is not found.');
      }

      if (!alloc.Fund_GL_Account__r.Active__c) {
        // Validation Failed
        validationErrors.add('Fund gl account is not active.');
      }
    }

    if (
      alloc.npsp__General_Accounting_Unit__c != null &&
      alloc.Fund_GL_Account__c != null &&
      alloc.npsp__General_Accounting_Unit__c != alloc.Fund_GL_Account__r.General_Accounting_Unit__c
    ) {
      // Validation Failed
      validationErrors.add(
        'The general accounting unit associated with the allocation is not the same as the general accounting unit tied to the related fund gl account record.'
      );
    }

    if (!validationErrors.isEmpty()) {
      alloc.GP_Export_Error__c = String.join(validationErrors, '\n');

      if (!alloc.npsp__General_Accounting_Unit__r.npsp__Active__c) {
        // Validation Failed
        alloc.GP_Export_Error__c += '\nInactive GAU';
        this.addBundleError('GAU Allocation: Inactive GAU');
      } else {
        this.addBundleError('GAU Allocation: Error Found');
      }
    }
  }

  /**
   * Map fields to represent the auto-generated reciprocal row for a new GP Export AAGL Row record.
   * Example file columns:
   * - SeqID
   * - Donation_ID
   * - Donation_Date
   * - Donation_Batch_Number
   * - GP Full Account ('1014-000-000' static value)
   * - Donation_Amount
   * - Purpose_Code (leave blank)
   * - GP_Natural_Account (leave blank)
   * - Checkbook ('MILLENNIUM' static value)
   * @param opp - The opportunity record
   * @param alloc - The allocation record
   * @param rowNumber - The aagl row number that would appear in the export file
   * @return GP_Export_AAGL_Row__c - The new instance of a gp export aagl row record that will
   * later be inserted.
   */
  private GP_Export_AAGL_Row__c buildAAGLReciprocalRow(
    Opportunity opp,
    npsp__Allocation__c alloc,
    Integer rowNumber
  ) {
    GP_Export_AAGL_Row__c aaglRow = new GP_Export_AAGL_Row__c();
    aaglRow.SeqID__c = rowNumber;
    aaglRow.Checkbook__c = 'MILLENNIUM';
    aaglRow.Donation_Amount__c = alloc.npsp__Amount__c;
    aaglRow.Donation_Batch_Number__c = this.batch.Name;
    aaglRow.Donation_Date__c = String.valueOf(opp.CloseDate);
    aaglRow.Donation_ID__c = opp.Id;
    aaglRow.GP_Export_Bundle__c = this.bundleId;
    aaglRow.GP_Full_Account__c = '1014-000-000';
    // GP_Natural_Account__c // Should be null
    // Purpose_Code__c // Should be null
    aaglRow.GAU_Allocation__c = alloc.Id;
    return aaglRow;
  }

  /**
   * Map fields to represent a row for a new GP Export AAGL Row record.
   * Example file columns:
   * - SeqID
   * - Donation_ID
   * - Donation_Date
   * - Donation_Batch_Number
   * - GP Full Account
   * - Donation_Amount
   * - Purpose_Code
   * - GP_Natural_Account
   * - Checkbook (leave blank)
   * @param opp - The opportunity record
   * @param alloc - The allocation record
   * @param rowNumber - The aagl row number that would appear in the export file
   * @return GP_Export_AAGL_Row__c - The new instance of a gp export aagl row record that will
   * later be inserted.
   */
  private GP_Export_AAGL_Row__c buildAAGLRow(
    Opportunity opp,
    npsp__Allocation__c alloc,
    Integer rowNumber
  ) {
    GP_Export_AAGL_Row__c aaglRow = new GP_Export_AAGL_Row__c();
    aaglRow.SeqID__c = rowNumber;
    // Checkbook__c // Should be null
    aaglRow.Donation_Amount__c = alloc.npsp__Amount__c * -1;
    aaglRow.Donation_Batch_Number__c = this.batch.Name;
    aaglRow.Donation_Date__c = String.valueOf(opp.CloseDate);
    aaglRow.Donation_ID__c = opp.Id;
    aaglRow.GP_Export_Bundle__c = this.bundleId;
    aaglRow.GP_Full_Account__c = alloc.Fund_GL_Account__r.GL_Account__c;
    aaglRow.GP_Natural_Account__c = alloc.Fund_GL_Account__r.GL_Account_Prefix__c;
    aaglRow.Purpose_Code__c = alloc.npsp__General_Accounting_Unit__r.Purpose_Code__c;
    aaglRow.GAU_Allocation__c = alloc.Id;
    return aaglRow;
  }

  /**
   * Map fields to represent a row for a new GP Export Deposit Row record.
   * Example file columns:
   * - Donation_Batch_Number
   * - Donation_Date
   * - GP Full Account ('1014-000-000' static value)
   * - SumOfDonation_Amount
   * - Checkbook ('MILLENIUM' static value)
   * @param opp - The opportunity record
   * @param amount - The allocation amount which will be added onto for each allocation in the batch
   * to sum up to the total donation amount
   * @return GP_Export_Deposit_Row__c - The new instance of a gp export deposit row record that will
   * later be upserted.
   */
  private GP_Export_Deposit_Row__c buildDepositRow(Opportunity opp, Decimal amount) {
    GP_Export_Deposit_Row__c depositRow = new GP_Export_Deposit_Row__c();
    depositRow.Checkbook__c = 'MILLENNIUM';
    depositRow.Donation_Batch_Number__c = this.batch.Name;
    depositRow.Donation_Date__c = opp.CloseDate;
    depositRow.GP_Export_Bundle__c = this.bundleId;
    depositRow.GP_Full_Account__c = '1014-000-000';
    depositRow.SumOfDonation_Amount__c = amount;
    depositRow.Cash_Batch__c = opp.Cash_Batch__c;
    return depositRow;
  }

  /**
   * Map fields to represent a row for a new GP Export Return Row record.
   * Example file columns:
   * - Donation_Batch_Number
   * - Donation_Date
   * - GP Full Account ('1014-000-000' static value)
   * - SumOfDonation_Amount
   * - Checkbook ('MILLENIUM' static value)
   * @param opp - The opportunity record
   * @param amount - The allocation amount which will be added onto for each allocation in the batch
   * to sum up to the total donation amount
   * @return GP_Export_Return_Row__c - The new instance of a gp export return row record that will
   * later be upserted.
   */
  private GP_Export_Return_Row__c buildReturnRow(Opportunity opp, Decimal amount) {
    GP_Export_Return_Row__c returnRow = new GP_Export_Return_Row__c();
    returnRow.Checkbook__c = 'MILLENNIUM';
    returnRow.Donation_Batch_Number__c = this.batch.Name;
    returnRow.Donation_Date__c = opp.CloseDate;
    returnRow.GP_Export_Bundle__c = this.bundleId;
    returnRow.GP_Full_Account__c = '1014-000-000';
    returnRow.SumOfDonation_Amount__c = amount;
    returnRow.Cash_Batch__c = opp.Cash_Batch__c;
    return returnRow;
  }

  /**
   * Check that deposit rows are positive and not negative.
   */
  private void validateDepositRows(List<GP_Export_Deposit_Row__c> depositRows) {
    for (GP_Export_Deposit_Row__c depositRow : depositRows) {
      if (depositRow.SumOfDonation_Amount__c < 0) {
        // Add the error to the gp export bundle record
        this.addBundleError('GP Export Deposit Row: Negative sum of the donation amounts');
      }
    }
  }

  /**
   * The main method called from the GPExportBundleJob which will call the above methods
   * to create gp export aagl rows and gp export deposit rows for the class instance's
   * gp export bundle.
   */
  public void run() {
    if (this.bundle.Fund_GL_Error_Message__c == null) {
      // Set to an empty string so that we don't have to null check it when concatenating errors.
      this.bundle.Fund_GL_Error_Message__c = '';
    }

    this.batch.GP_Export_Error__c = '';

    // Add GP Export Error message field on cash batch to capture if no opps are tied to it.
    if (this.opportunities.isEmpty()) {
      this.batch.GP_Export_Error__c = 'No opportunities found.';
      this.addBundleError('Cash Batch: No Opportunities');
    }

    Map<Id, AggregateResult> allocationAggregateMap = this.fetchAllocationAggregates();
    List<npsp__Allocation__c> allocations = this.fetchAllocations();

    // Capture validation errors on the GAU and Fund GL Account related to the GAU Allocations
    // and build a map of Opportunities to their related GAU Allocations
    Map<Id, List<npsp__Allocation__c>> oppAllocationMap = new Map<Id, List<npsp__Allocation__c>>();
    for (npsp__Allocation__c alloc : allocations) {
      List<npsp__Allocation__c> oppAllocations = oppAllocationMap.get(alloc.npsp__Opportunity__c);
      if (oppAllocations == null) {
        oppAllocations = new List<npsp__Allocation__c>();
        oppAllocationMap.put(alloc.npsp__Opportunity__c, oppAllocations);
      }
      oppAllocations.add(alloc);
    }

    Map<String, GP_Export_Deposit_Row__c> depositRowMap = new Map<String, GP_Export_Deposit_Row__c>();
    Map<String, GP_Export_Return_Row__c> returnRowMap = new Map<String, GP_Export_Return_Row__c>();
    List<GP_Export_AAGL_Row__c> aaglRows = new List<GP_Export_AAGL_Row__c>();

    Integer numAAGLRows = [
      SELECT COUNT()
      FROM GP_Export_AAGL_Row__c
      WHERE GP_Export_Bundle__c = :this.bundleId
    ];

    List<npsp__Allocation__c> allocationUpdateList = new List<npsp__Allocation__c>();

    for (Opportunity opp : this.opportunities) {
      AggregateResult res = allocationAggregateMap.get(opp.Id);
      this.validateOpportunities(opp, res);

      List<npsp__Allocation__c> oppAllocations = oppAllocationMap.get(opp.Id);

      if (oppAllocations == null) {
        continue;
      }

      for (npsp__Allocation__c alloc : oppAllocations) {
        if (
          alloc.npsp__General_Accounting_Unit__c == null ||
          alloc.npsp__General_Accounting_Unit__r.npsp__Active__c
        ) {
          // GAU lookup filter criteria on the GAU Allocation throws an error
          // preventing an update to the allocation if the gau is inactive.
          allocationUpdateList.add(alloc);
        }
        /* 
          Check that all General Accounting Units tied to opportunities in the current
          batch are active, have purpose codes, and an associated Fund GL Account record
          tied to them that is also active. 
        */
        this.validateGAUs(alloc);

        if (
          alloc.Fund_GL_Account__c == null || String.isBlank(alloc.Fund_GL_Account__r.GL_Account__c)
        ) {
          continue;
        }

        // Build deposit rows and return rows
        String key = this.batch.Name + ':' + String.valueOf(opp.CloseDate);

        if (alloc.npsp__Amount__c != null && alloc.npsp__Amount__c != 0) {
          // If the batch type is Adjustments, then use the GP Export Return Row object,
          // not the GP Export Deposit Row object.
          if (this.batch.Type__c == 'Adjustments') {
            GP_Export_Return_Row__c returnRow = returnRowMap.get(key);
            if (returnRow == null) {
              returnRow = this.buildReturnRow(opp, alloc.npsp__Amount__c);
              returnRowMap.put(key, returnRow);
            } else {
              returnRow.SumOfDonation_Amount__c += alloc.npsp__Amount__c;
            }
          } else {
            GP_Export_Deposit_Row__c depositRow = depositRowMap.get(key);
            if (depositRow == null) {
              depositRow = this.buildDepositRow(opp, alloc.npsp__Amount__c);
              depositRowMap.put(key, depositRow);
            } else {
              depositRow.SumOfDonation_Amount__c += alloc.npsp__Amount__c;
            }

            if (depositRow.SumOfDonation_Amount__c == 0) {
              // Remove from map
              depositRowMap.remove(key);
            }
          }
        }

        // Create instances of AAGL Rows
        GP_Export_AAGL_Row__c reciprocalRow = this.buildAAGLReciprocalRow(
          opp,
          alloc,
          numAAGLRows +
          aaglRows.size() +
          1
        );
        aaglRows.add(reciprocalRow);

        GP_Export_AAGL_Row__c aaglRow = this.buildAAGLRow(
          opp,
          alloc,
          numAAGLRows +
          aaglRows.size() +
          1
        );
        aaglRows.add(aaglRow);
      }
    }

    try {
      update allocationUpdateList;
      update this.opportunities;
      update this.batch;
      insert aaglRows;
      insert depositRowMap.values();
      this.validateDepositRows(depositRowMap.values());
      insert returnRowMap.values();
    } catch (Exception e) {
      this.addBundleError(e.getMessage());
    }

    update this.bundle;
  }
}