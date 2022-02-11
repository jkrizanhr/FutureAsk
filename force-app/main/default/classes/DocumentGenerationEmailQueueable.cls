public class DocumentGenerationEmailQueueable implements System.Queueable, Database.AllowsCallouts {
  private DocumentEmail email;

  public DocumentGenerationEmailQueueable(DocumentEmail email) {
    this.email = email;
  }
  public void execute(System.QueueableContext qc) {
    DocGenSettings__c docGenSettings = DocGenSettings__c.getInstance();
    if (docGenSettings == null || String.isBlank(docGenSettings.Email_Service__c)) {
      return;
    }

    DocumentEmailService emailService = DocumentEmailServiceFactory.getEmailServiceByType(
      docGenSettings.Email_Service__c
    );
    emailService.sendEmails(new List<DocumentEmail>{ this.email });
  }
}