public interface DocumentEmailService {
  Boolean sendEmails(List<DocumentEmail> documentEmailList); // Success or Failure.
  // NOTE: In the future, write a custom class to wrap the response and return an instance of it.
}