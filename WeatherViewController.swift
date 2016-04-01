//
//  WeatherViewController.swift
//  Skycast
//
//  Created by Kevin Kong on 2/27/16.
//  Copyright © 2016 Kevin Kong. All rights reserved.
//

import UIKit
import AVFoundation
import ForecastIO
import CoreLocation
import BEMSimpleLineGraph


class WeatherViewController: UIViewController, CLLocationManagerDelegate, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate {

    // Data
    
    
    // CoreLocation Data
    var locationManager: CLLocationManager = CLLocationManager()
    var locationNeedsUpdate = true
    
    var pageIndex: Int!
    var city: City! {
        didSet {
            updateWeather()
        }
    }
    
    var forecastTime: NSDate? {
        if let current = city.forecast?.forecast.currently {
            return current.time
        } else {
            return nil
        }
    }
    
    lazy var currentTemp:Float = 0.00
    lazy var currentConditions = ""
    
    lazy var hourlyTemp = [Float]()
    lazy var dailyTemp = [Float]()
    
    lazy var hourlySummary = [(String, Double)]()
    lazy var dailySummary = [(String, Double)]()
    
    var skipTimer: NSTimer?
    var textTimer: NSTimer?
    
    var videoStopped = true
    
    
    
    // UI
    
    var filter: UIView!
    
    var navBar: UINavigationBar!
    
    var holdGesture: UILongPressGestureRecognizer!
    
    
    var currentWeatherPlayer: AVPlayer!
    var forecastPlayer: AVQueuePlayer?
    
    var forecastLayer: AVPlayerLayer!
    
    var tempGraph: BEMSimpleLineGraphView!
    
    lazy var cityLabel = UILabel()
    lazy var conditionLabel = UILabel()
    lazy var tempLabel = UILabel()
    var timeLabel: UILabel?
    
    var forecastTypeButton: UIButton!
    var tempUnitsButton: UIButton!
    
    
    lazy var dateFormatter = NSDateFormatter()
    
    
    
    // Tutorial View
    var tutorialView: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        // CoreLocation
        triggerLocationServices()
        
        
        
        // Orientation Change
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WeatherViewController.orientationDidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        
        
        
        // GestureRecognizers
        
