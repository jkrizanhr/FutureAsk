@IsTest
private class DocumentQueryFieldParser_Test {
  // Utility test method
  private static List<DocumentQueryFieldParser.DocumentQueryField> executeParser(
    String queryString
  ) {
    DocumentQueryFieldParser parser = new DocumentQueryFieldParser(queryString);
    parser.parseQueryString();
    return parser.getDocumentQueryFields();
  }

  @IsTest
  static void testGetQueryFieldIndexMap() {
    String queryString = 'SELECT FirstName, LastName, Email FROM Contact';
    DocumentQueryFieldParser parser = new DocumentQueryFieldParser(queryString);
    parser.parseQueryString();

    Test.startTest();
    Map<Integer, DocumentQueryFieldParser.DocumentQueryField> resultMap = parser.getQueryFieldIndexMap();
    Test.stopTest();

    System.assertEquals(3, resultMap.size());
    System.assertEquals('FirstName', resultMap.get(0).selectField);
    System.assertEquals('LastName', resultMap.get(1).selectField);
    System.assertEquals('Email', resultMap.get(2).selectField);
  }

  @IsTest
  static void testParseFromObject() {
    // Basic query
    String q0 = 'SELECT FirstName, LastName, Email FROM Contact';

    // Test a string that is just a subquery
    String q1 =
      '( SELECT     Id,         Name     , CloseDate, Amount,           ' +
      ' AccountId FROM Opportunities )';

    // Aggregate query with multiple aggregate functions
    String q2 =
      'SELECT MIN(Amount) minAmt, MAX(Amount) maxAmt, AccountId Id FROM Opportunity' +
      ' GROUP BY AccountId';

    // Multiple subqueries
    String q3 =
      'SELECT Id, Name,(SELECT Id, FirstName, LastName, Email FROM Contacts)' +
      ',     (    SELECT    Id, Name, CloseDate, Amount FROM Opportunities WHERE Amount != NULL)' +
      ' FROM Account WHERE Id IN (     SELECT AccountId FROM Opportunities)';

    // Invalid field and handling the word select within a field
    String q4 = 'SELECT selectName__c, LastName, Email FROM Contact';

    DocumentQueryFieldParser p0 = new DocumentQueryFieldParser(q0);
    DocumentQueryFieldParser p1 = new DocumentQueryFieldParser(q1);
    DocumentQueryFieldParser p2 = new DocumentQueryFieldParser(q2);
    DocumentQueryFieldParser p3 = new DocumentQueryFieldParser(q3);
    DocumentQueryFieldParser p4 = new DocumentQueryFieldParser(q4);

    Test.startTest();
    String result0 = p0.parseFromObject(q0);
    String result1 = p1.parseFromObject(q1);
    String result2 = p2.parseFromObject(q2);
    String result3 = p3.parseFromObject(q3);
    String result4 = p4.parseFromObject(q4); // Invalid field but still returns the object?
    Test.stopTest();

    System.assertEquals('contact', result0);
    System.assertEquals('opportunities', result1);
    System.assertEquals('opportunity', result2);
    System.assertEquals('account', result3);
    System.assertEquals('contact', result4);
  }

  @IsTest
  static void testBuildQuerySelectList_basicQuery() {
    // Basic query
    String q0 = 'SELECT FirstName, LastName, Email FROM Contact';
    DocumentQueryFieldParser p0 = new DocumentQueryFieldParser(q0);

    Test.startTest();
    List<DocumentQueryFieldParser.QuerySelect> resultList0 = p0.buildQuerySelectList(q0);
    Test.stopTest();

    // q0
    System.assertEquals(1, resultList0.size());
    System.assertEquals(0, resultList0[0].selectNum);
    System.assertEquals(0, resultList0[0].fromNum);
    System.assertEquals('Contact', resultList0[0].fromObject);
  }

