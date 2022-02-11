public class DocumentGenerationServiceFactory {
  public static DocumentGenerationService getDocumentGenerationHandlerByType(String handlerType) {
    Type t = Type.forName('DocumentGeneration' + handlerType + 'Handler');
    return t != null ? (DocumentGenerationService)t.newInstance() : null;
  }
}