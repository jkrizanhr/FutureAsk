public class DocumentGenerationQueryHelper {
  private Document_Template_Query__c templateQuery;
  private String queryString;
  public List<String> appendWhereClauseList;
  public String replacementWhereClause;

  public DocumentGenerationQueryHelper(Document_Template_Query__c templateQuery) {
    this.templateQuery = templateQuery;
    this.queryString = templateQuery.SOQL_Query__c;
  }

  public String buildSelectCountQueryString(List<String> recordIds) {
    flattenQueryString();
    replaceWhereClauseOverride();
    appendWhereClauseOverride();
    injectRecordIdFilter(recordIds);
    List<String> queryStringList = new List<String>{ 'SELECT COUNT() ' };
    if (String.isNotBlank(this.templateQuery.FROM_Object__c)) {
      queryStringList.add('FROM ' + this.templateQuery.FROM_Object__c);
    }
    if (
      String.isNotBlank(this.templateQuery.WHERE_Clause__c) &&
      this.templateQuery.WHERE_Clause__c.trim() != 'WHERE'
    ) {
      queryStringList.add(this.templateQuery.WHERE_Clause__c);
    }
    this.queryString = String.join(queryStringList, ' ');
    return this.queryString;
  }

  public String buildPrimarySOQLQueryString(List<String> recordIds, String additionalSelectField) {
    flattenQueryString();
    replaceWhereClauseOverride();
    appendWhereClauseOverride();
    injectRecordIdFilter(recordIds);
    injectSelectField(additionalSelectField);
    buildQueryString();
    return this.queryString;
  }

  public String buildSOQLQueryString() {
    flattenQueryString();
    replaceWhereClauseOverride();
    appendWhereClauseOverride();
    buildQueryString();
    return this.queryString;
  }

  private void flattenQueryString() {
    if (String.isNotBlank(this.queryString)) {
      List<String> queryStringList = this.queryString.split('\n');
      this.queryString = String.join(queryStringList, ' ');
    }
  }

  /* Utility method */
  private void replaceWhereClauseOverride() {
    if (
      this.replacementWhereClause != null &&
      this.replacementWhereClause.equalsIgnoreCase('null') == false
    ) {
      this.templateQuery.WHERE_Clause__c = this.replacementWhereClause;
      if (
        String.isNotBlank(this.templateQuery.WHERE_Clause__c) &&
        this.templateQuery.WHERE_Clause__c.startsWithIgnoreCase('where') == false
      ) {
        this.templateQuery.WHERE_Clause__c = 'WHERE ' + this.templateQuery.WHERE_Clause__c;
      }
    }
  }

  /* Utility method */
  private void appendWhereClauseOverride() {
    if (this.appendWhereClauseList != null && this.appendWhereClauseList.isEmpty() == false) {
      for (String s : this.appendWhereClauseList) {
        if (String.isNotBlank(s) && s.equalsIgnoreCase('null') == false) {
          if (String.isNotBlank(this.templateQuery.WHERE_Clause__c)) {
            String appendString = ' AND (' + s + ')';
            if (this.templateQuery.WHERE_Clause__c.endsWithIgnoreCase(appendString) == false) {
              this.templateQuery.WHERE_Clause__c =
                'WHERE (' +
                this.templateQuery.WHERE_Clause__c.substringAfter('WHERE') +
                ')';
              this.templateQuery.WHERE_Clause__c += appendString;
            }
          } else {
            this.templateQuery.WHERE_Clause__c = 'WHERE ' + s;
          }
        }
        System.debug('new where clause = ' + this.templateQuery.WHERE_Clause__c);
      }
    }
  }

  /* For the Primary SOQL Query */
  private void injectRecordIdFilter(List<String> recordIds) {
    String recordIdFilter = 'WHERE Id IN :recordIds';

    if (
      recordIds != null &&
      recordIds.isEmpty() == false &&
      String.isNotBlank(this.queryString) &&
      this.templateQuery != null
    ) {
      if (
        String.isNotBlank(this.templateQuery.WHERE_Clause__c) &&
        this.templateQuery.WHERE_Clause__c.trim() != 'WHERE' &&
        this.templateQuery.WHERE_Clause__c != recordIdFilter
      ) {
        // Append record Id filter to the existing where clause
        String initialWhereClause = this.templateQuery.WHERE_Clause__c.substringAfter('WHERE');
        String newWhereClause = 'WHERE ' + initialWhereClause + ' AND Id IN :recordIds';
        this.templateQuery.WHERE_Clause__c = newWhereClause;
      } else {
        this.templateQuery.WHERE_Clause__c = recordIdFilter;
      }
    }
  }

  /* For the Primary SOQL Query to ensure that the Email_Recipient_Field_Path__c will be retrieved */
  private void injectSelectField(String selectField) {
    if (String.isNotBlank(selectField)) {
      if (selectField.startsWith('{!')) {
        selectField = selectField.replace('{!', '').replace('}', '');
      }
      if (String.isNotBlank(this.templateQuery.SELECT_Statement__c)) {
        if (this.templateQuery.SELECT_Statement__c.indexOfIgnoreCase(selectField) == -1) {
          this.templateQuery.SELECT_Statement__c += ', ' + selectField;
        }
      } else {
        this.templateQuery.SELECT_Statement__c = 'SELECT ' + selectField;
      }
    }
  }

  private void buildQueryString() {
    List<String> queryStringList = new List<String>{ this.templateQuery.SELECT_Statement__c };
    if (String.isNotBlank(this.templateQuery.FROM_Object__c)) {
      queryStringList.add('FROM ' + this.templateQuery.FROM_Object__c);
    }
    if (
      String.isNotBlank(this.templateQuery.WHERE_Clause__c) &&
      this.templateQuery.WHERE_Clause__c.trim() != 'WHERE'
    ) {
      queryStringList.add(this.templateQuery.WHERE_Clause__c);
    }
    if (String.isNotBlank(this.templateQuery.GROUP_BY_Statement__c)) {
      queryStringList.add(this.templateQuery.GROUP_BY_Statement__c);
    }
    if (String.isNotBlank(this.templateQuery.HAVING_Statement__c)) {
      queryStringList.add(this.templateQuery.HAVING_Statement__c);
    }
    if (String.isNotBlank(this.templateQuery.ORDER_BY_Statement__c)) {
      queryStringList.add(this.templateQuery.ORDER_BY_Statement__c);
    }
    if (this.templateQuery.LIMIT__c != null && this.templateQuery.LIMIT__c > 0) {
      queryStringList.add('LIMIT ' + this.templateQuery.LIMIT__c);
    }
    this.queryString = String.join(queryStringList, ' ');
  }
}