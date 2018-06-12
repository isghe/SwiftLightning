//
//  AutopilotViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-06-10.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import SwiftRangeSlider

protocol AutopilotDisplayLogic: class {
  func displayConfig(viewModel: Autopilot.ReadConfig.ViewModel)
  func displayError(viewModel: Autopilot.ErrorVM)
}


class AutopilotViewController: SLViewController, AutopilotDisplayLogic {
  var interactor: AutopilotBusinessLogic?
  var router: (NSObjectProtocol & AutopilotRoutingLogic & AutopilotDataPassing)?

  
  // MARK: IBOutlets
  
  @IBOutlet weak var fundPercentageView: SLSliderConfigView!
  @IBOutlet weak var channelMaxMinView: SLSliderConfigView!
  @IBOutlet weak var maxChannelsView: SLSliderConfigView!
  
  
  // MARK: Object lifecycle
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  override func viewDidLayoutSubviews() {
    fundPercentageView.setNeedsLayout()
    channelMaxMinView.setNeedsLayout()
    maxChannelsView.setNeedsLayout()
    
    fundPercentageView.layoutIfNeeded()
    channelMaxMinView.layoutIfNeeded()
    maxChannelsView.layoutIfNeeded()
  }
  
  
  // MARK: Setup
  
  private func setup() {
    let viewController = self
    let interactor = AutopilotInteractor()
    let presenter = AutopilotPresenter()
    let router = AutopilotRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
  }

  
  // MARK: Private Instance Variables
  