        // Long Press for playing/stopping the forecast videos
        self.holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(WeatherViewController.longPressHandler(_:)))
        holdGesture.minimumPressDuration = 0.5
        self.view.addGestureRecognizer(holdGesture)
        
        
        
        
        
        // Filter
        
        self.filter = UIView()
        filter.backgroundColor = UIColor.blackColor()
        filter.layer.zPosition = -1
        filter.alpha = 0.4
        filter.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(filter)
        
        let horizontalConstraints1 = NSLayoutConstraint(item: self.filter, attribute:
            .LeftMargin, relatedBy: .Equal, toItem: view,
            attribute: .LeftMargin, multiplier: 1.0,
            constant: -20)
        let horizontalConstraints2 = NSLayoutConstraint(item: self.filter, attribute: .RightMargin, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: 20)
        let verticalConstraints1 = NSLayoutConstraint(item: self.filter, attribute: .TopMargin, relatedBy: .Equal, toItem: view, attribute: .TopMargin, multiplier: 1.0, constant: 0)
        let verticalConstraints2 = NSLayoutConstraint(item: self.filter, attribute: .BottomMargin, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1.0, constant: 0)
        
        NSLayoutConstraint.activateConstraints([horizontalConstraints1, horizontalConstraints2, verticalConstraints1, verticalConstraints2])
        
        
        
        
        
        // Nav
        let rightBarButton = UIBarButtonItem(image: UIImage(named: "info")?.imageWithRenderingMode(.AlwaysTemplate), style: .Plain, target: self, action: #selector(WeatherViewController.showTutorial))
        navigationItem.rightBarButtonItem = rightBarButton

        
        self.navBar = UINavigationBar()
        navBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar.shadowImage = UIImage()
        navBar.translucent = true
        navBar.tintColor = UIColor.whiteColor()
        navBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "BrandonText-Bold", size: 14)!,
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        navBar.frame = CGRectMake(0, 0, view.frame.width, 44)
        navBar.items = [navigationItem]
        
        
        
        
        
        
        // Text Labels
        
        cityLabel = UILabel()
        cityLabel.textAlignment = .Center
        cityLabel.textColor = UIColor.whiteColor()
        cityLabel.font = UIFont(name: "BrandonText-Bold", size: 30)
        cityLabel.frame.size = CGSizeMake(view.frame.width, 35)
        cityLabel.translatesAutoresizingMaskIntoConstraints = false
        cityLabel.layer.zPosition = 1

        let hc1 = NSLayoutConstraint(item: cityLabel, attribute:
            .LeftMargin, relatedBy: .Equal, toItem: view,
            attribute: .LeftMargin, multiplier: 1.0,
            constant: 0)
        let hc2 = NSLayoutConstraint(item: cityLabel, attribute: .RightMargin, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: 0)
        let vc = NSLayoutConstraint(item: cityLabel, attribute: .TopMargin, relatedBy: .Equal, toItem: view, attribute: .TopMargin, multiplier: 1.0, constant: 64)
        
        
        tempLabel.textAlignment = .Center
        tempLabel.textColor = UIColor.whiteColor()
        tempLabel.font = UIFont(name: "BrandonText-Bold", size: 120)
        tempLabel.layer.zPosition = 1
        tempLabel.frame.size = CGSizeMake(view.frame.width, 100)
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        tempLabel.alpha = 0
        
        let hConstraints1 = NSLayoutConstraint(item: self.tempLabel, attribute:
            .LeftMargin, relatedBy: .Equal, toItem: view, attribute: .LeftMargin, multiplier: 1.0, constant: 0)
        let hConstraints2 = NSLayoutConstraint(item: self.tempLabel, attribute: .RightMargin, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: 0)
        let vConstraints1 = NSLayoutConstraint(item: self.tempLabel, attribute: .Top, relatedBy: .Equal, toItem: cityLabel, attribute: .Top, multiplier: 1.0, constant: 20)
        
        
        
        
        
        
        // Temp Graph
        self.tempGraph = BEMSimpleLineGraphView()
        tempGraph.delegate = self
        tempGraph.dataSource = self
        tempGraph.enableBezierCurve = true
        tempGraph.autoScaleYAxis = true
        tempGraph.frame.size = CGSizeMake(view.frame.width, 150)
        tempGraph.frame.origin = CGPointMake(0, 84)
        tempGraph.backgroundColor = UIColor.clearColor()
        tempGraph.widthLine = 4.0
        tempGraph.colorLine = UIColor.whiteColor()
        tempGraph.colorTop = UIColor.whiteColor()
        tempGraph.colorBottom = UIColor.whiteColor()
        tempGraph.alphaTop = 0.0
        tempGraph.alphaBottom = 0.05
        tempGraph.gradientLineDirection = .Vertical
        tempGraph.animationGraphStyle = .Draw
        tempGraph.animationGraphEntranceTime = 12.0
        tempGraph.displayDotsWhileAnimating = false
        tempGraph.enableYAxisLabel = true
        tempGraph.alpha = 0
        tempGraph.colorBackgroundYaxis = UIColor.clearColor()
        tempGraph.colorYaxisLabel = UIColor.whiteColor()
        tempGraph.labelFont = UIFont(name: "BrandonText-Light", size: 11)
        
        
        /*
        // Gradient
        let context = UIGraphicsGetCurrentContext()
        
        let colors = [UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor, UIColor.clearColor().CGColor]
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [1.0, 0.0]
        
        let gradient = CGGradientCreateWithColors(colorSpace,
            colors,
            colorLocations)
        
        tempGraph.gradientBottom = CGGradientCreateWithColorComponents(colorSpace, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0], colorLocations, 2)!
        */
        
        
        let hcTG1 = NSLayoutConstraint(item: self.tempGraph, attribute:
            .LeftMargin, relatedBy: .Equal, toItem: view, attribute: .LeftMargin, multiplier: 1.0, constant: 0)
        let hcTG2 = NSLayoutConstraint(item: self.tempGraph, attribute: .RightMargin, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: 0)
        let vcTG = NSLayoutConstraint(item: self.tempGraph, attribute: .Top, relatedBy: .Equal, toItem: cityLabel, attribute: .Top, multiplier: 1.0, constant: 20)
        
        
        
        
        conditionLabel.frame.size = CGSizeMake(view.frame.width, 37)
        conditionLabel.translatesAutoresizingMaskIntoConstraints = false
        conditionLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        conditionLabel.font = UIFont(name: "BrandonText-Bold", size: 35)
        conditionLabel.textAlignment = .Center
        conditionLabel.layer.zPosition = 1
        conditionLabel.alpha = 0
        
        
        let hc3 = NSLayoutConstraint(item: self.conditionLabel, attribute:
            .LeftMargin, relatedBy: .Equal, toItem: view,
            attribute: .LeftMargin, multiplier: 1.0,
            constant: 0)
        let hc4 = NSLayoutConstraint(item: self.conditionLabel, attribute: .RightMargin, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: 0)
        let vc1 = NSLayoutConstraint(item: self.conditionLabel, attribute: .Top, relatedBy: .Equal, toItem: self.tempLabel, attribute: .Bottom, multiplier: 1.0, constant: -20)
        
        
        
        
        // Buttons for forecast videos
        
        self.forecastTypeButton = UIButton()
        self.tempUnitsButton = UIButton()
        
        for (idx, btn) in [forecastTypeButton, tempUnitsButton].enumerate() {
            
            // Set Text Color based on user's ForecastType selection
            
            if Weather.forecastType == "hourly" {
                self.forecastTypeButton.setTitle("48 HOURS", forState: .Normal)
            } else {
                self.forecastTypeButton.setTitle("7 DAYS", forState: .Normal)
            }
            
            if Weather.tempUnits == "F" {
                self.tempUnitsButton.setTitle("F\u{00B0}", forState: .Normal)
            } else {
                self.tempUnitsButton.setTitle("C\u{00B0}", forState: .Normal)
            }
            
            btn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            btn.frame.size = CGSizeMake(view.frame.width / 2 - 15 - 15/2, 45)
            btn.translatesAutoresizingMaskIntoConstraints = false
            
            if idx == 0 {
                btn.addTarget(self, action: #selector(WeatherViewController.toggleForecastType(_:)), forControlEvents: .TouchUpInside)
            } else {
                btn.addTarget(self, action: #selector(WeatherViewController.toggleTempUnits(_:)), forControlEvents: .TouchUpInside)
            }
            
            btn.titleLabel!.font = UIFont(name: "BrandonText-Bold", size: 18)
            btn.backgroundColor = UIColor.clearColor()
            btn.layer.zPosition = 10
            btn.alpha = 0
        }
        
        for item in [forecastTypeButton, tempUnitsButton] {
            self.view.addSubview(item)
            item.fadeIn()
        }
        
        
        
        // Auto Layout for buttons
        let vcHF = NSLayoutConstraint(item: self.forecastTypeButton, attribute: .BottomMargin, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1.0, constant: -30)
        let vcDF = NSLayoutConstraint(item: self.tempUnitsButton, attribute: .BottomMargin, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1.0, constant: -30)
        
        let hcHF = NSLayoutConstraint(item: self.forecastTypeButton, attribute: .LeftMargin, relatedBy: .GreaterThanOrEqual, toItem: view, attribute: .LeftMargin, multiplier: 1.0, constant: 45)
        let hcDF = NSLayoutConstraint(item: self.tempUnitsButton, attribute: .RightMargin, relatedBy: .LessThanOrEqual, toItem: view, attribute: .RightMargin, multiplier: 1.0, constant: -45)
        //let hcDF2 = NSLayoutConstraint(item: self.forecastTypeButton, attribute: .Right, relatedBy: .LessThanOrEqual, toItem: self.tempUnitsButton, attribute: .Left, multiplier: 1.0, constant: 110)2
        
        NSLayoutConstraint.activateConstraints([vcHF, vcDF, hcHF, hcDF])
        

        
        
        
        
        for item in [navBar, cityLabel, conditionLabel, tempLabel, tempGraph] {
            self.view.addSubview(item)
        }
        
        
        
        // AutoLayout
        NSLayoutConstraint.activateConstraints([hc1, hc2, vc, hConstraints1, hConstraints2, vConstraints1, hcTG1, hcTG2, vcTG, hc3, hc4, vc1])
        
        
        
        
        
        // Show tutorial to onboard User
        if !Weather.isUserOnboarded() {
            NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(WeatherViewController.showTutorial), userInfo: nil, repeats: false)
        }
        
        

    }
    
    override func viewDidAppear(animated: Bool) {
        playCurrentWeatherVideo()
    }
    
    override func viewDidDisappear(animated: Bool) {
        pauseCurrentWeatherVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    // Play / pause Current Weather Video
    func playCurrentWeatherVideo() {
        if (self.currentWeatherPlayer != nil) {
            self.currentWeatherPlayer.play()
        }
    }
    func pauseCurrentWeatherVideo() {
        if (self.currentWeatherPlayer != nil) {
            self.currentWeatherPlayer.pause()
        }
    }
    
    
    
    // MARK: Gesture Handlers - Long Press & Second Finger Tap
    
    func longPressHandler(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .Began {
            
            self.playForecastVideo()
            
        } else if gesture.state == .Ended || gesture.state == .Cancelled {
            
            self.stopForecastVideo()
            
        }
        
    }
    
    
    
    
    
    
    
    
    // MARK: Permissions
    
    func triggerLocationServices() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    
    // MARK: CoreLocation Delegate - iOS 8+
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.startUpdatingLocation()
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .Restricted, .Denied:
            requestPermissionChangeInSettings()
        }
    }
    
    func requestPermissionChangeInSettings() {
        
        let alertController = UIAlertController(
            title: "Location Access Disabled",
            message: "To get forecasts for your location, please enable Skycast in Settings. We fetch data only when you're using the app!",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    // MARK: CoreLocation - Updates
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alert = UIAlertController(title: "Couldn't Find Location", message: "Please try again!", preferredStyle: .Alert)
        
        let action = UIAlertAction(title:"Okay", style: .Default, handler: nil)
        alert.addAction(action)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.locationNeedsUpdate {
            reverseGeocode(locations[locations.count - 1])
        }
    }
    
    func reverseGeocode(location: CLLocation) {
        
        // Set location once
        self.locationNeedsUpdate = false
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            if let placemarks = placemarks {
                
                
                // Stop Updating Location to save battery
                self.locationManager.stopUpdatingLocation()
                
                
                
                let placemark = placemarks[0]
                
                
                self.city = City(latitude: (placemark.location?.coordinate.latitude)!, longitude: (placemark.location?.coordinate.longitude)!)
                
                
                // Unwrap optionals
                
                if let name = placemark.locality {
                    
                    self.city.name = name
                    
                    // update UI
                    self.cityLabel.text = self.city.name
                    
                }
                
                if let state = placemark.administrativeArea {
                    self.city.state = state
                }
                
                if let country = placemark.country {
                    self.city.country = country
                }
                
                
                
                self.cityLabel.setNeedsDisplay()
                
                
                
            } else {
                
                let alert = UIAlertController(title: "Couldn't Find Your Location", message: "Please try again later.", preferredStyle: .Alert)
                self.presentViewController(alert, animated: true, completion: nil)
                
            }
        }
        
    }

    
    
    
        
    
    
    
    
    // MARK: - Asynchronous updating of UI
    
    func updateWeather() {
        
        // Init data if exists
        if let city = self.city {
            
            
            // ForecastIO API Key
            let forecastIOClient = APIClient(apiKey: "0a821ac78b5c0f2e8e78535f0e21d9b5")
            
            // Temp Units
            forecastIOClient.units = Weather.tempUnits == "F" ? Units.US : Units.SI
            
            
            // Handle API Call
            forecastIOClient.getForecast(latitude: city.latitude, longitude: city.longitude, completion: { (forecast, error) -> Void in
                if let forecast = forecast {
                    
                    let forecastWrapper = ForecastWrapper(forecast: forecast)
                    
                    // Set as city forecast
                    self.city.forecast = forecastWrapper
                    
                    
                    
                    // Hourly Temp Graph
                    if let hourlyTemp = forecastWrapper.forecast.hourly?.data {
                        
                        // Reduce and set the hourly temperatures
                        for i in 0..<hourlyTemp.count {
                            
                            // Fewer data points to smooth out the graph
                            if i % 4 == 0 {
                                self.hourlyTemp.append(hourlyTemp[i].temperature!)
                            }
                        }
                        
                        
                    }
                    
                    // Daily Temp Graph
                    if let dailyTemp = forecastWrapper.forecast.daily?.data {
                        
                        // Reduce and set the daily temperatures
                        for i in 0..<dailyTemp.count {
                            
                            // "temperature" property is always nil.
                            // get avg of temperatureMin and temperatureMax
                            
                            let avgTemp = (dailyTemp[i].temperatureMin! + dailyTemp[i].temperatureMax!) / 2
                            
                            self.dailyTemp.append(avgTemp)
                        }
                        
                    }
                    
                    
                    
                    
                    
                    // Update Current Info
                    
                    if let currentForecast = forecastWrapper.forecast.currently {
                        
                        
                        if let icon = currentForecast.icon {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.createCurrentVideo(icon.rawValue)
                            }
                        }
                        
                        if let conditions = currentForecast.summary {
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                // Store current conditions for when restoring CurrentWeather view
                                // after a forecast video
                                self.currentConditions = conditions
                                
                                // Set conditions now
                                self.conditionLabel.text = conditions
                                
                                // Tell View to redraw view
                                self.conditionLabel.setNeedsDisplay()
                                
                                // Fade in the text
                                self.conditionLabel.fadeIn()
                            }
                            
                        }
                        
                        if let temp = currentForecast.temperature {
                            
                            self.currentTemp = temp
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tempLabel.text = "\(Int(self.currentTemp))\u{00B0}"
                                self.conditionLabel.setNeedsDisplay()
                                self.tempLabel.fadeIn()
                            }
                            
                        }
                        
                    }
                    
                    
                    
                    
                    // Populate lists of video clips
                    self.populateForecastLists("hourly", forecastData: forecastWrapper.summarizedHourly)
                    self.populateForecastLists("daily", forecastData: forecastWrapper.summarizedDaily)
                    

                    
                } else if let _ = error {
                    
                    let alert = UIAlertController(title: "Couldn't find forecasts!", message: "There was an error in fetching forecasts. Please try again soon!", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Okay", style: .Default, handler: nil)
                    alert.addAction(action)
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
            })
            
            
            
        }

        
    }
    
    
    
    
    // MARK: BEMSimpleLineGraphDataSource
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return Weather.forecastType == "hourly" ? self.hourlyTemp.count : self.dailyTemp.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        let data = Weather.forecastType == "hourly" ? self.hourlyTemp : self.dailyTemp
        let temp = !data.isEmpty ? data[index] : 0
        return CGFloat(round(temp))
        
    }
    
    // MARK: BEMSimpleLineGraphDelegate
    
    
    
    
    
    // MARK: Create Forecast Videos
    
    private func createCurrentVideo(forecast: String) {
        
        let filePath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(forecast, ofType: "mp4")!)
        let playerItem = AVPlayerItem(URL: filePath)
        
        // For Looping - notify of playerItem's end
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WeatherViewController.playerItemDidReachEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        
        
        // Set up Player for Current Weather
        self.currentWeatherPlayer = AVPlayer(playerItem: playerItem)
        self.currentWeatherPlayer.actionAtItemEnd = .None
        
        
        // Set up Player inside View's SubLayer
        let layer = AVPlayerLayer(player: self.currentWeatherPlayer)
        layer.frame = self.view.frame
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        layer.backgroundColor = UIColor.darkGrayColor().CGColor
        layer.zPosition = -10
        
        self.view.layer.addSublayer(layer)
        
        
        self.currentWeatherPlayer.play()
        
    }
    
    
    
    // Populate and hold onto lists of conditions & duration
    // [("partly-cloudy-day", 2.6), ("clear-day", 3.0)]
    
    private func populateForecastLists(forecastType: String, forecastData: [(String, Int)]) {
        
        for (condition, duration) in forecastData {
            
            
            // Number of Data Points - 49 for Hourly, 7 for
            let numberOfDataPoints:Double = forecastType == "hourly" ? 49 : 8
            
            
            // Adjust length of clip to its share of 12 sec
            let weightedDuration = Double(duration) / numberOfDataPoints * 12
            

            
            if forecastType == "hourly" {
                
                // For timing the skip of videos
                self.hourlySummary.append((condition, weightedDuration))
                
                
            } else {
                
                self.dailySummary.append((condition, weightedDuration))
                
            }
        }
        
    }
    
    
    
    // MARK: Play Videos
    
    func playForecastVideo() {
        
        // Pause the CurrentWeatherPlayer
        self.currentWeatherPlayer.pause()
        
        // Set up AVPlayer
        self.setUpPlayer()
        
        // Play the player
        self.videoStopped = false
        self.forecastPlayer!.play()
        
        // Skip the video at the right times
        self.timeForecastVideos()
        
        // Show time
        self.startTimeLapse()
        
        // Hide/Disable Buttons
        self.toggleCurrentForecastButtons()
        
        // Hide nav bar
        self.navBar.fadeOut()
        
        
    }
    
    private func setUpPlayer() {
        
        
        // Create video queues
        
        var playerItems = [AVPlayerItem]()
        
        
        
        // Queue up the videos
        
        for (condition, _) in (Weather.forecastType == "hourly" ? self.hourlySummary : self.dailySummary) {
            
            
            // Find the video clip named corresponding to the weather condition
            
            let filePath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(condition, ofType: "mp4")!)
            let playerItem = AVPlayerItem(URL: filePath)
            
            
            //  video clips
            playerItems.append(playerItem)
            
        }

        
        // Create Player
        
        if self.forecastPlayer != nil {
            self.forecastPlayer = nil
        }
        
        self.forecastPlayer = AVQueuePlayer(items: playerItems)
        self.forecastPlayer!.actionAtItemEnd = .None
        
        self.forecastLayer = AVPlayerLayer(player: self.forecastPlayer)
        forecastLayer.frame = self.view.frame
        forecastLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        forecastLayer.backgroundColor = UIColor.darkGrayColor().CGColor
        forecastLayer.zPosition = -5
        
        self.view.layer.addSublayer(forecastLayer)
        
    }
    
    
    // Index for iterating through hourly-/daily- summaries as videos play
    var idx = 0
    
    func timeForecastVideos() {
        
        // For each duration, play video for that long, then skip
        // [4.0, 2.67, 1.56, 5.45]
        // ---> Now converted to tuples [("snow", 4.0),...]
        
        if idx < (Weather.forecastType == "hourly" ? self.hourlySummary.count : self.dailySummary.count) {
            
            let condition : String = Weather.forecastType == "hourly" ? self.hourlySummary[idx].0 : self.dailySummary[idx].0
            let timeInterval : Double = Weather.forecastType == "hourly" ? self.hourlySummary[idx].1 : self.dailySummary[idx].1
            
            // Skip to the next condition
            self.skipTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(WeatherViewController.skipToNext), userInfo: nil, repeats: false)
            
            // Change the text
            // Icon name's raw value mapped to a human-friendly Weather Condition
            // e.g. partly-cloudy-day --> Partly Cloudy
            self.conditionLabel.text = Weather.categories[condition]
            self.conditionLabel.setNeedsDisplay()
            
        } else {
            
            // End of video reached
            self.stopForecastVideo()
            
        }
        
    }
    
    func skipToNext() {
        
        // Skip the Video
        self.forecastPlayer!.advanceToNextItem()
        
        
        // Rinse & repeat
        self.idx += 1
        self.timeForecastVideos()
        
    }
    
    
    
    
    
    // MARK: Stop Videos
    
    
    
    func stopForecastVideo() {
        
        
        // stopVideo() msg can be sent from releasing Long Press or from video expiring.
        // In case video expires before releasing LP, check if video's already been stopped.
        
        if !videoStopped {
            
            // Toggle bool
            videoStopped = !videoStopped
            
            // Stop/Hide the time label
            self.stopTimeLapse()
            
            // Stop the video transitions
            self.skipTimer?.invalidate()
            self.skipTimer = nil
            
            // Reset video skip list to beginning
            self.idx = 0
            
            // Pause the video
            self.forecastPlayer!.pause()
            
            // Remove all items
            self.forecastPlayer!.removeAllItems()
            
            // Dealloc Player
            self.forecastPlayer = nil
            
            
            // Remove items from view
            self.forecastLayer.removeFromSuperlayer()
            
            // Show the buttons again
            self.toggleCurrentForecastButtons()
            
            // Show nav bar
            self.navBar.fadeIn()
            
            // Restore Conditions Text to Current
            self.conditionLabel.text = self.currentConditions
            
            // Continue playing Current Weather Video
            self.currentWeatherPlayer.play()
            
            
        }
        
    }
    
    
    func playerItemDidReachEnd(notification: NSNotification) {
        self.currentWeatherPlayer.seekToTime(kCMTimeZero)
    }
    
        
    
    
    
    
    
    // MARK: Time Lapse Label
    
    func startTimeLapse() {
        
        // Create, add, updateUI, then fade in
        self.timeLabel = UILabel()
        timeLabel!.frame = CGRectMake(0, 284, self.view.frame.width, 25)
        timeLabel!.font = UIFont(name: "BrandonText-Bold", size: 22)
        timeLabel!.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        timeLabel!.textAlignment = .Center
        timeLabel!.layer.zPosition = 1
        timeLabel!.alpha = 0
        self.view.addSubview(self.timeLabel!)
        
        self.updateTimer()
        self.timeLabel?.fadeIn()
        
        // Loop the skip timer
        // Daily Updates will span 1.5 sec per day
        let timeInterval:Double = Weather.forecastType == "hourly" ? 1.0 : 1.5
        
        self.textTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(WeatherViewController.updateTimer), userInfo: nil, repeats: true)
        
    }
    
    var timeLapseCounter:Double = 0
    
    func updateTimer() {
        
        
        // Hourly Update
        // Progress 4 hours per second - 48 hours in 12 sec
        // 60 sec * 60 min * 4 hrs
        
        
        // Daily Update
        // Progress  - 8 days in 12 sec
        // One day per transition, each transition will span 1.5 sec
        
        
        let timeInterval: Double = Weather.forecastType == "hourly" ? 60 * 60 * 4 : 60 * 60 * 24
        let transitionCount: Double = Weather.forecastType == "hourly" ? 12 : 8
        
        let datetime = NSDate().dateByAddingTimeInterval(timeInterval * timeLapseCounter)
        
        self.formatTime(datetime)
        
        if timeLapseCounter == transitionCount {
            
            // Reached the end
            self.timeLapseCounter = 0
            
        } else {
            
            timeLapseCounter += 1
            
        }
        
        
    }
    
    func formatTime(date: NSDate) {
        
        
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let thisDate = calendar.components(.Hour, fromDate: date)
        
        
        // Date - "Today" or "Tomorrow" or "Day After Tomorrow"
        
        var dateText = ""
        
        if calendar.isDateInToday(date) {
            dateText = "Today"
        } else if calendar.isDateInTomorrow(date) {
            dateText = "Tomorrow"
        } else {
            dateText = "Day After Tomorrow"
        }
        
        
        if Weather.forecastType == "hourly" {
            
            // Hour - AM / PM
            let amPm = (thisDate.hour >= 12) ? "PM" : "AM"
            var hour = 12
            
            if thisDate.hour > 0 {
                hour = (thisDate.hour > 12) ? thisDate.hour % 12 : thisDate.hour
            }
            
            
            dateFormatter.timeStyle = .MediumStyle
            self.timeLabel?.text = "\(dateText)  \(hour) \(amPm)"

            
        } else {
            
            if dateText == "Day After Tomorrow" {
                
                dateFormatter.dateFormat = "E MMM d"
                dateText = dateFormatter.stringFromDate(date)
                
            }
            
            self.timeLabel?.text = dateText
        }
        
    }
    
    func stopTimeLapse() {
        
        // Stop Timer
        self.textTimer?.invalidate()
        self.textTimer = nil
        
        // Reset counter
        self.timeLapseCounter = 0
        
        // Hide text
        self.timeLabel?.fadeOut()
        self.timeLabel = nil
        
    }
    
    
    
    
    
    // MARK: Toggle Forecast Type
    
    func toggleForecastType(sender: UIButton) {
        
        if Weather.forecastType == "hourly" {
            
            Weather.setForecastType("daily")
            
            // Update button UI - change text to 7 day-forecast
            self.forecastTypeButton.setTitle("7 DAYS", forState: .Normal)
            
            
        } else if Weather.forecastType == "daily" {
            
            Weather.setForecastType("hourly")
            
            
            // Update button UI - change text to 7 day-forecast
            self.forecastTypeButton.setTitle("48 HOURS", forState: .Normal)
            
            
        }
        
    }
    
    // MARK: Toggle Temp Units
    
    func toggleTempUnits(sender: UIButton) {
        
        Weather.toggleTempUnit()
        
        let tempUnit = Weather.tempUnits
        
        // Update button UI - change text to Celsius
        self.tempUnitsButton.setTitle("\(tempUnit)\u{00B0}", forState: .Normal)
        
        
        // Current temp
        self.currentTemp = Weather.convertTemp(self.currentTemp, toUnit: tempUnit)
        
        // Update CurrentTemp Label
        self.tempLabel.text = "\(Int(self.currentTemp))\u{00B0}"
        
        
        // Forecast temps
        for (idx, t) in hourlyTemp.enumerate() {
            hourlyTemp[idx] = Weather.convertTemp(t, toUnit: tempUnit)
        }
        
        for (idx, t) in dailyTemp.enumerate() {
            dailyTemp[idx] = Weather.convertTemp(t, toUnit: tempUnit)
        }
        
        
    }
    
    
    // MARK: Toggle UI during Forecast Video
    
    var currentForecastElementsHidden = false
    
    func toggleCurrentForecastButtons() {
        
        if currentForecastElementsHidden {
            
            currentForecastElementsHidden = !currentForecastElementsHidden
            
            self.forecastTypeButton.fadeIn()
            self.tempUnitsButton.fadeIn()
            
            // Toggle Temp Label/Graph
            self.tempGraph.fadeOut()
            self.tempLabel.fadeIn()
            
        } else {
            
            currentForecastElementsHidden = !currentForecastElementsHidden
            
            self.forecastTypeButton.fadeOut()
            self.tempUnitsButton.fadeOut()
            
            // Reload graph
            self.tempGraph.reloadGraph()
            
            
            // Toggle Temp Label/Graph
            self.tempLabel.fadeOut()
            self.tempGraph.fadeIn()
            
        }
        
    }
    
    

    
    
    // Onboard / Tutorial 
    
    func showTutorial() {
        
        if self.tutorialView == nil {
            
            
            // Create overlay view
            self.tutorialView = UIView()
            tutorialView.frame = self.view.frame
            tutorialView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.9)
            tutorialView.layer.zPosition = 10
            tutorialView.alpha = 0
            
            
        }
        
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(WeatherViewController.hideTutorial))
        tutorialView.addGestureRecognizer(tapGesture)
        
        
        
        // Create subviews
        
        let tintColor = UIColor(red:0.98, green:0.89, blue:0.67, alpha:1) //UIColor.whiteColor()
        
        let holdIcon = UIImageView()
        holdIcon.image = UIImage(named: "longpress")?.imageWithRenderingMode(.AlwaysTemplate)
        holdIcon.tintColor = tintColor
        holdIcon.frame.size = CGSizeMake(40, 50)
        holdIcon.center = CGPointMake(tutorialView.frame.width / 2, tutorialView.frame.height / 2 - 45)
        
        let holdInstructions = UILabel()
        holdInstructions.text = "Press and hold anywhere to watch the forecast!"
        holdInstructions.font = UIFont(name: "BrandonText-Bold", size: 16)
        holdInstructions.textColor = tintColor
        holdInstructions.textAlignment = .Center
        holdInstructions.frame.size = CGSizeMake(view.frame.width - 30, 60)
        holdInstructions.center = CGPointMake(tutorialView.frame.width / 2, tutorialView.frame.height / 2)
        holdInstructions.numberOfLines = 2
        
        
        // Button Explanations
        let otherInstructions = UILabel()
        otherInstructions.text = "Tap below to toggle forecast type and units"
        otherInstructions.font = UIFont(name: "BrandonText-Bold", size: 14)
        otherInstructions.textColor = tintColor
        otherInstructions.textAlignment = .Center
        otherInstructions.frame.size = CGSizeMake(view.frame.width - 30, 60)
        otherInstructions.center = CGPointMake(tutorialView.frame.width / 2, tutorialView.frame.height - 100)
        otherInstructions.numberOfLines = 1
        
        let leftArrow = UIImageView(image: UIImage(named:"down-arrow")?.imageWithRenderingMode(.AlwaysTemplate))
        leftArrow.tintColor = tintColor
        leftArrow.frame = CGRectMake(80, tutorialView.frame.height - 80, 20, 12)
        
        let rightArrow = UIImageView(image: UIImage(named:"down-arrow")?.imageWithRenderingMode(.AlwaysTemplate))
        rightArrow.tintColor = tintColor
        rightArrow.frame = CGRectMake(tutorialView.frame.width - 80 - 20, tutorialView.frame.height - 80, 20, 12)
        
        
        for item in [holdIcon, holdInstructions, otherInstructions, leftArrow, rightArrow] {
            tutorialView.addSubview(item)
        }
        

        
        
        // Fade in
        self.view.addSubview(tutorialView)
        
        tutorialView.fadeIn()
        
        
    }
    
    func hideTutorial() {
        
        // User Onboarded?
        if !Weather.isUserOnboarded() {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "userOnboarded")
        }
        
        // Remove all subviews
        for item in self.tutorialView.subviews {
            item.removeFromSuperview()
        }
        
        self.tutorialView.fadeOut(0.2, delay: 0) { f in
            self.tutorialView.removeFromSuperview()
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    // Orientation Change Handler
    
    
    func orientationDidChange(orientation: UIDeviceOrientation) {
        
        
        // Video
        for layer in self.view.layer.sublayers! {
            if layer.isKindOfClass(AVPlayerLayer) {
                layer.frame = self.view.frame
            }
        }
        
        // Nav Bar
        self.navBar.frame.size = CGSizeMake(self.view.frame.width, 44)
        
        // Graph
        self.tempGraph.frame.size = CGSizeMake(self.view.frame.width, 150)
        
        // TutorialView
        if self.tutorialView != nil {
            self.tutorialView.frame = self.view.frame
            self.tutorialView.setNeedsDisplay()
        }
        
        
        
        self.view.setNeedsDisplay()
        
    }
    
    

    
    
    
    

    /*
    // MARK: - Navigation
*/
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
