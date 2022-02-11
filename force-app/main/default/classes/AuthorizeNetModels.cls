public class AuthorizeNetModels {
  private static final String DEFAULT_NAMESPACE = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';

  public static String generateXmlNode(String name, Object value) {
    return '<' + name + '>' + String.valueOf(value) + '</' + name + '>';
  }

  public static String getImmediateChildNodeValue(
    Dom.XmlNode parentNode,
    String childNodeName,
    String namespace
  ) {
    if (parentNode == null) {
      return null;
    }
    Dom.XmlNode childNode = parentNode.getChildElement(childNodeName, namespace);
    return (childNode != null ? childNode.getText().trim() : null);
  }

  public class settingType {
    public String settingName;
    public String settingValue;

    public String toXML() {
      String xml = '<setting>';
      if (this.settingName != null)
        xml += generateXmlNode('settingName', this.settingName);
      if (this.settingValue != null)
        xml += generateXmlNode('settingValue', this.settingValue);
      xml += '</setting>';
      return xml;
    }
  }
  public class userField {
    public String name;
    public String value;

    public userField() {
    }
    public userField(Dom.XmlNode userNode) {
      this.name = getImmediateChildNodeValue(userNode, 'name', DEFAULT_NAMESPACE);
      this.value = getImmediateChildNodeValue(userNode, 'value', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<userField>';
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.value != null)
        xml += generateXmlNode('value', this.value);
      xml += '</userField>';
      return xml;
    }
  }
  public class lineItemType {
    public String itemId;
    public String name;
    public String description;
    public Decimal quantity;
    public Decimal unitPrice;
    public Boolean taxable;

    public lineItemType() {
    }
    public lineItemType(Dom.XmlNode lineItemNode) {
      this.itemId = getImmediateChildNodeValue(lineItemNode, 'itemId', DEFAULT_NAMESPACE);
      this.name = getImmediateChildNodeValue(lineItemNode, 'name', DEFAULT_NAMESPACE);
      this.description = getImmediateChildNodeValue(lineItemNode, 'description', DEFAULT_NAMESPACE);
      this.quantity = getImmediateChildNodeValue(lineItemNode, 'quantity', DEFAULT_NAMESPACE) !=
        null
        ? Integer.valueOf(getImmediateChildNodeValue(lineItemNode, 'quantity', DEFAULT_NAMESPACE))
        : null;
      this.unitPrice = getImmediateChildNodeValue(lineItemNode, 'unitPrice', DEFAULT_NAMESPACE) !=
        null
        ? Decimal.valueOf(getImmediateChildNodeValue(lineItemNode, 'unitPrice', DEFAULT_NAMESPACE))
        : null;
      this.taxable = getImmediateChildNodeValue(lineItemNode, 'taxable', DEFAULT_NAMESPACE) != null
        ? Boolean.valueOf(getImmediateChildNodeValue(lineItemNode, 'taxable', DEFAULT_NAMESPACE))
        : null;
    }

    public String toXML() {
      String xml = '<lineItem>';
      if (this.itemId != null)
        xml += generateXmlNode('itemId', this.itemId);
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      if (this.quantity != null)
        xml += generateXmlNode('quantity', this.quantity);
      if (this.unitPrice != null)
        xml += generateXmlNode('unitPrice', this.unitPrice);
      if (this.taxable != null)
        xml += generateXmlNode('taxable', this.taxable);
      xml += '</lineItem>';
      return xml;
    }
  }
  public class batchStatisticType {
    public String accountType;
    public Decimal chargeAmount;
    public Integer chargeCount;
    public Decimal refundAmount;
    public Integer refundCount;
    public Integer voidCount;
    public Integer declineCount;
    public Integer errorCount;
    public Decimal returnedItemAmount;
    public Integer returnedItemCount;
    public Decimal chargebackAmount;
    public Integer chargebackCount;
    public Integer correctionNoticeCount;
    public Decimal chargeChargeBackAmount;
    public Integer chargeChargeBackCount;
    public Decimal refundChargeBackAmount;
    public Integer refundChargeBackCount;
    public Decimal chargeReturnedItemsAmount;
    public Integer chargeReturnedItemsCount;
    public Decimal refundReturnedItemsAmount;
    public Integer refundReturnedItemsCount;

    public batchStatisticType(Dom.XmlNode batchStatisticsNode) {
      this.accountType = getImmediateChildNodeValue(
        batchStatisticsNode,
        'accountType',
        DEFAULT_NAMESPACE
      );
      this.chargeAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'chargeAmount', DEFAULT_NAMESPACE)
          )
        : null;
      this.chargeCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'chargeCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.refundAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'refundAmount', DEFAULT_NAMESPACE)
          )
        : null;
      this.refundCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'refundCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.voidCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'voidCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'voidCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.declineCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'declineCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'declineCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.errorCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'errorCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'errorCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.returnedItemAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'returnedItemAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'returnedItemAmount', DEFAULT_NAMESPACE)
          )
        : null;
      this.returnedItemCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'returnedItemCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'returnedItemCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.chargebackAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargebackAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'chargebackAmount', DEFAULT_NAMESPACE)
          )
        : null;
      this.chargebackCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargebackCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(batchStatisticsNode, 'chargebackCount', DEFAULT_NAMESPACE)
          )
        : null;
      this.correctionNoticeCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'correctionNoticeCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'correctionNoticeCount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.chargeChargeBackAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeChargeBackAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'chargeChargeBackAmount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.chargeChargeBackCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeChargeBackCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'chargeChargeBackCount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.refundChargeBackAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundChargeBackAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'refundChargeBackAmount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.refundChargeBackCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundChargeBackCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'refundChargeBackCount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.chargeReturnedItemsAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeReturnedItemsAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'chargeReturnedItemsAmount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.chargeReturnedItemsCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'chargeReturnedItemsCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'chargeReturnedItemsCount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.refundReturnedItemsAmount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundReturnedItemsAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'refundReturnedItemsAmount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
      this.refundReturnedItemsCount = getImmediateChildNodeValue(
          batchStatisticsNode,
          'refundReturnedItemsCount',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(
              batchStatisticsNode,
              'refundReturnedItemsCount',
              DEFAULT_NAMESPACE
            )
          )
        : null;
    }

    //public String toXML() {
    //  String xml = '<statistic>';
    //  if (this.accountType != null) xml += generateXmlNode('accountType', this.accountType);
    //  if (this.chargeAmount != null) xml += generateXmlNode('chargeAmount', this.chargeAmount);
    //  if (this.chargeCount != null) xml += generateXmlNode('chargeCount', this.chargeCount);
    //  if (this.refundAmount != null) xml += generateXmlNode('refundAmount', this.refundAmount);
    //  if (this.refundCount != null) xml += generateXmlNode('refundCount', this.refundCount);
    //  if (this.voidCount != null) xml += generateXmlNode('voidCount', this.voidCount);
    //  if (this.declineCount != null) xml += generateXmlNode('declineCount', this.declineCount);
    //  if (this.errorCount != null) xml += generateXmlNode('errorCount', this.errorCount);
    //  if (this.returnedItemAmount != null) xml += generateXmlNode('returnedItemAmount', this.returnedItemAmount);
    //  if (this.returnedItemCount != null) xml += generateXmlNode('returnedItemCount', this.returnedItemCount);
    //  if (this.chargebackAmount != null) xml += generateXmlNode('chargebackAmount', this.chargebackAmount);
    //  if (this.chargebackCount != null) xml += generateXmlNode('chargebackCount', this.chargebackCount);
    //  if (this.correctionNoticeCount != null) xml += generateXmlNode('correctionNoticeCount', this.correctionNoticeCount);
    //  if (this.chargeChargeBackAmount != null) xml += generateXmlNode('chargeChargeBackAmount', this.chargeChargeBackAmount);
    //  if (this.chargeChargeBackCount != null) xml += generateXmlNode('chargeChargeBackCount', this.chargeChargeBackCount);
    //  if (this.refundChargeBackAmount != null) xml += generateXmlNode('refundChargeBackAmount', this.refundChargeBackAmount);
    //  if (this.refundChargeBackCount != null) xml += generateXmlNode('refundChargeBackCount', this.refundChargeBackCount);
    //  if (this.chargeReturnedItemsAmount != null) xml += generateXmlNode('chargeReturnedItemsAmount', this.chargeReturnedItemsAmount);
    //  if (this.chargeReturnedItemsCount != null) xml += generateXmlNode('chargeReturnedItemsCount', this.chargeReturnedItemsCount);
    //  if (this.refundReturnedItemsAmount != null) xml += generateXmlNode('refundReturnedItemsAmount', this.refundReturnedItemsAmount);
    //  if (this.refundReturnedItemsCount != null) xml += generateXmlNode('refundReturnedItemsCount', this.refundReturnedItemsCount);
    //  xml += '</statistic>';
    //  return xml;
    //}
  }
  public class batchDetailsType {
    public String batchId;
    public String settlementTimeUTC;
    public String settlementTimeLocal;
    public String settlementState;
    public String paymentMethod;
    public String marketType;
    public String product;
    public batchStatisticType[] statistics;

    public batchDetailsType(Dom.XmlNode batchDetailsNode) {
      this.batchId = getImmediateChildNodeValue(batchDetailsNode, 'batchId', DEFAULT_NAMESPACE);
      this.settlementTimeUTC = getImmediateChildNodeValue(
        batchDetailsNode,
        'settlementTimeUTC',
        DEFAULT_NAMESPACE
      );
      this.settlementTimeLocal = getImmediateChildNodeValue(
        batchDetailsNode,
        'settlementTimeLocal',
        DEFAULT_NAMESPACE
      );
      this.settlementTimeLocal = getImmediateChildNodeValue(
        batchDetailsNode,
        'settlementTimeLocal',
        DEFAULT_NAMESPACE
      );
      this.paymentMethod = getImmediateChildNodeValue(
        batchDetailsNode,
        'paymentMethod',
        DEFAULT_NAMESPACE
      );
      this.marketType = getImmediateChildNodeValue(
        batchDetailsNode,
        'marketType',
        DEFAULT_NAMESPACE
      );
      this.product = getImmediateChildNodeValue(batchDetailsNode, 'product', DEFAULT_NAMESPACE);
      if (batchDetailsNode.getChildElement('statistics', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode statisticsNode = batchDetailsNode.getChildElement(
          'statistics',
          DEFAULT_NAMESPACE
        );
        this.statistics = new List<batchStatisticType>();
        for (Dom.XmlNode statisticNode : statisticsNode.getChildElements()) {
          this.statistics.add(new batchStatisticType(statisticNode));
        }
      }
    }

    //public String toXML() {
    //  String xml = '<batch>';
    //  if (this.batchId != null) xml += generateXmlNode('batchId', this.batchId);
    //  if (this.settlementTimeUTC != null) xml += generateXmlNode('settlementTimeUTC', this.settlementTimeUTC);
    //  if (this.settlementTimeLocal != null) xml += generateXmlNode('settlementTimeLocal', this.settlementTimeLocal);
    //  if (this.settlementState != null) xml += generateXmlNode('settlementState', this.settlementState);
    //  if (this.paymentMethod != null) xml += generateXmlNode('paymentMethod', this.paymentMethod);
    //  if (this.marketType != null) xml += generateXmlNode('marketType', this.marketType);
    //  if (this.product != null) xml += generateXmlNode('product', this.product);
    //  if (this.statistics != null) {
    //    xml += '<statistics>';
    //    for (batchStatisticType statistic : this.statistics) {
    //      xml += statistic.toXML();
    //    }
    //    xml += '</statistics>';
    //  }
    //  xml += '</batch>';
    //  return xml;
    //}
  }
  public class transactionSummaryType {
    public String transId;
    public String submitTimeUTC;
    public String submitTimeLocal;
    public String transactionStatus;
    public String invoiceNumber;
    public String firstName;
    public String lastName;
    public String accountType;
    public String accountNumber;
    public Decimal settleAmount;
    public String marketType;
    public String product;
    public String mobileDeviceId;
    public subscriptionPaymentType subscription;
    public Boolean hasReturnedItems;
    public customerProfileIdType profile;

    public transactionSummaryType(Dom.XmlNode tsNode) {
      this.transId = getImmediateChildNodeValue(tsNode, 'transId', DEFAULT_NAMESPACE);
      this.submitTimeUTC = getImmediateChildNodeValue(tsNode, 'submitTimeUTC', DEFAULT_NAMESPACE);
      this.submitTimeLocal = getImmediateChildNodeValue(
        tsNode,
        'submitTimeLocal',
        DEFAULT_NAMESPACE
      );
      this.transactionStatus = getImmediateChildNodeValue(
        tsNode,
        'transactionStatus',
        DEFAULT_NAMESPACE
      );
      this.invoiceNumber = getImmediateChildNodeValue(tsNode, 'invoiceNumber', DEFAULT_NAMESPACE);
      this.firstName = getImmediateChildNodeValue(tsNode, 'firstName', DEFAULT_NAMESPACE);
      this.lastName = getImmediateChildNodeValue(tsNode, 'lastName', DEFAULT_NAMESPACE);
      this.accountType = getImmediateChildNodeValue(tsNode, 'accountType', DEFAULT_NAMESPACE);
      this.accountNumber = getImmediateChildNodeValue(tsNode, 'accountNumber', DEFAULT_NAMESPACE);
      this.settleAmount = getImmediateChildNodeValue(tsNode, 'settleAmount', DEFAULT_NAMESPACE) !=
        null
        ? Decimal.valueOf(getImmediateChildNodeValue(tsNode, 'settleAmount', DEFAULT_NAMESPACE))
        : null;
      this.hasReturnedItems = getImmediateChildNodeValue(
          tsNode,
          'hasReturnedItems',
          DEFAULT_NAMESPACE
        ) != null
        ? Boolean.valueOf(getImmediateChildNodeValue(tsNode, 'hasReturnedItems', DEFAULT_NAMESPACE))
        : null;
      this.marketType = getImmediateChildNodeValue(tsNode, 'marketType', DEFAULT_NAMESPACE);
      this.product = getImmediateChildNodeValue(tsNode, 'product', DEFAULT_NAMESPACE);
      this.mobileDeviceId = getImmediateChildNodeValue(tsNode, 'mobileDeviceId', DEFAULT_NAMESPACE);
      if (tsNode.getChildElement('subscription', DEFAULT_NAMESPACE) != null) {
        this.subscription = new subscriptionPaymentType(
          tsNode.getChildElement('subscription', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class subscriptionPaymentType {
    public String id;
    public Integer payNum;

    public subscriptionPaymentType(Dom.XmlNode subNode) {
      this.id = getImmediateChildNodeValue(subNode, 'id', DEFAULT_NAMESPACE);
      this.payNum = getImmediateChildNodeValue(subNode, 'payNum', DEFAULT_NAMESPACE) != null
        ? Integer.valueOf(getImmediateChildNodeValue(subNode, 'payNum', DEFAULT_NAMESPACE))
        : null;
    }
  }
  public class FDSFilterType {
    public String name;
    public String action;

    public FDSFilterType(Dom.XmlNode fdsFilterNode) {
      this.name = getImmediateChildNodeValue(fdsFilterNode, 'name', DEFAULT_NAMESPACE);
      this.action = getImmediateChildNodeValue(fdsFilterNode, 'action', DEFAULT_NAMESPACE);
    }
  }
  public class driversLicenseType {
    public String num;
    public String state;
    public String dateOfBirth;

    public driversLicenseType() {
    }
    public driversLicenseType(Dom.XmlNode dlNode) {
      this.num = getImmediateChildNodeValue(dlNode, 'number', DEFAULT_NAMESPACE);
      this.state = getImmediateChildNodeValue(dlNode, 'state', DEFAULT_NAMESPACE);
      this.dateOfBirth = getImmediateChildNodeValue(dlNode, 'dateOfBirth', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<driversLicense>';
      if (this.num != null)
        xml += generateXmlNode('number', this.num);
      if (this.state != null)
        xml += generateXmlNode('state', this.state);
      if (this.dateOfBirth != null)
        xml += generateXmlNode('dateOfBirth', this.dateOfBirth);
      xml += '</driversLicense>';
      return xml;
    }
  }
  public class addressType {
    public String firstName;
    public String lastName;
    public String company;
    public String address;
    public String city;
    public String state;
    public String zip;
    public String country;
    public String phoneNumber;
    public String faxNumber;
    public String email;
    public String customerAddressId;

    public addressType() {
    }
    public addressType(Dom.XmlNode node) {
      this.firstName = getImmediateChildNodeValue(node, 'firstName', DEFAULT_NAMESPACE);
      this.lastName = getImmediateChildNodeValue(node, 'lastName', DEFAULT_NAMESPACE);
      this.company = getImmediateChildNodeValue(node, 'company', DEFAULT_NAMESPACE);
      this.address = getImmediateChildNodeValue(node, 'address', DEFAULT_NAMESPACE);
      this.city = getImmediateChildNodeValue(node, 'city', DEFAULT_NAMESPACE);
      this.state = getImmediateChildNodeValue(node, 'state', DEFAULT_NAMESPACE);
      this.zip = getImmediateChildNodeValue(node, 'zip', DEFAULT_NAMESPACE);
      this.country = getImmediateChildNodeValue(node, 'country', DEFAULT_NAMESPACE);
      this.phoneNumber = getImmediateChildNodeValue(node, 'phoneNumber', DEFAULT_NAMESPACE);
      this.faxNumber = getImmediateChildNodeValue(node, 'faxNumber', DEFAULT_NAMESPACE);
      this.email = getImmediateChildNodeValue(node, 'email', DEFAULT_NAMESPACE);
      this.customerAddressId = getImmediateChildNodeValue(
        node,
        'customerAddressId',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML(String baseNodeName) {
      String xml = '<' + baseNodeName + '>';
      if (this.firstName != null)
        xml += generateXmlNode('firstName', this.firstName);
      if (this.lastName != null)
        xml += generateXmlNode('lastName', this.lastName);
      if (this.company != null)
        xml += generateXmlNode('company', this.company);
      if (this.address != null)
        xml += generateXmlNode('address', this.address);
      if (this.city != null)
        xml += generateXmlNode('city', this.city);
      if (this.state != null)
        xml += generateXmlNode('state', this.state);
      if (this.zip != null)
        xml += generateXmlNode('zip', this.zip);
      if (this.country != null)
        xml += generateXmlNode('country', this.country);
      if (this.phoneNumber != null)
        xml += generateXmlNode('phoneNumber', this.phoneNumber);
      if (this.faxNumber != null)
        xml += generateXmlNode('faxNumber', this.faxNumber);
      if (this.email != null)
        xml += generateXmlNode('email', this.email);
      if (this.customerAddressId != null)
        xml += generateXmlNode('customerAddressId', this.customerAddressId);
      xml += '</' + baseNodeName + '>';
      return xml;
    }
  }
  public class transRetailInfoType {
    public String marketType;
    public String deviceType;
    public String customerSignature;

    public String toXML() {
      String xml = '<retail>';
      if (this.marketType != null)
        xml += generateXmlNode('marketType', this.marketType);
      if (this.deviceType != null)
        xml += generateXmlNode('deviceType', this.deviceType);
      if (this.customerSignature != null)
        xml += generateXmlNode('customerSignature', this.customerSignature);
      xml += '</retail>';
      return xml;
    }
  }
  public class ccAuthenticationType {
    public String authenticationIndicator;
    public String cardholderAuthenticationValue;

    public String toXML() {
      String xml = '<cardholderAuthentication>';
      if (this.authenticationIndicator != null)
        xml += generateXmlNode('authenticationIndicator', this.authenticationIndicator);
      if (this.cardholderAuthenticationValue != null)
        xml += generateXmlNode('cardholderAuthenticationValue', this.cardholderAuthenticationValue);
      xml += '</cardholderAuthentication>';
      return xml;
    }
  }
  public class paymentType {
    public creditCardType creditCard;
    public bankAccountType bankAccount;
    public opaqueDataType opaqueData;

    public paymentType() {
    }
    public paymentType(Dom.XmlNode paymentNode) {
      if (paymentNode.getChildElement('creditCard', DEFAULT_NAMESPACE) != null) {
        this.creditCard = new creditCardType(
          paymentNode.getChildElement('creditCard', DEFAULT_NAMESPACE)
        );
      }
      if (paymentNode.getChildElement('bankAccount', DEFAULT_NAMESPACE) != null) {
        this.bankAccount = new bankAccountType(
          paymentNode.getChildElement('bankAccount', DEFAULT_NAMESPACE)
        );
      }
      if (paymentNode.getChildElement('opaqueData', DEFAULT_NAMESPACE) != null) {
        this.opaqueData = new opaqueDataType(
          paymentNode.getChildElement('opaqueData', DEFAULT_NAMESPACE)
        );
      }
    }

    public String toXML() {
      String xml = '<payment>';
      if (this.creditCard != null) {
        xml += this.creditCard.toXML();
      }
      if (this.bankAccount != null) {
        xml += this.bankAccount.toXML();
      }
      if (this.opaqueData != null) {
        xml += this.opaqueData.toXML();
      }
      xml += '</payment>';
      return xml;
    }
  }
  public class creditCardType {
    public String cardNumber;
    public String expirationDate;
    public String cardCode;
    public String issuerNumber;
    public String cardType;

    public creditCardType() {
    }
    public creditCardType(Dom.XmlNode creditCardNode) {
      this.cardCode = getImmediateChildNodeValue(creditCardNode, 'cardCode', DEFAULT_NAMESPACE);
      this.cardNumber = getImmediateChildNodeValue(creditCardNode, 'cardNumber', DEFAULT_NAMESPACE);
      this.expirationDate = getImmediateChildNodeValue(
        creditCardNode,
        'expirationDate',
        DEFAULT_NAMESPACE
      );
      this.issuerNumber = getImmediateChildNodeValue(
        creditCardNode,
        'issuerNumber',
        DEFAULT_NAMESPACE
      );
      this.cardType = getImmediateChildNodeValue(creditCardNode, 'cardType', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<creditCard>';
      if (this.cardNumber != null)
        xml += generateXmlNode('cardNumber', this.cardNumber);
      if (this.expirationDate != null)
        xml += generateXmlNode('expirationDate', this.expirationDate);
      if (this.cardCode != null)
        xml += generateXmlNode('cardCode', this.cardCode);
      xml += '</creditCard>';
      return xml;
    }
  }
  public class bankAccountType {
    public String accountType;
    public String routingNumber;
    public String accountNumber;
    public String nameOnAccount;
    public String echeckType;
    public String bankName;
    public String checkNumber;

    public bankAccountType() {
    }
    public bankAccountType(Dom.XmlNode bankAccountNode) {
      this.accountType = getImmediateChildNodeValue(
        bankAccountNode,
        'accountType',
        DEFAULT_NAMESPACE
      );
      this.routingNumber = getImmediateChildNodeValue(
        bankAccountNode,
        'routingNumber',
        DEFAULT_NAMESPACE
      );
      this.accountNumber = getImmediateChildNodeValue(
        bankAccountNode,
        'accountNumber',
        DEFAULT_NAMESPACE
      );
      this.nameOnAccount = getImmediateChildNodeValue(
        bankAccountNode,
        'nameOnAccount',
        DEFAULT_NAMESPACE
      );
      this.echeckType = getImmediateChildNodeValue(
        bankAccountNode,
        'echeckType',
        DEFAULT_NAMESPACE
      );
      this.bankName = getImmediateChildNodeValue(bankAccountNode, 'bankName', DEFAULT_NAMESPACE);
      this.checkNumber = getImmediateChildNodeValue(
        bankAccountNode,
        'checkNumber',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML() {
      String xml = '<bankAccount>';
      if (this.accountType != null)
        xml += generateXmlNode('accountType', this.accountType);
      if (this.routingNumber != null)
        xml += generateXmlNode('routingNumber', this.routingNumber);
      if (this.accountNumber != null)
        xml += generateXmlNode('accountNumber', this.accountNumber);
      if (this.nameOnAccount != null)
        xml += generateXmlNode('nameOnAccount', this.nameOnAccount);
      if (this.echeckType != null)
        xml += generateXmlNode('echeckType', this.echeckType);
      if (this.bankName != null)
        xml += generateXmlNode('bankName', this.bankName);
      if (this.checkNumber != null)
        xml += generateXmlNode('checkNumber', this.checkNumber);
      xml += '</bankAccount>';
      return xml;
    }
  }
  public class opaqueDataType {
    public String dataDescriptor;
    public String dataValue;
    public String dataKey;
    public String expirationTimeStamp;

    public opaqueDataType() {
    }
    public opaqueDataType(Dom.XmlNode opaqueDataNode) {
      this.dataDescriptor = getImmediateChildNodeValue(
        opaqueDataNode,
        'dataDescriptor',
        DEFAULT_NAMESPACE
      );
      this.dataValue = getImmediateChildNodeValue(opaqueDataNode, 'dataValue', DEFAULT_NAMESPACE);
      this.dataKey = getImmediateChildNodeValue(opaqueDataNode, 'dataKey', DEFAULT_NAMESPACE);
      this.expirationTimeStamp = getImmediateChildNodeValue(
        opaqueDataNode,
        'expirationTimeStamp',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML() {
      String xml = '<opaqueData>';
      if (this.dataDescriptor != null)
        xml += generateXmlNode('dataDescriptor', this.dataDescriptor);
      if (this.dataValue != null)
        xml += generateXmlNode('dataValue', this.dataValue);
      if (this.dataKey != null)
        xml += generateXmlNode('dataKey', this.dataKey);
      if (this.expirationTimeStamp != null)
        xml += generateXmlNode('expirationTimeStamp', this.expirationTimeStamp);
      xml += '</opaqueData>';
      return xml;
    }
  }
  public class orderType {
    public String invoiceNumber;
    public String description;
    public String purchaseOrderNumber;

    public orderType() {
    }
    public orderType(Dom.XmlNode orderNode) {
      this.invoiceNumber = getImmediateChildNodeValue(
        orderNode,
        'invoiceNumber',
        DEFAULT_NAMESPACE
      );
      this.description = getImmediateChildNodeValue(orderNode, 'description', DEFAULT_NAMESPACE);
      this.purchaseOrderNumber = getImmediateChildNodeValue(
        orderNode,
        'purchaseOrderNumber',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML() {
      String xml = '<order>';
      if (this.invoiceNumber != null)
        xml += generateXmlNode('invoiceNumber', this.invoiceNumber);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      if (this.purchaseOrderNumber != null)
        xml += generateXmlNode('purchaseOrderNumber', this.purchaseOrderNumber);
      xml += '</order>';
      return xml;
    }
  }
  public class customerType {
    public String type;
    public String id;
    public String email;
    public String phoneNumber;
    public String faxNumber;
    public driversLicenseType driversLicense;
    public String taxId;

    public customerType() {
    }
    public customerType(Dom.XmlNode customerNode) {
      this.type = getImmediateChildNodeValue(customerNode, 'type', DEFAULT_NAMESPACE);
      this.id = getImmediateChildNodeValue(customerNode, 'id', DEFAULT_NAMESPACE);
      this.email = getImmediateChildNodeValue(customerNode, 'email', DEFAULT_NAMESPACE);
      this.phoneNumber = getImmediateChildNodeValue(customerNode, 'phoneNumber', DEFAULT_NAMESPACE);
      this.faxNumber = getImmediateChildNodeValue(customerNode, 'faxNumber', DEFAULT_NAMESPACE);
      this.taxId = getImmediateChildNodeValue(customerNode, 'taxId', DEFAULT_NAMESPACE);
      if (customerNode.getChildElement('driversLicense', DEFAULT_NAMESPACE) != null) {
        this.driversLicense = new driversLicenseType(
          customerNode.getChildElement('driversLicense', DEFAULT_NAMESPACE)
        );
      }
    }

    public String toXML() {
      String xml = '<customer>';
      if (this.type != null)
        xml += generateXmlNode('type', this.type);
      if (this.id != null)
        xml += generateXmlNode('id', this.id);
      if (this.email != null)
        xml += generateXmlNode('email', this.email);
      if (this.phoneNumber != null)
        xml += generateXmlNode('phoneNumber', this.phoneNumber);
      if (this.faxNumber != null)
        xml += generateXmlNode('faxNumber', this.faxNumber);
      if (this.driversLicense != null)
        xml += this.driversLicense.toXML();
      if (this.taxId != null)
        xml += generateXmlNode('taxId', this.taxId);
      xml += '</customer>';
      return xml;
    }
  }
  public class merchantAuthenticationType {
    public String name;
    public String transactionKey;
    public String mobileDeviceId;

    public merchantAuthenticationType() {
    }
    public merchantAuthenticationType(String name, String transactionKey) {
      this.name = name;
      this.transactionKey = transactionKey;
    }
    public merchantAuthenticationType(String name, String transactionKey, String mobileDeviceId) {
      this.name = name;
      this.transactionKey = transactionKey;
      this.mobileDeviceId = mobileDeviceId;
    }

    public String toXML() {
      String xml = '<merchantAuthentication>';
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.transactionKey != null)
        xml += generateXmlNode('transactionKey', this.transactionKey);
      if (this.mobileDeviceId != null)
        xml += generateXmlNode('mobileDeviceId', this.mobileDeviceId);
      xml += '</merchantAuthentication>';
      return xml;
    }
  }
  public class paymentScheduleType {
    public paymentScheduleTypeInterval interval;
    public String startDate;
    public Integer totalOccurrences;
    public Integer trialOccurrences;

    public paymentScheduleType() {
    }
    public paymentScheduleType(Dom.XmlNode node) {
      if (node.getChildElement('interval', DEFAULT_NAMESPACE) != null) {
        this.interval = new paymentScheduleTypeInterval(
          node.getChildElement('interval', DEFAULT_NAMESPACE)
        );
      }
      this.startDate = getImmediateChildNodeValue(node, 'startDate', DEFAULT_NAMESPACE);
      this.totalOccurrences = getImmediateChildNodeValue(
          node,
          'totalOccurrences',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(getImmediateChildNodeValue(node, 'totalOccurrences', DEFAULT_NAMESPACE))
        : null;
      this.trialOccurrences = getImmediateChildNodeValue(
          node,
          'trialOccurrences',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(getImmediateChildNodeValue(node, 'trialOccurrences', DEFAULT_NAMESPACE))
        : null;
    }

    public String toXML() {
      String xml = '<paymentSchedule>';
      if (this.interval != null)
        xml += this.interval.toXML();
      if (this.startDate != null)
        xml += generateXmlNode('startDate', this.startDate);
      if (this.totalOccurrences != null)
        xml += generateXmlNode('totalOccurrences', this.totalOccurrences);
      if (this.trialOccurrences != null)
        xml += generateXmlNode('trialOccurrences', this.trialOccurrences);
      xml += '</paymentSchedule>';
      return xml;
    }
  }
  public class paymentScheduleTypeInterval {
    public Integer length;
    public String unit;

    public paymentScheduleTypeInterval() {
    }
    public paymentScheduleTypeInterval(Dom.XmlNode node) {
      this.length = getImmediateChildNodeValue(node, 'length', DEFAULT_NAMESPACE) != null
        ? Integer.valueOf(getImmediateChildNodeValue(node, 'length', DEFAULT_NAMESPACE))
        : null;
      this.unit = getImmediateChildNodeValue(node, 'unit', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<interval>';
      if (this.length != null)
        xml += generateXmlNode('length', this.length);
      if (this.unit != null)
        xml += generateXmlNode('unit', this.unit);
      xml += '</interval>';
      return xml;
    }
  }
  public class ARBSubscriptionType {
    public String name;
    public paymentScheduleType paymentSchedule;
    public Decimal amount;
    public Decimal trialAmount;
    public paymentType payment;
    public orderType order;
    public customerType customer;
    public addressType billTo;
    public addressType shipTo;
    public customerProfileIdType profile;

    public String toXML() {
      String xml = '<subscription>';
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.paymentSchedule != null)
        xml += this.paymentSchedule.toXML();
      if (this.amount != null)
        xml += generateXmlNode('amount', this.amount);
      if (this.trialAmount != null)
        xml += generateXmlNode('trialAmount', this.trialAmount);
      if (this.customer != null)
        xml += this.customer.toXML();
      if (this.payment != null)
        xml += this.payment.toXML();
      if (this.order != null)
        xml += this.order.toXML();
      if (this.billTo != null)
        xml += this.billTo.toXML('billTo');
      if (this.shipTo != null)
        xml += this.shipTo.toXML('shipTo');
      if (this.profile != null)
        xml += this.profile.toXML();
      xml += '</subscription>';
      return xml;
    }
  }
  public class ARBSubscriptionMaskedType {
    public String name;
    public paymentScheduleType paymentSchedule;
    public Decimal amount;
    public Decimal trialAmount;
    public String status;
    public customerProfileType profile;
    public orderType order;

    public ARBSubscriptionMaskedType() {
    }
    public ARBSubscriptionMaskedType(Dom.XmlNode node) {
      this.name = getImmediateChildNodeValue(node, 'name', DEFAULT_NAMESPACE);
      if (node.getChildElement('paymentSchedule', DEFAULT_NAMESPACE) != null) {
        this.paymentSchedule = new paymentScheduleType(
          node.getChildElement('paymentSchedule', DEFAULT_NAMESPACE)
        );
      }
      this.amount = getImmediateChildNodeValue(node, 'amount', DEFAULT_NAMESPACE) != null
        ? Decimal.valueOf(getImmediateChildNodeValue(node, 'amount', DEFAULT_NAMESPACE))
        : null;
      this.trialAmount = getImmediateChildNodeValue(node, 'trialAmount', DEFAULT_NAMESPACE) != null
        ? Decimal.valueOf(getImmediateChildNodeValue(node, 'trialAmount', DEFAULT_NAMESPACE))
        : null;
      this.status = getImmediateChildNodeValue(node, 'status', DEFAULT_NAMESPACE);
      if (node.getChildElement('profile', DEFAULT_NAMESPACE) != null) {
        this.profile = new customerProfileType(node.getChildElement('profile', DEFAULT_NAMESPACE));
      }
      if (node.getChildElement('order', DEFAULT_NAMESPACE) != null) {
        this.order = new orderType(node.getChildElement('order', DEFAULT_NAMESPACE));
      }
    }
  }
  public class transactionRequestType {
    public String transactionType;
    public Decimal amount;
    public String currencyCode;
    public paymentType payment;
    public orderType order;
    public lineItemType[] lineItems;
    public extendedAmountType tax;
    public extendedAmountType duty;
    public extendedAmountType shipping;
    public String poNumber;
    public customerType customer;
    public addressType billTo;
    public addressType shipTo;
    public String customerIP;
    public String callId;
    public String terminalNumber;
    public String authCode;
    public String refTransId;
    public String splitTenderId;
    public String employeeId;
    public Boolean taxExempt;
    public solutionType solution;
    public transRetailInfoType retail;
    public ccAuthenticationType cardholderAuthentication;
    public customerProfilePaymentType profile;
    public settingType[] transactionSettings;
    public userField[] userFields;

    public String toXML() {
      String xml = '<transactionRequest>';
      if (this.transactionType != null)
        xml += generateXmlNode('transactionType', this.transactionType);
      if (this.amount != null)
        xml += generateXmlNode('amount', this.amount);
      if (this.payment != null)
        xml += this.payment.toXML();
      if (this.order != null)
        xml += this.order.toXML();
      if (this.lineItems != null) {
        xml += '<lineItems>';
        for (lineItemType li : this.lineItems) {
          xml += li.toXML();
        }
        xml += '</lineItems>';
      }
      if (this.tax != null)
        xml += this.tax.toXML('tax');
      if (this.duty != null)
        xml += this.duty.toXML('duty');
      if (this.shipping != null)
        xml += this.shipping.toXML('shipping');
      if (this.poNumber != null)
        xml += generateXmlNode('poNumber', this.poNumber);
      if (this.customer != null)
        xml += this.customer.toXML();
      if (this.billTo != null)
        xml += this.billTo.toXML('billTo');
      if (this.shipTo != null)
        xml += this.shipTo.toXML('shipTo');
      if (this.customerIP != null)
        xml += generateXmlNode('customerIP', this.customerIP);
      if (this.callId != null)
        xml += generateXmlNode('callId', this.callId);
      if (this.terminalNumber != null)
        xml += generateXmlNode('terminalNumber', this.terminalNumber);
      if (this.authCode != null)
        xml += generateXmlNode('authCode', this.authCode);
      if (this.refTransId != null)
        xml += generateXmlNode('refTransId', this.refTransId);
      if (this.splitTenderId != null)
        xml += generateXmlNode('splitTenderId', this.splitTenderId);
      if (this.employeeId != null)
        xml += generateXmlNode('employeeId', this.employeeId);
      if (this.taxExempt != null)
        xml += generateXmlNode('taxExempt', this.taxExempt);
      if (this.solution != null)
        xml += this.solution.toXML();
      if (this.retail != null)
        xml += this.retail.toXML();
      if (this.cardholderAuthentication != null)
        xml += this.cardholderAuthentication.toXML();
      if (this.profile != null)
        xml += this.profile.toXML();
      if (this.transactionSettings != null) {
        xml += '<transactionSettings>';
        for (settingType setting : this.transactionSettings) {
          xml += setting.toXML();
        }
        xml += '</transactionSettings>';
      }
      if (this.userFields != null) {
        xml += '<userFields>';
        for (userField uField : this.userFields) {
          xml += uField.toXML();
        }
        xml += '</userFields>';
      }
      xml += '</transactionRequest>';
      return xml;
    }
  }
  public class solutionType {
    public String id;
    public String name;
    public String vendorName;

    public solutionType() {
    }
    public solutionType(Dom.XmlNode solutionNode) {
      this.id = getImmediateChildNodeValue(solutionNode, 'id', DEFAULT_NAMESPACE);
      this.name = getImmediateChildNodeValue(solutionNode, 'name', DEFAULT_NAMESPACE);
      this.vendorName = getImmediateChildNodeValue(solutionNode, 'vendorName', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<solution>';
      if (this.id != null)
        xml += generateXmlNode('id', this.id);
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.vendorName != null)
        xml += generateXmlNode('vendorName', this.vendorName);
      xml += '</solution>';
      return xml;
    }
  }
  public class extendedAmountType {
    public Decimal amount;
    public String name;
    public String description;

    public extendedAmountType() {
    }
    public extendedAmountType(Dom.XmlNode extendedAmountNode) {
      this.name = getImmediateChildNodeValue(extendedAmountNode, 'name', DEFAULT_NAMESPACE);
      this.description = getImmediateChildNodeValue(
        extendedAmountNode,
        'description',
        DEFAULT_NAMESPACE
      );
      this.amount = getImmediateChildNodeValue(extendedAmountNode, 'amount', DEFAULT_NAMESPACE) !=
        null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(extendedAmountNode, 'amount', DEFAULT_NAMESPACE)
          )
        : null;
    }

    public String toXML(String baseNodeName) {
      String xml = '<' + baseNodeName + '>';
      if (this.name != null)
        xml += generateXmlNode('name', this.name);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      if (this.amount != null)
        xml += generateXmlNode('amount', this.amount);
      xml += '</' + baseNodeName + '>';
      return xml;
    }
  }
  public class paymentProfile {
    public String paymentProfileId;
    public String cardCode;

    public paymentProfile() {
    }
    public paymentProfile(Dom.XmlNode paymentProfileNode) {
      this.paymentProfileId = getImmediateChildNodeValue(
        paymentProfileNode,
        'paymentProfileId',
        DEFAULT_NAMESPACE
      );
      this.cardCode = getImmediateChildNodeValue(paymentProfileNode, 'cardCode', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<paymentProfile>';
      if (this.paymentProfileId != null)
        xml += generateXmlNode('paymentProfileId', this.paymentProfileId);
      if (this.cardCode != null)
        xml += generateXmlNode('cardCode', this.cardCode);
      xml += '</paymentProfile>';
      return xml;
    }
  }
  public class customerPaymentProfileType {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public String customerType; // String. Either individual or business
    public addressType billTo;
    public paymentType payment;
    public driversLicenseType driversLicense;
    public String taxId;
    public String[] subscriptionIds;
    public Boolean defaultPaymentProfile;

    public customerPaymentProfileType() {
    }
    public customerPaymentProfileType(Dom.XmlNode node) {
      // not sure if needed this.defaultPaymentProfile = getImmediateChildNodeValue(node, 'defaultPaymentProfile', DEFAULT_NAMESPACE);
      this.customerProfileId = getImmediateChildNodeValue(
        node,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      this.customerPaymentProfileId = getImmediateChildNodeValue(
        node,
        'customerPaymentProfileId',
        DEFAULT_NAMESPACE
      );
      this.customerType = getImmediateChildNodeValue(node, 'customerType', DEFAULT_NAMESPACE);
      this.taxId = getImmediateChildNodeValue(node, 'taxId', DEFAULT_NAMESPACE);
      if (node.getChildElement('billTo', DEFAULT_NAMESPACE) != null) {
        this.billTo = new addressType(node.getChildElement('billTo', DEFAULT_NAMESPACE));
      }
      if (node.getChildElement('payment', DEFAULT_NAMESPACE) != null) {
        this.payment = new paymentType(node.getChildElement('payment', DEFAULT_NAMESPACE));
      }
      if (node.getChildElement('driversLicense', DEFAULT_NAMESPACE) != null) {
        this.driversLicense = new driversLicenseType(
          node.getChildElement('driversLicense', DEFAULT_NAMESPACE)
        );
      }
      Dom.XmlNode subsIds = node.getChildElement('subscriptionIds', DEFAULT_NAMESPACE);
      if (subsIds != null) {
        this.subscriptionIds = new List<String>{};
        for (Dom.XmlNode n : subsIds.getChildElements()) {
          this.subscriptionIds.add(n.getText());
        }
      }
    }
    public String toXML(String elementName) {
      String xml = '<' + elementName + '>';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customerType != null)
        xml += generateXmlNode('customerType', this.customerType);
      if (this.taxId != null)
        xml += generateXmlNode('taxId', this.taxId);
      if (this.billTo != null)
        xml += this.billTo.toXML('billTo');
      if (this.payment != null)
        xml += this.payment.toXML();
      if (this.driversLicense != null)
        xml += this.driversLicense.toXML();
      if (this.defaultPaymentProfile != null)
        xml += generateXmlNode('defaultPaymentProfile', this.defaultPaymentProfile);
      if (this.customerPaymentProfileId != null)
        xml += generateXmlNode('customerPaymentProfileId', this.customerPaymentProfileId);
      xml += '</' + elementName + '>';
      return xml;
    }
  }
  public class customerProfilePaymentType {
    public Boolean createProfile;
    public String customerProfileId;
    public String shippingProfileId;
    public paymentProfile paymentProfile;

    public customerProfilePaymentType() {
    }
    public customerProfilePaymentType(Dom.XmlNode node) {
      this.createProfile = getImmediateChildNodeValue(node, 'createProfile', DEFAULT_NAMESPACE) !=
        null
        ? Boolean.valueOf(getImmediateChildNodeValue(node, 'createProfile', DEFAULT_NAMESPACE))
        : null;
      this.customerProfileId = getImmediateChildNodeValue(
        node,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      this.shippingProfileId = getImmediateChildNodeValue(
        node,
        'shippingProfileId',
        DEFAULT_NAMESPACE
      );
      if (node.getChildElement('profile', DEFAULT_NAMESPACE) != null) {
        this.paymentProfile = new paymentProfile(
          node.getChildElement('profile', DEFAULT_NAMESPACE)
        );
      }
    }

    public String toXML() {
      String xml = '<profile>';
      if (this.createProfile != null)
        xml += generateXmlNode('createProfile', this.createProfile);
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.shippingProfileId != null)
        xml += generateXmlNode('shippingProfileId', this.shippingProfileId);
      if (this.paymentProfile != null)
        xml += this.paymentProfile.toXML();
      xml += '</profile>';
      return xml;
    }
  }
  public class customerProfileType {
    public String customerProfileId;
    public String merchantCustomerId;
    public String description;
    public String email;
    public String profileType;
    //    public customerPaymentProfileType paymentProfile;
    public addressType shippingProfile;
    public customerPaymentProfileType[] paymentProfiles;
    public addressType[] shipToList;

    public customerProfileType() {
    }
    public customerProfileType(Dom.XmlNode node) {
      this.customerProfileId = getImmediateChildNodeValue(
        node,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      this.merchantCustomerId = getImmediateChildNodeValue(
        node,
        'merchantCustomerId',
        DEFAULT_NAMESPACE
      );
      this.description = getImmediateChildNodeValue(node, 'description', DEFAULT_NAMESPACE);
      this.email = getImmediateChildNodeValue(node, 'email', DEFAULT_NAMESPACE);
      this.profileType = getImmediateChildNodeValue(node, 'profileType', DEFAULT_NAMESPACE);
      //      if (node.getChildElement('paymentProfile', DEFAULT_NAMESPACE) != null) {
      //        this.paymentProfile = new customerPaymentProfileType(node.getChildElement('paymentProfile', DEFAULT_NAMESPACE));
      //      }
      this.shippingProfile = new addressType(
        node.getChildElement('shippingProfile', DEFAULT_NAMESPACE)
      );
      for (Dom.XmlNode n : node.getChildElements()) {
        if (n.getName() == 'paymentProfile') {
          if (this.paymentProfiles == null) {
            this.paymentProfiles = new List<customerPaymentProfileType>{};
          }
          this.paymentProfiles.add(new customerPaymentProfileType(n));
        }
      }
      if (node.getChildElement('shipToList', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode shipToListNode = node.getChildElement('shipToList', DEFAULT_NAMESPACE);
        this.shipToList = new List<addressType>();
        for (Dom.XmlNode shipToNode : shipToListNode.getChildElements()) {
          this.shipToList.add(new addressType(shipToNode));
        }
      }
    }

    public String toXML() {
      String xml = '<profile>';
      if (this.profileType != null)
        xml += generateXmlNode('profileType', this.profileType);
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.merchantCustomerId != null)
        xml += generateXmlNode('merchantCustomerId', this.merchantCustomerId);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      if (this.email != null)
        xml += generateXmlNode('email', this.email);
      if (this.shippingProfile != null)
        xml += this.shippingProfile.toXML('shippingProfile');
      if (this.paymentProfiles != null) {
        for (customerPaymentProfileType paymentProfile : this.paymentProfiles) {
          xml += paymentProfile.toXML('paymentProfiles');
        }
      }
      if (this.shipToList != null) {
        xml += '<shipToList>';
        for (addressType shipTo : this.shipToList) {
          xml += shipTo.toXML('shipTo'); // TODO: verify this is the correct node name
        }
        xml += '</shipToList>';
      }
      xml += '</profile>';
      return xml;
    }
  }
  public class customerProfileIdType {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public String customerAddressId;

    public customerProfileIdType() {
    }
    public customerProfileIdType(Dom.XmlNode node) {
      this.customerProfileId = getImmediateChildNodeValue(
        node,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      this.customerPaymentProfileId = getImmediateChildNodeValue(
        node,
        'customerPaymentProfileId',
        DEFAULT_NAMESPACE
      );
      this.customerAddressId = getImmediateChildNodeValue(
        node,
        'customerAddressId',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML() {
      String xml = '<profile>';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customerPaymentProfileId != null)
        xml += generateXmlNode('customerPaymentProfileId', this.customerPaymentProfileId);
      if (this.customerAddressId != null)
        xml += generateXmlNode('customerAddressId', this.customerAddressId);
      xml += '</profile>';
      return xml;
    }
  }
  public class customer {
    public String merchantCustomerId;
    public String description;
    public String email;

    public customer() {
    }
    public customer(Dom.XmlNode node) {
      this.merchantCustomerId = getImmediateChildNodeValue(
        node,
        'merchantCustomerId',
        DEFAULT_NAMESPACE
      );
      this.description = getImmediateChildNodeValue(node, 'description', DEFAULT_NAMESPACE);
      this.email = getImmediateChildNodeValue(node, 'email', DEFAULT_NAMESPACE);
    }

    public String toXML() {
      String xml = '<customer>';
      if (this.merchantCustomerId != null)
        xml += generateXmlNode('merchantCustomerId', this.merchantCustomerId);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      if (this.email != null)
        xml += generateXmlNode('email', this.email);
      xml += '</customer>';
      return xml;
    }
  }
  public class transactionDetailsType {
    public String transId;
    public String refTransId;
    public String splitTenderId;
    public String submitTimeUTC;
    public String submitTimeLocal;
    public String transactionType;
    public String transactionStatus;
    public Integer responseCode;
    public Integer responseReasonCode;
    public String responseReasonDescription;
    public String authCode;
    public String AVSResponse;
    public String cardCodeResponse;
    public String CAVVResponse;
    public String FDSFilterAction;
    public FDSFilterType[] FDSFilters;
    public batchDetailsType batch;
    public orderType order;
    public Decimal requestedAmount;
    public Decimal authAmount;
    public Decimal settleAmount;
    public extendedAmountType tax;
    public extendedAmountType shipping;
    public extendedAmountType duty;
    public lineItemType[] lineItems;
    public Decimal prepaidBalanceRemaining;
    public Boolean taxExempt;
    public paymentType payment;
    public customerType customer;
    public addressType billTo;
    public addressType shipTo;
    public Boolean recurringBilling;
    public String customerIP;
    public subscriptionPaymentType subscription;
    public String marketType;
    public String product;
    public returnedItemType[] returnedItems;
    public solutionType solution;
    public String mobileDeviceId;
    public String entryMode;
    public String customerSignature;

    public transactionDetailsType(Dom.XmlNode tdNode) {
      this.transId = getImmediateChildNodeValue(tdNode, 'transId', DEFAULT_NAMESPACE);
      this.refTransId = getImmediateChildNodeValue(tdNode, 'refTransId', DEFAULT_NAMESPACE);
      this.splitTenderId = getImmediateChildNodeValue(tdNode, 'splitTenderId', DEFAULT_NAMESPACE);
      this.submitTimeUTC = getImmediateChildNodeValue(tdNode, 'submitTimeUTC', DEFAULT_NAMESPACE);
      this.submitTimeLocal = getImmediateChildNodeValue(
        tdNode,
        'submitTimeLocal',
        DEFAULT_NAMESPACE
      );
      this.transactionType = getImmediateChildNodeValue(
        tdNode,
        'transactionType',
        DEFAULT_NAMESPACE
      );
      this.transactionStatus = getImmediateChildNodeValue(
        tdNode,
        'transactionStatus',
        DEFAULT_NAMESPACE
      );
      this.responseCode = getImmediateChildNodeValue(tdNode, 'responseCode', DEFAULT_NAMESPACE) !=
        null
        ? Integer.valueOf(getImmediateChildNodeValue(tdNode, 'responseCode', DEFAULT_NAMESPACE))
        : null;
      this.responseReasonCode = getImmediateChildNodeValue(
          tdNode,
          'responseReasonCode',
          DEFAULT_NAMESPACE
        ) != null
        ? Integer.valueOf(
            getImmediateChildNodeValue(tdNode, 'responseReasonCode', DEFAULT_NAMESPACE)
          )
        : null;
      this.responseReasonDescription = getImmediateChildNodeValue(
        tdNode,
        'responseReasonDescription',
        DEFAULT_NAMESPACE
      );
      this.authCode = getImmediateChildNodeValue(tdNode, 'authCode', DEFAULT_NAMESPACE);
      this.AVSResponse = getImmediateChildNodeValue(tdNode, 'AVSResponse', DEFAULT_NAMESPACE);
      this.cardCodeResponse = getImmediateChildNodeValue(
        tdNode,
        'cardCodeResponse',
        DEFAULT_NAMESPACE
      );
      this.CAVVResponse = getImmediateChildNodeValue(tdNode, 'CAVVResponse', DEFAULT_NAMESPACE);
      this.FDSFilterAction = getImmediateChildNodeValue(tdNode, 'refId', DEFAULT_NAMESPACE);
      if (tdNode.getChildElement('FDSFilters', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode fdsFiltersNode = tdNode.getChildElement('FDSFilters', DEFAULT_NAMESPACE);
        this.FDSFilters = new List<FDSFilterType>();
        for (Dom.XmlNode fdsFilterNode : fdsFiltersNode.getChildElements()) {
          this.FDSFilters.add(new FDSFilterType(fdsFilterNode));
        }
      }
      if (tdNode.getChildElement('batch', DEFAULT_NAMESPACE) != null) {
        this.batch = new batchDetailsType(tdNode.getChildElement('batch', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('order', DEFAULT_NAMESPACE) != null) {
        this.order = new orderType(tdNode.getChildElement('order', DEFAULT_NAMESPACE));
      }
      this.requestedAmount = getImmediateChildNodeValue(
          tdNode,
          'requestedAmount',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(getImmediateChildNodeValue(tdNode, 'requestedAmount', DEFAULT_NAMESPACE))
        : null;
      this.authAmount = getImmediateChildNodeValue(tdNode, 'authAmount', DEFAULT_NAMESPACE) != null
        ? Decimal.valueOf(getImmediateChildNodeValue(tdNode, 'authAmount', DEFAULT_NAMESPACE))
        : null;
      this.settleAmount = getImmediateChildNodeValue(tdNode, 'settleAmount', DEFAULT_NAMESPACE) !=
        null
        ? Decimal.valueOf(getImmediateChildNodeValue(tdNode, 'settleAmount', DEFAULT_NAMESPACE))
        : null;
      if (tdNode.getChildElement('tax', DEFAULT_NAMESPACE) != null) {
        this.tax = new extendedAmountType(tdNode.getChildElement('tax', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('shipping', DEFAULT_NAMESPACE) != null) {
        this.shipping = new extendedAmountType(
          tdNode.getChildElement('shipping', DEFAULT_NAMESPACE)
        );
      }
      if (tdNode.getChildElement('duty', DEFAULT_NAMESPACE) != null) {
        this.duty = new extendedAmountType(tdNode.getChildElement('duty', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('lineItems', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode lineItemsNode = tdNode.getChildElement('lineItems', DEFAULT_NAMESPACE);
        this.lineItems = new List<lineItemType>();
        for (Dom.XmlNode lineItemNode : lineItemsNode.getChildElements()) {
          this.lineItems.add(new lineItemType(lineItemNode));
        }
      }
      this.prepaidBalanceRemaining = getImmediateChildNodeValue(
          tdNode,
          'prepaidBalanceRemaining',
          DEFAULT_NAMESPACE
        ) != null
        ? Decimal.valueOf(
            getImmediateChildNodeValue(tdNode, 'prepaidBalanceRemaining', DEFAULT_NAMESPACE)
          )
        : null;
      this.taxExempt = getImmediateChildNodeValue(tdNode, 'taxExempt', DEFAULT_NAMESPACE) != null
        ? Boolean.valueOf(getImmediateChildNodeValue(tdNode, 'taxExempt', DEFAULT_NAMESPACE))
        : null;
      if (tdNode.getChildElement('payment', DEFAULT_NAMESPACE) != null) {
        this.payment = new paymentType(tdNode.getChildElement('payment', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('customer', DEFAULT_NAMESPACE) != null) {
        this.customer = new customerType(tdNode.getChildElement('customer', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('billTo', DEFAULT_NAMESPACE) != null) {
        this.billTo = new addressType(tdNode.getChildElement('billTo', DEFAULT_NAMESPACE));
      }
      if (tdNode.getChildElement('shipTo', DEFAULT_NAMESPACE) != null) {
        this.shipTo = new addressType(tdNode.getChildElement('shipTo', DEFAULT_NAMESPACE));
      }
      this.recurringBilling = getImmediateChildNodeValue(
          tdNode,
          'recurringBilling',
          DEFAULT_NAMESPACE
        ) != null
        ? Boolean.valueOf(getImmediateChildNodeValue(tdNode, 'recurringBilling', DEFAULT_NAMESPACE))
        : null;
      this.customerIP = getImmediateChildNodeValue(tdNode, 'customerIP', DEFAULT_NAMESPACE);
      if (tdNode.getChildElement('subscription', DEFAULT_NAMESPACE) != null) {
        this.subscription = new subscriptionPaymentType(
          tdNode.getChildElement('subscription', DEFAULT_NAMESPACE)
        );
      }
      this.marketType = getImmediateChildNodeValue(tdNode, 'marketType', DEFAULT_NAMESPACE);
      this.product = getImmediateChildNodeValue(tdNode, 'product', DEFAULT_NAMESPACE);
      if (tdNode.getChildElement('returnedItems', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode returnedItemsNode = tdNode.getChildElement('returnedItems', DEFAULT_NAMESPACE);
        this.returnedItems = new List<returnedItemType>();
        for (Dom.XmlNode returnedItemNode : returnedItemsNode.getChildElements()) {
          this.returnedItems.add(new returnedItemType(returnedItemNode));
        }
      }
      if (tdNode.getChildElement('solution', DEFAULT_NAMESPACE) != null) {
        this.solution = new solutionType(tdNode.getChildElement('solution', DEFAULT_NAMESPACE));
      }
      this.mobileDeviceId = getImmediateChildNodeValue(tdNode, 'mobileDeviceId', DEFAULT_NAMESPACE);
      this.entryMode = getImmediateChildNodeValue(tdNode, 'entryMode', DEFAULT_NAMESPACE);
      this.customerSignature = getImmediateChildNodeValue(
        tdNode,
        'customerSignature',
        DEFAULT_NAMESPACE
      );
    }
  }
  public class returnedItemType {
    public String id;
    public String dateUTC;
    public String dateLocal;
    public String code;
    public String description;

    public returnedItemType() {
    }
    public returnedItemType(Dom.XmlNode returnedItemNode) {
      this.id = getImmediateChildNodeValue(returnedItemNode, 'id', DEFAULT_NAMESPACE);
      this.dateUTC = getImmediateChildNodeValue(returnedItemNode, 'dateUTC', DEFAULT_NAMESPACE);
      this.dateLocal = getImmediateChildNodeValue(returnedItemNode, 'dateLocal', DEFAULT_NAMESPACE);
      this.code = getImmediateChildNodeValue(returnedItemNode, 'code', DEFAULT_NAMESPACE);
      this.description = getImmediateChildNodeValue(
        returnedItemNode,
        'description',
        DEFAULT_NAMESPACE
      );
    }

    public String toXML() {
      String xml = '<returnedItem>';
      if (this.id != null)
        xml += generateXmlNode('id', this.id);
      if (this.dateUTC != null)
        xml += generateXmlNode('dateUTC', this.dateUTC);
      if (this.dateLocal != null)
        xml += generateXmlNode('dateLocal', this.dateLocal);
      if (this.code != null)
        xml += generateXmlNode('code', this.code);
      if (this.description != null)
        xml += generateXmlNode('description', this.description);
      xml += '</returnedItem>';
      return xml;
    }
  }
  public class transactionResponse {
    public String responseCode;
    public String rawResponseCode;
    public String authCode;
    public String avsResultCode;
    public String cvvResultCode;
    public String cavvResultCode;
    public String transId;
    public String refTransId;
    public String transHash;
    public String testRequest;
    public String accountNumber;
    public String accountType;
    public String entryMode;
    public String splitTenderId;
    public transactionResponseMessage[] messages;
    public transactionResponseError[] errors;
    public transactionResponseSplitTenderPayment[] splitTenderPayments;
    public userField[] userFields;
    public addressType shipTo;

    public transactionResponse(Dom.XmlNode transactionResponseNode) {
      this.responseCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'responseCode',
        DEFAULT_NAMESPACE
      );
      this.rawResponseCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'rawResponseCode',
        DEFAULT_NAMESPACE
      );
      this.authCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'authCode',
        DEFAULT_NAMESPACE
      );
      this.avsResultCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'avsResultCode',
        DEFAULT_NAMESPACE
      );
      this.cvvResultCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'cvvResultCode',
        DEFAULT_NAMESPACE
      );
      this.cavvResultCode = getImmediateChildNodeValue(
        transactionResponseNode,
        'cavvResultCode',
        DEFAULT_NAMESPACE
      );
      this.transId = getImmediateChildNodeValue(
        transactionResponseNode,
        'transId',
        DEFAULT_NAMESPACE
      );
      this.refTransId = getImmediateChildNodeValue(
        transactionResponseNode,
        'refTransId',
        DEFAULT_NAMESPACE
      );
      this.transHash = getImmediateChildNodeValue(
        transactionResponseNode,
        'transHash',
        DEFAULT_NAMESPACE
      );
      this.testRequest = getImmediateChildNodeValue(
        transactionResponseNode,
        'testRequest',
        DEFAULT_NAMESPACE
      );
      this.accountNumber = getImmediateChildNodeValue(
        transactionResponseNode,
        'accountNumber',
        DEFAULT_NAMESPACE
      );
      this.accountType = getImmediateChildNodeValue(
        transactionResponseNode,
        'accountType',
        DEFAULT_NAMESPACE
      );
      this.entryMode = getImmediateChildNodeValue(
        transactionResponseNode,
        'entryMode',
        DEFAULT_NAMESPACE
      );
      this.splitTenderId = getImmediateChildNodeValue(
        transactionResponseNode,
        'splitTenderId',
        DEFAULT_NAMESPACE
      );
      if (transactionResponseNode.getChildElement('messages', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode messagesNode = transactionResponseNode.getChildElement(
          'messages',
          DEFAULT_NAMESPACE
        );
        this.messages = new List<transactionResponseMessage>();
        for (Dom.XmlNode messageNode : messagesNode.getChildElements()) {
          this.messages.add(new transactionResponseMessage(messageNode));
        }
      }
      if (transactionResponseNode.getChildElement('errors', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode errorsNode = transactionResponseNode.getChildElement(
          'errors',
          DEFAULT_NAMESPACE
        );
        this.errors = new List<transactionResponseError>();
        for (Dom.XmlNode errorNode : errorsNode.getChildElements()) {
          this.errors.add(new transactionResponseError(errorNode));
        }
      }
      if (
        transactionResponseNode.getChildElement('splitTenderPayments', DEFAULT_NAMESPACE) != null
      ) {
        Dom.XmlNode splitTenderPaymentsNode = transactionResponseNode.getChildElement(
          'splitTenderPayments',
          DEFAULT_NAMESPACE
        );
        this.splitTenderPayments = new List<transactionResponseSplitTenderPayment>();
        for (Dom.XmlNode splitTenderPaymentNode : splitTenderPaymentsNode.getChildElements()) {
          this.splitTenderPayments.add(
            new transactionResponseSplitTenderPayment(splitTenderPaymentNode)
          );
        }
      }
      if (transactionResponseNode.getChildElement('userFields', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode userFieldsNode = transactionResponseNode.getChildElement(
          'userFields',
          DEFAULT_NAMESPACE
        );
        this.userFields = new List<userField>();
        for (Dom.XmlNode userFieldNode : userFieldsNode.getChildElements()) {
          this.userFields.add(new userField(userFieldNode));
        }
      }
    }
  }
  public class transactionResponseMessage {
    public String code;
    public String description;

    public transactionResponseMessage() {
    }
    public transactionResponseMessage(Dom.XmlNode messageNode) {
      this.code = getImmediateChildNodeValue(messageNode, 'code', DEFAULT_NAMESPACE);
      this.description = getImmediateChildNodeValue(messageNode, 'description', DEFAULT_NAMESPACE);
    }
  }
  public class transactionResponseError {
    public String errorCode;
    public String errorText;

    public transactionResponseError() {
    }
    public transactionResponseError(Dom.XmlNode errorNode) {
      this.errorCode = getImmediateChildNodeValue(errorNode, 'errorCode', DEFAULT_NAMESPACE);
      this.errorText = getImmediateChildNodeValue(errorNode, 'errorText', DEFAULT_NAMESPACE);
    }
  }
  public class transactionResponseSplitTenderPayment {
    public String transId;
    public String responseCode;
    public String responseToCustomer;
    public String authCode;
    public String accountNumber;
    public String accountType;
    public String requestedAmount;
    public String approvedAmount;
    public String balanceOnCard;

    public transactionResponseSplitTenderPayment() {
    }
    public transactionResponseSplitTenderPayment(Dom.XmlNode node) {
      this.transId = getImmediateChildNodeValue(node, 'transId', DEFAULT_NAMESPACE);
      this.responseCode = getImmediateChildNodeValue(node, 'responseCode', DEFAULT_NAMESPACE);
      this.responseToCustomer = getImmediateChildNodeValue(
        node,
        'responseToCustomer',
        DEFAULT_NAMESPACE
      );
      this.authCode = getImmediateChildNodeValue(node, 'authCode', DEFAULT_NAMESPACE);
      this.accountNumber = getImmediateChildNodeValue(node, 'accountNumber', DEFAULT_NAMESPACE);
      this.accountType = getImmediateChildNodeValue(node, 'accountType', DEFAULT_NAMESPACE);
      this.requestedAmount = getImmediateChildNodeValue(node, 'requestedAmount', DEFAULT_NAMESPACE);
      this.approvedAmount = getImmediateChildNodeValue(node, 'approvedAmount', DEFAULT_NAMESPACE);
      this.balanceOnCard = getImmediateChildNodeValue(node, 'balanceOnCard', DEFAULT_NAMESPACE);
    }
  }
  public virtual class ANetApiRequest {
    public merchantAuthenticationType merchantAuthentication;
    public String clientId;
    public String refId;

    public ANetApiRequest(merchantAuthenticationType ma, String refId) {
      this.merchantAuthentication = ma;
      this.refId = refId;
    }
    public ANetApiRequest(merchantAuthenticationType ma, String refId, String clientId) {
      this.merchantAuthentication = ma;
      this.refId = refId;
      this.clientId = clientId;
    }

    public String toXML(String baseNodeName, String childContents) {
      String xml = '<' + baseNodeName + ' xmlns="' + DEFAULT_NAMESPACE + '">';
      if (this.merchantAuthentication != null)
        xml += this.merchantAuthentication.toXML();
      if (this.clientId != null)
        xml += generateXmlNode('clientId', this.clientId);
      if (this.refId != null)
        xml += generateXmlNode('refId', this.refId);
      if (childContents != null)
        xml += childContents;
      xml += '</' + baseNodeName + '>';
      return xml;
    }
  }
  public class messagesType {
    public String resultCode;
    public messagesTypeMessage message;

    public messagesType(Dom.XMLNode messagesNode) {
      this.resultCode = getImmediateChildNodeValue(messagesNode, 'resultCode', DEFAULT_NAMESPACE);
      if (messagesNode.getChildElement('message', DEFAULT_NAMESPACE) != null) {
        this.message = new messagesTypeMessage(
          messagesNode.getChildElement('message', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class messagesTypeMessage {
    public String code;
    public String text;

    public messagesTypeMessage(Dom.XmlNode messageNode) {
      this.code = getImmediateChildNodeValue(messageNode, 'code', DEFAULT_NAMESPACE);
      this.text = getImmediateChildNodeValue(messageNode, 'text', DEFAULT_NAMESPACE);
    }
  }
  public virtual class ANetApiResponse {
    public transient HttpResponse res;
    public transient Dom.XmlNode rootNode;
    public String refId;
    public messagesType messages;
    public String sessionToken;

    public ANetApiResponse(HttpResponse res) {
      this.res = res;
      this.rootNode = res.getBodyDocument().getRootElement();
      this.refId = getImmediateChildNodeValue(this.rootNode, 'refId', DEFAULT_NAMESPACE);
      this.sessionToken = getImmediateChildNodeValue(
        this.rootNode,
        'sessionToken',
        DEFAULT_NAMESPACE
      );
      if (this.rootNode.getChildElement('messages', DEFAULT_NAMESPACE) != null) {
        this.messages = new messagesType(
          this.rootNode.getChildElement('messages', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class createProfileResponse {
    public messagesType messages;
    public String customerProfileId;
    public String[] customerPaymentProfileIdList;
    public String[] customerShippingAddressIdList;

    public createProfileResponse(Dom.XmlNode node) {
      if (node.getChildElement('messages', DEFAULT_NAMESPACE) != null) {
        this.messages = new messagesType(node.getChildElement('messages', DEFAULT_NAMESPACE));
      }
      this.customerProfileId = getImmediateChildNodeValue(
        node,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      // TODO: figure out how to parse customerPaymentProfileIdList
      // TODO: figure out how to parse customerPShippingAddressIdList
    }
  }
  public class ARBCreateSubscriptionRequest extends ANetApiRequest {
    public ARBSubscriptionType subscription;

    public ARBCreateSubscriptionRequest(
      merchantAuthenticationType ma,
      String refId,
      ARBSubscriptionType subscription
    ) {
      super(ma, refId);
      this.subscription = subscription;
    }

    public String toXML() {
      String xml = '';
      if (this.subscription != null)
        xml += this.subscription.toXML();
      return super.toXML('ARBCreateSubscriptionRequest', xml);
    }
  }
  public class ARBCreateSubscriptionResponse extends ANetApiResponse {
    public String subscriptionId;
    public customerProfileIdType profile;

    public ARBCreateSubscriptionResponse(HttpResponse res) {
      super(res);
      this.subscriptionId = getImmediateChildNodeValue(
        this.rootNode,
        'subscriptionId',
        DEFAULT_NAMESPACE
      );
      if (this.rootNode.getChildElement('profile', DEFAULT_NAMESPACE) != null) {
        this.profile = new customerProfileIdType(
          this.rootNode.getChildElement('profile', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class ARBUpdateSubscriptionRequest extends ANetApiRequest {
    public String subscriptionId;
    public ARBSubscriptionType subscription;

    public ARBUpdateSubscriptionRequest(
      merchantAuthenticationType ma,
      String refId,
      String subscriptionId,
      ARBSubscriptionType subscription
    ) {
      super(ma, refId);
      this.subscriptionId = subscriptionId;
      this.subscription = subscription;
    }

    public String toXML() {
      String xml = '';
      if (this.subscriptionId != null)
        xml += generateXmlNode('subscriptionId', this.subscriptionId);
      if (this.subscription != null)
        xml += this.subscription.toXML();
      return super.toXML('ARBUpdateSubscriptionRequest', xml);
    }
  }
  public class ARBUpdateSubscriptionResponse extends ANetApiResponse {
    public customerProfileIdType profile;

    public ARBUpdateSubscriptionResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('profile', DEFAULT_NAMESPACE) != null) {
        this.profile = new customerProfileIdType(
          this.rootNode.getChildElement('profile', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class ARBCancelSubscriptionRequest extends ANetApiRequest {
    public String subscriptionId;

    public ARBCancelSubscriptionRequest(
      merchantAuthenticationType ma,
      String refId,
      String subscriptionId
    ) {
      super(ma, refId);
      this.subscriptionId = subscriptionId;
    }

    public String toXML() {
      String xml = '';
      if (this.subscriptionId != null)
        xml += generateXmlNode('subscriptionId', this.subscriptionId);
      return super.toXML('ARBCancelSubscriptionRequest', xml);
    }
  }
  public class ARBCancelSubscriptionResponse extends ANetApiResponse {
    public ARBCancelSubscriptionResponse(HttpResponse res) {
      super(res);
    }
  }
  public class ARBGetSubscriptionStatusRequest extends ANetApiRequest {
    public String subscriptionId;

    public ARBGetSubscriptionStatusRequest(
      merchantAuthenticationType ma,
      String refId,
      String subscriptionId
    ) {
      super(ma, refId);
      this.subscriptionId = subscriptionId;
    }

    public String toXML() {
      String xml = '';
      if (this.subscriptionId != null)
        xml += generateXmlNode('subscriptionId', this.subscriptionId);
      return super.toXML('ARBGetSubscriptionStatusRequest', xml);
    }
  }
  public class ARBGetSubscriptionStatusResponse extends ANetApiResponse {
    public String status;

    public ARBGetSubscriptionStatusResponse(HttpResponse res) {
      super(res);
      this.status = getImmediateChildNodeValue(this.rootNode, 'status', DEFAULT_NAMESPACE);
    }
  }
  public class getTransactionDetailsRequest extends ANetApiRequest {
    public String transId;

    public getTransactionDetailsRequest(
      merchantAuthenticationType ma,
      String refId,
      String transId
    ) {
      super(ma, refId);
      this.transId = transId;
    }

    public String toXML() {
      String xml = '';
      if (this.transId != null)
        xml += generateXmlNode('transId', this.transId);
      return super.toXML('getTransactionDetailsRequest', xml);
    }
  }
  public class getTransactionDetailsResponse extends ANetApiResponse {
    public transactionDetailsType trans;

    public getTransactionDetailsResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('transaction', DEFAULT_NAMESPACE) != null) {
        this.trans = new transactionDetailsType(
          this.rootNode.getChildElement('transaction', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class createTransactionRequest extends ANetApiRequest {
    public transactionRequestType transactionRequest;

    public createTransactionRequest(
      merchantAuthenticationType ma,
      String refId,
      transactionRequestType transactionRequest
    ) {
      super(ma, refId);
      this.transactionRequest = transactionRequest;
    }

    public String toXML() {
      String xml = '';
      if (this.transactionRequest != null)
        xml += this.transactionRequest.toXML();
      return super.toXML('createTransactionRequest', xml);
    }
  }
  public class createTransactionResponse extends ANetApiResponse {
    public transactionResponse transactionResponse;
    public createProfileResponse profileResponse;

    public createTransactionResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('transactionResponse', DEFAULT_NAMESPACE) != null) {
        this.transactionResponse = new transactionResponse(
          this.rootNode.getChildElement('transactionResponse', DEFAULT_NAMESPACE)
        );
      }
      if (this.rootNode.getChildElement('profileResponse', DEFAULT_NAMESPACE) != null) {
        this.profileResponse = new createProfileResponse(
          this.rootNode.getChildElement('profileResponse', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class getSettledBatchListRequest extends ANetApiRequest {
    public Boolean includeStatistics;
    public String firstSettlementDate;
    public String lastSettlementDate;

    public getSettledBatchListRequest(
      merchantAuthenticationType ma,
      String refId,
      String firstSettlementDate,
      String lastSettlementDate,
      Boolean includeStatistics
    ) {
      super(ma, refId);
      this.includeStatistics = includeStatistics;
      this.firstSettlementDate = firstSettlementDate;
      this.lastSettlementDate = lastSettlementDate;
    }

    public String toXML() {
      String xml = '';
      if (this.includeStatistics != null)
        xml += generateXmlNode('includeStatistics', this.includeStatistics);
      if (this.firstSettlementDate != null)
        xml += generateXmlNode('firstSettlementDate', this.firstSettlementDate);
      if (this.lastSettlementDate != null)
        xml += generateXmlNode('lastSettlementDate', this.lastSettlementDate);
      return super.toXML('getSettledBatchListRequest', xml);
    }
  }
  public class getSettledBatchListResponse extends ANetApiResponse {
    public batchDetailsType[] batchList;

    public getSettledBatchListResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('batchList', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode batchListNode = this.rootNode.getChildElement('batchList', DEFAULT_NAMESPACE);
        this.batchList = new List<batchDetailsType>();
        for (Dom.XmlNode batchNode : batchListNode.getChildElements()) {
          this.batchList.add(new batchDetailsType(batchNode));
        }
      }
    }
  }
  public class getTransactionListRequest extends ANetApiRequest {
    public String batchId;

    public getTransactionListRequest(merchantAuthenticationType ma, String refId, String batchId) {
      super(ma, refId);
      this.batchId = batchId;
    }

    public String toXML() {
      String xml = '';
      if (this.batchId != null)
        xml += generateXmlNode('batchId', this.batchId);
      return super.toXML('getTransactionListRequest', xml);
    }
  }
  public class getTransactionListResponse extends ANetApiResponse {
    public transactionSummaryType[] transactions;

    public getTransactionListResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('transactions', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode transactionsNode = this.rootNode.getChildElement(
          'transactions',
          DEFAULT_NAMESPACE
        );
        this.transactions = new List<transactionSummaryType>();
        for (Dom.XmlNode transactionNode : transactionsNode.getChildElements()) {
          this.transactions.add(new transactionSummaryType(transactionNode));
        }
      }
    }
  }
  public class getUnsettledTransactionListRequest extends ANetApiRequest {
    public getUnsettledTransactionListRequest(merchantAuthenticationType ma) {
      super(ma, null);
    }

    public String toXML() {
      return super.toXML('getUnsettledTransactionListRequest', null);
    }
  }
  public class getUnsettledTransactionListResponse extends ANetApiResponse {
    public transactionSummaryType[] transactions;

    public getUnsettledTransactionListResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('transactions', DEFAULT_NAMESPACE) != null) {
        Dom.XmlNode transactionsNode = this.rootNode.getChildElement(
          'transactions',
          DEFAULT_NAMESPACE
        );
        this.transactions = new List<transactionSummaryType>();
        for (Dom.XmlNode transactionNode : transactionsNode.getChildElements()) {
          this.transactions.add(new transactionSummaryType(transactionNode));
        }
      }
    }
  }
  public class getBatchStatisticsRequest extends ANetApiRequest {
    public String batchId;

    public getBatchStatisticsRequest(merchantAuthenticationType ma, String batchId) {
      super(ma, null);
      this.batchId = batchId;
    }

    public String toXML() {
      String xml = '';
      if (this.batchId != null)
        xml += generateXmlNode('batchid', this.batchId);
      return super.toXML('getBatchStatisticsRequest', xml);
    }
  }
  public class getBatchStatisticsResponse extends ANetApiResponse {
    public batchDetailsType batch;

    public getBatchStatisticsResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('batch', DEFAULT_NAMESPACE) != null) {
        this.batch = new batchDetailsType(
          this.rootNode.getChildElement('batch', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class ARBGetSubscriptionRequest extends ANetApiRequest {
    public String subscriptionId;

    public ARBGetSubscriptionRequest(
      merchantAuthenticationType ma,
      String refId,
      String subscriptionId
    ) {
      super(ma, refId);
      this.subscriptionId = subscriptionId;
    }

    public String toXML() {
      String xml = '';
      if (this.subscriptionId != null)
        xml += generateXmlNode('subscriptionId', this.subscriptionId);
      return super.toXML('ARBGetSubscriptionRequest', xml);
    }
  }
  public class ARBGetSubscriptionResponse extends ANetApiResponse {
    public ARBSubscriptionMaskedType subscription;

    public ARBGetSubscriptionResponse(HttpResponse res) {
      super(res);
      if (this.rootNode.getChildElement('subscription', DEFAULT_NAMESPACE) != null) {
        this.subscription = new ARBSubscriptionMaskedType(
          this.rootNode.getChildElement('subscription', DEFAULT_NAMESPACE)
        );
      }
    }
  }
  public class getCustomerProfileResponse extends ANetApiResponse {
    public customerProfileType profile;
    public String[] subscriptionIds;
    public getCustomerProfileResponse(HttpResponse res) {
      super(res);
      Dom.XmlNode profileNode = this.rootNode.getChildElement('profile', DEFAULT_NAMESPACE);
      if (profileNode != null) {
        this.profile = new customerProfileType(profileNode);
      }
      Dom.XmlNode ids = this.rootNode.getChildElement('subscriptionIds', DEFAULT_NAMESPACE);
      if (ids != null) {
        this.subscriptionIds = new List<String>{};
        for (Dom.XmlNode n : ids.getChildElements()) {
          this.subscriptionIds.add(n.getText().trim());
        }
      }
    }
  }
  public class getCustomerProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public String merchantCustomerId;
    public String email;
    public Boolean unmaskExpirationDate;
    public Boolean includeIssuerInfo;
    public getCustomerProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.merchantCustomerId != null)
        xml += generateXmlNode('merchantCustomerId', this.merchantCustomerId);
      if (this.email != null)
        xml += generateXmlNode('email', this.email);
      if (this.unmaskExpirationDate != null)
        xml += generateXmlNode('unmaskExpirationDate', this.unmaskExpirationDate);
      if (this.includeIssuerInfo != null)
        xml += generateXmlNode('includeIssuerInfo', this.includeIssuerInfo);
      return super.toXML('getCustomerProfileRequest', xml);
    }
  }
  public class createCustomerProfileResponse extends ANetApiResponse {
    public String customerProfileId;
    public String[] customerPaymentProfileIdList;
    // customerShippingAddressIdList ???
    // validationDirectResponseList ???
    public createCustomerProfileResponse(HttpResponse res) {
      super(res);
      this.customerProfileId = getImmediateChildNodeValue(
        this.rootNode,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      Dom.XmlNode cppids = this.rootNode.getChildElement(
        'customerPaymentProfileIdList',
        DEFAULT_NAMESPACE
      );
      if (cppids != null) {
        this.customerPaymentProfileIdList = new List<String>{};
        for (Dom.XmlNode n : cppids.getChildElements()) {
          this.customerPaymentProfileIdList.add(n.getText().trim());
        }
      }
    }
  }
  public class createCustomerProfileRequest extends ANetApiRequest {
    public customerProfileType profile;
    // Indicates the processing mode for the request. If the customer profile
    // contains no payment data, this field should not be sent.
    // Use testMode to perform a Luhn mod-10 check on the card number, without
    // further validation. Use liveMode to submit a zero-dollar or one-cent
    // transaction (depending on card type and processor support) to confirm the
    // card number belongs to an active credit or debit account.
    public String validationMode; // testMode or liveMode
    public createCustomerProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.profile != null)
        xml += this.profile.toXML();
      if (this.validationMode != null)
        xml += generateXmlNode('validationMode', this.validationMode);
      return super.toXML('createCustomerProfileRequest', xml);
    }
  }
  public class createCustomerProfileFromTransactionRequest extends ANetApiRequest {
    public customer customer;
    public String transId;
    public String customerProfileId;

    public createCustomerProfileFromTransactionRequest(
      merchantAuthenticationType ma,
      String refId
    ) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.transId != null)
        xml += generateXmlNode('transId', this.transId);
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customer != null)
        xml += this.customer.toXML();
      return super.toXML('createCustomerProfileFromTransactionRequest', xml);
    }
  }
  public class getCustomerProfileIdsResponse extends ANetApiResponse {
    public String[] ids;
    public getCustomerProfileIdsResponse(HttpResponse res) {
      super(res);
      Dom.XmlNode ids = this.rootNode.getChildElement('ids', DEFAULT_NAMESPACE);
      if (ids != null) {
        this.ids = new List<String>{};
        for (Dom.XmlNode id : ids.getChildElements()) {
          this.ids.add(id.getText());
        }
      }
    }
  }
  public class getCustomerProfileIdsRequest extends ANetApiRequest {
    public getCustomerProfileIdsRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      return super.toXML('getCustomerProfileIdsRequest', '');
    }
  }
  public class deleteCustomerProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public deleteCustomerProfileRequest(
      merchantAuthenticationType ma,
      String refId,
      String customerProfileId
    ) {
      super(ma, refId);
      this.customerProfileId = customerProfileId;
    }
    public String toXML() {
      String xml = generateXmlNode('customerProfileId', this.customerProfileId);
      return super.toXML('deleteCustomerProfileRequest', xml);
    }
  }
  public class updateCustomerProfileRequest extends ANetApiRequest {
    public customerProfileType profile;
    public updateCustomerProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.profile != null)
        xml += this.profile.toXML();
      return super.toXML('updateCustomerProfileRequest', xml);
    }
  }
  public class createCustomerPaymentProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public customerPaymentProfileType paymentProfile;
    // Indicates the processing mode for the request. If the customer profile
    // contains no payment data, this field should not be sent.
    // Use testMode to perform a Luhn mod-10 check on the card number, without
    // further validation. Use liveMode to submit a zero-dollar or one-cent
    // transaction (depending on card type and processor support) to confirm
    // the card number belongs to an active credit or debit account.
    public String validationMode;
    public createCustomerPaymentProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.paymentProfile != null)
        xml += this.paymentProfile.toXML('paymentProfile');
      if (this.validationMode != null)
        xml += generateXmlNode('validationMode', this.validationMode);
      return super.toXML('createCustomerPaymentProfileRequest', xml);
    }
  }
  public class createCustomerPaymentProfileResponse extends ANetApiResponse {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public String validationDirectResponse;
    public createCustomerPaymentProfileResponse(HttpResponse res) {
      super(res);
      this.customerProfileId = getImmediateChildNodeValue(
        this.rootNode,
        'customerProfileId',
        DEFAULT_NAMESPACE
      );
      this.customerPaymentProfileId = getImmediateChildNodeValue(
        this.rootNode,
        'customerPaymentProfileId',
        DEFAULT_NAMESPACE
      );
      this.validationDirectResponse = getImmediateChildNodeValue(
        this.rootNode,
        'validationDirectResponse',
        DEFAULT_NAMESPACE
      );
    }
  }
  public class getCustomerPaymentProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public Boolean unmaskExpirationDate;
    public Boolean includeIssuerInfo;
    public getCustomerPaymentProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customerPaymentProfileId != null)
        xml += generateXmlNode('customerPaymentProfileId', this.customerPaymentProfileId);
      if (this.unmaskExpirationDate != null)
        xml += generateXmlNode('unmaskExpirationDate', this.unmaskExpirationDate);
      if (this.includeIssuerInfo != null)
        xml += generateXmlNode('includeIssuerInfo', this.includeIssuerInfo);
      return super.toXML('getCustomerPaymentProfileRequest', xml);
    }
  }
  public class getCustomerPaymentProfileResponse extends ANetApiResponse {
    public customerPaymentProfileType paymentProfile;
    public getCustomerPaymentProfileResponse(HttpResponse res) {
      super(res);
      Dom.XmlNode pp = this.rootNode.getChildElement('paymentProfile', DEFAULT_NAMESPACE);
      if (pp != null) {
        this.paymentProfile = new customerPaymentProfileType(pp);
      }
    }
  }
  public class validateCustomerPaymentProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public String customerShippingAddressId;
    public String cardCode;
    public String validationMode;
    public validateCustomerPaymentProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customerPaymentProfileId != null)
        xml += generateXmlNode('customerPaymentProfileId', this.customerPaymentProfileId);
      if (this.customerShippingAddressId != null)
        xml += generateXmlNode('customerShippingAddressId', this.customerShippingAddressId);
      if (this.cardCode != null)
        xml += generateXmlNode('cardCode', this.cardCode);
      if (this.validationMode != null)
        xml += generateXmlNode('validationMode', this.validationMode);
      return super.toXML('validateCustomerPaymentProfileRequest', xml);
    }
  }
  public class validateCustomerPaymentProfileResponse extends ANetApiResponse {
    public String directResponse;
    public validateCustomerPaymentProfileResponse(HttpResponse res) {
      super(res);
      this.directResponse = getImmediateChildNodeValue(
        this.rootNode,
        'directResponse',
        DEFAULT_NAMESPACE
      );
    }
  }
  public class deleteCustomerPaymentProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public String customerPaymentProfileId;
    public deleteCustomerPaymentProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.customerPaymentProfileId != null)
        xml += generateXmlNode('customerPaymentProfileId', this.customerPaymentProfileId);
      return super.toXML('deleteCustomerPaymentProfileRequest', xml);
    }
  }
  public class updateCustomerPaymentProfileRequest extends ANetApiRequest {
    public String customerProfileId;
    public customerPaymentProfileType paymentProfile;
    public String validationMode;
    public updateCustomerPaymentProfileRequest(merchantAuthenticationType ma, String refId) {
      super(ma, refId);
    }
    public String toXML() {
      String xml = '';
      if (this.customerProfileId != null)
        xml += generateXmlNode('customerProfileId', this.customerProfileId);
      if (this.paymentProfile != null)
        xml += this.paymentProfile.toXML('paymentProfile');
      if (this.validationMode != null)
        xml += generateXmlNode('validationMode', this.validationMode);
      return super.toXML('updateCustomerPaymentProfileRequest', xml);
    }
  }
}