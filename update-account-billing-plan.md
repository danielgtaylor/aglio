##Update Account Billing Plan
This updates the billing plan information, billing address, and credit card information for the specified account.

#####URL:
/accounts/{accountId}/billing_plan

#####Formats:
XML, JSON

#####HTTP Method:
PUT

#####Parameters:
The billingAddressIsCreditCardAddress parameter (found when [Getting Account Billing Plan information](https://www.docusign.com/p/RESTAPIGuide/Content/REST%20API%20References/Get%20Account%20Billing%20Plan.htm)) determines how the
billing address and creditCardInformation address are updated.

  + If billingAddressIsCreditCardAddress is ‘true’ then either the billingAddress values or the creditCardInformation address values can be used to update the single address used as billing and credit card address. If the PUT updates both billing and credit card addresses, then the address field values must exactly match or an error is returned. DocuSign recommends that only one of the addresses is updated. 
  <br/>
  + If billingAddressIsCreditCardAddress is ‘false’ then the billingAddress is a billing contact address and the credit card address is the current credit card address for billing and can be updated separately.
  
  
When updating creditCardInformation, all of the creditCardInformation must be included in the update (including the cardNumber, nameOnCard, expirationYear, expirationMonth, and address), even if only part of the information is being changed. The only exception is that the expirationMonth and expirationYear may be updated without updating the other information.
> **NOTE:** When updating account billing plan information to upgrade a plan if creditCardInformation is not included, the system will use the existing credit card information for any charges.

The referralInformation is included so that promotional codes (promoCode) can be used when upgrading plans.
<br/>

| Name                            | Required?     | Type    | Description                                                                   | 
| ------------------------------- | ------------- | ------  | ----------------------------------------------------------------------------- | 
| BillingAddress                  | No            | String  | A complex type that contains the following address information for the account: <br/> <ul> <li> address1 – The first address line for the billing address. </li><li> address2 – An additional address line for the billing address. </li> <li> city – The city for the billing address. </li><li> state – The state for the billing address, see note below. </li><li> postalCode – The postal code for the billing address. </li><li> phone – The telephone number for the billing address. </li><li> fax – The fax number for the billing address. </li> <li> country – The country code for the billing address, see note below. </li><li> firstName – The first name of a contact person associated with the billing address. </li><li> lastName – The last name of a contact person associated with the billing address. </li> <li> email – The email address associated with the billing address. </li></ul>  **Note:** If country is US (United States) then State codes are validated for US States. Otherwise, State is treated as a non-validated string and serves the purpose of entering a state/province/region.
| CreditCardInformation           | No            | String  | A complex type that has information about the credit card used to pay for this account. It included the elements:  <ul> <li> cardNumber – The credit card number. Note that in responses only the last four digits are shown. </li><li> expirationMonth – The expiration month shown on the credit card. </li><li> expirationYear – The expiration year shown on the credit card. </li><li> nameOnCard – The name listed on the credit card. </li><li> cardType – The credit card type can be: visa, mastercard, or amex. </li></ul> address – A complex element with the credit card billing address information. This can be the same as billing address and follows the same rules as billingAddress. It contains the following elements: street1, street2, city, state, zip, zipPlus4, phone, fax, and country.
| EnableSupport                   | No            | Boolean | If true, the plan has support enabled. |
| IncludeSeats                    | No            | String  | The number of seats included in the plan. |
| SaleDiscountPercent, <br/> SaleDiscountAmount, <br/> SaleDiscountFixedAmount, <br/> SaleDiscountPeriods, <br/> SaleDiscountSeatPriceOverride | No | String | These elements are reserved for DoucSign use only. |
| RenewalStatus                   | No            | String  | Sets the renewal status for the account. The acceptable values are: <ul> <li> auto: The account automatically renews. </li><li> queued_for_close: Account will be closed at the billingPeriodEndDate. </li><li> queued_for_downgrade: Account will be downgraded at the billingPeriodEndDate. </li> </ul> |
| DowngradeReason                 | No            | String  | An optional element that has the reason for downgrade of account. |
| PlanInformation <br/> currencyCode | Yes        |         | This is the ISO currency code for the account. |
| PlanInformation <br/> planFeatureSets | See Description |  | A complex type that sets the feature sets for the account. It contains the following information (all string content): <ul> <li> envelopeFee - An incremental envelope cost for plans with envelope overages (when isEnabled=true).  </li> <li> featureSetId - A unique ID for the feature set. </li> <li> fixedFee - A one-time fee associated with the plan (when isEnabled=true). </li> isActive - Determines if the feature set is actively set as part of the plan. </li><li> isEnabled - Determines if the feature set is actively enabled as part of the plan. </li> <li> name - The name of the feature set. </li><li> seatFee - An incremental seat cost for seat-based plans (when isEnabled=true).</li></ul>
| PlanInformation <br/> planId    | No            | String  | The plan ID for the account. It uniquely identifies a plan and is used to set plans in other functions. |
| PlanInformation <br/> freeTrialDaysOverride | No| String | Reserved for DocuSign use only. |
| ReferralInformation             | No            |         | A complex type that contains the following information for entering referral and discount information. The following items are included in the referral information (all string content): referralCode, referrerName, advertisementId, publisherId, shopperId, promoCode, groupMemberId, idType, and industry |


##Example
####Request Body

**PUT** https://{server}/restapi/{apiVersion}/accounts/{accountId}/billing_plan
 
      {
          "billingAddress": {
            "address1": "string",
            "address2": "string",
            "city": "string",
            "state": "string",
            "postalCode": "string",
            "phone": "string",
            "fax": "string",
            "country": "string",
            "firstName": "string",
            "lastName": "string",
            "email": "string "
            }
        },
          "creditCardInformation":{
            "cardNumber": "string",
            "expirationMonth": "string",
            "expirationYear": "string",
            "nameOnCard": "string",
            "cardType": "string",
            "address": {
              "street1": "string",
              "street2": "string",
              "city": "string",
              "state": "string",
              "zip": "string",
              "zipPlus4": "string",
              "phone": "string",
              "fax": "string",
              "country": "string"
            }
        },
        "enableSupport":"String content",
        "includedSeats":"String content",
        "saleDiscountPercent": "string",
        "saleDiscountAmount": "string",
        "saleDiscountFixedAmount": "string",
        "saleDiscountPeriods": "string",
        "saleDiscountSeatPriceOverride": "string",
        "renewalStatus": "string",
        "downgradeReason": "string",
        "planInformation":{
          "currencyCode":"String content",
          "planFeatureSets":[{
            "currencyFeatureSetPrices":[{
              "currencyCode":"String content",
              "currencySymbol":"String content",
              "envelopeFee":"String content",
              "fixedFee":"String content",
              "seatFee":"String content"
            }],
            "envelopeFee":"String content",
            "featureSetId":"String content",
            "fixedFee":"String content",
            "isActive":"String content",
            "isEnabled":"String content",
            "name":"String content",
            "seatFee":"String content"
          }],
          "planId":"String content",
          "freeTrialDaysOverride":"String content"
        },
        "referralInformation": {
          "enableSupport": "string",
          "includedSeats": "string",
          "planStartMonth": "string",
          "referralCode": "string",
          "referrerName": "string ",
          "advertisementId": "string",
          "publisherId": "string",
          "shopperId": "string",
          "promoCode": "string",
          "groupMemberId": "string",
          "idType": "string",
          "industry": "string"
        }
    }

####Response
The response returns a **success** or **failure**.




