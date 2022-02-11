@isTest
public class UnitTestHelper {
  public static Boolean suppressAddressValidation = false;

  public static User getCurrentUser() {
    return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
  }

  public static User createCommunityUser(Id conId, String email) {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Staff Portal User'];
    User newUser = new User();
    newUser.Alias = 'test';
    newUser.Email = email;
    newUser.EmailEncodingKey = 'UTF-8';
    newUser.LastName = 'Test';
    newUser.LanguageLocaleKey = 'en_US';
    newUser.LocaleSidKey = 'en_US';
    newUser.ProfileId = p.Id;
    newUser.TimeZoneSidKey = 'America/Los_Angeles';
    newUser.UserName = email;
    insert newUser;
    return newUser;
  }

  public static User createStandardUser() {
    Profile p = [SELECT Id FROM profile WHERE name = 'Standard User'];
    return new User(
      alias = 'newUser',
      email = 'newuser@iv-testorg.com',
      emailencodingkey = 'UTF-8',
      lastname = 'Testing',
      languagelocalekey = 'en_US',
      localesidkey = 'en_US',
      profileid = p.Id,
      timezonesidkey = 'America/Los_Angeles',
      username = Math.random() + 'newuser@testorg.com'
    );
  }
}