public class DocumentQueryFieldParser {
  private String queryString;
  private List<DocumentQueryField> queryFieldList;
  private String primaryObject;
  private Map<Integer, QuerySelect> querySelectMap;

  public class DocumentQueryField {
    public String selectField;
    public String sfFieldLabel;
    public String apiName;
    public String alias;
    public String dataType;
    public String source; // Primary, Aggregate, Parent, Subquery
    public String fromObject; // API name of the object the field is on
    public Integer index; // The place in query string
    public Integer selectNum;
  }

  /*
  Serves as a mapper so that when we find a select, we will also have the object name
  for the that the fields that follow.
  In doing so, we don't have to backtrack and update the DocumentQueryFields
  after finally reaching the from object.
   */
  public class QuerySelect {
    public Integer selectNum;
    public Integer fromNum;
    public String fromObject;
  }

  public DocumentQueryFieldParser(String queryString) {
    this.queryString = queryString;
    this.queryFieldList = new List<DocumentQueryField>();

  }

  public List<DocumentQueryField> getDocumentQueryFields() {
    return this.queryFieldList;
  }

  public Map<Integer, DocumentQueryField> getQueryFieldIndexMap() {
    Map<Integer, DocumentQueryField> queryFieldIndexMap = new Map<Integer, DocumentQueryField>();
    for (DocumentQueryField qField : this.queryFieldList) {
      queryFieldIndexMap.put(qField.index, qField);
    }
    return queryFieldIndexMap;
  }

  private Boolean validateQueryString() {
    if (String.isBlank(this.queryString)) {
      return false;
    }
    return true;
  }

  /*
  * Remove line breaks
  * Remove excess spacing
  * Trim to remove whitespaces on ends of the string
   */
  private void cleanUpQueryString() {
    List<String> queryNewLineSplit = this.queryString.split('\n');
    this.queryString = String.join(queryNewLineSplit, ' ');
    List<String> querySpaceSplit = this.queryString.split('  ');
    this.queryString = '';
    for (String str : querySpaceSplit) {
      if (String.isEmpty(str) == false) {
        queryString += str + ' ';
      }
    }
    this.queryString = this.queryString.trim();
  }

  public void parseQueryString() {
    if (validateQueryString() == false) {
      return;
    }

    cleanUpQueryString();
    List<QuerySelect> querySelectList = buildQuerySelectList(this.queryString);
    buildQuerySelectMap(querySelectList);
    setFromObject();
//        this.primaryObject = parseFromObject(this.queryString); // Not used but does work!

    Integer lastFromNum = 0;
    if (querySelectList.isEmpty() == false) {
      lastFromNum = querySelectList[0].fromNum;
    }

    Integer selectNum = 0;
    QuerySelect qs;
    List<String> querySplitList = this.queryString.split(',');
    Boolean lastFieldFound = false;

    for (String queryStrPart : querySplitList) {
      String str = queryStrPart;

      if (String.isBlank(queryStrPart)) {
        continue;
      }

      if (lastFieldFound == true) {
        return;
      }

      if (queryStrPart.containsIgnoreCase(' from ')) {
        Integer fromIndex = queryStrPart.indexOfIgnoreCase(' from ');
        queryStrPart = queryStrPart.substring(0, fromIndex);
        if (qs != null && qs.selectNum == 0) {
          lastFieldFound = true;
        }
      }
      if (queryStrPart.containsIgnoreCase('select ')) {
        Integer selectIndex = queryStrPart.indexOfIgnoreCase('select ');
        String selectString = 'select ';
        queryStrPart = queryStrPart.substring(selectIndex + selectString.length());
        if (this.querySelectMap.containsKey(selectNum)) {
          qs = this.querySelectMap.get(selectNum);
          if (qs.fromNum > lastFromNum) {
            // Any remaining QuerySelects are in the where clause
            // and so we don't need those fields.
            break;
          }
        }
        selectNum++;
      }
      queryStrPart = queryStrPart.trim();

      DocumentQueryField dqField = new DocumentQueryField();
      dqField.selectField = queryStrPart.trim();
      dqField.selectNum = qs.selectNum;
      setDocQueryFieldProperties(dqField, qs);
      this.queryFieldList.add(dqField);

      if (str.contains(')') && str.containsIgnoreCase(' from ')) {
        // Found the end of a subquery, there may be additional primary query fields left
        qs = this.querySelectMap.get(0);
      }
    }
  }

