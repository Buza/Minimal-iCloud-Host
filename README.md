Minimal-iCloud-Host
=========

This is a simple example project that demonstrates how to properly open and save UIDocument-based data to iCloud.

Summary
-----------

Adding iCloud support for your iOS5+ app isn't as straightforward as I had initially anticipated. Most of the documentation and examples found online are incomplete, inconsistent, or incorrect. I wrote this simple project to demonstrate and document the proper steps needed to create an app using UIDocument subclasses that saves and updates files stored in iCloud. To keep things simple, this project just performs the creation and saving functionality. See the
Minimal-iCloud-Client project for an example of how to build an app that reads these documents stored in iCloud and responds to notifications about document changes.   


Note that you'll need to run this on an acutal device, not the simulator. To do this, you'll need to configure iCloud in the iOS Developer Center. For a good overview of how to set this up for an app, [visit this link](http://www.raywenderlich.com/6015/beginning-icloud-in-ios-5-tutorial-part-1)