  private let percentFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.multiplier = 100.0
    formatter.maximumFractionDigits = 0
    return formatter
  }()
  
  
  // MARK: View lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let minFundMarkString = percentFormatter.string(from: NSNumber(value: Autopilot.Constants.minFundAlloc))
    let midFundValue = (Autopilot.Constants.maxFundAlloc - Autopilot.Constants.minFundAlloc) / 2 + Autopilot.Constants.minFundAlloc
    let midFundMarkString = percentFormatter.string(from: NSNumber(value: midFundValue))
    let maxFundMarkString = percentFormatter.string(from: NSNumber(value: Autopilot.Constants.maxFundAlloc))
    
    fundPercentageView.rangeSlider.isHidden = true
    fundPercentageView.slider.isHidden = false
    fundPercentageView.slider.addTarget(self,
                                        action: #selector(updateSliderValue(sender:forEvent:)),
                                        for: .valueChanged)
    
    fundPercentageView.titleLabel.text = "Funds for autopilot channels:  "
    fundPercentageView.minMarkLabel.text = minFundMarkString
    fundPercentageView.secondMarkLabel.text = ""
    fundPercentageView.thirdMarkLabel.text = midFundMarkString
    fundPercentageView.fourthMarkLabel.text = ""
    fundPercentageView.maxMarkLabel.text = maxFundMarkString
    
    channelMaxMinView.rangeSlider.isHidden = false
    channelMaxMinView.slider.isHidden = true
    channelMaxMinView.rangeSlider.addTarget(self,
                                            action: #selector(updateRangeSliderValue(sender:forEvent:)),
                                            for: .valueChanged)
    
    channelMaxMinView.titleLabel.text = "Channel value range:  "
    channelMaxMinView.minMarkLabel.text = Autopilot.Constants.minChannelSize.formattedInSatoshis()
    channelMaxMinView.secondMarkLabel.text = ""
    channelMaxMinView.thirdMarkLabel.text = ""
    channelMaxMinView.fourthMarkLabel.text = ""
    channelMaxMinView.maxMarkLabel.text = Autopilot.Constants.maxChannelSize.formattedInSatoshis()
    
    let markRange = Autopilot.Constants.maxNumChannels - Autopilot.Constants.minNumChannels
    let secondMarkString = Autopilot.Constants.minNumChannels + 1*markRange/4
    let thirdMarkString = Autopilot.Constants.minNumChannels + 2*markRange/4
    let fourthMarkString = Autopilot.Constants.minNumChannels + 3*markRange/4
    
    maxChannelsView.rangeSlider.isHidden = true
    maxChannelsView.slider.isHidden = false
    maxChannelsView.slider.addTarget(self,
                                     action: #selector(updateSliderValue(sender:forEvent:)),
                                     for: .valueChanged)
    
    maxChannelsView.titleLabel.text = "Maximum number of channels:  "
    maxChannelsView.minMarkLabel.text = "\(Autopilot.Constants.minNumChannels)"
    maxChannelsView.secondMarkLabel.text = "\(secondMarkString)"
    maxChannelsView.thirdMarkLabel.text = "\(thirdMarkString)"
    maxChannelsView.fourthMarkLabel.text = "\(fourthMarkString)"
    maxChannelsView.maxMarkLabel.text = "\(Autopilot.Constants.maxNumChannels)"
    
    
    // Configure button appearances
    disengageButton.selectedColor = UIColor.sandyOrange
    disengageButton.selectedShadowColor = UIColor.sandyOrangeShadow
    disengageButton.selectedTextColor = UIColor.normalText
    
    // Get the current Autopilot Configuration from LND for display purposes
    let request = Autopilot.ReadConfig.Request()
    interactor?.readConfig(request: request)
  }
  
  
  // MARK: Update on track slide
  
  private func convertToAlloc(from sliderValue: Float) -> Double {
    let range = Double(Autopilot.Constants.maxFundAlloc - Autopilot.Constants.minFundAlloc)
    return (Double(sliderValue)*range + Autopilot.Constants.minFundAlloc)
  }
  
  private func convertToChValue(from sliderValue: Double) -> Bitcoin {
    let range = Double(Autopilot.Constants.maxChannelSize.integerInSatoshis -
      Autopilot.Constants.minChannelSize.integerInSatoshis)
    let integer = Int(sliderValue*range) + Autopilot.Constants.minChannelSize.integerInSatoshis
    return Bitcoin(inSatoshi: integer)
  }
  
  private func convertToNumChs(from sliderValue: Float) -> Int {
    let range = Float(Autopilot.Constants.maxNumChannels - Autopilot.Constants.minNumChannels)
    return Int(sliderValue*range) + Autopilot.Constants.minNumChannels
  }
  
  @objc func updateSliderValue(sender: UISlider, forEvent event: UIEvent) {
    if sender == fundPercentageView.slider {
      let fundPercentage = convertToAlloc(from: sender.value)
      fundPercentageView.valueLabel.text = percentFormatter.string(from: NSNumber(value: fundPercentage))
    } else if sender == maxChannelsView.slider {
      maxChannelsView.valueLabel.text = "\(convertToNumChs(from: sender.value))"
    } else {
      SLLog.assert("Unexpected slider value update")
    }
  }
  
  @objc func updateRangeSliderValue(sender: RangeSlider, forEvent event: UIEvent) {
    if sender == channelMaxMinView.rangeSlider {
      let minChanSize = convertToChValue(from: sender.lowerValue)
      let maxChanSize = convertToChValue(from: sender.upperValue)
      channelMaxMinView.valueLabel.text = "\(minChanSize.formattedInSatoshis()) - \(maxChanSize.formattedInSatoshis()) sats"
    } else {
      SLLog.assert("Unexpected range slider value update")
    }
  }
  
  
  // MARK: Update on Selection
  
  @IBOutlet weak var engageButton: SLSelectButton!
  
  @IBOutlet weak var disengageButton: SLSelectButton!
  
  @IBAction func engageTapped(_ sender: SLSelectButton) {
    engageButton.selectedAppearance()
    disengageButton.deselectedAppearance()
  }
  
  @IBAction func disengageTapped(_ sender: SLSelectButton) {
    engageButton.deselectedAppearance()
    disengageButton.selectedAppearance()
  }
  
  
  // MARK: Read & Display Config
  
  func displayConfig(viewModel: Autopilot.ReadConfig.ViewModel) {
    let fundRange = Float(Autopilot.Constants.maxFundAlloc - Autopilot.Constants.minFundAlloc)
    let fundPercentageValue = Float(viewModel.fundAlloc - Autopilot.Constants.minFundAlloc) / fundRange
    fundPercentageView.slider.setValue(fundPercentageValue, animated: true)
    fundPercentageView.valueLabel.text = percentFormatter.string(from: NSNumber(value: viewModel.fundAlloc))

    let chValueRange = Double(Autopilot.Constants.maxChannelSize.integerInSatoshis -
      Autopilot.Constants.minChannelSize.integerInSatoshis)
    let minChValue = Double(viewModel.minChanSize.integerInSatoshis - Autopilot.Constants.minChannelSize.integerInSatoshis) / chValueRange
    let maxChValue = Double(viewModel.maxChanSize.integerInSatoshis - Autopilot.Constants.minChannelSize.integerInSatoshis) / chValueRange
    channelMaxMinView.rangeSlider.lowerValue = minChValue
    channelMaxMinView.rangeSlider.upperValue = maxChValue
    channelMaxMinView.valueLabel.text = "\(viewModel.minChanSize.formattedInSatoshis()) - \(viewModel.maxChanSize.formattedInSatoshis()) sats"
    
    let channelsRange = Float(Autopilot.Constants.maxNumChannels - Autopilot.Constants.minNumChannels)
    let numChannelsValue = Float(viewModel.maxChanNum - Autopilot.Constants.minNumChannels) / channelsRange
    maxChannelsView.slider.setValue(numChannelsValue, animated: true)
    maxChannelsView.valueLabel.text = "\(viewModel.maxChanNum)"
    
    if viewModel.active {
      engageButton.selectedAppearance()
      disengageButton.deselectedAppearance()
    } else {
      engageButton.deselectedAppearance()
      disengageButton.selectedAppearance()
    }
  }
  
  
  // MARK: Write Config & Restart if needed
  
  @IBOutlet weak var restartButton: SLBarButton!
  
  @IBAction func restartTapped(_ sender: SLBarButton) {
  }
  
  
  
  // MARK: Error Display
  
  func displayError(viewModel: Autopilot.ErrorVM) {
    
  }
  
  
  // MARK: Close Cross Tapped
  
  @IBAction func closeCrossTapped(_ sender: UIBarButtonItem) {
    router?.routeToWalletMain()
  }
  
}