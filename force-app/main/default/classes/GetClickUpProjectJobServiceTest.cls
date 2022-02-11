@isTest
private class GetClickUpProjectJobServiceTest {
  
  @isTest
  static void testGetClickUpProjectJobServiceTest(){
    Clickup_Settings__c cs = new Clickup_Settings__c();
    cs.Authorization_Code__c = 'pk_123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    insert cs;

    Clickup_Spaces__c ct = new Clickup_Spaces__c();
    ct.Name = 'Projects';
    ct.Space_Id__c = '123456';
    insert ct; 
    
    Project__c p = new Project__c(
      Name = 'Test Project',
      Clickup_Space__c = 'Projects',
      Clickup_External_Id__c = '123456',
      Status__c = 'In Progress'
    );
    insert p;

    Project_Deliverable__c pd = new Project_Deliverable__c(
      Name = 'Test Deliverable',
      Project__c = p.Id,
      Clickup_External_Id__c = '17057719'
    );
    insert pd;

    Map<String, HTTPResponse> responseMap = new Map<String, HTTPResponse>();

    HTTPResponse res1 = new HTTPResponse();
    res1.setHeader('Content-Type', 'application/json');
    res1.setBody('{"id":"123546","name":"Test Project","hidden":false,"task_count":"1","archived":false,"statuses":[],"lists":[{"id":"17057718","name":"Test List 1","status":{},"task_count":"0","due_date":{},"start_date":{},"archived":false,"statuses":[{"status":"in progress","orderindex":0,"color":"#2ecd6f","type":"open"},{"status":"planning","orderindex":1,"color":"#2ecd6f","type":"custom"},{"status":"cancelled","orderindex":2,"color":"#e50000","type":"done"},{"status":"complete","orderindex":3,"color":"#6bc950","type":"closed"}]},{"id":"17057719","name":"Test List 2","status":{},"task_count":"1","due_date":{},"start_date":{},"archived":false,"statuses":[{"status":"in progress","orderindex":0,"color":"#2ecd6f","type":"open"},{"status":"planning","orderindex":1,"color":"#2ecd6f","type":"custom"},{"status":"cancelled","orderindex":2,"color":"#e50000","type":"done"},{"status":"complete","orderindex":3,"color":"#6bc950","type":"closed"}]}]}');
    res1.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/folder/123456/?archived=false', res1);
    HTTPResponse res2 = new HTTPResponse();
    res2.setHeader('Content-Type', 'application/json');
    res2.setBody('{"tasks":[{"id":"4jcr3b","name":"Task 1","status":{"status":"in progress","color":"#2ecd6f","type":"open","orderindex":0},"date_created":"1581430395420","date_updated":"1581430478832","date_closed":{},"archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr3b","list":{"id":"17057719","name":"Test List 1","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}},{"id":"4jcr30","name":"Task 2","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430383430","date_updated":"1581430473833","date_closed":{},"archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr30","list":{"id":"17057719","name":"Test List 1","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}}]}');
    res2.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/list/17057719/task?archived=false&include_closed=true', res2);
    HTTPResponse res3 = new HTTPResponse();
    res3.setHeader('Content-Type', 'application/json');
    res3.setBody('{"tasks":[{"id":"4jcr3b","name":"Task 1","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430395420","date_updated":"1581430478832","date_closed":"1581430473833","archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr3b","list":{"id":"17057718","name":"Test List 2","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}},{"id":"4jcr30","name":"Task 2","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430383430","date_updated":"1581430473833","date_closed":"1581430473833","archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr30","list":{"id":"17057718","name":"Test List 2","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}}]}');
    res3.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/list/17057718/task?archived=false&include_closed=true', res3);

    Test.setMock(HTTPCalloutMock.class, new HTTPMock(responseMap));
    
    Test.startTest();
      Database.executeBatch(new GetClickUpProjectJob());
    Test.stopTest();

    Clickup_Status_Snapshot__c css = [SELECT Id, Name, Project__c, Total_Tasks__c, Total_Open_Tasks__c, Total_Completed_Tasks__c, Total_Tasks_Completed_in_Last_30_Days__c, Total_Lists__c FROM Clickup_Status_Snapshot__c WHERE Project__c = :p.Id];   
    System.assertEquals(1, css.Total_Open_Tasks__c, 'The number of open tasks are not calculated correctly.');
    System.assertEquals(3, css.Total_Completed_Tasks__c, 'The number of closed tasks are not calculated correctly.');
    System.assertEquals(css.Total_Tasks__c, css.Total_Open_Tasks__c + css.Total_Completed_Tasks__c, 'Open + Closed Tasks != Total Tasks');

    Project_Deliverable__c pd_res = [SELECT Id, Total_Tasks__c, Total_Completed_Tasks__c, Total_Open_Tasks__c FROM Project_Deliverable__c WHERE Id = :pd.Id];
    System.assertEquals(1, css.Total_Open_Tasks__c, 'The number of open tasks are not calculated correctly.');
    System.assertEquals(3, css.Total_Completed_Tasks__c, 'The number of closed tasks are not calculated correctly.');
    System.assertEquals(4, css.Total_Tasks__c, 'The number of total tasks was not calculated correctly.');
  }

