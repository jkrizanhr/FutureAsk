public class DuplicateCheckService {
  /**
   * Check duplicate rules and set the id for the record if there is a match
   * @param records
   * @param exactMatchOnly
   */
  public static void duplicateCheck(List<SObject> records) {
    List<Datacloud.FindDuplicatesResult> findDupeResults
        = Datacloud.FindDuplicates.findDuplicates(records);
    // Iterate over find duplicate results
    for (Integer i = 0; i < findDupeResults.size(); i++) {
      Datacloud.FindDuplicatesResult findDupeResult = findDupeResults[i];
      SObject sObj = records[i];
      // Iterate over the duplicate results
      for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
//        System.debug('Duplicate Rule Developer Name = ' + dupeResult.getDuplicateRule());
        // Iterate over match results
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
//          System.debug('MatchResult = ' + matchResult);
//          System.debug('Duplicate Match Engine = ' + matchResult.getMatchEngine());
//          System.debug('MatchResult.getMatchRecords() = ' + matchResult.getMatchRecords());
          if (matchResult.getMatchRecords() == null || matchResult.getMatchRecords().isEmpty()) {
//            System.debug('No duplicate records found for duplicate rule: ' + dupeResult.getDuplicateRule());
            continue;
          }
          // Iterate over matched records
          for (DataCloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
            SObject matchedRecord = matchRecord.getRecord();
            if (matchResult.getMatchEngine() == 'ExactMatchEngine') {
              sObj.Id = matchedRecord.Id;
              break;
            }
          }
          if (sObj.Id != null) {
            break;
          }
        }
        if (sObj.Id != null) {
          break;
        }
      }
    }
  }
}