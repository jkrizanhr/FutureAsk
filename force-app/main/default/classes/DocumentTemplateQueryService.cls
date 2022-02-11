public class DocumentTemplateQueryService {
  // Before Insert, Before Update
  public static void validateNumPrimaryQueries(List<Document_Template_Query__c> queryList, String triggerContext) {
    Set<Id> templateIds = buildPrimaryQueryDocumentTemplateIdSet(queryList);

    // Get the existing primary soql query records for the templates related to the original query list.
    List<Document_Template_Query__c> primaryQueryList = new List<Document_Template_Query__c>();
    if (String.isNotBlank(triggerContext) && triggerContext.containsIgnoreCase('insert')) {
      // Is insert and does not have an id yet.
      primaryQueryList = fetchPrimaryQueries(templateIds);
    } else {
      // Is update and has an Id so we want to make sure that our results do not contain the original query list.
      primaryQueryList = fetchPrimaryQueries(templateIds, queryList);
    }

    // Create a set of templates that currently have a primary soql query record and are not in the original list
    Set<Id> templatePrimaryQuerySet = new Set<Id>();
    for (Document_Template_Query__c pq : primaryQueryList) {
      if (pq.Document_Template__c != null && !templatePrimaryQuerySet.contains(pq.Document_Template__c)) {
        templatePrimaryQuerySet.add(pq.Document_Template__c);
      }
    }

    // Loop through the original query list and verify if a primary soql query already exists
    // for the related template. Throw and error if one already exists, add to the set if one doesn't exist.
    Id primarySOQLQueryRecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    for (Document_Template_Query__c query : queryList) {
      if (query.RecordTypeId == primarySOQLQueryRecordTypeId && query.Document_Template__c != null) {
        if (templatePrimaryQuerySet.contains(query.Document_Template__c)) {
          query.addError('Error: There can only be one primary query for each document template!');
        } else {
          templatePrimaryQuerySet.add(query.Document_Template__c);
        }
      }
    }
  }

  private static Set<Id> buildPrimaryQueryDocumentTemplateIdSet(List<Document_Template_Query__c> queryList) {
    Set<Id> templateIds = new Set<Id>();
    Id primarySOQLQueryRecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    for (Document_Template_Query__c query : queryList) {
      if (query.RecordTypeId == primarySOQLQueryRecordTypeId && query.Document_Template__c != null) {
        templateIds.add(query.Document_Template__c);
      }
    }
    return templateIds;
  }

  // Utility method for validating the number of primary queries (before insert)
  private static List<Document_Template_Query__c> fetchPrimaryQueries(Set<Id> templateIds) {
    return [
      SELECT Document_Template__c, Id
      FROM Document_Template_Query__c
      WHERE Document_Template__c IN :templateIds
        AND RecordType.Name = 'Primary SOQL Query'
      ORDER BY CreatedDate
    ];
  }

  // Utility method for validating the number of primary queries when needing to filter out the original query list (before update)
  private static List<Document_Template_Query__c> fetchPrimaryQueries(Set<Id> templateIds, List<Document_Template_Query__c> queryList) {
    Map<Id, Document_Template_Query__c> queryMap = new Map<Id, Document_Template_Query__c>(queryList);
    return [
      SELECT Document_Template__c, Id
      FROM Document_Template_Query__c
      WHERE Document_Template__c IN :templateIds
        AND RecordType.Name = 'Primary SOQL Query'
        AND Id NOT IN :queryMap.keySet()
      ORDER BY CreatedDate
    ];
  }

  // Before Insert, Before Update
  public static void buildQuery(List<Document_Template_Query__c> queryList) {
    Id primarySOQLQueryRecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    for (Document_Template_Query__c query : queryList) {
      query.SELECT_Statement__c = formatQuerySubstring(query.SELECT_Statement__c, 'select');
      query.WHERE_Clause__c = formatQuerySubstring(query.WHERE_Clause__c, 'where');
      query.GROUP_BY_Statement__c = formatQuerySubstring(query.GROUP_BY_Statement__c, 'group by');
      query.HAVING_Statement__c = formatQuerySubstring(query.HAVING_Statement__c, 'having');
      query.ORDER_BY_Statement__c = formatQuerySubstring(query.ORDER_BY_Statement__c, 'order by');
      query.SOQL_Query__c = concatenateQueryStatements(query);

      // Validate the query execution order
      if (query.RecordTypeId == primarySOQLQueryRecordTypeId) {
        query.Query_Execution_Order__c = 1;
      } else if (query.RecordTypeId != primarySOQLQueryRecordTypeId && query.Query_Execution_Order__c == 1) {
        query.Query_Execution_Order__c = null;
      }
    }
  }

  private static String formatQuerySubstring(String querySubstring, String querySegment) {
    if (String.isNotBlank(querySubstring) && !querySubstring.startsWithIgnoreCase(querySegment)) {
      querySubstring = querySegment.toUpperCase() + ' ' + querySubstring;
    } else if (String.isNotBlank(querySubstring) && querySubstring.trim().toUpperCase() == querySegment.toUpperCase()) {
      return '';
    }
    return querySubstring;
  }

  private static String concatenateQueryStatements(Document_Template_Query__c query) {
    String fromString = '';
    if (String.isNotBlank(query.FROM_Object__c)) {
      fromString += 'FROM ' + query.FROM_Object__c;
    }
    List<String> queryStringList = new List<String>{
      query.SELECT_Statement__c,
      fromString
    };
    if (String.isNotBlank(query.WHERE_Clause__c) && query.WHERE_Clause__c.trim() != 'WHERE') {
      queryStringList.add(query.WHERE_Clause__c);
    }
    if (String.isNotBlank(query.GROUP_BY_Statement__c)) {
      queryStringList.add(query.GROUP_BY_Statement__c);
    }
    if (String.isNotBlank(query.HAVING_Statement__c)) {
      queryStringList.add(query.HAVING_Statement__c);
    }
    if (String.isNotBlank(query.ORDER_BY_Statement__c)) {
      queryStringList.add(query.ORDER_BY_Statement__c);
    }
    if (query.LIMIT__c != null && query.LIMIT__c > 0) {
      queryStringList.add('LIMIT ' + query.LIMIT__c);
    }
    return String.join(queryStringList, '\n');
  }

  // After Insert, After Update
  public static void assignPrimaryQuery(List<Document_Template_Query__c> queryList) {
    Set<Id> templateIds = buildPrimaryQueryDocumentTemplateIdSet(queryList);
    Map<Id, Document_Template__c> templateMap = new Map<Id, Document_Template__c>([
      SELECT Id, Primary_Query__c
      FROM Document_Template__c
      WHERE Id IN :templateIds
        AND Primary_Query__c = NULL
    ]);

    Id primarySOQLQueryRecordTypeId = Schema.SObjectType.Document_Template_Query__c.getRecordTypeInfosByName().get('Primary SOQL Query').getRecordTypeId();
    for (Document_Template_Query__c query : queryList) {
      if (query.RecordTypeId == primarySOQLQueryRecordTypeId
      && query.Document_Template__c != null
      && templateMap.containsKey(query.Document_Template__c)) {
        Document_Template__c template = new Document_Template__c();
        template.Id = query.Document_Template__c;
        template.Primary_Query__c = query.Id;
        templateMap.put(template.Id, template);
      }
    }

    update templateMap.values();
  }
}