![](https://travis-ci.org/msimms/Straen.svg?branch=master)

# OpenWorkoutTracker
OpenWorkoutTracker is a privacy-oriented, open source workout tracker. It was initially written as a bike computer, but it also supports numerous other activity types. This includes strength exercises, such as pull-ups and push-ups, as well as aerobic sports like running, walking, and hiking.

## Rationale
Why develop a workout tracker when there are so many closed-source options available?
* The existing apps on the market function poorly as bike computers, in my opinion. I feel this is because the screens are not customizable, or are hard to read, and the screens won't stay on or prevent the phone from locking.  Using the phone as a bike computer makes a lot of sense, since dedicated bike computers are expensive and you probably have your phone with you anyway.
* Lack of support for strength-based exercises.
* Other applications require you to create an account to use the application at all.
* Users should have control over their own data and this is only possible with an open source application.
* The network should be optional. It should be possible to use the app without sending any data to the cloud.

## Major Features
* Support for cycling, running, hiking, walking, pull-ups, push-ups (press-ups), etc.
* Customizable workout screens, very useful when using the application a bike computer.
* Support for Bluetooth LE sensors, including heart rate, cycling power, and cycling cadence.
* Optional ability to live broadcast to the companion server app (OpenWorkoutWeb). Note that this is off by default, but is something I added so friends could track me during long cycling events.
* Integrates with Apple Health.
* Can export data to the iCloud Drive.
* Apple Watch Companion App.

## Major Todos
* Unit Tests
* Ability to upload to services such as Strava, Training Peaks, Runkeeper, etc.
* Android Version

## User Documentation

The User Documentation is stored [on this wiki page](https://github.com/msimms/OpenWorkoutTracker/wiki). There you will be able to find an explanation on how to use the app.

<p align="center">
<img src="https://mikesimms.net/straen_images/Cycling.jpg" alt="Cycling Screen" width=256/>
</p>

## Architecture

The software architecture uses a model-view-controller philosophy. Keeping the view separate from the model allows porting the application to different platforms without the need to rewrite everything.

As much as possible, the view layer is written in C/C++. This is because it can be compiled for any hardware platform and can also be called from almost any other programming language. For example, the iOS and watchOS apps utilize Objective-C for their view and controller layers and call into C for model functionality. In the future, the iOS and watch OS view and controller classes could be re-written in Swift. Likewise, an Android app could be written in Java, all while retaining the same backend (i.e. model) code.

![Architecture Diagram](https://github.com/msimms/OpenWorkoutTracker/blob/master/Docs/Architecture.png?raw=true)

## Building
This app is built using Apple XCode. Every attempt is made to stay up-to-date with the latest version of XCode and the latest version of iOS. In theory, if you have cloned the source code and initialized the submodules, then you should be able to open the project in XCode, build, and deploy.
```
git clone https://github.com/msimms/OpenWorkoutTracker
cd OpenWorkoutTracker
git submodule update --init --recursive
```

## Version History
2019-06-13 Version 1.0.0 - Initial Release

## Tech
This app uses three other source projects to work properly:

* [core-plot](https://github.com/core-plot/core-plot) - A graph plotting framework for iOS.
* [LibMath](https://github.com/msimms/LibMath) - A collection of math utilities, including a peak finding algorithm.
* [sqlite](https://www.sqlite.org) - Database for storing activities.

The app is written in a combination of Objective-C and C++ and targets the Apple iPhone and Apple Watch.

## Social
Twitter: [@StraenApp](https://twitter.com/StraenApp)

## License
MPL 2.0 (Mozilla Public License) - There are no restrictions for non-commercial use (i.e. personal or academic). Commercial use of the code in this repository is prohibited by the MPL 2.0 license; however, I still posses the original, unlicensed version of the repository, for whatever that is worth.
