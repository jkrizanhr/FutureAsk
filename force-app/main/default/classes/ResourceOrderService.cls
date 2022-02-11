public without sharing class ResourceOrderService {
  /**
   * Truncates a Resource Order name that is longer than 80 characters by truncating the Resource Item name.
   *
   * @param currentName - The current Resource Order name.
   * @return An 80 character length Resource Order name.
   */
  private static String form80CharacterName(String currentName) {
    if (currentName.length() > 80) {
      /*
      Subtract 77 from current name length. Using 77 so elipses can be added after Resource name 
      truncation.
      */
      Integer deltaChars = currentName.length() - 77;
      List<String> splitName = currentName.split(' - ');

      // The list should have 5 entries. Resource Item Name would be contained at index 2.
      Integer lengthToKeep = splitName[2].length() - deltaChars;
      String truncatedResourceName = (splitName[2].left(lengthToKeep) + '...');
      splitName[2] = truncatedResourceName;

      return String.join(splitName, ' - ');
    } else {
      return currentName;
    }
  }

  /**
   * @description Queries Patnership Director Users for use in Resource Order Naming.
   *
   * @param resourceOrders - A list of Resource Orders.
   * @return A map relating Resource Orders to their Partnership Director User.
   */
  private static Map<Id, User> getPartnershipDirectors(List<Resource_Order__c> resourceOrders) {
    Set<Id> userIds = new Set<Id>();
    for (Resource_Order__c ro : resourceOrders) {
      if (ro.Partnership_Director__c != null) {
        userIds.add(ro.Partnership_Director__c);
      }
    }

    Map<Id, User> userMap = new Map<Id, User>([SELECT Id, LastName FROM User WHERE Id IN :userIds]);

    return userMap;
  }

  /**
   * Sets the name for Resource Orders being inserted.
   *
   * @param reosurceOrders - A list of Resource Orders being inserted.
   */
  public static void setNameInsert(List<Resource_Order__c> resourceOrders) {
    Set<Id> acctIds = new Set<Id>();
    Set<Id> lmpProjectIds = new Set<Id>();
    for (Resource_Order__c resourceOrder : resourceOrders) {
      acctIds.add(resourceOrder.Account__c);
      lmpProjectIds.add(resourceOrder.LMP_Project__c);
    }

    // Query related LMP Projects
    Map<Id, Project__c> relatedLmpProjects = new Map<Id, Project__c>(
      [
        SELECT Id, Counter__c, General_Accounting_Unit__r.Purpose_Code__c
        FROM Project__c
        WHERE Id IN :lmpProjectIds AND RecordType.Name = 'Language Ministry Project'
      ]
    );

    Map<Id, User> partnershipDirectors = getPartnershipDirectors(resourceOrders);

    /*
    Custom setting used as a counter for Resource Orders not linked to an LMP Project. Keep track 
    if it will need to be updated due to a counter increase.
    */
    Resource_Order_Name__c defaultCounter = Resource_Order_Name__c.getOrgDefaults();
    Boolean updateCustomSetting = false;

    // A map of Projects to update as a result of their Counter field getting updated.
    Map<Id, Project__c> projectsToUpdate = new Map<Id, Project__c>();

    for (Resource_Order__c resourceOrder : resourceOrders) {
      Project__c relatedLmpProj = relatedLmpProjects.get(resourceOrder.LMP_Project__c);
      String tempName = '';

      // Purpose Code
      if (
        relatedLmpProj == null ||
        relatedLmpProj.General_Accounting_Unit__c == null ||
        relatedLmpProj.General_Accounting_Unit__r.Purpose_Code__c == null
      ) {
        tempName += '9999 - ';
      } else {
        tempName += (relatedLmpProj.General_Accounting_Unit__r.Purpose_Code__c + ' - ');
      }

      // Counter
      if (relatedLmpProj == null) {
        // There is no related LMP Project, use the custom settings variable.
        tempName += (String.valueOf(Integer.valueOf(defaultCounter.Counter__c)).leftPad(4, '0') +
        ' - ');
        defaultCounter.Counter__c++;
        updateCustomSetting = true;
      } else {
        // Initialize the LMP Project's counter.
        if (relatedLmpProj.Counter__c == null) {
          relatedLmpProj.Counter__c = 0;
        }

        tempName += (String.valueOf(relatedLmpProj.Counter__c).leftPad(4, '0') + ' - ');

        // The Project's counter was updated so make sure it gets updated.
        relatedLmpProj.Counter__c++;
        projectsToUpdate.put(relatedLmpProj.Id, relatedLmpProj);
      }

      // Resource Name - Before insert a Resource Order will not have child Resource Order Items.
      tempName += 'No Items - ';

      // Last name of Partnership Director for this Resource Order
      if (
        resourceOrder.Partnership_Director__c != null &&
        partnershipDirectors.get(resourceOrder.Partnership_Director__c) != null
      ) {
        tempName += (partnershipDirectors.get(resourceOrder.Partnership_Director__c).LastName +
        ' - ');
      } else {
        tempName += 'No Director - ';
      }

      // Date
      String formattedDate;
      if (resourceOrder.Submitted_Date__c != null) {
        Date dateToUse = resourceOrder.Submitted_Date__c;
        formattedDate =
          String.valueOf(dateToUse.month()).leftPad(2, '0') +
          '/' +
          String.valueOf(dateToUse.year());
      } else {
        formattedDate = 'XX/XXXX';
      }

      tempName += formattedDate;

      // Set the new name for the Resource Order
      resourceOrder.Name = tempName;
    }

    if (updateCustomSetting) {
      // Update the Resource Order Name custom setting counter.
      update defaultCounter;
    }

    if (!projectsToUpdate.isEmpty()) {
      update projectsToUpdate.values();
    }
  }

  /**
   * Sets the name for Resource Orders before updates. The name format is as follows:
   * [Related GAU Purpose Code] - [Counter from Related LMP Project] - Resource Name - [Last name of related Account's Partnership Director] - [Production & Delivery date]
   *
   * @param resourceOrders - A list of new Resource Orders.
   * @param oldMap - A map of old Resource Order values.
   */
  public static void setNameUpdate(
    List<Resource_Order__c> resourceOrders,
    Map<Id, Resource_Order__c> oldMap
  ) {
    Map<Id, Resource_Order__c> resourceOrderMap = new Map<Id, Resource_Order__c>(
      [
        SELECT
          Id,
          Submitted_Date__c,
          Partnership_Director__c,
          LMP_Project__c,
          LMP_Project__r.Counter__c,
          LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c,
          (
            SELECT Id, Resource__r.Name
            FROM Resource_Order_Items__r
            ORDER BY Quantity__c DESC
            LIMIT 1
          )
        FROM Resource_Order__c
        WHERE Id IN :resourceOrders
      ]
    );

    Map<Id, User> partnershipDirectors = getPartnershipDirectors(resourceOrders);

    /*
    Custom setting used as a counter for Resource Orders not linked to an LMP Project. Keep track 
    if it will need to be updated due to a counter increase.
    */
    Resource_Order_Name__c defaultCounter = Resource_Order_Name__c.getOrgDefaults();
    Boolean updateCustomSetting = false;

    // A map of Projects to update as a result of their Counter field getting updated.
    Map<Id, Project__c> projectsToUpdate = new Map<Id, Project__c>();

    for (Resource_Order__c resourceOrder : resourceOrders) {
      Resource_Order__c queriedResourceOrder = resourceOrderMap.get(resourceOrder.Id);
      Resource_Order__c oldResourceOrder = oldMap.get(resourceOrder.Id);
      Project__c relatedLmpProj = null;

      if (queriedResourceOrder.LMP_Project__c != null) {
        relatedLmpProj = new Project__c(
          Id = queriedResourceOrder.LMP_Project__c,
          Counter__c = queriedResourceOrder.LMP_Project__r.Counter__c
        );
      }

      if (queriedResourceOrder != null) {
        String tempName = '';

        // Purpose Code
        if (
          queriedResourceOrder.LMP_Project__c != null &&
          String.isNotBlank(
            queriedResourceOrder.LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c
          )
        ) {
          tempName += (queriedResourceOrder.LMP_Project__r.General_Accounting_Unit__r.Purpose_Code__c +
          ' - ');
        } else {
          // Default Purpose Code to use.
          tempName += '9999 - ';
        }

        // Counter
        if (oldResourceOrder.Name.split(' - ').size() > 1) {
          tempName += oldResourceOrder.Name.split(' - ')[1] + ' - ';
        } else if (relatedLmpProj != null) {
          // Use the counter from the related LMP project.
          if (relatedLmpProj.Counter__c == null) {
            relatedLmpProj.Counter__c = 1;
            projectsToUpdate.put(relatedLmpProj.Id, relatedLmpProj);
          }
          tempName += (String.valueOf(relatedLmpProj.Counter__c).leftPad(4, '0') + ' - ');
        } else {
          // There is no related LMP Project, use the custom settings variable.
          tempName += (String.valueOf(Integer.valueOf(defaultCounter.Counter__c)).leftPad(4, '0') +
          ' - ');
        }

        // Resource Name
        String resourceOrderItemName;
        if (!queriedResourceOrder.Resource_Order_Items__r.isEmpty()) {
          resourceOrderItemName = queriedResourceOrder.Resource_Order_Items__r[0].Resource__r.Name;
          tempName += (resourceOrderItemName + ' - ');
        } else {
          tempName += 'No Items - ';
        }

        // Last name of Partnership Director for this Resource Order
        if (
          resourceOrder.Partnership_Director__c != null &&
          partnershipDirectors.get(resourceOrder.Partnership_Director__c) != null
        ) {
          tempName += (partnershipDirectors.get(resourceOrder.Partnership_Director__c).LastName +
          ' - ');
        } else {
          tempName += 'No Director - ';
        }

        // Date
        String formattedDate;
        if (queriedResourceOrder.Submitted_Date__c != null) {
          Date dateToUse = queriedResourceOrder.Submitted_Date__c;
          formattedDate =
            String.valueOf(dateToUse.month()).leftPad(2, '0') +
            '/' +
            String.valueOf(dateToUse.year());
        } else {
          formattedDate = 'XX/XXXX';
        }

        tempName += formattedDate;

        if (tempName.length() > 80) {
          tempName = form80CharacterName(tempName);
        }

        resourceOrder.Name = tempName;
      }
    }

    if (!projectsToUpdate.isEmpty()) {
      update projectsToUpdate.values();
    }
  }

  public static void rollupResourceOrdersToAccount(
    List<Resource_Order__c> orders,
    Map<Id, Resource_Order__c> oldMap
  ) {
    Map<Id, Account> acctsToUpdate = new Map<Id, Account>();

    for (Resource_Order__c ro : orders) {
      Resource_Order__c old = oldMap != null ? oldMap.get(ro.Id) : null;

      if (
        old == null ||
        (old != null &&
        ((ro.Resource_Order_Total__c != old.Resource_Order_Total__c) ||
        (ro.Account__c != old.Account__c) ||
        (ro.Total_Order_Quanity__c != old.Total_Order_Quanity__c)))
      ) {
        if (ro.Account__c != null) {
          Account acct = new Account(
            Id = ro.Account__c,
            Total_Orders_Amount__c = 0,
            Number_of_Resource_Item_Quantity__c = 0,
            Number_of_Resource_Orders__c = 0
          );
          acctsToUpdate.put(ro.Account__c, acct);
        }
        if (old != null && old.Account__c != null && old.Account__c != ro.Account__c) {
          Account acct = new Account(
            Id = old.Account__c,
            Total_Orders_Amount__c = 0,
            Number_of_Resource_Item_Quantity__c = 0,
            Number_of_Resource_Orders__c = 0
          );
          acctsToUpdate.put(old.Account__c, acct);
        }
      }
    }

    if (!acctsToUpdate.isEmpty()) {
      for (AggregateResult ar : [
        SELECT SUM(Resource_Order_Total__c) amt, Account__c
        FROM Resource_Order__c
        WHERE Account__c IN :acctsToUpdate.keySet() AND Resource_Order_Total__c != NULL
        GROUP BY Account__c
      ]) {
        Id acctId = String.valueOf(ar.get('Account__c'));
        if (acctId != null) {
          Account acct = acctsToUpdate.get(acctId);
          acct.Total_Orders_Amount__c = Double.valueOf(ar.get('amt'));
        }
      }
      for (AggregateResult ar : [
        SELECT SUM(Total_Order_Quanity__c) qty, COUNT(Id) ct, Account__c
        FROM Resource_Order__c
        WHERE
          Account__c IN :acctsToUpdate.keySet()
          AND Resource_Order_Total__c != NULL
          AND Submitted_Date__c >= :Date.today().addYears(-5)
        GROUP BY Account__c
      ]) {
        Id acctId = String.valueOf(ar.get('Account__c'));
        if (acctId != null) {
          Account acct = acctsToUpdate.get(acctId);
          acct.Number_of_Resource_Item_Quantity__c = Double.valueOf(ar.get('qty'));
          acct.Number_of_Resource_Orders__c = Double.valueOf(ar.get('ct'));
        }
      }
      if (!acctsToUpdate.isEmpty()) {
        update acctsToUpdate.values();
      }
    }
  }

  public static void updateProjectRollups(
    List<Resource_Order__c> orders,
    Map<Id, Resource_Order__c> oldMap
  ) {
    Map<Id, Project__c> projectsToUpdate = new Map<Id, Project__c>();
    for (Resource_Order__c ro : orders) {
      Resource_Order__c old = oldMap != null ? oldMap.get(ro.Id) : null;

      if ((old != null && (ro.LMP_Project__c != old.LMP_Project__c))) {
        if (ro.LMP_Project__c != null) {
          Project__c proj = new Project__c(Id = ro.LMP_Project__c, Print_Reach__c = 0);
          projectsToUpdate.put(ro.LMP_Project__c, proj);
        }
        if (old != null && old.LMP_Project__c != null && old.LMP_Project__c != ro.LMP_Project__c) {
          Project__c proj = new Project__c(Id = old.LMP_Project__c, Print_Reach__c = 0);
          projectsToUpdate.put(old.LMP_Project__c, proj);
        }
      }
    }
    if (!projectsToUpdate.isEmpty()) {
      // This method does the project rollups from the resource items
      ResourceOrderItemService.projectRollups(new Set<Id>(), projectsToUpdate);
    }
  }

  public static void createTasksForResourceOrders(
    List<Resource_Order__c> orders,
    Map<Id, Resource_Order__c> oldMap
  ) {
    List<Task> tasksToCreate = new List<Task>();
    List<Resource_Order__c> resourceOrderToUpdate = new List<Resource_Order__c>();

    for (Resource_Order__c ro : orders) {
      Resource_Order__c old = oldMap != null ? oldMap.get(ro.Id) : null;

      if (old == null || (old != null && (ro.Status__c != old.Status__c))) {
        switch on ro.Status__c {
          when 'Information Gathering' {
            if (ro.Information_Gathering__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Partnership Director completes the Print Estimate Request Form which kicks off the process.',
                    'Print Estimate Request Form',
                    ro.Id
                  )
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Information_Gathering__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Cost Estimate and Proposal' {
            if (ro.Cost_Estimate_Proposal__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Research for initial print project proposal: materials, production costs, shipping costs, (estimates & quotes) and standard margin.',
                    'Research for Initial Proposal',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Send estimate to Project Manager and Partnership Director with mark up included.',
                    'Send Estimates',
                    ro.Id
                  )
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Cost_Estimate_Proposal__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Acceptance and Sales Agreement' {
            if (ro.Acceptance_Sales_Agreement__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Answer Partner questions and negotiate final terms.',
                    'Questions and Final Negotiations',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Once the Partner agrees to proposal, draft the Print Sales Agreement to record the agreed details and send to Partner via DocuSign.',
                    'Draft Agreement and send via DocuSign',
                    ro.Id
                  )
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Acceptance_Sales_Agreement__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Systems Update and Project Details' {
            if (ro.Systems_Update_Project_Details__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Create Resource Order and Proforma Invoice from Great Plains.',
                    'Proforma Invoice',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Confirm receipt of initial payment from client. Notify Production.',
                    'Confirm Receipt and Notify Production',
                    ro.Id
                  )
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Systems_Update_Project_Details__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Production and Delivery' {
            if (ro.Production_Delivery__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Prepare a Purchase Order in GP.',
                    'Prepare Purchase Order',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Create Final Product Invoice and send to Project Manager.',
                    'Create Final Product Invoice',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Email confirmation of product order delivery to Partner and all Biblica staff involved.',
                    'Email Confirmation to Partner',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Prepare a Purchase Order for the printer.  Materials purchased, printer booked, etc. ',
                    'Prepare Purchase Order',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Product Production.Notify Project Manager of estimated completion date and actual completion.',
                    'Notify PM of Estimated Completion Date',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Product Delivery, Shipping,and Receipt. Various delivery and shipping, customs documentsas necessary. Notify Project Manager of product delivery.',
                    'Shipping and Delivery Tasking',
                    ro.Id
                  )
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Production_Delivery__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Final Invoice and Payment' {
            if (ro.Final_Invoice_Payment_Completion__c == null) {
              if (ro.Project_Manager__c != null) {
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Create and send Final Shipping Invoice to Partner. Including shipping and handling charges, as agreed.',
                    'Send Shipping Invoice',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(
                    ro.Project_Manager__c,
                    'Confirm receipt of final payment from Partner. Follow up as necessary.',
                    'Confirm Final Payment',
                    ro.Id
                  )
                );
                tasksToCreate.add(
                  createTask(ro.Project_Manager__c, 'Close project.', 'Close project.', ro.Id)
                );
              }
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Final_Invoice_Payment_Completion__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when 'Complete' {
            if (ro.Complete__c == null) {
              Resource_Order__c temp = new Resource_Order__c(
                Id = ro.Id,
                Complete__c = Datetime.now()
              );
              resourceOrderToUpdate.add(temp);
            }
          }
          when else {
          }
        }
      }
    }
    if (!tasksToCreate.isEmpty()) {
      insert tasksToCreate;
    }
    if (!resourceOrderToUpdate.isEmpty()) {
      update resourceOrderToUpdate;
    }
  }

  public static Task createTask(Id userId, String description, String subject, Id roId) {
    Task t = new Task(
      ActivityDate = Date.today().addDays(14),
      Description = description,
      OwnerId = userId,
      Priority = 'Normal',
      Status = 'Not Started',
      Subject = subject,
      WhatId = roId
    );
    return t;
  }
}