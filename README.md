# Skycast
Weather meets Giphy


## What It Is
Skycast is a beautiful iOS app that turns weather data into summary videos.
Sometimes we don't care what the numbers are. We just want to know if it's going to get colder, or if it's going to rain soon. This is a nifty app for the video-centric millennial or busy professional who just want the basics in a beautiful interface.

## What It Does
Skycast takes location data from your smartphone and fetches corresponding weather data (current, and 48-hour/7-day forecasts). AVQueuePlayer plays a 12-second video that is spliced together from clips of weather footages that summarize the conditions of the next 48 hours. The script reduces "noise": weather conditions that only last an hour are disregarded.


## Libraries Used:
* [Forecastio Client](https://github.com/sxg/ForecastIO) for [Forecast.io](http://forecast.io)
* [BEMSimpleLineGraph](https://github.com/Boris-Em/BEMSimpleLineGraph)
* CoreLocation, AVFoundation, AutoLayout, NSUserDefaults
* Cocoapods

### Future Features / Room for Improvement
* Support for multiple cities - UIPageViewController, search, Google Maps API
* Time-based footage selection (e.g. Clear[Day] v. Clear[Night])
* Location-based footage selection (e.g. Clear day in Dubai v. clear day in Siberia)
* Convert to GIFs
