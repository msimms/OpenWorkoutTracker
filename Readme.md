# Straen
Straen is an open source workout tracker. It was initially written as a bike computer, but it also supports numerous other activities. This includes strength exercises, such as pull-ups and push-ups, as well as aerobic sports like running.

## Rationale
Why develop a workout tracker when there are so many closed-source options available?
* The existing apps function poorly as bike computers, in my opinion. Using the phone as a bike computer makes a lot of sense, since dedicated bike computers are expensive and you probably have your phone with you anyway.
* Lack of support for strength-based exercises.
* I think users should have control over their own data and this is only possible with an open source application.

## Major Features
* Support for cycling, running, hiking, walking, pull-ups, push-ups (press-ups), 
* Customizable workout screens, very useful when using the application a bike computer.
* Support for Bluetooth LE sensors, including heart rate, cycling power, and cycling cadence.
* Optional ability to live broadcast to the companion server app (StraenWeb). Note that this is off by default, but is something I added so friends could track me during long cycling events.
* Integrates with Apple Health.

## Major Todos
- Unit Tests
- Ability to upload to services such as Strava, Garmin Connect, Training Peaks, Endomondo, Runkeeper, etc.
- Apple Watch Companion App
- Android Version

## Version History
Beta

## Tech
Straen uses one other source project to work properly:

* [core-plot] - A graph plotting framework for iOS

The app is written in a combination of Objective-C and C++ and targets the Apple iPhone.

## Social
Twitter: [@StraenApp](https://twitter.com/StraenApp)

## License
MPL 2.0 (Mozilla Public License)
