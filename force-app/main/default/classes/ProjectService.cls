public without sharing class ProjectService {

  public static void setProjectLookupOnGAU(List<Project__c> projList, Map<Id, Project__c> oldMap) {
    Map<Id, Id> gauToProjectMap = new Map<Id, Id>();

    for (Project__c proj : projList){
      if (oldMap != null){
        Project__c old = oldMap.get(proj.Id) != null ? oldMap.get(proj.Id) : null;
        if (old.General_Accounting_Unit__c != proj.General_Accounting_Unit__c){
          if (proj.General_Accounting_Unit__c != null){ gauToProjectMap.put(proj.General_Accounting_Unit__c, proj.Id); }
          if (old.General_Accounting_Unit__c != null){ gauToProjectMap.put(old.General_Accounting_Unit__c, null); }
        }
      } else {
        if (proj.General_Accounting_Unit__c != null){
          gauToProjectMap.put(proj.General_Accounting_Unit__c, proj.Id);
        }
      }
    }

    List<npsp__General_Accounting_Unit__c> gausToUpdate = new List<npsp__General_Accounting_Unit__c>();
    if (!gauToProjectMap.isEmpty()){
      for (npsp__General_Accounting_Unit__c gau : [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id IN :gauToProjectMap.keySet()]){
        gau.Project__c = gauToProjectMap.get(gau.Id);
        gausToUpdate.add(gau);
      }

      if (!gausToUpdate.isEmpty()){
        update gausToUpdate;
      }
    }
  }

  public static void setProjectTypeFieldOnProjectPartner(List<Project__c> projList, Map<Id, Project__c> oldMap) {
    Set<Id> projectIds = new Set<Id>();

    for (Project__c proj : projList){
      Project__c old = oldMap != null ? oldMap.get(proj.Id) : null;
      if (old == null || (old != null && old.RecordTypeId != proj.RecordTypeId)){
        projectIds.add(proj.Id);
      }
    }

    List<Project_Partner__c> partnersToUpdate = new List<Project_Partner__c>();
    if (!projectIds.isEmpty()){
      for (Project_Partner__c pp : [SELECT Id, Project_Record_Type__c, Project__r.RecordType.Name 
                                    FROM Project_Partner__c WHERE Project__c IN :projectIds
      ]){
        pp.Project_Record_Type__c = pp.Project__r.RecordType.Name;
        partnersToUpdate.add(pp);
      }

      if (!partnersToUpdate.isEmpty()){
        update partnersToUpdate;
      }
    }
  }


  public class createProjectInClickup implements Queueable, Database.AllowsCallouts{
    private List<Project__c> projList;
    private Map<Id, Project__c> oldMap;

    public createProjectInClickup(List<Project__c> projList, Map<Id, Project__c> oldMap){
      this.projList = projList;
      this.oldMap = oldMap;
    }

    public void execute(QueueableContext context){
      List<Project__c> clickupProjectsToCreate = new List<Project__c>();

      for (Project__c proj : projList){
        if (proj.MPP_Approved__c == true && proj.Clickup_External_Id__c == null){
          if (oldMap != null) {
            Project__c old = oldMap.get(proj.Id) != null ? oldMap.get(proj.Id) : null;
            if (old.MPP_Approved__c != proj.MPP_Approved__c && proj.MPP_Approved__c == true && proj.Clickup_External_Id__c == null){
              clickupProjectsToCreate.add(proj);
            }
          } else {
            clickupProjectsToCreate.add(proj);
          }
        }
      }

      if (!clickupProjectsToCreate.isEmpty()){
        List<Project__c> updateTheseProjects = new List<Project__c>();
        String authCode = Clickup_Settings__c.getOrgDefaults().Authorization_Code__c;
        Map<String, Clickup_Spaces__c> clickUpSpacesMap = Clickup_Spaces__c.getAll(); 
        Map<Id, String> projToClickupMap = new Map<Id, String>();
        
        for (Project__c proj : clickupProjectsToCreate){
          String spaceId = clickUpSpacesMap.get(proj.Clickup_Space__c).Space_Id__c;
          
          Http h = new Http();
          HttpRequest request = new HttpRequest();

          request.setEndPoint('https://api.clickup.com/api/v2/space/' + spaceId + '/folder');
          request.setHeader('Authorization', authCode);
          request.setHeader('Content-Type', 'application/json');
          request.setBody('{"name":"' + proj.Name + '"}');
          request.setMethod('POST');

          HTTPResponse response = h.send(request);
          ClickupResponse cr = (ClickupResponse)JSON.deserialize(response.getBody(), ClickupResponse.class);

          Project__c newProj = new Project__c();
          newProj.Id = proj.Id;
          if (cr.Id != null){
            newProj.Clickup_External_Id__c = cr.id;
            newProj.Clickup_Project_Created_Date__c = Datetime.now();
            projToClickupMap.put(proj.Id, cr.id);
          } else {
            newProj.Clickup_Errors__c = cr.err;
          }
          updateTheseProjects.add(newProj);
        }

        if (!projToClickupMap.isEmpty()){
          List<Project_Deliverable__c> pdToUpdate = new List<Project_Deliverable__c>();
          for (Project__c proj : [SELECT Id, Name,
                                    (SELECT Id, Name, Clickup_External_Id__c, Clickup_List_Assignee__c, Total_Tasks__c, Total_Open_Tasks__c, Total_Completed_Tasks__c FROM Project_Deliverables__r WHERE Clickup_List_Assignee__c != null) 
                                  FROM Project__c 
                                  WHERE Id IN :projToClickupMap.keySet() AND RecordType.Name = 'Language Ministry Project']
          ){
            if (!proj.Project_Deliverables__r.isEmpty()){
              Map<String, Clickup_Team_Members__c> clickUpMembersMap = Clickup_Team_Members__c.getAll(); 
              for (Project_Deliverable__c pd : proj.Project_Deliverables__r){
                String memberId = clickUpMembersMap.get(pd.Clickup_List_Assignee__c).Member_Id__c;

                Http pd_h = new Http();
                HttpRequest pd_request = new HttpRequest();

                pd_request.setEndPoint('https://api.clickup.com/api/v2/folder/' + projToClickupMap.get(proj.Id) + '/list');
                pd_request.setHeader('Authorization', authCode);
                pd_request.setHeader('Content-Type', 'application/json');
                pd_request.setBody('{"name":"' + pd.Name + '","content":"Deliverable for ' + proj.Name + '","due_date":"' + DateTime.now().getTime() + '","due_date_time":false,"priority":3,"assignee":"' + memberId + '","status":"green"}');
                pd_request.setMethod('POST');

                HTTPResponse pd_response = pd_h.send(pd_request);
                ClickupResponse pd_cr = (ClickupResponse)JSON.deserialize(pd_response.getBody(), ClickupResponse.class);

                Project_Deliverable__c newPd = new Project_Deliverable__c();
                newPd.Id = pd.Id;
                if (pd_cr.Id != null){
                  newPd.Clickup_External_Id__c = pd_cr.id;
                  newPd.Total_Tasks__c = 0;
                  newPd.Total_Open_Tasks__c = 0;
                  newPd.Total_Completed_Tasks__c = 0;
                } else {
                  newPd.Clickup_Errors__c = pd_cr.err;
                }
                pdToUpdate.add(newPd);
              }
            }
          }
          if (!pdToUpdate.isEmpty()){
            update pdToUpdate;
          }
        }
        if (!updateTheseProjects.isEmpty()){
          update updateTheseProjects;
        }
      }
    }
  }

  public class ClickupResponse {
    String id;
    String err;
  }
}