  private void setDocQueryFieldProperties(DocumentQueryField dqField, QuerySelect qs) {
    dqField.fromObject = qs.fromObject;
    dqField.index = this.queryFieldList.size();

    if (dqField.selectField.contains('(') && dqField.selectField.contains(')')) {
      // Aggregate function
      String s = dqField.selectField.substringBetween('(', ')');
      dqField.apiName = s.trim();
    }
    if (dqField.selectField.contains(' ')) {
      List<String> strs = dqField.selectField.split(' ');
      dqField.alias = strs[strs.size() - 1].trim();
      if (String.isBlank(dqField.apiName)) {
        dqField.apiName = strs[0].trim();
      }
    }
    if (String.isBlank(dqField.apiName)) {
      dqField.apiName = dqField.selectField.trim();
    }

    if (qs.selectNum == 0 && dqField.selectField.contains('.') == false) {
      buildPrimaryObjectQueryField(dqField);
    } else if (dqField.selectField.contains('.')) {
      buildParentObjectQueryField(dqField, qs);
    } else {
      buildSubqueryObjectQueryField(dqField, qs);
    }
  }

  private void buildPrimaryObjectQueryField(DocumentQueryField dqField) {
    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(this.primaryObject);
    Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();

    if (this.queryString.containsIgnoreCase('group by')) {
      dqField.source = 'Aggregate';
    } else {
      dqField.source = 'Primary';
    }

    Map<String, Object> fieldMap = sObjResult.fields.getMap();
    if (fieldMap.containsKey(dqField.apiName)) {
      Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(dqField.apiName).getDescribe();
      dqField.sfFieldLabel = fieldResult.getLabel();
      dqField.apiName = fieldResult.getName();
      dqField.dataType = getDataType(this.primaryObject, dqField.apiName);
    }
  }

  private void buildParentObjectQueryField(DocumentQueryField dqField, QuerySelect qs) {
    dqField.source = 'Parent';
    List<String> fieldSplit = dqField.selectField.split('\\.');
    // Get the fromNum for the current field
    Integer currentObjectNum = qs.fromNum;
    // Get the fromNum for the first select
    QuerySelect primaryQuerySelect = this.querySelectMap.get(0);
    Integer primaryObjectNum = primaryQuerySelect.fromNum;

    // The parent relationship field is in a subquery
    if (currentObjectNum != primaryObjectNum) {
      dqField.source = 'Subquery';
      String str = dqField.fromObject + '.' + dqField.selectField;
      fieldSplit = str.split('\\.');
    }

    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(this.primaryObject);
    Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();

    for (Integer i = 0; i < fieldSplit.size(); i++) {
      String field = fieldSplit[i].toLowerCase();

      // Get the fields for the current SObject Type
      Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
      if (i == fieldSplit.size() - 1) {
        if (fieldMap.containsKey(field)) {
          sObjResult = sObjType.getDescribe();
          Schema.DescribeFieldResult fieldResult = fieldMap.get(field).getDescribe();
          dqField.apiName = dqField.apiName + '.' + fieldResult.getName();
          dqField.sfFieldLabel = dqField.sfFieldLabel + ' ' + fieldResult.getLabel();
          dqField.dataType = getDataType(sObjResult.getName(), fieldResult.getName());
        } else {
          return;
        }
      } else {
        // Traverse the object relationship
        Schema.SObjectType referencedObjectType = traverseObjectRelationship(sObjType, dqField, field);
        if (referencedObjectType == null) {
          // Parent object type reference not found. Searching child relationships...
          // Attempt to match the field with a child relationship name
          List<Schema.ChildRelationship> childRelationships = sObjType.getDescribe().getChildRelationships();
          for (Schema.ChildRelationship cr : childRelationships) {
            if (cr.getRelationshipName() == field) {
              // Child relationship matches the field
              referencedObjectType = cr.getChildSObject();
              dqField.sfFieldLabel = cr.getRelationshipName() + '.';
              dqField.apiName = cr.getRelationshipName();
              break;
            }
          }
          if (referencedObjectType == null) {
            return;
          }
        }
        sObjType = referencedObjectType;
      }
    }
  }