  @IsTest
  static void testBuildQuerySelectList_subquery() {
    // Test a string that is just a subquery
    String q1 =
      '( SELECT     Id,         Name     , CloseDate, Amount,           ' +
      ' AccountId FROM Opportunities )';
    DocumentQueryFieldParser p1 = new DocumentQueryFieldParser(q1);

    Test.startTest();
    List<DocumentQueryFieldParser.QuerySelect> resultList1 = p1.buildQuerySelectList(q1);
    Test.stopTest();

    // q1
    System.assertEquals(1, resultList1.size());
    System.assertEquals(0, resultList1[0].selectNum);
    System.assertEquals(0, resultList1[0].fromNum);
    System.assertEquals('Opportunities', resultList1[0].fromObject);
  }

  @IsTest
  static void testBuildQuerySelectList_aggregate() {
    // Aggregate query with multiple aggregate functions
    String q2 =
      'SELECT MIN(Amount) minAmt, MAX(Amount) maxAmt, AccountId Id FROM Opportunity' +
      ' GROUP BY AccountId';
    DocumentQueryFieldParser p2 = new DocumentQueryFieldParser(q2);

    Test.startTest();
    List<DocumentQueryFieldParser.QuerySelect> resultList2 = p2.buildQuerySelectList(q2);
    Test.stopTest();

    // q2
    System.assertEquals(1, resultList2.size());
    System.assertEquals(0, resultList2[0].selectNum);
    System.assertEquals(0, resultList2[0].fromNum);
    System.assertEquals('Opportunity', resultList2[0].fromObject);
  }

  @IsTest
  static void testBuildQuerySelectList_multipleSubqueries() {
    // Multiple subqueries
    String q3 =
      'SELECT Id, Name,(SELECT Id, FirstName, LastName, Email FROM Contacts)' +
      ',     (    SELECT    Id, Name, CloseDate, Amount FROM Opportunities WHERE Amount != NULL)' +
      ' FROM Account WHERE Id IN (     SELECT AccountId FROM Opportunities)';

    DocumentQueryFieldParser p3 = new DocumentQueryFieldParser(q3);

    Test.startTest();
    List<DocumentQueryFieldParser.QuerySelect> resultList3 = p3.buildQuerySelectList(q3);
    Test.stopTest();

    // q3
    System.assertEquals(4, resultList3.size());

    System.assertEquals(0, resultList3[0].selectNum);
    System.assertEquals(2, resultList3[0].fromNum);
    System.assertEquals('Account', resultList3[0].fromObject);

    System.assertEquals(1, resultList3[1].selectNum);
    System.assertEquals(0, resultList3[1].fromNum);
    System.assertEquals('Contacts', resultList3[1].fromObject);

    System.assertEquals(2, resultList3[2].selectNum);
    System.assertEquals(1, resultList3[2].fromNum);
    System.assertEquals('Opportunities', resultList3[2].fromObject);

    System.assertEquals(3, resultList3[3].selectNum);
    System.assertEquals(3, resultList3[3].fromNum);
    System.assertEquals('Opportunities', resultList3[3].fromObject);
  }

  @IsTest
  static void testBuildQuerySelectList_withSelectField() {
    // Invalid field and handling the word select within a field
    String q4 =
      'SELECT selectName__c, LastName, Email FROM Contact' +
      ' WHERE Id IN (SELECT npsp__Primary_Contact__c FROM Opportunity)';

    DocumentQueryFieldParser p4 = new DocumentQueryFieldParser(q4);

    Test.startTest();
    List<DocumentQueryFieldParser.QuerySelect> resultList4 = p4.buildQuerySelectList(q4);
    Test.stopTest();

    // q4
    System.assertEquals(2, resultList4.size());

    System.assertEquals(0, resultList4[0].selectNum);
    System.assertEquals(0, resultList4[0].fromNum);
    System.assertEquals('Contact', resultList4[0].fromObject);

    System.assertEquals(1, resultList4[1].selectNum);
    System.assertEquals(1, resultList4[1].fromNum);
    System.assertEquals('Opportunity', resultList4[1].fromObject);
  }

