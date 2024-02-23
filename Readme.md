![](https://travis-ci.org/msimms/Straen.svg?branch=master)

# OpenWorkoutTracker

OpenWorkoutTracker is a privacy-oriented, open source workout tracker. It was initially written as a bike computer, but now supports numerous other activity types. This includes strength exercises, such as pull-ups and push-ups, as well as aerobic sports like running, walking, and hiking.

## Rationale

Why develop a workout tracker when there are so many closed-source options available?
* The existing apps on the market function poorly as bike computers, in my opinion. I feel this is because the screens are not customizable, or are hard to read, and the screens won't stay on or prevent the phone from locking. Using the phone as a bike computer makes a lot of sense, since dedicated bike computers are expensive and you probably have your phone with you anyway.
* Some people don't want to buy a dedicated bike computer when they already take a phone with them on their rides.
* Lack of support for strength-based exercises.
* Other applications require you to create an account to use the application at all. Though there are certainly some advantages to using a cloud service, it should not be required.
* Users should have control over their own data and this is only possible with an open source application.
* A belief that the "cloud" should be optional.
* As a platform for future ideas and experiments.

## Major Features

* Support for cycling, running, hiking, walking, pull-ups, push-ups (press-ups), etc.
* Customizable workout screens, very useful when using the application a bike computer.
* Support for Bluetooth LE sensors, including heart rate, cycling power, and cycling cadence.
* Support for the Garmin Varia bicycle radar.
* Integrates with Apple Health.
* Can export data to the iCloud Drive.
* Apple Watch Companion app.
* Optional ability to live broadcast to the companion server app (OpenWorkoutWeb). Note that this is off by default, but is something I added so friends could track me during long cycling events.

## Major Todos

* Unit Tests
* Ability to upload to services such as Strava, Training Peaks, Runkeeper, etc.
* Android Version

## User Documentation

The User Documentation is stored [on this wiki page](https://github.com/msimms/OpenWorkoutTracker/wiki). There you will be able to find an explanation on how to use the app.

<p align="center">
<img src="https://github.com/msimms/OpenWorkoutTracker/blob/master/Docs/Images/cycling.png?raw=true" alt="Cycling Screen" width=256/>
</p>

## Architecture

The software architecture uses a model-view philosophy. The view is separate from the model and enables porting the application to different platforms without the need to rewrite everything.

As much as possible, the model layer is written in C/C++. This is so it can be compiled for a variety of platforms and be called from almost any other programming language. For example, the iOS and Watch OS apps utilize SwiftUI for the view layer and call C functions for model functionality. Likewise, an Android app could be written in Java, all while retaining the same backend (i.e. model) code.

![Architecture Diagram](https://github.com/msimms/OpenWorkoutTracker/blob/master/Docs/Architecture/Architecture.png?raw=true)

## Building

This app is built using Apple XCode. Every attempt is made to stay up-to-date with the latest version of XCode and the latest versions of iOS and watchOS. In theory, if you have cloned the source code and initialized the submodules, then you should be able to open the project in XCode, build, and deploy.
```
git clone https://github.com/msimms/OpenWorkoutTracker
cd OpenWorkoutTracker
git submodule update --init --recursive
```

Open `OpenWorkoutTracker-Swift.xcodeproj` with XCode and build.

## Version History

2019-06-13 Version 1.0.0 - Initial Release

## Tech

This app uses these source projects to work properly:

* <s>[core-plot](https://github.com/core-plot/core-plot) - A graph plotting framework for iOS (historical, used by the old, Objective C front end).</s>
* [LibBluetooth](https://github.com/msimms/LibBluetooth) - Cross-platform Bluetooth library.
* [LibMath](https://github.com/msimms/LibMath) - A collection of math utilities.
* [PeakFinder](https://github.com/msimms/PeakFinder) - A peak finding algorithm.
* [SimpleSwiftCharts](https://github.com/msimms/SimpleSwiftCharts) - Charts and graphs code for SwiftUI.
* [sqlite](https://www.sqlite.org) - Database for storing activities.

The app is written in a combination of Swift/SwiftUI (though previously used Objective-C) as well as C/C++ and targets the Apple iPhone and Apple Watch.

## License

MPL 2.0 (Mozilla Public License) - There are no restrictions for non-commercial use (i.e. personal or academic). Commercial use of the code in this repository is prohibited by the MPL 2.0 license; however, I still posses the original, unlicensed version of the repository, for whatever that is worth.