  @isTest
  static void testGetClickUpProjectJobServiceTestSingleProject(){
    Clickup_Settings__c cs = new Clickup_Settings__c();
    cs.Authorization_Code__c = 'pk_123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    insert cs;

    Clickup_Spaces__c ct = new Clickup_Spaces__c();
    ct.Name = 'Projects';
    ct.Space_Id__c = '123456';
    insert ct; 
    
    Project__c p = new Project__c(
      Name = 'Test Project',
      Clickup_Space__c = 'Projects',
      Clickup_External_Id__c = '123456',
      Status__c = 'In Progress'
    );
    insert p;

    Project_Deliverable__c pd = new Project_Deliverable__c(
      Name = 'Test Deliverable',
      Project__c = p.Id,
      Clickup_External_Id__c = '17057719'
    );
    insert pd;

    Map<String, HTTPResponse> responseMap = new Map<String, HTTPResponse>();

    HTTPResponse res1 = new HTTPResponse();
    res1.setHeader('Content-Type', 'application/json');
    res1.setBody('{"id":"123546","name":"Test Project","hidden":false,"task_count":"1","archived":false,"statuses":[],"lists":[{"id":"17057718","name":"Test List 1","status":{},"task_count":"0","due_date":{},"start_date":{},"archived":false,"statuses":[{"status":"in progress","orderindex":0,"color":"#2ecd6f","type":"open"},{"status":"planning","orderindex":1,"color":"#2ecd6f","type":"custom"},{"status":"cancelled","orderindex":2,"color":"#e50000","type":"done"},{"status":"complete","orderindex":3,"color":"#6bc950","type":"closed"}]},{"id":"17057719","name":"Test List 2","status":{},"task_count":"1","due_date":{},"start_date":{},"archived":false,"statuses":[{"status":"in progress","orderindex":0,"color":"#2ecd6f","type":"open"},{"status":"planning","orderindex":1,"color":"#2ecd6f","type":"custom"},{"status":"cancelled","orderindex":2,"color":"#e50000","type":"done"},{"status":"complete","orderindex":3,"color":"#6bc950","type":"closed"}]}]}');
    res1.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/folder/123456/?archived=false', res1);
    HTTPResponse res2 = new HTTPResponse();
    res2.setHeader('Content-Type', 'application/json');
    res2.setBody('{"tasks":[{"id":"4jcr3b","name":"Task 1","status":{"status":"in progress","color":"#2ecd6f","type":"open","orderindex":0},"date_created":"1581430395420","date_updated":"1581430478832","date_closed":{},"archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr3b","list":{"id":"17057719","name":"Test List 1","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}},{"id":"4jcr30","name":"Task 2","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430383430","date_updated":"1581430473833","date_closed":{},"archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr30","list":{"id":"17057719","name":"Test List 1","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}}]}');
    res2.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/list/17057719/task?archived=false&include_closed=true', res2);
    HTTPResponse res3 = new HTTPResponse();
    res3.setHeader('Content-Type', 'application/json');
    res3.setBody('{"tasks":[{"id":"4jcr3b","name":"Task 1","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430395420","date_updated":"1581430478832","date_closed":"1581430473833","archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr3b","list":{"id":"17057718","name":"Test List 2","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}},{"id":"4jcr30","name":"Task 2","status":{"status":"in progress","color":"#2ecd6f","type":"closed","orderindex":0},"date_created":"1581430383430","date_updated":"1581430473833","date_closed":"1581430473833","archived":false,"due_date":{},"start_date":{},"team_id":"67554","url":"https://app.clickup.com/t/4jcr30","list":{"id":"17057718","name":"Test List 2","access":true},"project":{"id":"8510768","name":"hidden","hidden":true,"access":true},"folder":{"id":"8511420","name":"Test Folder","hidden":false,"access":true},"space":{"id":"4315102"}}]}');
    res3.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/list/17057718/task?archived=false&include_closed=true', res3);

    Test.setMock(HTTPCalloutMock.class, new HTTPMock(responseMap));
    
    Test.startTest();
      GetClickUpProjectJob.getOneClickUpProject(p.Id);
    Test.stopTest();

    Clickup_Status_Snapshot__c css = [SELECT Id, Name, Project__c, Total_Tasks__c, Total_Open_Tasks__c, Total_Completed_Tasks__c, Total_Tasks_Completed_in_Last_30_Days__c, Total_Lists__c FROM Clickup_Status_Snapshot__c WHERE Project__c = :p.Id];   
    System.assertEquals(1, css.Total_Open_Tasks__c, 'The number of open tasks are not calculated correctly.');
    System.assertEquals(3, css.Total_Completed_Tasks__c, 'The number of closed tasks are not calculated correctly.');
    System.assertEquals(css.Total_Tasks__c, css.Total_Open_Tasks__c + css.Total_Completed_Tasks__c, 'Open + Closed Tasks != Total Tasks');

    Project_Deliverable__c pd_res = [SELECT Id, Total_Tasks__c, Total_Completed_Tasks__c, Total_Open_Tasks__c FROM Project_Deliverable__c WHERE Id = :pd.Id];
    System.assertEquals(1, css.Total_Open_Tasks__c, 'The number of open tasks are not calculated correctly.');
    System.assertEquals(3, css.Total_Completed_Tasks__c, 'The number of closed tasks are not calculated correctly.');
    System.assertEquals(4, css.Total_Tasks__c, 'The number of total tasks was not calculated correctly.');
  }
}