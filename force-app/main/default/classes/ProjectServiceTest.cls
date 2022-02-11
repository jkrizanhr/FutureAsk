@isTest
private class ProjectServiceTest {
    
  @isTest
  public static void testProjectService() {
    
    npsp__General_Accounting_Unit__c gau1 = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '123'
    );
    insert gau1;

    npsp__General_Accounting_Unit__c gau2 = new npsp__General_Accounting_Unit__c(
      Name = 'Test GAU',
      Purpose_Code__c = '456'
    );
    insert gau2;

    Project__c proj = new Project__c(
      Name = 'Test Project',
      General_Accounting_Unit__c = gau1.Id
    );

    Test.startTest();
    // TEST ON INSERT OF PROJECT
    insert proj;
    npsp__General_Accounting_Unit__c res1 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau1.Id];
    System.assertEquals(proj.Id, res1.Project__c, 'Should be set to match the Project.');

    // UPDATE THE GAU TO A DIFFERENT GAU
    proj.General_Accounting_Unit__c = gau2.Id;
    update proj;
    npsp__General_Accounting_Unit__c res2 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau1.Id];
    System.assertEquals(null, res2.Project__c, 'Should be set to null because the gau lookup was changed.');
    npsp__General_Accounting_Unit__c res3 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau2.Id];
    System.assertEquals(proj.Id, res3.Project__c, 'Should be set to the project because the gau lookup was changed.');
    
    // DELETE/UNDELETE THE PROJECT
    delete proj;
    npsp__General_Accounting_Unit__c res4 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau2.Id];
    System.assertEquals(null, res4.Project__c, 'Should be set to null because the project was deleted.');
    undelete proj;
    npsp__General_Accounting_Unit__c res5 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau2.Id];
    System.assertEquals(proj.Id, res5.Project__c, 'Should be set to the project because the project was undeleted.');

    // UPDATE THE GAU LOOKUP TO NULL
    proj.General_Accounting_Unit__c = null;
    update proj;
    npsp__General_Accounting_Unit__c res6 = [SELECT Id, Project__c FROM npsp__General_Accounting_Unit__c WHERE Id = :gau2.Id];
    System.assertEquals(null, res6.Project__c, 'Should be set to null because the project lookup was blanked out.');

  }

  @isTest
  public static void testCreateClickupProject() {
    Clickup_Settings__c cs = new Clickup_Settings__c();
    cs.Authorization_Code__c = 'pk_123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    insert cs;

    Clickup_Spaces__c ct = new Clickup_Spaces__c();
    ct.Name = 'Projects';
    ct.Space_Id__c = '123456';
    insert ct;    
    
    Clickup_Team_Members__c ctm = new Clickup_Team_Members__c();
    ctm.Name = 'Candoris Consultant';
    ctm.Member_Id__c = '183';
    insert ctm;    
    
    Project__c p = new Project__c(
      Name = 'Test Project',
      Clickup_Space__c = 'Projects', 
      Status__c = 'In Progress',
      RecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByName().get('Language Ministry Project').getRecordTypeId()
    );
    insert p;

    Project_Deliverable__c pd1 = new Project_Deliverable__c(
      Name = 'Test Deliverable',
      Project__c = p.Id,
      Clickup_List_Assignee__c = 'Candoris Consultant'
    );
    insert pd1;

    Map<String, HTTPResponse> responseMap = new Map<String, HTTPResponse>();
    
    HTTPResponse response1 = new HTTPResponse();
    response1.setHeader('Content-Type', 'application/json');
    response1.setBody('{"id":"12345","name":"Test Project","orderindex":0,"override_statuses":false,"hidden":false,"space":{"id":"789","name":"Space Name","access":true},"task_count":"0"}');
    response1.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/space/123456/folder', response1);
    
    HTTPResponse response2 = new HTTPResponse();
    response2.setHeader('Content-Type', 'application/json');
    response2.setBody('{"id":"54321","name":"Test Deliverable","orderindex":1,"content":"New List Content","status":{"status":"green","color":"#e50000","hide_label":true},"priority":{"priority":"normal","color":"#f50000"},"assignee":{"id":183,"color":"#827718","username":"Jerry Krusinski","initials":"JK","profilePicture":"https://dev-attachments-public.clickup.com/profilePictures/183_nx1.jpg"},"task_count":null,"due_date":"1567780450202","due_date_time":false,"start_date":null,"start_date_time":null,"folder":{"id":"456","name":"Folder Name","hidden":false,"access":true},"space":{"id":"789","name":"Space Name","access":true},"inbound_address":"add.task.1389.ac725f.31518a6a-05bb-4997-92a6-1dcfe2f527ca@tasks.clickup.com"}');
    response2.setStatusCode(200);
    responseMap.put('https://api.clickup.com/api/v2/folder/12345/list', response2);

    Test.setMock(HTTPCalloutMock.class, new HTTPMock(responseMap));

    Test.startTest();
      p.MPP_Approved__c = true;
      update p;
    Test.stopTest();

    Project__c res1 = [SELECT Id, Clickup_External_Id__c FROM Project__c WHERE Id = :p.Id];
    System.assertEquals('12345', res1.Clickup_External_Id__c, 'The Clickup Project should be created as a folder.');
    
    Project_Deliverable__c res2 = [SELECT Id, Clickup_External_Id__c FROM Project_Deliverable__c WHERE Id = :pd1.Id];
    System.assertEquals('54321', res2.Clickup_External_Id__c, 'The Clickup Project Deliverable should be created as a list in the folder.');
  }
}