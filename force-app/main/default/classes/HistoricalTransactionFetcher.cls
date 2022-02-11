global class HistoricalTransactionFetcher implements System.Queueable, Database.AllowsCallouts {
  private String type;

  global HistoricalTransactionFetcher(String type) {
    this.type = type;
  }

  global void execute(System.QueueableContext qc) {
    Historical_Transaction_Settings__c htSettings = Historical_Transaction_Settings__c.getInstance(type);
    if (htSettings == null) {
      throw new HistoricalTransactionException('No Historical_Transaction_Settings__c found with type: ' + type);
    }

    Datetime lastCheckedTime = htSettings.Last_Checked_Time__c;
    String nextId = htSettings.Next_Id__c;
    Integer startTimeStepSeconds = Integer.valueOf(htSettings.Start_Time_Step_seconds__c);
    Integer timeStepMinutes = Integer.valueOf(htSettings.Time_Step_Minutes__c);
    Integer recordQuerySize = Integer.valueOf(htSettings.Record_Query_Size__c);
    String mode = htSettings.API_Type__c;
    String datetimeCompareField = htSettings.Datetime_Compare_Field__c;

    HistoricalTransactionAPI api = HistoricalTransactionAPIFactory.getTransactionsAPIByType(type);
    api.setMode(mode);
    api.authenticate();

    Datetime now = Datetime.now();

    Datetime startTime = (lastCheckedTime != null ? lastCheckedTime : now);
    Datetime endTime = startTime.addMinutes(timeStepMinutes);
    System.debug('START TIME: ' + startTime + ' END TIME: ' + endTime);

    if (endTime.getTime() > now.getTime()) {
      endTime = Datetime.newInstanceGmt(now.dateGmt(), now.timeGmt());
    }

    /*
      Check for new transactions until one of the following is true:
      1. Salesforce limits are close to being exceeded (CPU Time or callouts used > 80%)
      2. The amount of records to be upserted through DML is close to 10000
      3. We have reached the current time.
    */
    HistoricalTransactionModel.TransactionsResponse currentResponse = null;
    List<Historical_Transaction__c> transactionsToInsert = new List<Historical_Transaction__c>();

    do {
      currentResponse = api.getTransactions(startTime, endTime, nextId, recordQuerySize);
      if (currentResponse != null && currentResponse.hasError) { break; }

      if (currentResponse != null && currentResponse.transactions != null && !currentResponse.transactions.isEmpty()) {
        transactionsToInsert.addAll(currentResponse.transactions);

        Datetime maxDate = this.getMaxDate(datetimeCompareField, currentResponse.transactions);
        if (maxDate < startTime) {
          maxDate = startTime;
        }
        startTime = maxDate.addSeconds(startTimeStepSeconds); // default to 1 second
        endTime = startTime.addMinutes(timeStepMinutes);
        nextId = currentResponse.nextId;
      } else {
        startTime = startTime.addMinutes(timeStepMinutes);
        endTime = startTime.addMinutes(timeStepMinutes);
      }
    } while (!this.areLimitsExceeded() &&
             transactionsToInsert.size() <= 9900 &&
             (endTime.getTime() <= now.getTime()));

    // Ensure the next run doesn't start past the current time
    if (startTime > now) {
      startTime = now;
    }

    // Set last checked time and errors, if applicable
    htSettings.Last_Checked_Time__c = startTime;
    htSettings.Last_Error_Message__c = (currentResponse.hasError ? currentResponse.errorMessage : null);
    update htSettings;

    // Create a map of transactions by id to make sure there are no duplicated transaction ids
    Map<String, Historical_Transaction__c> historicalTransactionMap = new Map<String, Historical_Transaction__c>();
    for (Historical_Transaction__c ht : transactionsToInsert) {
      historicalTransactionMap.put(ht.Transaction_Id__c, ht);
    }

    // Create/update historical transactions
    if (!historicalTransactionMap.values().isEmpty()) {
      upsert historicalTransactionMap.values() Transaction_Id__c;
    }
  }

  private Boolean areLimitsExceeded() {
    Double cpuTimeSpent = (Double)Limits.getCpuTime() / (Double)Limits.getLimitCpuTime();
    Double calloutsUsed = (Double)Limits.getCallouts() / (Double)Limits.getLimitCallouts();
    return (cpuTimeSpent > .80 || calloutsUsed > .80);
  }

  private Datetime getMaxDate(String datetimeCompareField, List<Historical_Transaction__c> transactions) {
    Datetime maxDate = (Datetime)transactions[0].get(datetimeCompareField);
    for (Integer i = 1; i < transactions.size(); i++) {
      if ((Datetime)transactions[i].get(datetimeCompareField) > maxDate) {
        maxDate = (Datetime)transactions[i].get(datetimeCompareField);
      }
    }
    return maxDate;
  }
}