  @IsTest
  static void testBasicPrimaryQueryParsing() {
    String queryString = 'SELECT Name, CloseDate, Amount FROM Opportunity';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(3, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Primary', resultList[0].source);
    System.assertEquals('Name', resultList[0].apiName);
    System.assertEquals(null, resultList[0].alias);
    //        System.assertEquals('Name', resultList[0].sfFieldLabel); // Not asserting the label because client wanted it changed
    System.assertEquals('Name', resultList[0].selectField);
    System.assertEquals('Opportunity', resultList[0].fromObject);
    System.assertEquals('', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Primary', resultList[1].source);
    System.assertEquals('CloseDate', resultList[1].apiName);
    System.assertEquals(null, resultList[1].alias);
    System.assertEquals('Close Date', resultList[1].sfFieldLabel);
    System.assertEquals('CloseDate', resultList[1].selectField);
    System.assertEquals('Opportunity', resultList[1].fromObject);
    System.assertEquals('date', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Primary', resultList[2].source);
    System.assertEquals('Amount', resultList[2].apiName);
    System.assertEquals(null, resultList[2].alias);
    // System.assertEquals('Amount (USD)', resultList[2].sfFieldLabel);
    System.assertEquals('Amount', resultList[2].selectField);
    System.assertEquals('Opportunity', resultList[2].fromObject);
    System.assertEquals('currency', resultList[2].dataType);
  }

  @IsTest
  static void testParsingWithSpacing() {
    // NOTE: This also tests that the query string is trimmed first
    String queryString = '( SELECT     Id,         Name     , CloseDate, Amount,           AccountId FROM Opportunity )';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(5, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Primary', resultList[0].source);
    System.assertEquals('Id', resultList[0].apiName);
    System.assertEquals(null, resultList[0].alias);
    //        System.assertEquals('Opportunity ID', resultList[0].sfFieldLabel); // Not asserting the label because client wanted it changed
    System.assertEquals('Id', resultList[0].selectField);
    System.assertEquals('Opportunity', resultList[0].fromObject);
    System.assertEquals('', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Primary', resultList[1].source);
    System.assertEquals('Name', resultList[1].apiName);
    System.assertEquals(null, resultList[1].alias);
    //        System.assertEquals('Name', resultList[1].sfFieldLabel); // Not asserting the label because client wanted it changed
    System.assertEquals('Name', resultList[1].selectField);
    System.assertEquals('Opportunity', resultList[1].fromObject);
    System.assertEquals('', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Primary', resultList[2].source);
    System.assertEquals('CloseDate', resultList[2].apiName);
    System.assertEquals(null, resultList[2].alias);
    System.assertEquals('Close Date', resultList[2].sfFieldLabel);
    System.assertEquals('CloseDate', resultList[2].selectField);
    System.assertEquals('Opportunity', resultList[2].fromObject);
    System.assertEquals('date', resultList[2].dataType);

    System.assertEquals(3, resultList[3].index);
    System.assertEquals('Primary', resultList[3].source);
    System.assertEquals('Amount', resultList[3].apiName);
    System.assertEquals(null, resultList[3].alias);
    // System.assertEquals('Amount (USD)', resultList[3].sfFieldLabel);
    System.assertEquals('Amount', resultList[3].selectField);
    System.assertEquals('Opportunity', resultList[3].fromObject);
    System.assertEquals('currency', resultList[3].dataType);

    System.assertEquals(4, resultList[4].index);
    System.assertEquals('Primary', resultList[4].source);
    System.assertEquals('AccountId', resultList[4].apiName);
    System.assertEquals(null, resultList[4].alias);
    System.assertEquals('Account ID', resultList[4].sfFieldLabel);
    System.assertEquals('AccountId', resultList[4].selectField);
    System.assertEquals('Opportunity', resultList[4].fromObject);
    System.assertEquals('', resultList[4].dataType);
  }

  @IsTest
  static void testParentFieldTraversalParsing() {
    String queryString = 'SELECT Id, Name, CloseDate, Account.Name FROM Opportunity';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(4, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Primary', resultList[0].source);
    System.assertEquals('Id', resultList[0].apiName);
    System.assertEquals(null, resultList[0].alias);
    //        System.assertEquals('Opportunity ID', resultList[0].sfFieldLabel);
    System.assertEquals('Id', resultList[0].selectField);
    System.assertEquals('Opportunity', resultList[0].fromObject);
    System.assertEquals('', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Primary', resultList[1].source);
    System.assertEquals('Name', resultList[1].apiName);
    System.assertEquals(null, resultList[1].alias);
    //        System.assertEquals('Name', resultList[1].sfFieldLabel);
    System.assertEquals('Name', resultList[1].selectField);
    System.assertEquals('Opportunity', resultList[1].fromObject);
    System.assertEquals('', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Primary', resultList[2].source);
    System.assertEquals('CloseDate', resultList[2].apiName);
    System.assertEquals(null, resultList[2].alias);
    System.assertEquals('Close Date', resultList[2].sfFieldLabel);
    System.assertEquals('CloseDate', resultList[2].selectField);
    System.assertEquals('Opportunity', resultList[2].fromObject);
    System.assertEquals('date', resultList[2].dataType);

    System.assertEquals(3, resultList[3].index);
    System.assertEquals('Parent', resultList[3].source);
    System.assertEquals('Account.Name', resultList[3].apiName);
    System.assertEquals(null, resultList[3].alias);
    System.assertEquals('Account ID Account Name', resultList[3].sfFieldLabel);
    System.assertEquals('Account.Name', resultList[3].selectField);
    System.assertEquals('Opportunity', resultList[3].fromObject);
    System.assertEquals('', resultList[3].dataType);
  }

  @IsTest
  static void testAggregateQueryParsing() {
    String queryString = 'SELECT MIN(Amount) minAmt, MAX(Amount) maxAmt, AccountId Id FROM Opportunity';
    queryString += ' GROUP BY AccountId';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(3, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Aggregate', resultList[0].source);
    System.assertEquals('Amount', resultList[0].apiName);
    System.assertEquals('minAmt', resultList[0].alias);
    // System.assertEquals('Amount (USD)', resultList[0].sfFieldLabel);
    System.assertEquals('MIN(Amount) minAmt', resultList[0].selectField);
    System.assertEquals('Opportunity', resultList[0].fromObject);
    System.assertEquals('currency', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Aggregate', resultList[1].source);
    System.assertEquals('Amount', resultList[1].apiName);
    System.assertEquals('maxAmt', resultList[1].alias);
    // System.assertEquals('Amount (USD)', resultList[1].sfFieldLabel);
    System.assertEquals('MAX(Amount) maxAmt', resultList[1].selectField);
    System.assertEquals('Opportunity', resultList[1].fromObject);
    System.assertEquals('currency', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Aggregate', resultList[2].source);
    System.assertEquals('AccountId', resultList[2].apiName);
    System.assertEquals('Id', resultList[2].alias);
    System.assertEquals('Account ID', resultList[2].sfFieldLabel);
    System.assertEquals('AccountId Id', resultList[2].selectField);
    System.assertEquals('Opportunity', resultList[2].fromObject);
    System.assertEquals('', resultList[2].dataType);
  }

  @IsTest
  static void testAggregateQueryParsing_multipleGroupBys() {
    String queryString = 'SELECT SUM(Amount) Total_Amount, AccountId Id, CALENDAR_MONTH(CloseDate) Month FROM Opportunity';
    queryString += ' GROUP BY AccountId, CALENDAR_MONTH(CloseDate)';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(3, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Aggregate', resultList[0].source);
    System.assertEquals('Amount', resultList[0].apiName);
    System.assertEquals('Total_Amount', resultList[0].alias);
    // System.assertEquals('Amount (USD)', resultList[0].sfFieldLabel);
    System.assertEquals('SUM(Amount) Total_Amount', resultList[0].selectField);
    System.assertEquals('Opportunity', resultList[0].fromObject);
    System.assertEquals('currency', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Aggregate', resultList[1].source);
    System.assertEquals('AccountId', resultList[1].apiName);
    System.assertEquals('Id', resultList[1].alias);
    System.assertEquals('Account ID', resultList[1].sfFieldLabel);
    System.assertEquals('AccountId Id', resultList[1].selectField);
    System.assertEquals('Opportunity', resultList[1].fromObject);
    System.assertEquals('', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Aggregate', resultList[2].source);
    System.assertEquals('CloseDate', resultList[2].apiName);
    System.assertEquals('Month', resultList[2].alias);
    System.assertEquals('Close Date', resultList[2].sfFieldLabel);
    System.assertEquals('CALENDAR_MONTH(CloseDate) Month', resultList[2].selectField);
    System.assertEquals('Opportunity', resultList[2].fromObject);
    System.assertEquals('date', resultList[2].dataType);
  }

  @IsTest
  static void testTraverseParentInSubquery() {
    String queryString = 'SELECT Id, (SELECT npsp__Primary_Contact__r.Name FROM Opportunities) FROM Account';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(2, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Primary', resultList[0].source);
    System.assertEquals('Id', resultList[0].apiName);
    System.assertEquals(null, resultList[0].alias);
    System.assertEquals('Account ID', resultList[0].sfFieldLabel);
    System.assertEquals('Id', resultList[0].selectField);
    System.assertEquals('Account', resultList[0].fromObject);
    System.assertEquals('', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Subquery', resultList[1].source);
    System.assertEquals('Opportunities.npsp__Primary_Contact__r.Name', resultList[1].apiName);
    System.assertEquals(null, resultList[1].alias);
    System.assertEquals('Opportunities.Primary Contact Full Name', resultList[1].sfFieldLabel);
    System.assertEquals('npsp__Primary_Contact__r.Name', resultList[1].selectField);
    System.assertEquals('Opportunities', resultList[1].fromObject);
    System.assertEquals('', resultList[1].dataType);
  }

  @IsTest
  static void testSubqueryParsing() {
    String queryString =
      'SELECT Id, (SELECT Id, FirstName, LastName, Email FROM Contacts)' +
      ',     (    SELECT    Id, Name, CloseDate, Amount, npsp__Primary_Contact__r.Name FROM Opportunities)' +
      ',Name FROM Account WHERE Id IN (     SELECT AccountId FROM Opportunities)';

    Test.startTest();
    List<DocumentQueryFieldParser.DocumentQueryField> resultList = executeParser(queryString);
    Test.stopTest();

    System.assertEquals(11, resultList.size());

    System.assertEquals(0, resultList[0].index);
    System.assertEquals('Primary', resultList[0].source);
    System.assertEquals('Id', resultList[0].apiName);
    System.assertEquals(null, resultList[0].alias);
    System.assertEquals('Account ID', resultList[0].sfFieldLabel);
    System.assertEquals('Id', resultList[0].selectField);
    System.assertEquals('Account', resultList[0].fromObject);
    System.assertEquals('', resultList[0].dataType);

    System.assertEquals(1, resultList[1].index);
    System.assertEquals('Subquery', resultList[1].source);
    System.assertEquals('Contacts.Id', resultList[1].apiName);
    System.assertEquals(null, resultList[1].alias);
    System.assertEquals('Contacts.Contact ID', resultList[1].sfFieldLabel);
    System.assertEquals('Id', resultList[1].selectField);
    System.assertEquals('Contacts', resultList[1].fromObject);
    System.assertEquals('', resultList[1].dataType);

    System.assertEquals(2, resultList[2].index);
    System.assertEquals('Subquery', resultList[2].source);
    System.assertEquals('Contacts.FirstName', resultList[2].apiName);
    System.assertEquals(null, resultList[2].alias);
    System.assertEquals('Contacts.First Name', resultList[2].sfFieldLabel);
    System.assertEquals('FirstName', resultList[2].selectField);
    System.assertEquals('Contacts', resultList[2].fromObject);
    System.assertEquals('', resultList[2].dataType);

    System.assertEquals(3, resultList[3].index);
    System.assertEquals('Subquery', resultList[3].source);
    System.assertEquals('Contacts.LastName', resultList[3].apiName);
    System.assertEquals(null, resultList[3].alias);
    System.assertEquals('Contacts.Last Name', resultList[3].sfFieldLabel);
    System.assertEquals('LastName', resultList[3].selectField);
    System.assertEquals('Contacts', resultList[3].fromObject);
    System.assertEquals('', resultList[3].dataType);

    System.assertEquals(4, resultList[4].index);
    System.assertEquals('Subquery', resultList[4].source);
    System.assertEquals('Contacts.Email', resultList[4].apiName);
    System.assertEquals(null, resultList[4].alias);
    System.assertEquals('Contacts.Email', resultList[4].sfFieldLabel);
    System.assertEquals('Email', resultList[4].selectField);
    System.assertEquals('Contacts', resultList[4].fromObject);
    System.assertEquals('', resultList[4].dataType);

    System.assertEquals(5, resultList[5].index);
    System.assertEquals('Subquery', resultList[5].source);
    System.assertEquals('Opportunities.Id', resultList[5].apiName);
    System.assertEquals(null, resultList[5].alias);
    //        System.assertEquals('Opportunities.Opportunity ID', resultList[5].sfFieldLabel);
    System.assertEquals('Id', resultList[5].selectField);
    System.assertEquals('Opportunities', resultList[5].fromObject);
    System.assertEquals('', resultList[5].dataType);

    System.assertEquals(6, resultList[6].index);
    System.assertEquals('Subquery', resultList[6].source);
    System.assertEquals('Opportunities.Name', resultList[6].apiName);
    System.assertEquals(null, resultList[6].alias);
    //        System.assertEquals('Opportunities.Name', resultList[6].sfFieldLabel);
    System.assertEquals('Name', resultList[6].selectField);
    System.assertEquals('Opportunities', resultList[6].fromObject);
    System.assertEquals('', resultList[6].dataType);

    System.assertEquals(7, resultList[7].index);
    System.assertEquals('Subquery', resultList[7].source);
    System.assertEquals('Opportunities.CloseDate', resultList[7].apiName);
    System.assertEquals(null, resultList[7].alias);
    System.assertEquals('Opportunities.Close Date', resultList[7].sfFieldLabel);
    System.assertEquals('CloseDate', resultList[7].selectField);
    System.assertEquals('Opportunities', resultList[7].fromObject);
    System.assertEquals('date', resultList[7].dataType);

    System.assertEquals(8, resultList[8].index);
    System.assertEquals('Subquery', resultList[8].source);
    System.assertEquals('Opportunities.Amount', resultList[8].apiName);
    System.assertEquals(null, resultList[8].alias);
    // System.assertEquals('Opportunities.Amount (USD)', resultList[8].sfFieldLabel);
    System.assertEquals('Amount', resultList[8].selectField);
    System.assertEquals('Opportunities', resultList[8].fromObject);
    System.assertEquals('currency', resultList[8].dataType);

    System.assertEquals(9, resultList[9].index);
    System.assertEquals('Subquery', resultList[9].source);
    System.assertEquals('Opportunities.npsp__Primary_Contact__r.Name', resultList[9].apiName);
    System.assertEquals(null, resultList[9].alias);
    System.assertEquals('Opportunities.Primary Contact Full Name', resultList[9].sfFieldLabel);
    System.assertEquals('npsp__Primary_Contact__r.Name', resultList[9].selectField);
    System.assertEquals('Opportunities', resultList[9].fromObject);
    System.assertEquals('', resultList[9].dataType);

    System.assertEquals(10, resultList[10].index);
    System.assertEquals('Primary', resultList[10].source);
    System.assertEquals('Name', resultList[10].apiName);
    System.assertEquals(null, resultList[10].alias);
    System.assertEquals('Account Name', resultList[10].sfFieldLabel);
    System.assertEquals('Name', resultList[10].selectField);
    System.assertEquals('Account', resultList[10].fromObject);
    System.assertEquals('', resultList[10].dataType);
  }
}