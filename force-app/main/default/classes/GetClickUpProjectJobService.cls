public without sharing class GetClickUpProjectJobService {
  
  public static void createClickUpSnapshot(List<Project__c> projects) {
    List<Clickup_Status_Snapshot__c> snapshotsToInsert = new List<Clickup_Status_Snapshot__c>();
    List<Project_Deliverable__c> pdToUpdate = new List<Project_Deliverable__c>();
    
    String authCode = Clickup_Settings__c.getOrgDefaults().Authorization_Code__c;
    Map<String, Clickup_Spaces__c> clickUpSpacesMap = Clickup_Spaces__c.getAll(); 
    
    for (Project__c proj : projects){
      String spaceId = clickUpSpacesMap.get(proj.Clickup_Space__c).Space_Id__c;
      Set<String> listIds =  new Set<String>();
      Map<String, List<Task>> listTaskMap =  new Map<String, List<Task>>();
      List<Task> tasks =  new List<Task>();

      // GET FOLDERS AND LISTS THEY CONTAIN
      Http httpFolder = new Http();
      HttpRequest reqFolder = new HttpRequest();
      
      reqFolder.setEndPoint('https://api.clickup.com/api/v2/folder/' + proj.Clickup_External_Id__c + '/?archived=false');
      reqFolder.setHeader('Authorization', authCode);
      reqFolder.setMethod('GET');

      HttpResponse respFolder = httpFolder.send(reqFolder);
      String bodyFolder = respFolder.getBody().replaceAll('\\{\\}', 'null');
      System.debug(bodyFolder);
      Folder f = (Folder)JSON.deserialize(bodyFolder, Folder.class);
      System.debug(f);

      if (!f.lists.isEmpty()){
        for (Lists l : f.lists) {
          listIds.add(l.id);
        }
      }
        
      // GET TASKS
      for (String listId : listIds){
        Http httpTasks = new Http();
        HttpRequest reqTasks = new HttpRequest();
        
        reqTasks.setEndPoint('https://api.clickup.com/api/v2/list/' + listId + '/task?archived=false&include_closed=true');
        reqTasks.setHeader('Authorization', authCode);
        reqTasks.setMethod('GET');

        HttpResponse resTasks = httpTasks.send(reqTasks);
        String bodyTasks = resTasks.getBody().replaceAll('\\{\\}', 'null');
        TaskResponse tr = (TaskResponse)JSON.deserialize(bodyTasks, TaskResponse.class);
        
        tasks.addAll(tr.tasks);
        listTaskMap.put(listId, tr.tasks);
      }

      // GET CLICKUP SNAPSHOT STATISTICS
      Double totalTasks = 0;
      Double openTasks = 0;
      Double completeTasks = 0;
      Double completeTasksLast30Days = 0;
      
      for (Task t : tasks){
        totalTasks++;
        if (t.status.type == 'Open'){
          openTasks++;
        } else {
          completeTasks++;
          Long timestamp = t.date_closed != null ? Long.valueOf(t.date_closed) : null;
          if (timestamp != null && Datetime.newInstance(timeStamp) >= Datetime.now().addDays(-30)){
            completeTasksLast30Days++;
          }
        }
      }
            
      // SET CLICKUP SNAPSHOT STATISTICS
      Clickup_Status_Snapshot__c css = new Clickup_Status_Snapshot__c(
        Name = proj.Name + ' - ' + Date.today().format(),
        Project__c = proj.Id,
        Total_Tasks__c = totalTasks,
        Total_Open_Tasks__c = openTasks,
        Total_Completed_Tasks__c = completeTasks,
        Total_Tasks_Completed_in_Last_30_Days__c = completeTasksLast30Days,
        Total_Lists__c = listIds.size()
      );
      snapshotsToInsert.add(css);

      // UPDATE PROJECT DELIVERABLE STATISTICS
      if (!proj.Project_Deliverables__r.isEmpty()){
        for (Project_Deliverable__c pd : proj.Project_Deliverables__r){
          if (!listTaskMap.isEmpty() && listTaskMap.get(pd.Clickup_External_Id__c) != null){
            // GET CLICKUP SNAPSHOT STATISTICS
            totalTasks = 0;
            openTasks = 0;
            completeTasks = 0;

            for (Task t : listTaskMap.get(pd.Clickup_External_Id__c)){
              totalTasks++;
              if (t.status.type == 'Open'){
                openTasks++;
              } else {
                completeTasks++;
              }
            }

            Project_Deliverable__c newPd = new Project_Deliverable__c(
              Id = pd.Id,
              Total_Open_Tasks__c = openTasks,
              Total_Completed_Tasks__c = completeTasks,
              Total_Tasks__c = totalTasks
            );
            pdToUpdate.add(newPd);
          }
        }
      }
    }

    // INSERT CLICKUP SNAPSHOTS    
    if (!snapshotsToInsert.isEmpty()){
      insert snapshotsToInsert;
    }
    // UPDATE PROJECT DELIVERABLES
    if (!pdToUpdate.isEmpty()){
      update pdToUpdate;
    }
  }

  public class Folder {
    public String id;
    public String name;
    public String task_count;
    List<Lists> lists;
  }

  public class ListResponse {
    List<Lists> lists;
  }

  public class Lists {
    public String id;
    public String name;
    public String start_date;
    public String due_date;
    public String task_count;
  }

  public class TaskResponse {
    List<Task> tasks;
  }

  public class Task {
    public String id;
    public String name;
    public String date_closed;
    public String due_date;
    public String start_date;
    public TaskStatus status;
  }

  public class TaskStatus {
    public String status;
    public String type;
  }
}