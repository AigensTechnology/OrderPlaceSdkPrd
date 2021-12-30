//
//  ApplepayService.swift
//  OrderPlaceSdk_Example
//
//  Created by 陈培爵 on 2018/11/5.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import PassKit
import AddressBook
class ApplepayService: OrderPlaceService {
    public var options: [String: Any]?
    
    
    var merchantIdentifier: String? = nil
    
    private var supportedPaymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard]
    private var merchantCapabilities = PKMerchantCapability.RawValue(UInt8(PKMerchantCapability.capability3DS.rawValue))
    
    typealias completionBlock = (PKPaymentAuthorizationStatus) -> ()
    private var completion: completionBlock?
    private var payResultCallback: CallbackHandler? = nil
    
    
    init(_ options: [String: Any]) {
        super.init()
        self.options = options;
        
        if let merchantIdentifier = options["appleMerchantIdentifier"] as? String {
            self.merchantIdentifier = merchantIdentifier
        }
        
        if let cards = options["appleCardType"] as? [String] {
            if cards.contains("amex") {
                supportedPaymentNetworks.append(PKPaymentNetwork.amex)
            }
            if cards.contains("chinaUnion") {
                if #available(iOS 9.2, *) {
                    supportedPaymentNetworks.append(PKPaymentNetwork.chinaUnionPay)
                    merchantCapabilities = PKMerchantCapability.RawValue(UInt8(PKMerchantCapability.capability3DS.rawValue) | UInt8(PKMerchantCapability.capabilityEMV.rawValue))
                }
            }
        }
    }
    
    override func getServiceName() -> String {
        return "ApplepayService"
    }
    
    override func initialize() {
//        if #available(iOS 9.2, *) {
//            supportedPaymentNetworks.append(PKPaymentNetwork.chinaUnionPay)
//        }
    }
    
    override func handleMessage(method: String, body: NSDictionary, callback: CallbackHandler?) {
        switch method {
        case "makePaymentRequest":
            if merchantIdentifier == nil {
                showAlert(nil, "miss apple merchant identifier")
                return
            }
            payResultCallback = callback
            makePaymentRequest(body, callback)
            break;
        case "completeLastTransaction":
            if merchantIdentifier == nil {
                showAlert(nil, "miss apple merchant identifier")
                return
            }
            completeLastTransaction(body, callback)
            break;
        default:
            break;
        }
    }
    
    /*
     body: {
     items: [
     {
     label: '3 x Basket Items',
     amount: 49.99
     },
     {
     label: 'Next Day Delivery',
     amount: 3.99
     },
     {
     label: 'My Fashion Company',
     amount: 53.98
     }],
     
     shippingMethods: [
     {
     identifier: 'NextDay',
     label: 'NextDay',
     detail: 'Arrives tomorrow by 5pm.',
     amount: 3.99
     },
     {
     identifier: 'Standard',
     label: 'Standard',
     detail: 'Arrive by Friday.',
     amount: 4.99
     },
     {
     identifier: 'SaturdayDelivery',
     label: 'Saturday',
     detail: 'Arrive by 5pm this Saturday.',
     amount: 6.99
     }],
     
     merchantIdentifier: 'merchant.apple.test',  // Need to pass?
     
     currencyCode: 'HKD',
     countryCode: 'HK',
     billingAddressRequirement: 'none', // none/all/postcode/email/phone
     shippingAddressRequirement: 'none', // none/all/postcode/email/phone
     shippingType: 'shipping'  // shipping/delivery/store/service
     }
     
     */
    private func makePaymentRequest(_ body: NSDictionary, _ callback: CallbackHandler?) {
        JJPrint("apple pay body:\(body) callback:\(callback)")
        guard canMakePayments() else { return }
        
        completion = nil
        
        let request = PKPaymentRequest();
        request.supportedNetworks = supportedPaymentNetworks
        request.merchantCapabilities = PKMerchantCapability(rawValue: merchantCapabilities)
        
        //request info
        if let currencyCode = body.value(forKey: "currencyCode") as? String {
            request.currencyCode = currencyCode
        }
        if let countryCode = body.value(forKey: "countryCode") as? String {
            request.countryCode = countryCode
        }
        
        if let merchantIdentifier = merchantIdentifier {
            request.merchantIdentifier = merchantIdentifier
        }
        
        request.requiredBillingAddressFields = billingAddressRequirementFromBody(body)
        request.requiredShippingAddressFields = shippingAddressRequirementFromArgumentsBody(body)
        if #available(iOS 8.3, *) {
            request.shippingType = shippingTypeFromBody(body)
        }
        request.shippingMethods = shippingMethodsFromBody(body)
        request.paymentSummaryItems = itemsFromBody(body)
        
        
        let authVC = PKPaymentAuthorizationViewController(paymentRequest: request)
        authVC?.delegate = self
        
        if let authVC = authVC {
            vc?.present(authVC, animated: true, completion: nil)
        } else {
            showAlert(nil, "PKPaymentAuthorizationViewController was nil.")
            return
        }
        
        
    }
    
    private func canMakePayments() -> Bool {
        var canPayment = false
        if PKPaymentAuthorizationViewController.canMakePayments() {
            if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_8_0) { // < ios8.0
                showAlert(nil, "This device cannot make payments.")
            } else if #available(iOS 9.0, *) {
                if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedPaymentNetworks, capabilities: PKMerchantCapability(rawValue: merchantCapabilities)) {
                    // This device can make payments and has a supported card"
                    canPayment = true
                } else {
                    showAlert(nil, "This device can make payments but has no supported cards.")
                }
            } else if #available(iOS 8.0, *) {
                if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedPaymentNetworks) {
                    // This device can make payments and has a supported card , in ios 8
                    canPayment = true
                } else {
                    showAlert(nil, "This device can make payments but has no supported cards.")
                }
            } else {
                showAlert(nil, "This device cannot make payments.")
            }
        } else {
            showAlert(nil, "This device cannot make payments.")
        }
        return canPayment;
    }
    
    // Pay the call, pass the result
    /*
     body: {paymentAuthorizationStatus: success / failure / invalid-billing-address / invalid-shipping-address / invalid-shipping-contact / require-pin/ incorrect-pin/ locked-pin  }
     */
    private func completeLastTransaction(_ body: NSDictionary, _ callback: CallbackHandler?) {
        let paymentAuthorizationStatusString = self.paymentAuthorizationStatusFromBody(body)
        completion?(paymentAuthorizationStatusString)
    }
    /*
     {
     shippingMethods :{
     [{
     label:String
     amount:DecimalNumber
     detail:String?
     identifier:String?
     },{
     label:String
     amount:DecimalNumber
     detail:String?
     identifier:String?
     }]
     }
     }
     
     */
    private func shippingMethodsFromBody(_ body: NSDictionary) -> [PKShippingMethod] {
        var methods: [PKShippingMethod] = []
        if let tempMethods = body.value(forKey: "shippingMethods") as? Array<Dictionary<String, Any>> {
            for tempMethod in tempMethods {
                JJPrint("payment method:\(tempMethod)")
                let method = PKShippingMethod()
                if let lable = tempMethod["label"] as? String, let amount = tempMethod["amount"], let decimalValue = (amount as AnyObject).decimalValue {
                    let amountNumber = NSDecimalNumber(decimal: decimalValue)
                    method.label = lable
                    method.amount = amountNumber
                }
                let identifier = tempMethod["identifier"] as? String
                let detail = tempMethod["detail"] as? String
                method.detail = detail
                method.identifier = identifier
                methods.append(method)
            }
        }
        return methods;
    }
    
    /*
     {
     items :{
     [{
     label:String
     amount:DecimalNumber
     },{
     label:String
     amount:DecimalNumber
     }]
     }
     }
     */
    private func itemsFromBody(_ body: NSDictionary) -> [PKPaymentSummaryItem] {
        var items: [PKPaymentSummaryItem] = []
        if let tempItems = body.value(forKey: "items") as? Array<Dictionary<String, Any>> {
            for item in tempItems {
                //                JJPrint("payment item:\(item)")
                if let lable = item["label"] as? String, let amount = item["amount"], let decimalValue = (amount as AnyObject).decimalValue {
                    let amountNumber = NSDecimalNumber(decimal: decimalValue)
                    let newItem = PKPaymentSummaryItem(label: lable, amount: amountNumber)
                    items.append(newItem)
                }
            }
        }
        return items
    }
    // shipping/delivery/store/service
    @available(iOS 8.3, *)
    private func shippingTypeFromBody(_ body: NSDictionary) -> PKShippingType {
        if let shippingType = body.value(forKey: "shippingType") as? String {
            if shippingType == "shipping" {
                return PKShippingType.shipping
            } else if shippingType == "delivery" {
                return PKShippingType.delivery
            } else if shippingType == "store" {
                return PKShippingType.storePickup
            } else if shippingType == "service" {
                return PKShippingType.servicePickup
            }
        }
        return PKShippingType.shipping
    }
    
    /*
     // param:none/all/postcode/email/phone
     {shippingAddressRequirement:"none"}
     */
    private func shippingAddressRequirementFromArgumentsBody(_ body: NSDictionary) -> PKAddressField {
        if let shippingAddressRequirement = body.value(forKey: "shippingAddressRequirement") as? String {
            if shippingAddressRequirement == "none" {
                return PKAddressField.init(rawValue: 0) // none
            } else if shippingAddressRequirement == "all" {
                return PKAddressField.all
            } else if shippingAddressRequirement == "postcode" {
                return PKAddressField.postalAddress
            } else if shippingAddressRequirement == "name" {
                if #available(iOS 8.3, *) {
                    return PKAddressField.name
                }
            } else if shippingAddressRequirement == "email" {
                return PKAddressField.email
            } else if shippingAddressRequirement == "phone" {
                return PKAddressField.phone
            }
        }
        return PKAddressField.init(rawValue: 0) // none
    }
    
    /*
     // param:none/all/postcode/email/phone
     {billingAddressRequirement:"none"}
     */
    private func billingAddressRequirementFromBody(_ body: NSDictionary) -> PKAddressField {
        if let billingAddressRequirement = body.value(forKey: "billingAddressRequirement") as? String {
            if billingAddressRequirement == "none" {
                return PKAddressField.init(rawValue: 0) // none
            } else if billingAddressRequirement == "all" {
                return PKAddressField.all
            } else if billingAddressRequirement == "postcode" {
                return PKAddressField.postalAddress
            } else if billingAddressRequirement == "name" {
                if #available(iOS 8.3, *) {
                    return PKAddressField.name
                }
            } else if billingAddressRequirement == "email" {
                return PKAddressField.email
            } else if billingAddressRequirement == "phone" {
                return PKAddressField.phone
            }
        }
        return PKAddressField.init(rawValue: 0) // none
    }
    
    /*
     body: {paymentAuthorizationStatus: success / failure / invalid-billing-address / invalid-shipping-address / invalid-shipping-contact / require-pin/ incorrect-pin/ locked-pin  }
     */
    /// Pay the call, pass the result
    private func paymentAuthorizationStatusFromBody(_ body: NSDictionary) -> PKPaymentAuthorizationStatus {
        
        if let paymentAuthorizationStatus = body.value(forKey: "paymentAuthorizationStatus") as? String {
            if paymentAuthorizationStatus == "success" {
                return PKPaymentAuthorizationStatus.success
            } else if paymentAuthorizationStatus == "failure" {
                return PKPaymentAuthorizationStatus.failure
            } else if paymentAuthorizationStatus == "invalid-billing-address" {
                return PKPaymentAuthorizationStatus.invalidBillingPostalAddress
            } else if paymentAuthorizationStatus == "invalid-shipping-address" {
                return PKPaymentAuthorizationStatus.invalidShippingPostalAddress
            } else if paymentAuthorizationStatus == "invalid-shipping-contact" {
                return PKPaymentAuthorizationStatus.invalidShippingContact
            } else if paymentAuthorizationStatus == "require-pin" {
                if #available(iOS 9.2, *) {
                    return PKPaymentAuthorizationStatus.pinRequired
                }
            } else if paymentAuthorizationStatus == "incorrect-pin" {
                if #available(iOS 9.2, *) {
                    return PKPaymentAuthorizationStatus.pinIncorrect
                }
            } else if paymentAuthorizationStatus == "locked-pin" {
                if #available(iOS 9.2, *) {
                    return PKPaymentAuthorizationStatus.pinLockout
                }
            }
        }
        return PKPaymentAuthorizationStatus.failure
    }
    
    
    
}
/// PKPaymentAuthorizationViewControllerDelegate --------start
extension ApplepayService: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // payment result
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        self.completion = completion
        
        /*
         lements
         ▿ 0 : 2 elements
         - key : "paymentData"
         - value : "eyJ2ZXJzaW9uIjoiRUNfdjEiLCJkYXRhIjoiVFZqZnhMdVF0Q0xvQUxpOW5sVjBwUVJ2VnZMVFRmMkU1NHJoRm1vb2M4S0FHUzF2aC9TQlJwaCtnY0M2WFpwbzE3NU4xQ0tJczNNL09XWk5IWEs2Q2xGQndZcHVQdUltbk9LcWx4L3VHUVczSHc1OHBJd2JZWk55Q3NwZlgrZHIxWDFETndQYUI4UnhtNHdNbmRZbDRGOTJvbDRxS2Y0Zk1vdHB4TXRSSFkrd2hnQlY1bkVVM1d2NWpwRmo5U281dkZQdXVhelJLdm9FSTRjaGlWcGxoaFI1THlPUkVhaGV0Zll4VHNZeXFTUnp2NGZ5SElyZzBOYjRxZW4zcDYyM1QrVUpYelNTU0ZKM2tVN2QzbHpoS0xHZ2ZQR29Sck5lakxwMGtnTS9ZUjgyTFVtZU0vTjkwNDJaeGFDbTB4LzBqY1lwTms1MUM1eTVuTkM3TksrRTBFL0VidkJUc1FNM1p6SC9xWlUxWWl2c1dCS0hnL2hUQVNZYmRVZGhNNVNSbGFOc1p3NUdKQXhGaHh0WXNwc21WVXVQWkJvd2QrWGxteU1sc050OVRtQzBXNjdlMmR3SG01eGRKZ2h0enlIN0Jqd0hiMEtteEFTb1JQVGM3UG9DeTcwYkdxSVY4ZDk1b3pHNHFxdXBpTFM4YzFJYWsyaU8zSzcycEVjdVBNa0xKK3FZcGZtRTJWVDNoamNaWGwrZCtTWE9RMXNhbDQ4RXI0L3Y4Y1J2a2hZZVgzL2xEa1E1YmxkblFJbmlpQVpKZ1hsQ3pyMUhVb09mSTRmckZzR1Z4Vi9uQjFYWmFYTmZXQ1FNUW9zPSIsInNpZ25hdHVyZSI6Ik1JQUdDU3FHU0liM0RRRUhBcUNBTUlBQ0FRRXhEekFOQmdsZ2hrZ0JaUU1FQWdFRkFEQ0FCZ2txaGtpRzl3MEJCd0VBQUtDQU1JSUQ3akNDQTVTZ0F3SUJBZ0lJT1N4Qkh2c2dtRDB3Q2dZSUtvWkl6ajBFQXdJd2VqRXVNQ3dHQTFVRUF3d2xRWEJ3YkdVZ1FYQndiR2xqWVhScGIyNGdTVzUwWldkeVlYUnBiMjRnUTBFZ0xTQkhNekVtTUNRR0ExVUVDd3dkUVhCd2JHVWdRMlZ5ZEdsbWFXTmhkR2x2YmlCQmRYUm9iM0pwZEhreEV6QVJCZ05WQkFvTUNrRndjR3hsSUVsdVl5NHhDekFKQmdOVkJBWVRBbFZUTUI0WERURTJNREV4TVRJeE1EYzBObG9YRFRJeE1ERXdPVEl4TURjME5sb3dhekV4TUM4R0ExVUVBd3dvWldOakxYTnRjQzFpY205clpYSXRjMmxuYmw5VlF6UXRVRkpQUkY5TGNubHdkRzl1WDBWRFF6RVVNQklHQTFVRUN3d0xhVTlUSUZONWMzUmxiWE14RXpBUkJnTlZCQW9NQ2tGd2NHeGxJRWx1WXk0eEN6QUpCZ05WQkFZVEFsVlRNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVadURxRG5oOXl6OW12Rk14aWRvcjJnanRsWFRrSVJGNm9hOHN3eEQycUxHY28rZCswQStvVG8zeXJJYUk1U21HYm5icnJZbnRwYmZETnVEdzJLZlFYYU9DQWhFd2dnSU5NRVVHQ0NzR0FRVUZCd0VCQkRrd056QTFCZ2dyQmdFRkJRY3dBWVlwYUhSMGNEb3ZMMjlqYzNBdVlYQndiR1V1WTI5dEwyOWpjM0F3TkMxaGNIQnNaV0ZwWTJFek1ESXdIUVlEVlIwT0JCWUVGRmZITlpRcXZaNmkvc3pUeStmdDRLTjhqTVg2TUF3R0ExVWRFd0VCL3dRQ01BQXdId1lEVlIwakJCZ3dGb0FVSS9KSnhFK1Q1TzhuNXNUMktHdy9vcnY5TGtzd2dnRWRCZ05WSFNBRWdnRVVNSUlCRURDQ0FRd0dDU3FHU0liM1kyUUZBVENCL2pDQnd3WUlLd1lCQlFVSEFnSXdnYllNZ2JOU1pXeHBZVzVqWlNCdmJpQjBhR2x6SUdObGNuUnBabWxqWVhSbElHSjVJR0Z1ZVNCd1lYSjBlU0JoYzNOMWJXVnpJR0ZqWTJWd2RHRnVZMlVnYjJZZ2RHaGxJSFJvWlc0Z1lYQndiR2xqWVdKc1pTQnpkR0Z1WkdGeVpDQjBaWEp0Y3lCaGJtUWdZMjl1WkdsMGFXOXVjeUJ2WmlCMWMyVXNJR05sY25ScFptbGpZWFJsSUhCdmJHbGplU0JoYm1RZ1kyVnlkR2xtYVdOaGRHbHZiaUJ3Y21GamRHbGpaU0J6ZEdGMFpXMWxiblJ6TGpBMkJnZ3JCZ0VGQlFjQ0FSWXFhSFIwY0RvdkwzZDNkeTVoY0hCc1pTNWpiMjB2WTJWeWRHbG1hV05oZEdWaGRYUm9iM0pwZEhrdk1EUUdBMVVkSHdRdE1Dc3dLYUFub0NXR0kyaDBkSEE2THk5amNtd3VZWEJ3YkdVdVkyOXRMMkZ3Y0d4bFlXbGpZVE11WTNKc01BNEdBMVVkRHdFQi93UUVBd0lIZ0RBUEJna3Foa2lHOTJOa0JoMEVBZ1VBTUFvR0NDcUdTTTQ5QkFNQ0EwZ0FNRVVDSUVTSVU4YkVnd0VqdEVxMmREYlJPK0MxMENzeGpWVlZJU2dwemRqRXlsR1dBaUVBa09aK3NqNXZTek5sRGxPeTV2eUo1Wk8zYjVHNVBwbnZ3SngxZ2M0QTllWXdnZ0x1TUlJQ2RhQURBZ0VDQWdoSmJTKy9PcGphbHpBS0JnZ3Foa2pPUFFRREFqQm5NUnN3R1FZRFZRUUREQkpCY0hCc1pTQlNiMjkwSUVOQklDMGdSek14SmpBa0JnTlZCQXNNSFVGd2NHeGxJRU5sY25ScFptbGpZWFJwYjI0Z1FYVjBhRzl5YVhSNU1STXdFUVlEVlFRS0RBcEJjSEJzWlNCSmJtTXVNUXN3Q1FZRFZRUUdFd0pWVXpBZUZ3MHhOREExTURZeU16UTJNekJhRncweU9UQTFNRFl5TXpRMk16QmFNSG94TGpBc0JnTlZCQU1NSlVGd2NHeGxJRUZ3Y0d4cFkyRjBhVzl1SUVsdWRHVm5jbUYwYVc5dUlFTkJJQzBnUnpNeEpqQWtCZ05WQkFzTUhVRndjR3hsSUVObGNuUnBabWxqWVhScGIyNGdRWFYwYUc5eWFYUjVNUk13RVFZRFZRUUtEQXBCY0hCc1pTQkpibU11TVFzd0NRWURWUVFHRXdKVlV6QlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJQQVhFWVFaMTJTRjFScGVKWUVIZHVpQW91L2VlNjVONEkzOFM1UGhNMWJWWmxzMXJpTFFsM1lOSWs1N3VnajlkaGZPaU10MnUyWnd2c2pvS1lUL1ZFV2pnZmN3Z2ZRd1JnWUlLd1lCQlFVSEFRRUVPakE0TURZR0NDc0dBUVVGQnpBQmhpcG9kSFJ3T2k4dmIyTnpjQzVoY0hCc1pTNWpiMjB2YjJOemNEQTBMV0Z3Y0d4bGNtOXZkR05oWnpNd0hRWURWUjBPQkJZRUZDUHlTY1JQaytUdkorYkU5aWhzUDZLNy9TNUxNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdId1lEVlIwakJCZ3dGb0FVdTdEZW9WZ3ppSnFraXBuZXZyM3JyOXJMSktzd053WURWUjBmQkRBd0xqQXNvQ3FnS0lZbWFIUjBjRG92TDJOeWJDNWhjSEJzWlM1amIyMHZZWEJ3YkdWeWIyOTBZMkZuTXk1amNtd3dEZ1lEVlIwUEFRSC9CQVFEQWdFR01CQUdDaXFHU0liM1kyUUdBZzRFQWdVQU1Bb0dDQ3FHU000OUJBTUNBMmNBTUdRQ01EclBjb05SRnBteGh2czF3MWJLWXIvMEYrM1pEM1ZOb282KzhaeUJYa0szaWZpWTk1dFpuNWpWUVEyUG5lbkMvZ0l3TWkzVlJDR3dvd1YzYkYzek9EdVFaLzBYZkN3aGJaWlB4bkpwZ2hKdlZQaDZmUnVaeTVzSmlTRmhCcGtQQ1pJZEFBQXhnZ0dNTUlJQmlBSUJBVENCaGpCNk1TNHdMQVlEVlFRRERDVkJjSEJzWlNCQmNIQnNhV05oZEdsdmJpQkpiblJsWjNKaGRHbHZiaUJEUVNBdElFY3pNU1l3SkFZRFZRUUxEQjFCY0hCc1pTQkRaWEowYVdacFkyRjBhVzl1SUVGMWRHaHZjbWwwZVRFVE1CRUdBMVVFQ2d3S1FYQndiR1VnU1c1akxqRUxNQWtHQTFVRUJoTUNWVk1DQ0Rrc1FSNzdJSmc5TUEwR0NXQ0dTQUZsQXdRQ0FRVUFvSUdWTUJnR0NTcUdTSWIzRFFFSkF6RUxCZ2txaGtpRzl3MEJCd0V3SEFZSktvWklodmNOQVFrRk1ROFhEVEU0TVRFd056QTJOVEUxTlZvd0tnWUpLb1pJaHZjTkFRazBNUjB3R3pBTkJnbGdoa2dCWlFNRUFnRUZBS0VLQmdncWhrak9QUVFEQWpBdkJna3Foa2lHOXcwQkNRUXhJZ1FnN090WUVlZVhJbGJjeUtnMmgrWTlMWEdUYk11QjlKa3JGR3U4TXF2dmZ3UXdDZ1lJS29aSXpqMEVBd0lFUnpCRkFpRUEwZkR4UFRjTEwxVXBQdDE5SkdhYzJ3dU9tcklPZkI0c1dseTRpNmtna0FJQ0lGSzZ6MDJhVDdjZ2ZQKzYxNSt4djluRk5JRXVLQ2g5L05HOG9vc2xoVVFUQUFBQUFBQUEiLCJoZWFkZXIiOnsiZXBoZW1lcmFsUHVibGljS2V5IjoiTUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFK2NMVlEva2VjMnJPZVpsaUluTGkxdHlBdFIrSjl5TnVSSHBxMTJTb3V1U3lQaFh2U2s5czJIZUlCcTJSZDJvalVtMG1JM0ZsRlhTZHJFZTJkR2dpckE9PSIsInB1YmxpY0tleUhhc2giOiJNSFI0YlBtdUFpcVBIem9KcU0xTk5lcjVMU3gxeU5DS0lnamo5N1hxemMwPSIsInRyYW5zYWN0aW9uSWQiOiJkOTQ0YmQ3MGQyMTU5NDQ2Nzk5ZjVlY2MyN2EyNDdkMWQ3NWYzM2IwYTg1MTc2OWFmMzY1ZWU1ZmQ3YTQ5NTNhIn19"
         ▿ 1 : 2 elements
         - key : "paymentMethodNetwork"
         ▿ value : PKPaymentNetwork
         - _rawValue : ChinaUnionPay
         ▿ 2 : 2 elements
         - key : "transactionIdentifier"
         - value : "D944BD70D2159446799F5ECC27A247D1D75F33B0A851769AF365EE5FD7A4953A"
         ▿ 3 : 2 elements
         - key : "paymentMethodTypeCard"
         - value : "credit"
         ▿ 4 : 2 elements
         - key : "paymentMethodDisplayName"
         - value : "ChinaUnionPay 7647"
         */
        
        //        let paymentData =  String(data: payment.token.paymentData, encoding: .utf8);
        
        let response = formatPaymentForApplication(payment)
        payResultCallback?.success(response: response)
        
    }
    
    //    @available(iOS 11.0, *)
    //    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Swift.Void) {
    //        JJPrint("payment:\(payment)")
    //    }
    
    /*
     {
     "paymentData": "<BASE64 ENCODED TOKEN WILL APPEAR HERE>",
     "transactionIdentifier": "Simulated Identifier",
     "paymentMethodDisplayName": "MasterCard 1234",
     "paymentMethodNetwork": "MasterCard",
     "paymentMethodTypeCard": "credit",
     "billingEmailAddress": "",
     "billingSupplementarySubLocality": "",
     "billingNameFirst": "First",
     "billingNameMiddle": "",
     "billingNameLast": "NAME",
     "billingAddressStreet": "Street 1\n",
     "billingAddressCity": "London",
     "billingAddressState": "London",
     "billingPostalCode": "POST CODE",
     "billingCountry": "United Kingdom",
     "billingISOCountryCode": "gb",
     "shippingEmailAddress": "",
     "shippingPhoneNumber": "",
     "shippingNameFirst": "First",
     "shippingNameMiddle": "",
     "shippingNameLast": "Name",
     "shippingSupplementarySubLocality": "",
     "shippingAddressStreet": "Street Line 1\nStreet Line 2",
     "shippingAddressCity": "London",
     "shippingAddressState": "London",
     "shippingPostalCode": "POST CODE",
     "shippingCountry": "United Kingdom",
     "shippingISOCountryCode": "gb",
     }
     */
    private func formatPaymentForApplication(_ payment: PKPayment) -> Dictionary<String, Any> {
        
        let paymentData = payment.token.paymentData.base64EncodedString()
        var response = Dictionary<String, Any>()
        response["paymentData"] = paymentData
        response["transactionIdentifier"] = payment.token.transactionIdentifier
        var typeCard = "error"
        if #available(iOS 9.0, *) {
            response["paymentMethodDisplayName"] = payment.token.paymentMethod.displayName
            response["paymentMethodNetwork"] = payment.token.paymentMethod.network
            
            switch payment.token.paymentMethod.type {
            case PKPaymentMethodType.unknown:
                typeCard = "unknown"
                break;
            case PKPaymentMethodType.debit:
                typeCard = "debit"
                break;
            case PKPaymentMethodType.credit:
                typeCard = "credit"
                break;
            case PKPaymentMethodType.prepaid:
                typeCard = "prepaid"
                break;
            case PKPaymentMethodType.store:
                typeCard = "store"
                break;
            default:
                typeCard = "eMoney"
                break;
            }
        } else {
            typeCard = "error"
        }
        response["paymentMethodTypeCard"] = typeCard
        //        if #available(iOS 9.0, *), let billingContact = payment.billingContact {
        //            if let emailAddress = billingContact.emailAddress {
        //                response["billingEmailAddress"] = emailAddress
        //            }
        //            if #available(iOS 9.2, *), let supplementarySubLocality = billingContact.supplementarySubLocality {
        //                response["billingSupplementarySubLocality"] = supplementarySubLocality
        //            }
        //            if let name = billingContact.name {
        //                if let givenName = name.givenName {
        //                    response["billingNameFirst"] = givenName
        //                }
        //                if let middleName = name.middleName {
        //                    response["billingNameMiddle"] = middleName
        //                }
        //                if let familyName = name.familyName {
        //                    response["billingNameLast"] = familyName
        //                }
        //            }
        //            if let postalAddress = billingContact.postalAddress {
        //                response["billingAddressStreet"] = postalAddress.street
        //                response["billingAddressCity"] = postalAddress.city
        //                response["billingAddressState"] = postalAddress.state
        //                response["billingPostalCode"] = postalAddress.postalCode
        //                response["billingCountry"] = postalAddress.country
        //                response["billingISOCountryCode"] = postalAddress.isoCountryCode
        //            }
        //
        //            if let shippingContact = payment.shippingContact {
        //                if let emailAddress = shippingContact.emailAddress {
        //                    response["shippingEmailAddress"] = emailAddress
        //                }
        //                if let phoneNumber = shippingContact.phoneNumber {
        //                    response["shippingPhoneNumber"] = phoneNumber.stringValue
        //                }
        //                if let name = shippingContact.name {
        //                    if let givenName = name.givenName {
        //                        response["shippingNameFirst"] = givenName
        //                    }
        //                    if let middleName = name.middleName {
        //                        response["shippingNameMiddle"] = middleName
        //                    }
        //                    if let familyName = name.familyName {
        //                        response["shippingNameLast"] = familyName
        //                    }
        //                }
        //                if #available(iOS 9.2, *), let supplementarySubLocality = shippingContact.supplementarySubLocality {
        //                    response["shippingSupplementarySubLocality"] = supplementarySubLocality
        //                }
        //                if let postalAddress = shippingContact.postalAddress {
        //                    response["shippingAddressStreet"] = postalAddress.street
        //                    response["shippingAddressCity"] = postalAddress.city
        //                    response["shippingAddressState"] = postalAddress.state
        //                    response["shippingPostalCode"] = postalAddress.postalCode
        //                    response["shippingCountry"] = postalAddress.country
        //                    response["shippingISOCountryCode"] = postalAddress.isoCountryCode
        //                }
        //            }
        //
        //        } else if #available(iOS 8.0, *) {
        //            if let shippingAddress = payment.shippingAddress {
        //
        //                if let PersonAddressStreetKey = kABPersonAddressStreetKey as? ABPropertyID, let shippingAddressStreet = ABRecordCopyValue(shippingAddress, PersonAddressStreetKey).takeRetainedValue() as? String {
        //                    response["shippingAddressStreet"] = shippingAddressStreet
        //                }
        //                if let PersonAddressCityKey = kABPersonAddressCityKey as? ABPropertyID, let shippingAddressCity = ABRecordCopyValue(shippingAddress, PersonAddressCityKey).takeRetainedValue() as? String {
        //                    response["shippingAddressCity"] = shippingAddressCity
        //                }
        //                if let PersonAddressZIPKey = kABPersonAddressZIPKey as? ABPropertyID, let shippingPostalCode = ABRecordCopyValue(shippingAddress, PersonAddressZIPKey).takeRetainedValue() as? String {
        //                    response["shippingPostalCode"] = shippingPostalCode
        //                }
        //                if let PersonAddressStateKey = kABPersonAddressStateKey as? ABPropertyID, let shippingAddressState = ABRecordCopyValue(shippingAddress, PersonAddressStateKey).takeRetainedValue() as? String {
        //                    response["shippingAddressState"] = shippingAddressState
        //                }
        //                if let PersonAddressCountryCodeKey = kABPersonAddressCountryCodeKey as? ABPropertyID, let shippingCountry = ABRecordCopyValue(shippingAddress, PersonAddressCountryCodeKey).takeRetainedValue() as? String {
        //                    response["shippingCountry"] = shippingCountry
        //                }
        //                if let PersonAddressCityKey = kABPersonAddressCityKey as? ABPropertyID, let shippingISOCountryCode = ABRecordCopyValue(shippingAddress, PersonAddressCityKey).takeRetainedValue() as? String {
        //                    response["shippingISOCountryCode"] = shippingISOCountryCode
        //                }
        //                if let shippingEmailAddress = ABRecordCopyValue(shippingAddress, kABPersonEmailProperty).takeRetainedValue() as? String {
        //                    response["shippingEmailAddress"] = shippingEmailAddress
        //                }
        //
        //            }
        //        }
        
        
        return response
    }
    
    
}
/// PKPaymentAuthorizationViewControllerDelegate --------end
