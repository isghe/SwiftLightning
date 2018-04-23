//
//  RootPresenter.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-20.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol RootPresentationLogic
{
  func presentWalletPresenceRouting(response: Root.WalletPresenceRouting.Response)
  func presentConfirmWalletUnlock(response: Root.ConfirmWalletUnlock.Response)
}

class RootPresenter: RootPresentationLogic
{
  weak var viewController: RootDisplayLogic?
  
  // MARK: Wallet Presence Routing
  
  func presentWalletPresenceRouting(response: Root.WalletPresenceRouting.Response)
  {
    guard let walletPresent = response.walletPresent else {
      let viewModel = Root.WalletPresenceRouting.ViewModel(errorTitle: "Critical Wallet Error",
                                                           errorMsg: "Cannot reach internal wallet backend. Please make sure the app is up to date, and please also file a bug report. Thanks!")
      viewController?.displayErrorStatus(viewModel: viewModel)
      return
    }

    switch walletPresent {
      case true:
      viewController?.displayUnlockScenes()
      case false:
      viewController?.displaySetupScenes()
    }
  }
  
  // MARK: Confirm Wallet Unlock
  
  func presentConfirmWalletUnlock(response: Root.ConfirmWalletUnlock.Response) {
    if response.isWalletUnlocked {
      viewController?.displayWalletNavigation()
    } else {
      let viewModel = Root.ConfirmWalletUnlock.ViewModel(errTitle: "Wallet Error",
                                                         errMsg: "Cannot talk to Wallet. Please restart app in attempt to retry.")
      viewController?.displayConfirmWalletUnlockFailure(viewModel: viewModel)
    }
  }
}