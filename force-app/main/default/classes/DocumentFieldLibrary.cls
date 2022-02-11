public class DocumentFieldLibrary {
  public Date today { get; set; }
  public Date tomorrow { get; set; }
  public Date yesterday { get; set; }
  public Datetime now { get; set; }
  public Id userId { get; set; }
  public String userName { get; set; }
  public String userEmail { get; set; }
  public Map<String, String> mergeFieldMap { get; set; }
  public List<Integer> monthIntegers { get; set; }
  public List<String> monthNames { get; set; }
  public List<String> monthShortNames { get; set; }
  public List<List<String>> monthNamesSeparated { get; set; }

  public DocumentFieldLibrary() {
    this.today = Date.today();
    this.tomorrow = Date.today() + 1;
    this.yesterday = Date.today() - 1;
    this.now = Datetime.now();
    this.userId = UserInfo.getUserId();
    this.userName = UserInfo.getUserName();
    this.userEmail = UserInfo.getUserEmail();
    this.mergeFieldMap = new Map<String, String>();
    this.mergeFieldMap.put('{!today}', String.valueOf(this.today));
    this.mergeFieldMap.put('{!tomorrow}', String.valueOf(this.tomorrow));
    this.mergeFieldMap.put('{!yesterday}', String.valueOf(this.yesterday));
    this.mergeFieldMap.put('{!now}', String.valueOf(this.now));
    this.mergeFieldMap.put('{!userinfo.getuserid()}', this.userId);
    this.mergeFieldMap.put('{!userinfo.getusername()}', this.userName);
    this.mergeFieldMap.put('{!userinfo.getusername()}', this.userEmail);
    this.monthIntegers = new List<Integer>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
    this.monthNames = new List<String>{
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    };
    this.monthShortNames = new List<String>{
      'Jan.',
      'Feb.',
      'Mar.',
      'Apr.',
      'May',
      'Jun.',
      'Jul.',
      'Aug.',
      'Sept.',
      'Oct.',
      'Nov.',
      'Dec.'
    };
    this.monthNamesSeparated = new List<List<String>>{
      new List<String>{'January', 'July'},
      new List<String>{'February', 'August'},
      new List<String>{'March', 'September'},
      new List<String>{'April', 'October'},
      new List<String>{'May', 'November'},
      new List<String>{'June', 'December'}
    };
  }
}