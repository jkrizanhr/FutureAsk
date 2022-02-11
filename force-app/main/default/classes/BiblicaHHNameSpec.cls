/**
 * @author Candoris
 * @date 2021
 * @group Households
 * @description BiblicaHH_NameSpec class that implements template based naming for Households. This is a custom implementation
 * of the naming spec that allows for differing naming order between formal and informal greeting.
 */
global with sharing class BiblicaHHNameSpec implements npsp.HH_INaming {
  /*******************************************************************************************************
   * @description Get the Household name for the list of Contacts from a single Household.
   * Contacts who have set their npo02__Naming_Exclusions__c field to be excluded from the name, are not included in the list of Contacts.
   * If the list of Contacts is empty, returns the appropriate 'anonymous' name.
   * @param listCon the list of Contacts in the Household
   * @return the Household name
   */
  global string getHouseholdName(list<Contact> listCon) {
    NameSpec ns = new NameSpec(hns, 'npsp__Household_Name_Format__c');
    return strNameFromNameSpec(ns, listCon);
  }

  /*******************************************************************************************************
   * @description Get the Household Formal Greeting for the list of Contacts from a single Household.
   * Contacts who have set their npo02__Naming_Exclusions__c field to be excluded from the greeting, are not included in the list of Contacts.
   * If the list of Contacts is empty, returns the appropriate 'anonymous' greeting.
   * @param listCon the list of Contacts in the Household
   * @return the Household Formal Greeting
   */
  global string getHouseholdFormalGreeting(list<Contact> listCon) {
    List<Contact> reorderedList = [
      SELECT Id, FirstName, LastName, Salutation, Gender__c, NPSP_Formal_Greeting_Order__c
      FROM Contact
      WHERE Id IN :listCon
      ORDER BY NPSP_Formal_Greeting_Order__c ASC
    ];
    System.debug(reorderedList);
    NameSpec ns = new NameSpec(hns, 'npsp__Formal_Greeting_Format__c');
    return strNameFromNameSpec(ns, reorderedList);
  }

  /*******************************************************************************************************
   * @description Get the Household Informal Greeting for the list of Contacts from a single Household.
   * Contacts who have set their npo02__Naming_Exclusions__c field to be excluded from the greeting, are not included in the list of Contacts.
   * If the list of Contacts is empty, returns the appropriate 'anonymous' greeting.
   * @param listCon the list of Contacts in the Household
   * @return the Household Informal Greeting
   */
  global string getHouseholdInformalGreeting(list<Contact> listCon) {
    NameSpec ns = new NameSpec(hns, 'npsp__Informal_Greeting_Format__c');
    return strNameFromNameSpec(ns, listCon);
  }

  /*******************************************************************************************************
   * @description For the Settings page, get the formatted name or greeting for the list of Contacts.
   * @param hns an in-memory Household Naming Settings object
   * @param strField is one of: Household_Name_Format__c, Formal_Greeting_Format__c, or Informal_Greeting_Format__c.
   * @param listCon the list of Contacts in the Household
   * @return the appropriate Household name or greeting
   */
  global string getExampleName(
    npsp__Household_Naming_Settings__c hnsMem,
    string strField,
    list<Contact> listCon
  ) {
    NameSpec ns = new NameSpec(hnsMem, 'npsp__Household_Name_Format__c');
    return strNameFromNameSpec(ns, listCon);
  }

  /*******************************************************************************************************
   * @description To allow the NPSP code to know which fields to query for on Contact, before handing them off to the naming routines.
   * @return set of strings of all fields referenced from Contact.
   */
  global set<string> setHouseholdNameFieldsOnContact() {
    set<string> setStrField = new Set<string>{'NPSP_Formal_Greeting_Order__c'};
    NameSpec ns;
    ns = new NameSpec(hns, 'npsp__Household_Name_Format__c');
    setStrField.addAll(ns.setStrFieldsInNameSpec());
    ns = new NameSpec(hns, 'npsp__Formal_Greeting_Format__c');
    setStrField.addAll(ns.setStrFieldsInNameSpec());
    ns = new NameSpec(hns, 'npsp__Informal_Greeting_Format__c');
    setStrField.addAll(ns.setStrFieldsInNameSpec());
    return setStrField;
  }

  /*******************************************************************************************************
   * @description our cached copy of the Household Naming Settings
   */
  private npsp__Household_Naming_Settings__c hns {
    get {
      if (hns == null)
        hns = getHouseholdNamingSettings();
      return hns;
    }
    set;
  }

  private static string chLToken = '{!';
  private static string chRToken = '}';

  /*******************************************************************************************************
   * @description
   * Class that supports the parsing of a format string from the Household Naming Settings object.
   *
   * The NameSpec looks like:
   *      prefix {lastname} {{firstnamespec}} suffix
   * Where firstname spec is a combo of fields and literals like:
   *      {salutation} {firstname} ({mailingcity})
   *
   */
  private class NameSpec {
    private string strPrefix { get; set; }
    private string strSuffix { get; set; }
    private string strFirstNameSpec { get; set; }
    private string strFullNameSpec { get; set; }
    private string strAnd { get; set; }
    private string strOverrun { get; set; }
    private integer cMaxUseOverrun { get; set; }
    private string strHNSField { get; set; }

    /*******************************************************************************************************
     * @description NameSpec Constructor
     * @param hns An instance of Household Naming Settings to use.
     * @param strField The namespec field in Settings to use.
     */
    private NameSpec(npsp__Household_Naming_Settings__c hns, string strField) {
      strHNSField = strField;
      string strNameSpec = string.valueOf(hns.get(strField));
      strAnd = (hns.npsp__Name_Connector__c == null
        ? ' '
        : ' ' + hns.npsp__Name_Connector__c + ' ');
      strOverrun = hns.npsp__Name_Overrun__c;
      cMaxUseOverrun = integer.valueOf(hns.npsp__Contact_Overrun_Count__c);
      parseNameSpec(strNameSpec);
    }

    /*******************************************************************************************************
     * @description Given the namespec string, parses out its constituent parts, and sets them in the class.
     * @param strNameSpec The namespec
     */
    private void parseNameSpec(string strNameSpec) {
      strPrefix = '';
      strSuffix = '';
      strFirstNameSpec = '';
      strFullNameSpec = '';

      if (strNameSpec == null)
        return;

      // get optional Prefix
      integer ich = strNameSpec.indexOf(chLToken);
      if (ich > 0) {
        // don't include any tokens immediately next to the '{' in the prefix
        //while (ich > 0 && strNameSpec.substring(ich, ich+1) != ' ') ich--;
        strPrefix = strNameSpec.left(ich);
        strNameSpec = strNameSpec.substring(ich);
      }

      // get optional Suffix
      ich = strNameSpec.lastIndexOf(chRToken);
      if (ich > 0) {
        // don't include any tokens immediately after the '}' in the suffix
        while (ich < strNameSpec.length() - 1 && strNameSpec.substring(ich + 1, ich + 2) != ' ')
          ich++;
        strSuffix = strNameSpec.substring(ich + 1);
        strNameSpec = strNameSpec.left(ich + 1);
      }

      // extract FirstNameSpec
      string str = strFNameSpecFromStrNameSpec(strNameSpec);

      // replace the firstnamespec with a token in our fullnamespec
      ich = str.indexOf(chLToken);
      integer ichR = str.lastIndexOf(chRToken);
      if (ich >= 0 && ichR > 0) {
        strFullNameSpec = strNameSpec.replace(str, 'FirstNameSpec');
        strFirstNameSpec = str.substring(ich + chLToken.length(), ichR);
      } else {
        strFullNameSpec = strNameSpec;
      }
    }

    /*******************************************************************************************************
     * @description Returns a set of all field names in all parts of the namespec
     * @return string
     */
    public set<string> setStrFieldsInNameSpec() {
      set<string> setStrField = new Set<string>();
      if (strFirstNameSpec != null)
        setStrField.addAll(setStrFieldFromStrFSpec(strFirstNameSpec));
      if (strFullNameSpec != null)
        setStrField.addAll(setStrFieldFromStrFSpec(strFullNameSpec));
      setStrField.add('LastName');
      return setStrField;
    }
  }

  /*******************************************************************************************************
   * @description Given a namespec and a list of Contacts (assumed from a single household),
   * return the formated string for that household.
   * this can be used for any of the household strings (name, formal greeting, informal greeting).
   * @param ns The namespec class
   * @param listCon the list of Contacts in the Household
   * return string
   */
  private static string strNameFromNameSpec(NameSpec ns, list<Contact> listCon) {
    Integer cCon = listCon.size();
    Boolean isNoLastnames =
      ns.strFullNameSpec.toUpperCase().indexOf(chLToken + 'LASTNAME' + chRToken) == -1;
    Boolean isLastNameOnlyFormat = !isNoLastnames && ns.setStrFieldsInNameSpec().size() == 1;
    Set<String> processedLastNames = new Set<String>();
    String[] names = new List<String>(0);

    if (cCon == 0) {
      names.add(
        ns.strHNSField == 'npsp__Household_Name_Format__c'
          ? label.npo02.HouseholdAnonymousName
          : label.npo02.HouseholdAnonymousGreeting
      );
    }

    for (Integer i = 0, next = 0; i < cCon && i < ns.cMaxUseOverrun; i = next) {
      String strLname = listCon[i].LastName;
      next = i + 1;

      if (isLastNameOnlyFormat && processedLastNames.contains(strLname)) {
        continue;
      }
      processedLastNames.add(strLname);

      String strFname = strConFspec(listCon[i], ns.strFirstNameSpec);

      // get the set of additional fname's for this lname
      list<String> listFname = new List<String>();
      for (; next < cCon && (isNoLastnames || listCon[next].LastName == strLname); next++) {
        String nextFname = strConFspec(listCon[next], ns.strFirstNameSpec);

        if (nextFname != '') {
          listFName.add(nextFname);
        }
      }

      // now put those additional fname's together
      for (Integer k = 0; k < listFName.size(); k++) {
        // if we've hit the limit, then bail out
        if (i + k + 1 == ns.cMaxUseOverrun) {
          // reached max contact count limit
          next = ns.cMaxUseOverrun;
          break;
        }

        // we want to use And if this is the last person in this lastname, or the last one we will include
        if (k == listFName.size() - 1 || (!isNoLastnames && (i + k + 2) == ns.cMaxUseOverrun)) {
          strFname += ns.strAnd + listFName[k];
        } else {
          strFName += ', ' + listFname[k];
        }
      }

      // create lname part using first contact with that lastname
      String name = strConFSpec(listCon[i], ns.strFullNameSpec);
      name = name.replace('FirstNameSpec', strFname);
      if (strFname == '') {
        name = name.trim();
      }

      names.add(name);

      Boolean willAddOverrun =
        next >= ns.cMaxUseOverrun &&
        cCon > ns.cMaxUseOverrun &&
        ns.strFirstNameSpec != '' &&
        ns.strOverrun != null;

      if (willAddOverrun) {
        names.add(ns.strOverrun);
      }
    }

    return ns.strPrefix + buildName(ns, names) + ns.strSuffix;
  }

  /*******************************************************************************************************
   * @description Concatenate string out of individual formatted names.
   * @param ns The namespec class
   * @param names List of strings to concatenate
   * return string Concatenated string where names are separated by comma except
   * the last string is linked with the namespec's AND delimiter
   */
  private static String buildName(NameSpec ns, String[] names) {
    String name = '';
    String delimiter = '';
    Integer size = names.size();

    for (Integer i = 0; i < size; i++) {
      if (i > 0 && i == size - 1) {
        delimiter = ns.strAnd;
      } else if (i > 0) {
        delimiter = ', ';
      }
      name += delimiter + names[i];
    }

    return name;
  }

  /*******************************************************************************************************
   * @description Given a single contact and a namespec string, returns the formatted string filling
   * in fields in the namespec from the contact.
   * @param con The Contact
   * @param strFspec The namespec string
   * return string
   */
  private static string strConFspec(Contact con, string strFspec) {
    string str = strFspec;

    // First, instantiate a new Pattern object looking for {...} without any nested {'s.
    Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');
    // Then instantiate a new Matcher object
    Matcher MyMatcher = MyPattern.matcher(strFspec);

    while (MyMatcher.find()) {
      // get the fieldname without the {}'s
      string strField = strFspec.substring(
        MyMatcher.start() + chLToken.length(),
        MyMatcher.end() - chRToken.length()
      );

      //separate cross object references, i.e. account.name
      list<string> splitField = (strField.split('\\.', 0));

      //remove the field name itself to only include parent object references
      string fieldName = splitField[splitField.size() - 1].trim();
      splitField.remove(splitField.size() - 1);

      //use the correct sObject
      sObject thisObj;
      if (!splitField.isEmpty()) {
        thisObj = con.getsObject(splitField[0]);
        splitField.remove(0);
      } else {
        thisObj = con;
      }

      //traverse parent relationships until the last one
      for (string parentObj : splitField) {
        if (thisObj != null) {
          thisObj = thisObj.getsObject(parentObj);
        }
      }

      string val;
      if (thisObj != null) {
        val = string.valueOf(thisObj.get(fieldName));
      }

      // add back the {}'s for string substitution
      strField = chLToken + strField + chRToken;
      if (val == null) {
        // eat potential trailing space
        str = str.replace(strField + ' ', '');
        // eat potential leading space
        str = str.replace(' ' + strField, '');
      }
      str = str.replace(strField, val == null ? '' : val);
    }
    return str;
  }

  /*******************************************************************************************************
   * @description Given a namespec string, returns a set of contact fieldnames
   * specified in that string.
   * @param strFspec The namespec string
   * return set<string>
   */
  private static set<string> setStrFieldFromStrFSpec(string strFSpec) {
    set<string> setStrField = new Set<string>();

    // First, instantiate a new Pattern object looking for {...} without any nested {'s.
    Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');
    // Then instantiate a new Matcher object
    Matcher MyMatcher = MyPattern.matcher(strFSpec);

    while (MyMatcher.find()) {
      // get the fieldname without the {}'s
      string strField = strFSpec.substring(
        MyMatcher.start() + chLToken.length(),
        MyMatcher.end() - chRToken.length()
      );
      setStrField.add(strField.trim());
    }
    return setStrField;
  }

  /*******************************************************************************************************
   * @description Given a namespec string, returns the firstnamespec which is demarcated by an outer {! }
   * specified in that string.
   * @param strNameSpec The namespec string, ie. {!lastname} {! {!firstname} foo {!bar}} Family
   * return string The firstnamespec string, ie. {! {!firstname} foo {!bar}}
   */
  private static string strFNameSpecFromStrNameSpec(string strNameSpec) {
    // First, instantiate a new Pattern object looking for {! {! xxxx } }
    Pattern MyPattern = Pattern.compile('\\{![^\\}]*\\{!.*\\}[^\\{!]*\\}');
    // Then instantiate a new Matcher object
    Matcher MyMatcher = MyPattern.matcher(strNameSpec);

    if (MyMatcher.find()) {
      return strNameSpec.substring(MyMatcher.start(), MyMatcher.end());
    } else {
      return '';
    }
  }

  static npsp__Household_Naming_Settings__c householdNamingSettings;
  static npsp__Household_Naming_Settings__c orgHouseholdNamingSettings;

  global static npsp__Household_Naming_Settings__c getHouseholdNamingSettings() {
    if (Test.isRunningTest() && householdNamingSettings == null) {
      householdNamingSettings = new npsp__Household_Naming_Settings__c();
      configHouseholdNamingSettings(householdNamingSettings);
    } else if (householdNamingSettings == null) {
      householdNamingSettings = npsp__Household_Naming_Settings__c.getInstance();
      if (householdNamingSettings.Id == null)
        householdNamingSettings = getOrgHouseholdNamingSettings();
    }
    return householdNamingSettings;
  }

  global static npsp__Household_Naming_Settings__c getOrgHouseholdNamingSettings() {
    if (orgHouseholdNamingSettings == null) {
      orgHouseholdNamingSettings = npsp__Household_Naming_Settings__c.getOrgDefaults();
      if (orgHouseholdNamingSettings.Id == null) {
        configHouseholdNamingSettings(orgHouseholdNamingSettings);
        if (!Test.isRunningTest())
          upsert orgHouseholdNamingSettings;
      }
    }
    return orgHouseholdNamingSettings;
  }
  private static void configHouseholdNamingSettings(npsp__Household_Naming_Settings__c hns) {
    hns.npsp__Household_Name_Format__c = '{!LastName} ' + label.npo02.DefaultHouseholdName;
    hns.npsp__Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
    hns.npsp__Informal_Greeting_Format__c = '{!{!FirstName}}';
    hns.npsp__Name_Connector__c = label.npo02.HouseholdNameConnector;
    hns.npsp__Name_Overrun__c = label.npo02.HouseholdNameOverrun;
    hns.npsp__Contact_Overrun_Count__c = 9;
    hns.npsp__Implementing_Class__c = 'BiblicaHHNameSpec';
  }
}