  private Schema.SObjectType traverseObjectRelationship(
      Schema.SObjectType sObjType,
      DocumentQueryField dqField,
      String field) {
    Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
    Schema.SObjectType referencedObjectType;

    for (Schema.SObjectField sObjField : fieldMap.values()) {
      if (String.isNotBlank(sObjField.getDescribe().getRelationshipName())) {

        if (sObjField.getDescribe().getRelationshipName().toLowerCase() == field) {
          // Relationship field found
          if (String.isBlank(dqField.sfFieldLabel)) {
            dqField.apiName = sObjField.getDescribe().getRelationshipName();
            dqField.sfFieldLabel = sObjField.getDescribe().getLabel();
          } else {
            dqField.apiName = dqField.apiName + '.' + sObjField.getDescribe().getRelationshipName();
            // Don't add a space when it's a parent object field after a child relationship name
            if (dqField.sfFieldLabel.indexOf('.') == dqField.sfFieldLabel.length() - 1) {
              dqField.sfFieldLabel = dqField.sfFieldLabel + sObjField.getDescribe().getLabel();
            } else {
              dqField.sfFieldLabel = dqField.sfFieldLabel + ' ' + sObjField.getDescribe().getLabel();
            }
          }
          referencedObjectType = sObjField.getDescribe().getReferenceTo()[0];
        }
      }
    }
    return referencedObjectType;
  }

  private void buildSubqueryObjectQueryField(DocumentQueryField dqField, QuerySelect qs) {
    dqField.source = 'Subquery';
    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(this.primaryObject);
    Schema.DescribeSObjectResult sObjResult = sObjType.getDescribe();
    List<Schema.ChildRelationship> crList = sObjResult.getChildRelationships();
    for (Schema.ChildRelationship cr : crList) {
      if (cr.getRelationshipName() != null) {
        String relationshipName = cr.getRelationshipName();
        if (relationshipName.toLowerCase() == qs.fromObject.toLowerCase()) {
          dqField.fromObject = relationshipName;
          setChildObjectResultFields(dqField, cr);
        }
      }
    }
  }

  private void setChildObjectResultFields(DocumentQueryField dqField, Schema.ChildRelationship cr) {
    SObjectType childType = cr.getChildSObject();
    Schema.DescribeSObjectResult childSObjectResult = childType.getDescribe();
    Map<String, Object> fieldMap = childSObjectResult.fields.getMap();

    if (fieldMap.containsKey(dqField.apiName)) {
      Schema.DescribeFieldResult fieldResult
          = childSObjectResult.fields.getMap().get(dqField.apiName).getDescribe();
      dqField.sfFieldLabel = cr.getRelationshipName() + '.' + fieldResult.getLabel();
      dqField.dataType = getDataType(childSObjectResult.getName(), dqField.apiName);
      dqField.apiName = cr.getRelationshipName() + '.' + fieldResult.getName();
    }
  }

  public String parseFromObject(String queryStrToParse) {
    queryStrToParse = queryStrToParse.toLowerCase();
    String fromObjectStr;
    Integer selectCount = 0;
    Integer fromCount = 0;
    List<String> strList = queryStrToParse.split(',');

    for (String chunk : strList) {
      chunk = chunk.trim();
      String chunkLowerCase = chunk.toLowerCase(); // Used to count matches of words
      if (chunk.containsIgnoreCase('select ')) {
        // Count the occurences of the word 'select' within the query string chunk
        // and add to the total count
        selectCount += chunkLowerCase.countMatches('select ');
      }
      // Count the occurences of the word 'from' within the query string chunk
      // and add to the total count
      if (chunk.containsIgnoreCase('from ')) {
        fromCount += chunkLowerCase.countMatches('from ');
        if (selectCount == fromCount) {
          // Match
          if (chunk.contains(')') && chunk.indexOf(')') < chunk.length() - 1) {
            // The last 'select field' is actually a subquery
            chunk = chunk.substring(chunk.indexOf(')'));
          }
          Integer fromIndex = chunk.indexOfIgnoreCase('from ');
          String fromString = 'from ';
          chunk = chunk.substring(fromIndex + fromString.length());
          List<String> endSubstring = chunk.split(' ');
          if (endSubstring.isEmpty() == false && endSubstring.size() > 0) {
            fromObjectStr = endSubstring[0].trim();
            return fromObjectStr;
          }
        }
      }
    }
    return fromObjectStr;
  }

