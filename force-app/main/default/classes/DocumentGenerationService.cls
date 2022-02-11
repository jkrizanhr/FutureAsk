public interface DocumentGenerationService {
  void init(DocumentGeneratorModel docGenModel);
    Boolean handleDocumentGeneration(List<SObject> recordList);
    Boolean handleDocumentGeneration(List<DocumentGeneratorModel.Doc> documents);
    Boolean completeDocumentGeneration();
}