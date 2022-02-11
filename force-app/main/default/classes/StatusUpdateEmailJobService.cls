public inherited sharing class StatusUpdateEmailJobService {
  /**
   * Gets and returns the Id of the organization wide email address.
   *
   * @return The Id of the organization wide email address.
   */
  private static String fetchOrgWideEmailAddressId() {
    List<OrgWideEmailAddress> orgEmailAddressList = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'noreply@biblica.com'
    ];

    if (!orgEmailAddressList.isEmpty()) {
      return orgEmailAddressList[0].Id;
    }
    return null;
  }

  /**
   * Builds a map that contains a list of sObjects keyed by their region.
   *
   * @param sObjectMap - A map of sObjects that have the Region__c field.
   * @return A map of a list of sObjects keyed by their region.
   */
  private static Map<String, List<sObject>> getRegionMap(Map<Id, sObject> sObjectMap) {
    Map<String, List<sObject>> mapToReturn = new Map<String, List<sObject>>();

    for (sObject sObj : sObjectMap.values()) {
      List<sObject> sObjList = mapToReturn.get((String) (sObj.get('Region__c')));
      if (sObjList == null) {
        mapToReturn.put((String) sObj.get('Region__c'), new List<sObject>{ sObj });
      } else {
        sObjList.add(sObj);
        mapToReturn.put((String) sObj.get('Region__c'), sObjList);
      }
    }

    return mapToReturn;
  }

  /**
   * Returns a list of Status Updates from the last seven days. If there are none in the last seven days, returns the most recent one.
   *
   * @param statusUpdates - A list of a Resource Order's Status Updates.
   * @return A list of Status Updates.
   */
  private static List<Status_Update__c> getStatusUpdatesToUse(
    List<Status_Update__c> statusUpdates
  ) {
    if (statusUpdates.isEmpty()) {
      return null;
    }

    List<Status_Update__c> statusUpdatesToUse = new List<Status_Update__c>();

    for (Status_Update__c statusUpdate : statusUpdates) {
      if (statusUpdate.Status_Update_Date__c >= Date.today().addDays(-7)) {
        statusUpdatesToUse.add(statusUpdate);
      }
    }

    if (statusUpdatesToUse.isEmpty()) {
      // Status Updates are ordered by date, with the most recent one being first in the list.
      statusUpdatesToUse.add(statusUpdates[0]);
    }

    return statusUpdatesToUse;
  }

  /**
   * Creates a String that represents a Resource Order's details, including Status Updates.
   *
   * @param resourceOrder - The Resource Order to get details from.
   * @return A String that represents the Resource Order's details including Status Updates.
   */
  private static String getDetailsForResource(Resource_Order__c resourceOrder) {
    String stringToReturn = '';

    if (resourceOrder.Project_Manager__c != null) {
      stringToReturn += resourceOrder.Project_Manager__r.Name + '\n';
    }

    if (resourceOrder.Status__c != null) {
      stringToReturn += resourceOrder.Name + ' — ' + resourceOrder.Status__c + '\n';
    } else {
      stringToReturn += resourceOrder.Name + '\n';
    }

    List<Status_Update__c> statusUpdatesToUse = getStatusUpdatesToUse(
      resourceOrder.Status_Updates__r
    );

    if (statusUpdatesToUse != null) {
      for (Status_Update__c statusUpdate : statusUpdatesToUse) {
        stringToReturn +=
          String.valueOf(statusUpdate.Status_Update_Date__c.format()) +
          ': ' +
          statusUpdate.Status_Update__c +
          '\n';
      }
    }

    stringToReturn += '\n';

    return stringToReturn;
  }

  /**
   * Creates and returns a map of Project Manager names as keys and their associated Resource Order Details as values.
   *
   * @param resourceOrderDetails - A list of Resource Order Details
   * @return A map of Project Manager names as keys and their associated Resource Order Details as values.
   */
  private static Map<String, List<String>> getPmToResourceOrderDetailsMap(
    List<String> resourceOrderDetails
  ) {
    Map<String, List<String>> pmToResourceOrderDetailsMap = new Map<String, List<String>>();

    for (String detail : resourceOrderDetails) {
      String pmName = detail.split('\n')[0];
      List<String> detailsFromMap = pmToResourceOrderDetailsMap.get(pmName);

      if (detailsFromMap == null) {
        pmToResourceOrderDetailsMap.put(pmName, new List<String>{ detail });
      } else {
        detailsFromMap.add(detail);
        pmToResourceOrderDetailsMap.put(pmName, detailsFromMap);
      }
    }

    return pmToResourceOrderDetailsMap;
  }

  /**
   * Builds a string to use as the plain text body in an email message.
   *
   * @param greeting - The greeting to be used in the email message.
   * @param resourceOrderDetails - A list of Resource Order Detail Strings.
   * @param prayerReqs - A list of Prayer Requests.
   * @return A plain text String to be used in an email message.
   */
  private static String buildPlainBody(
    String greeting,
    List<String> resourceOrderDetails,
    List<Prayer_Request__c> prayerReqs,
    String region
  ) {
    String plainBody = greeting + '\n\n';

    if (prayerReqs != null && !prayerReqs.isEmpty()) {
      plainBody +=
        'Below is a summary of the Resource Orders and Prayer Requests for the ' +
        region +
        ' region.\n';
    } else {
      plainBody += 'Below is a summary of the Resource Orders for the ' + region + ' region.\n';
    }

    for (String detail : resourceOrderDetails) {
      plainBody += detail.stripHtmlTags();
    }

    if (prayerReqs != null && !prayerReqs.isEmpty()) {
      plainBody += 'Prayer Requests: \n';

      for (Prayer_Request__c prayerReq : prayerReqs) {
        plainBody += prayerReq.Request__c + ': ' + prayerReq.Request_Explanation__c + '\n';

        if (prayerReq.Contact__c != null) {
          plainBody += '- Requested by ' + prayerReq.Contact__r.Name + '\n';
        } else if (prayerReq.Account__c != null) {
          plainBody += '- Requested by ' + prayerReq.Account__r.Name + '\n';
        }
      }
    }

    plainBody += 'Please let Sheri know of any Prayer Requests by email at Sheri.Greiner@biblica.com, or submit them in Salesforce via the Prayer Request object.';

    return plainBody;
  }

  /**
   * Returns inline CSS for higlighting text based on the status of a Resource Order.
   *
   * @param status - A string representing the Resource Order Status.
   * @return A CSS String
   */
  private static String getCssStyleForStatus(String status) {
    String trimmedStatus = status.trim();
    String style;

    if (trimmedStatus == 'Information Gathering') {
      style = 'style="background-color: yellow; color: black;"';
    } else if (trimmedStatus == 'Cost Estimate and Proposal') {
      style = 'style="background-color: cyan; color: black;"';
    } else if (trimmedStatus == 'Acceptance and Sales Agreement') {
      style = 'style="background-color: orange; color: black;"';
    } else if (trimmedStatus == 'Systems Update and Project Details') {
      style = 'style="background-color: blue; color: white;"';
    } else if (trimmedStatus == 'Production and Delivery') {
      style = 'style="background-color: teal; color: white;"';
    } else if (trimmedStatus == 'Final Invoice and Payment') {
      style = 'style="background-color: fuchsia; color: black;"';
    } else {
      style = 'style="background-color: white; color: black;"';
    }

    return style;
  }

  /**
   * Builds the Resource Order Detail section for a Project Managers Resource Order Details.
   *
   * @param resourceOrderDetails - A list of Resource Order Detail strings.
   * @return An HTML String to that displays Resource Order Details.
   */
  private static String buildHtmlDetailSection(List<String> resourceOrderDetails) {
    String htmlToReturn = '';

    for (String detail : resourceOrderDetails) {
      htmlToReturn += '<ul>';
      List<String> splitDetails = detail.split('\n');

      // List each status update under the Resource Order name.
      for (Integer i = 1; i < splitDetails.size(); i++) {
        // We do not care about the first detail line. That line only represents the PM name.
        String detailLine = splitDetails[i];

        if (i == 1) {
          // The second detail line is the Resource Order name and Status if there is one.
          String resourceOrderName = detailLine;

          // Color code the Resource Order Status in HTML.
          if (resourceOrderName.contains('—')) {
            String status = resourceOrderName.split('—')[1];
            String cssStyle = getCssStyleForStatus(status);
            String htmlStatus = '<span ' + cssStyle + '>' + status + '</span>';
            resourceOrderName =
              '<span style="font-size: 20px;">' +
              resourceOrderName.split('—')[0] +
              '</span> — ' +
              htmlStatus;
          }

          htmlToReturn += '<li>' + resourceOrderName + '</li><ul>';
        } else {
          // The following detail lines are the Resource Order status updates.
          htmlToReturn += '<li>' + detailLine.replace('<p>', '').replace('</p>', '') + '</li>';
        }
      }

      htmlToReturn += '</ul></ul>';
    }

    return htmlToReturn;
  }

  /**
   * Builds a string to use as the HTML body in an email message.
   *
   * @param greeting - The greeting to be used in the email message.
   * @param resourceOrderDetails - A list of Resource Order Detail Strings.
   * @param prayerReqs - A list of Prayer Requests.
   * @return An HTML String to be used in an email message.
   */
  private static String buildHtmlBody(
    String greeting,
    List<String> resourceOrderDetails,
    List<Prayer_Request__c> prayerReqs,
    String region
  ) {
    String html = '<p>' + greeting + '</p>';

    if (prayerReqs != null && !prayerReqs.isEmpty()) {
      html +=
        '<p>Below is a summary of the Resource Orders and Prayer Requests for the ' +
        region +
        ' region.</p>';
    } else {
      html += '<p>Below is a summary of the Resource Orders for the ' + region + ' region.</p>';
    }

    html += '<b><u>Resource Orders</u></b>';

    // Get a map of each Project Manager with their Resource Order Details
    Map<String, List<String>> pmToResourceOrderDetails = getPmToResourceOrderDetailsMap(
      resourceOrderDetails
    );

    for (String pmName : pmToResourceOrderDetails.keySet()) {
      html += '<p>' + pmName + '<p>';
      List<String> details = pmToResourceOrderDetails.get(pmName);

      html += buildHtmlDetailSection(details);
    }

    if (prayerReqs != null && !prayerReqs.isEmpty()) {
      html += '<b><u>Prayer Requests</u></b><ul>';

      for (Prayer_Request__c prayerReq : prayerReqs) {
        html +=
          '<li><b>' +
          prayerReq.Request__c +
          '</b>: ' +
          prayerReq.Request_Explanation__c +
          '</li>';

        if (prayerReq.Contact__c != null) {
          html += '<ul><li>Requested by ' + prayerReq.Contact__r.Name + '</li></ul>';
        } else if (prayerReq.Account__c != null) {
          html += '<ul><li>Requested by ' + prayerReq.Account__r.Name + '</li></ul>';
        }
      }

      html += '</ul>';
    }

    html += '<p><i>Please let Sheri know of any Prayer Requests by email at Sheri.Greiner@biblica.com, or submit them in Salesforce via the Prayer Request object.</i></p>';

    return html;
  }

  /**
   * Builds an email message from an Email Recipient, Resource Orders, and Prayer Requests.
   *
   * @param recipient - The Email Recipient for the email being built.
   * @param resourceOrderDetails - A list of Strings that repreresent Resource Order Details.
   * @param prayerReqs - A list of Prayer Requests to include in the email.
   * @return A Messaging.SingleEmailMessage object.
   */
  private static Messaging.SingleEmailMessage buildEmailMessage(
    Email_Recipient__c recipient,
    List<String> resourceOrderDetails,
    List<Prayer_Request__c> prayerReqs,
    String orgWideEmailAddressId
  ) {
    String plainBody = buildPlainBody(
      recipient.Greeting__c,
      resourceOrderDetails,
      prayerReqs,
      recipient.Region__c
    );
    String htmlBody = buildHtmlBody(
      recipient.Greeting__c,
      resourceOrderDetails,
      prayerReqs,
      recipient.Region__c
    );

    Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
    emailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
    emailMessage.setToAddresses(new List<String>{ recipient.Email__c });
    emailMessage.setSubject('Resource Order Status Updates for ' + recipient.Region__c);
    emailMessage.setPlainTextBody(plainBody);
    emailMessage.setHtmlBody(htmlBody);
    emailMessage.setSaveAsActivity(false);

    return emailMessage;
  }

  /**
   * Creates and sends emails to Email Recipients. This email contains Status Updates for Resource Orders and Prayer Requests, all per Region.
   *
   * @param resourceOrders - A list of Resource Orders to process.
   */
  public static void run(List<Resource_Order__c> resourceOrders) {
    // All Email Recipients should receive emails for their region.
    Map<Id, Email_Recipient__c> emailRecipients = new Map<Id, Email_Recipient__c>(
      [
        SELECT Id, Name, Email__c, Greeting__c, Region__c
        FROM Email_Recipient__c
        WHERE Active__c = TRUE
        ORDER BY Region__c ASC
      ]
    );

    // Get all the Prayer Requests from the last seven days.
    Map<Id, Prayer_Request__c> prayerRequests = new Map<Id, Prayer_Request__c>(
      [
        SELECT
          Id,
          Contact__c,
          Contact__r.Name,
          Account__c,
          Account__r.Name,
          Date_Requested__c,
          Request__c,
          Request_Explanation__c,
          Region__c
        FROM Prayer_Request__c
        WHERE Date_Requested__c >= :Date.today().addDays(-7)
        ORDER BY Region__c ASC, Date_Requested__c DESC
      ]
    );

    // A Region keyed map with Email Recipients for those Regions as values.
    Map<String, List<Email_Recipient__c>> regionToEmailRcptMap = (Map<String, List<Email_Recipient__c>>) getRegionMap(
      emailRecipients
    );

    // A Region keyed map with Prayer Requests for those Regions as values.
    Map<String, List<Prayer_Request__c>> regionToPrayerReqMap = (Map<String, List<Prayer_Request__c>>) getRegionMap(
      prayerRequests
    );

    // A Region keyed map with Resource Order Details for those Regions as values.
    Map<String, List<String>> regionToResourceOrderDetails = new Map<String, List<String>>();

    // A set to hold all Regions to be processed.
    Set<String> relatedRegions = new Set<String>();

    for (Resource_Order__c resourceOrder : resourceOrders) {
      relatedRegions.add(resourceOrder.Region__c);

      // Build body of the email that displays Resource Orders and Status Updates by region.
      String resourceOrderDetails = getDetailsForResource(resourceOrder);

      if (resourceOrderDetails != null) {
        List<String> resourceOrderDetailList = regionToResourceOrderDetails.get(
          resourceOrder.Region__c
        );

        // If the map does not have Resource Order Details for the current Region, create them.
        if (resourceOrderDetailList == null) {
          regionToResourceOrderDetails.put(
            resourceOrder.Region__c,
            new List<String>{ resourceOrderDetails }
          );
        } else {
          // Add this Resource Order Detail to the existing Region.
          resourceOrderDetailList.add(resourceOrderDetails);
          regionToResourceOrderDetails.put(resourceOrder.Region__c, resourceOrderDetailList);
        }
      }
    }

    // A list of emails to send.
    List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
    String orgWideEmailAddressId = fetchOrgWideEmailAddressId();

    for (String region : relatedRegions) {
      // Get the Email Recipients for the current Region.
      List<Email_Recipient__c> emailRcpts = regionToEmailRcptMap.get(region);

      // Do not process if there is no one to send to.
      if (emailRcpts == null || emailRcpts.isEmpty()) {
        continue;
      }

      // Get the Prayer Requests for the current Region.
      List<Prayer_Request__c> prayerReqs = regionToPrayerReqMap.get(region);

      // Get the Resource Order Details for the current Region.
      List<String> resourceOrderDetails = regionToResourceOrderDetails.get(region);

      // Create an Email Message for each Email Recipient.
      for (Email_Recipient__c recipient : emailRcpts) {
        Messaging.SingleEmailMessage emailMessage = buildEmailMessage(
          recipient,
          resourceOrderDetails,
          prayerReqs,
          orgWideEmailAddressId
        );

        emailMessageList.add(emailMessage);
      }
    }

    // All or nothing when sending the emails
    List<Messaging.SendEmailResult> emailResults = new List<Messaging.SendEmailResult>();

    try {
      emailResults = Messaging.sendEmail(emailMessageList, true);
    } catch (System.EmailException e) {
      System.debug('Failed to send email(s). ERROR: ' + e.getMessage());
    }
  }
}