global class DocumentGenerationScheduleJob implements Schedulable {
  /* This purpose of this class is to find out which Document Templates
    are scheduled to execute and then kick off the batch job for them
  */

  global void execute(SchedulableContext sc) {
    List<Document_Template__c> templateList = getDocumentTemplates();

    Map<Id, Document_Template__c> templateMap = new Map<Id, Document_Template__c>(templateList);
    Map<Id, Map<String, String>> docTempQuestionIdAnswerMap = getDefaultTemplateAnswers(
      templateMap.keySet()
    );
    Map<Id, Integer> docTempQueryCountMap = getDocumentTemplateQueryCounts(templateMap.keySet());

    for (Document_Template__c template : templateList) {
      template.Last_Generation_Date_Time__c = System.now();
      Map<String, String> questionIdAnswerMap = new Map<String, String>();
      if (docTempQuestionIdAnswerMap.containsKey(template.Id)) {
        questionIdAnswerMap = docTempQuestionIdAnswerMap.get(template.Id);
      }

      Integer numSelects = docTempQueryCountMap.get(template.Id);
      Integer batchSize = determineBatchSize(numSelects);

      Database.executeBatch(
        new DocumentGenerationBatchJob(
          template.Id,
          template.Scheduled_Delivery_Option__c,
          false,
          questionIdAnswerMap,
          template.Scheduled_TO_Address__c
        ),
        batchSize
      );
    }
    update templateList;
  }

  private List<Document_Template__c> getDocumentTemplates() {
    Datetime now = Datetime.now();
    String hourOfDay = now.format('h a');
    String dayOfWeek = now.format('EEEE');
    String dayOfMonth = String.valueOf(now.day());
    String monthOfYear = now.format('MMMMM');

    return [
      SELECT
        Day_of_Month__c,
        Day_of_Week__c,
        Daily_Time__c,
        Id,
        Month_of_Year__c,
        Name,
        Scheduled_Delivery_Option__c,
        Schedule_Frequency__c,
        Scheduled_TO_Address__c
      FROM Document_Template__c
      WHERE
        Scheduled_Delivery_Option__c != null
        AND (Schedule_Frequency__c = 'Hourly'
        OR (Schedule_Frequency__c = 'Daily'
        AND Daily_Time__c = :hourOfDay)
        OR (Schedule_Frequency__c = 'Weekly'
        AND Day_of_Week__c = :dayOfWeek
        AND Daily_Time__c = :hourOfDay)
        OR (Schedule_Frequency__c = 'Monthly'
        AND Day_of_Month__c = :dayOfMonth
        AND Daily_Time__c = :hourOfDay)
        OR (Schedule_Frequency__c = 'Yearly'
        AND Month_of_Year__c = :monthOfYear
        AND Day_of_Month__c = :dayOfMonth
        AND Daily_Time__c = :hourOfDay))
    ];
  }

  private Map<Id, Map<String, String>> getDefaultTemplateAnswers(Set<Id> templateIds) {
    List<Document_Template_Question_Option__c> docTempOptionList = [
      SELECT Document_Template__c, Document_Template_Question__c, Id, Option_Value__c
      FROM Document_Template_Question_Option__c
      WHERE Document_Template__c IN :templateIds AND Scheduled_Job_Default_Value__c = true
      ORDER BY Document_Template_Question__c, CreatedDate DESC
    ];

    Map<Id, Map<String, String>> docTempQuestionIdAnswerMap = new Map<Id, Map<String, String>>();
    for (Document_Template_Question_Option__c docTempOption : docTempOptionList) {
      if (docTempQuestionIdAnswerMap.containsKey(docTempOption.Document_Template__c) == false) {
        docTempQuestionIdAnswerMap.put(
          docTempOption.Document_Template__c,
          new Map<String, String>()
        );
      }
      Map<String, String> questionIdAnswerMap = docTempQuestionIdAnswerMap.get(
        docTempOption.Document_Template__c
      );
      questionIdAnswerMap.put(
        docTempOption.Document_Template_Question__c,
        docTempOption.Option_Value__c
      );
    }
    return docTempQuestionIdAnswerMap;
  }

  private Map<Id, Integer> getDocumentTemplateQueryCounts(Set<Id> templateIds) {
    List<Document_Template_Query__c> docTempQueryList = [
      SELECT Document_Template__c, Id, SOQL_Query__c
      FROM Document_Template_Query__c
      WHERE Document_Template__c IN :templateIds
      ORDER BY Document_Template__c, Query_Execution_Order__c
    ];

    Map<Id, Integer> docTempQueryCountMap = new Map<Id, Integer>();
    for (Document_Template_Query__c query : docTempQueryList) {
      Integer numSelects = countNumSelectStatements(query);
      if (docTempQueryCountMap.containsKey(query.Document_Template__c) == false) {
        docTempQueryCountMap.put(query.Document_Template__c, 0);
      }
      Integer count = docTempQueryCountMap.get(query.Document_Template__c) + numSelects;
      docTempQueryCountMap.put(query.Document_Template__c, count);
    }
    return docTempQueryCountMap;
  }

  private Integer countNumSelectStatements(Document_Template_Query__c query) {
    Integer numSelects = 0;
    // Factor in queries (and subqueries) as part of the count
    if (String.isNotBlank(query.SOQL_Query__c)) {
      Integer regexFindLimit = 1000;
      Integer regexFindCount = 0;
      Matcher matcher = Pattern.compile('select').matcher(query.SOQL_Query__c.toLowerCase());
      Integer lastEnd = 0;
      while (!matcher.hitEnd()) {
        while (regexFindCount < regexFindLimit && !matcher.hitEnd()) {
          if (matcher.find()) {
            numSelects++;
            lastEnd = matcher.end();
          } else {
            lastEnd = query.SOQL_Query__c.length();
          }
          regexFindCount++;
        }
        matcher.reset(query.SOQL_Query__c);
        matcher.region(lastEnd, matcher.regionEnd());
        regexFindCount = 0;
      }
    }
    return numSelects;
  }

  private static Integer determineBatchSize(Integer numQueries) {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    Integer batchSize = 45; // Default batch size

    if (
      docGenSettings != null &&
      docGenSettings.Max_Batch_Size__c != null &&
      docGenSettings.Max_Batch_Size__c > 0
    ) {
      batchSize = Integer.valueOf(docGenSettings.Max_Batch_Size__c);
    }

    if (numQueries != null && numQueries > 0 && numQueries <= batchSize) {
      batchSize = batchSize / numQueries;
    }
    return batchSize;
  }

  global static String schedule(String jobName, String cron) {
    String CRON_EXP = '0 0 13 * * ?';
    if (String.isBlank(cron)) {
      cron = CRON_EXP;
    }
    if (String.isBlank(jobName)) {
      jobName = 'Document Generation Schedule Job';
    }
    return System.schedule(jobName, cron, new DocumentGenerationScheduleJob());
  }

  global static String scheduleHourly(String jobName) {
    String CRON_EXP = '0 0 0 1/1 * ? *';
    if (String.isBlank(jobName)) {
      jobName = 'Document Generation Hourly Job';
    }
    return System.schedule(jobName, CRON_EXP, new DocumentGenerationScheduleJob());
  }
}