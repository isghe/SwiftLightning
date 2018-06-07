//
//  PayMainInteractor.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-28.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol PayMainBusinessLogic {
  func checkURL(request: PayMain.CheckURL.Request)
  func confirmPayment(request: PayMain.ConfirmPayment.Request)
  func validate(request: PayMain.Validate.Request)
}


protocol PayMainDataStore {
  var paymentURL: URL? { get set }
  var address: String { get }
  var amount: Bitcoin { get }
  var description: String { get }
  var fee: Bitcoin? { get }
  var paymentType: BitcoinPaymentType? { get }
}


class PayMainInteractor: PayMainBusinessLogic, PayMainDataStore {
  
  var presenter: PayMainPresentationLogic?
  var worker: PayMainWorker?
  
  
  // MARK: Data Store
  
  var paymentURL: URL?
  
  private var _address: String?
  private var _amount: Bitcoin?
  private var _description: String?
  private var _fee: Bitcoin?
  private var _paymentType: BitcoinPaymentType?
  
  var address: String {
    guard let returnValue = _address else {
      SLLog.fatal("address in Data Store = nil")
    }
    return returnValue
  }
  
  var amount: Bitcoin {
    guard let returnValue = _amount else {
      SLLog.fatal("amount in Data Store = nil")
    }
    return returnValue
  }
  
  var description: String {
    return _description ?? ""
  }
  
  var fee: Bitcoin? {
    return _fee
  }
  
  var paymentType: BitcoinPaymentType? {
    return _paymentType
  }
  
  
  // MARK: Check Incoming URL
  
  func checkURL(request: PayMain.CheckURL.Request) {
    let response = PayMain.CheckURL.Response(url: paymentURL)
    presenter?.presentCheckURL(response: response)
  }
  
  
  // MARK: Validate Address/Amount
  
  func validate(request: PayMain.Validate.Request) {
    let amount: Bitcoin? = Bitcoin(inSatoshi: request.rawAmountString)
    
    validate(inputAddress: request.rawAddressString, inputAmount: amount) { result in
      
      // Respond to Presenter
      let response = PayMain.Response(inputAddress: request.rawAddressString,
                                      inputAmount: amount,
                                      validationResult: result)
      self.presenter?.presentValidate(response: response)
    }
  }

  
  // MARK: Confirm Payment
  
  func confirmPayment(request: PayMain.ConfirmPayment.Request) {
    let amount: Bitcoin? = Bitcoin(inSatoshi: request.rawAmountString)
    
    validate(inputAddress: request.rawAddressString, inputAmount: amount) { result in
      
      // Store parameters to Data Store
      
      // If it's lightning, just make sure it's the inputString (Payment Request)
      if let paymentType = result.paymentType, paymentType == .lightning {
        self._address = request.rawAddressString
      } else {
        self._address = result.revisedAddress ?? request.rawAddressString
      }
      self._amount = result.revisedAmount ?? amount
      self._description = result.payDescription ?? request.description
      self._fee = result.fee
      self._paymentType = result.paymentType
      
      // Respond to Presenter
      let response = PayMain.Response(inputAddress: request.rawAddressString,
                                      inputAmount: amount,
                                      validationResult: result)
      self.presenter?.presentConfirmPayment(response: response)
    }
  }
  
  
  // MARK: Common Validation Algorithm
  
  private func validate(inputAddress: String,
                        inputAmount: Bitcoin?,
                        completion: @escaping (PayMain.ValidationResult) -> ()) {
    
    LNManager.determineAddress(inputString: inputAddress) { address, amount, description, network, valid in
      
      // Pre-fill bulk of the result ahead of time. Adjust as necassary
      var result = PayMain.ValidationResult(paymentType: network,
                                            revisedAddress: address,
                                            revisedAmount: amount,
                                            payDescription: description)
      // Error case first
      guard let valid = valid else {
        result.error = PayMain.Err.determineAddr
        completion(result)
        return
      }
      
      // No further validation is possible without a valid address or known payment type
      guard let addr = address, let type = network, valid else {
        result.addressError = PayMain.AddrError.invalidAddr
        completion(result)
        return
      }
      
      
      // Validate the amount only if there's an amount in the payment request
      if let amount = amount, let inputAmount = inputAmount {
        
        // For Lightning requests, the amount fields must match.
        // For Bitcoin on chain, will only hit this case if a pay req is put in last.
        //   If the amount is put in last, won't have a problem with mismatch
        // So just enforce the match for both cases here
        guard amount == inputAmount else {
          result.amountError = PayMain.AmountError.amtMismatch
          completion(result)
          return
        }
      }
      
      // Nothing for description, we are always going to overwrite the field if available
      
      switch type {
      case .lightning:
        
        // Get channel balance first regardless
        LNServices.channelBalance() { (balancer) in
          do {
            let balance = try balancer()
            result.balance = Bitcoin(inSatoshi: balance.confirmed)
            
            // Try to find a route only if there is an amount
            if let amount = amount ?? inputAmount {
              
              // Find route and fee for LN
              LNServices.queryRoutes(pubKey: addr,
                                     amt: amount.integerInSatoshis,
                                     numRoutes: 1) { (responder) in
                do {
                  let routes = try responder()
                  
                  guard routes.count > 0 else {
                    throw PayMain.Warning.noRouteFound
                  }
                  result.fee = Bitcoin(inSatoshi: routes[0].totalFees)
            
                  if Bitcoin(inSatoshi: balance.confirmed) < Bitcoin(amount + result.fee!) {
                    result.amountError = PayMain.AmountError.insufficient
                  }
                  completion(result)
                  
                } catch {
                  result.routeError = error
                  completion(result)
                }
              }  // LNServices.queryRoutes
              
            } else {
              completion(result)
            }
            
          } catch {
            result.error = error
            completion(result)
          }
        }  // LNServices.channelBalance
        
      case .onChain:
          
        // Check everything against wallet balance
        LNServices.walletBalance() { (balancer) in
          do {
            let balance = try balancer()
            result.balance = Bitcoin(inSatoshi: balance.confirmed)
            
            // Check the amount if there is an amount. All good otherwise
            if let amount = amount ?? inputAmount {
              if Bitcoin(inSatoshi: balance.confirmed) < amount {  // TODO: Subtract fee when fee estimation is in place
                result.amountError = PayMain.AmountError.insufficient
              }
            }
            completion(result)
            
          } catch {
            result.error = error
            completion(result)
          }
        }
      } // switch lightning / onChain
    }
  }
}
