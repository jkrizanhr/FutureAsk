public class DocumentTemplateQuestionService {
    public static void setName(List<Document_Template_Question__c> questionList) {
        for (Document_Template_Question__c question : questionList) {
            if (String.isNotBlank(question.Question__c)) {
                question.Name = question.Question__c.abbreviate(80);
            }
        }
    }

    public static void validateDistinctFields(List<Document_Template_Question__c> questionList) {
        Set<Id> templateIds = new Set<Id>();
        Set<Id> questionIds = new Set<Id>();
        for (Document_Template_Question__c question : questionList) {
            if (question.Document_Template__c != null) {
                templateIds.add(question.Document_Template__c);
            }
            // If the trigger context is before update, then we want to ensure that
            // we are not getting the same questions that we want to validate.
            if (question.Id != null) {
                questionIds.add(question.Id);
            }
        }

        List<Document_Template_Question__c> existingQuestionList = fetchDocTempQuestions(templateIds, questionIds);

        Set<String> templateMergeFieldSet = new Set<String>();
        Set<String> templateURLParamSet = new Set<String>();
        for (Document_Template_Question__c existingQuestion : existingQuestionList) {
            if (String.isNotBlank(existingQuestion.Query_Merge_Field__c)) {
                String mergeFieldSetKey = existingQuestion.Document_Template__c + '-' + existingQuestion.Query_Merge_Field__c;
                templateMergeFieldSet.add(mergeFieldSetKey);
            }
            if (String.isNotBlank(existingQuestion.URL_Parameter__c)) {
                String urlParamSetKey = existingQuestion.Document_Template__c + '-' + existingQuestion.URL_Parameter__c;
                templateURLParamSet.add(urlParamSetKey);
            }
        }

        // Ensure that there are no duplicate values across Query_Merge_Field__c fields.
        // Ensure that there are no duplicate values across URL_Parameter__c fields.
        for (Document_Template_Question__c question : questionList) {
            if (question.Document_Template__c != null && String.isNotBlank(question.Query_Merge_Field__c)) {
                String mergeFieldSetKey = question.Document_Template__c + '-' + question.Query_Merge_Field__c;
//                if (templateMergeFieldSet.contains(mergeFieldSetKey)) {
//                    question.addError('Query Merge Fields must be distinct for a Document Template!');
//                } else {
                    templateMergeFieldSet.add(mergeFieldSetKey);
//                }
            }
            if (question.Document_Template__c != null && String.isNotBlank(question.URL_Parameter__c)) {
                String urlParamFieldKey = question.Document_Template__c + '-' + question.URL_Parameter__c;
//                if (templateURLParamSet.contains(urlParamFieldKey)) {
//                    question.addError('URL Parameter Fields must be distinct for a Document Template!');
//                } else {
                    templateURLParamSet.add(urlParamFieldKey);
//                }
            }
        }
    }

    public static List<Document_Template_Question__c> fetchDocTempQuestions(Set<Id> templateIds, Set<Id> questionIds) {
        List<Document_Template_Question__c> docTempQuestionList = [
            SELECT
                Document_Template__c,
                Id,
                URL_Parameter__c,
                Query_Merge_Field__c
            FROM Document_Template_Question__c
            WHERE Document_Template__c IN :templateIds
                AND Id NOT IN :questionIds
                AND (
                    Query_Merge_Field__c != NULL
                        OR URL_Parameter__c != NULL
                )
            ORDER BY Document_Template__c
        ];
        return docTempQuestionList;
    }
}