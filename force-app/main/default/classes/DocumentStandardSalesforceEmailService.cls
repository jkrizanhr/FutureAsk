public class DocumentStandardSalesforceEmailService implements DocumentEmailService {
  // Create Standard Salesforce Email Messaging object and send it then return a response
  public Boolean sendEmails(List<DocumentEmail> documentEmailList) {
    String orgWideEmailAddressId = fetchOrgWideEmailAddressId();

    if (Test.isRunningTest()) {
      // Not needed unless email deliverability in setup is set to no emails or system only
      return true;
    }

    if (documentEmailList.isEmpty()) {
      System.debug('Error: The email list is empty');
      return false;
    }

    if (String.isBlank(orgWideEmailAddressId)) {
      System.debug('Error: No org wide address.');
      return false;
    }

    List<ContentVersion> contentVersions = new List<ContentVersion>();
    for (DocumentEmail email : documentEmailList) {
      if (email.blobContent == null) {
        System.debug('Blob is an empty in attachment');
        return false;
      }

      if (email.contentVersion == null || email.contentVersion.Id == null) {
        ContentVersion cv = new ContentVersion();
        cv.Title = email.fileName;
        cv.VersionData = email.blobContent;
        cv.PathOnClient = email.fileName + '.' + email.contentType;
        contentVersions.add(cv);
        email.contentVersion = cv;
      }
    }

    if (!contentVersions.isEmpty()) {
      try {
        insert contentVersions;
      } catch (DmlException e) {
        System.debug(
          'DocumentStandardSalesforceEmailService: error inserting content versions. ' +
          e.getMessage()
        );
        return false;
      }
    }

    List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
    for (DocumentEmail email : documentEmailList) {
      Messaging.SingleEmailMessage emailMessage = createSingleEmailMessage(
        email,
        orgWideEmailAddressId
      );
      emailMessage.setEntityAttachments(new List<String>{ email.contentVersion.Id });
      emailMessageList.add(emailMessage);
    }

    System.debug('emailMessageList.size() : ' + emailMessageList.size());

    // All or nothing when sending the emails
    List<Messaging.SendEmailResult> emailResults = new List<Messaging.SendEmailResult>();
    // System.debug(emailMessageList);
    try {
      emailResults = Messaging.sendEmail(emailMessageList, true);
      System.debug('emailResults: ' + emailResults);
    } catch (System.EmailException e) {
      System.debug('Failed to send email(s). ERROR: ' + e.getMessage());
      return false;
    }

    if (emailResults.isEmpty()) {
      System.debug('Error while sending email');
      return false;
    } else {
      return emailResults.get(0).isSuccess();
    }
  }

  private Messaging.SingleEmailMessage createSingleEmailMessage(
    DocumentEmail email,
    String orgWideEmailAddressId
  ) {
    Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
    emailMessage.setTemplateId(email.emailTemplateId);
    emailMessage.setSaveAsActivity(false);
    emailMessage.setToAddresses(new List<String>{ email.toAddress });
    emailMessage.setHtmlBody(email.emailContent);
    emailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);

    if (String.isNotBlank(email.whatId)) {
      emailMessage.setWhatId(email.whatId);
    }
    if (String.isNotBlank(email.emailSubject)) {
      emailMessage.setSubject(email.emailSubject);
    }

    return emailMessage;
  }

  private String fetchOrgWideEmailAddressId() {
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
}