public class DocumentEmailServiceFactory {
  public static DocumentEmailService getEmailServiceByType(String emailServiceType) {
    Type t = Type.forName('Document' + emailServiceType + 'EmailService');
    return t != null ? (DocumentEmailService) t.newInstance() : null;
  }
}