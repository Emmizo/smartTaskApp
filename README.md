# smart_task_app 
 Step to run project

 Step 1: Install Prerequisites

Before running the project, ensure you have the necessary tools installed:

1. Install Flutter SDK

Download and install Flutter from and quidance are there:
🔗 https://flutter.dev/docs/get-started/install

After installation, verify it by running:
flutter --version

2. Install Dependencies
	•	Android Studio (for Android development & emulator)
	•	Xcode (for iOS development on macOS)
	•	VS Code (optional, but recommended)
	•	Git (to clone the project) from this https://github.com/Emmizo/smartTaskApp.git 

 3.   Clone from GitHub

Run the following command in your terminal or command prompt:  
git clone https://github.com/Emmizo/smartTaskApp.git

4. Navigate to the Project Directory
cd smartTaskApp

5. Install Dependencies Get Flutter Packages
run flutter pub get
Check for Missing Dependencies

Ensure everything is properly set up: flutter doctor

note: If any issues appear, follow the provided instructions to fix them.

6.  Run the Project

8 Connect a Device or Emulator
	•	If using a real device, enable USB debugging on Android or developer mode on iOS.
	•	If using an emulator:
	•	Android: Open Android Studio → AVD Manager → Launch Emulator.
	•	iOS: Open Xcode → open -a Simulator.

Check if the device is recognized:
Run the App

For Android/iOS: flutter run
For a specific platform (Android or iOS):flutter run -d <device_id>