  public List<QuerySelect> buildQuerySelectList(String inputString) {
    Integer selectNum = 0;
    String selectStr = 'select ';
    String fromStr = ' from ';
    String strToParseThru = inputString;
    Integer selectIndex = strToParseThru.indexOfIgnoreCase(selectStr);
    Integer lim = 100;
    Integer count = 0;
    List<QuerySelect> querySelectList = new List<QuerySelect>();

    // While the remaining string contains the word selectStr and
    // the original select is not paired with a from object.
    while (selectIndex != -1 && count < lim) {
      count++;

      QuerySelect querySelect = new QuerySelect();
      querySelect.selectNum = querySelectList.size();
      selectNum++;
      // Get the next index of the ' from '
      String newStr = strToParseThru.substring(selectIndex);
      Integer fromIndex = newStr.indexOfIgnoreCase(fromStr) + selectIndex;

      while (fromIndex != -1 && querySelect.fromNum == null && count < lim) {
        count++;
        // Get the number of times the word select appears between the current index and ' from ' index
        String strBetween = strToParseThru.substring(selectIndex, fromIndex);
        String lowerCaseStrBetween = strBetween.toLowerCase();
        Integer selectCount = lowerCaseStrBetween.countMatches(selectStr);
        Integer fromCount = lowerCaseStrBetween.countMatches(fromStr);

        // If once, including the current 'select ', then it's a match!
        if (selectCount == fromCount + 1) {
          // Match!
          // Set the fromNum on the QuerySelect object
          String strBefore = strToParseThru.substring(0, fromIndex);
          String lowerCaseStrBefore = strBefore.toLowerCase();
          querySelect.fromNum = lowerCaseStrBefore.countMatches(fromStr);
          String strAfterFrom = strToParseThru.substring(fromIndex);
          // Get the object name
          List<String> strParts = strAfterFrom.split(' ');

          for (String str : strParts) {
            if (String.isNotBlank(str) && str != fromStr.trim()) {
              if (str.contains(')')) {
                str = str.substringBefore(')');
              }
              str = str.replaceAll(',', '');
              querySelect.fromObject = str.trim();
              // Add the completed QuerySelect object to the list
              querySelectList.add(querySelect);
              // Find the next occurence of 'select '
              Integer newStartIndex = selectIndex + selectStr.length();
              // Find the next occurrence of 'select '
              String strRemaining = strToParseThru.substring(newStartIndex);
              selectIndex = strRemaining.indexOfIgnoreCase(selectStr) + newStartIndex;
              fromIndex = -1;
              // Break to return to step 1 in the outer-most loop to search for the next
              break;
            }
          }
        } else {
          // No match
          // The ' from ' found matches a different 'select '
          // Keep walking through the string and find the next index of ' from '
          // with the current index of ' from ' as the starting point.
          Integer newStartIndex = selectIndex + fromIndex + fromStr.length();
          if (newStartIndex >= strToParseThru.length()) {
            selectIndex = -1;
            fromIndex = -1;
            break;
          }
          String strRemaining = strToParseThru.substring(newStartIndex);
          fromIndex = strRemaining.indexOfIgnoreCase(fromStr) + newStartIndex;
          // Loop until a match or the end of the string is found.
        }
      }
    }
    return querySelectList;
  }

  private void buildQuerySelectMap(List<QuerySelect> querySelectList) {
    this.querySelectMap = new Map<Integer, QuerySelect>();
    for (QuerySelect qs : querySelectList) {
      this.querySelectMap.put(qs.selectNum, qs);
    }
  }

  private void setFromObject() {
    if (this.querySelectMap.isEmpty() == false && this.querySelectMap.containsKey(0)) {
      QuerySelect qs = this.querySelectMap.get(0);
      this.primaryObject = qs.fromObject;
    }
  }

  private String getDataType(String objectName, String fieldName) {
    // NOTE: Schema method parameters are case insensitive so objectName and fieldName can be upper or lower case.
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
    Schema.DescribeSObjectResult res = sObjectType.getDescribe();
    Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(fieldName).getDescribe();
    if (fieldResult.getType() == Schema.DisplayType.DATE) {
      return 'date';
    } else if (fieldResult.getType() == Schema.DisplayType.DATETIME) {
      return 'dateTime';
    } else if (fieldResult.getType() == Schema.DisplayType.CURRENCY) {
      return 'currency';
    } else if (fieldResult.getType() == Schema.DisplayType.PERCENT) {
      return 'percent';
    } else {
      return '';
    }
  }
}