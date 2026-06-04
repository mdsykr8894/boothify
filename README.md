# Boothify

Boothify is a Flutter-based exhibition booth booking and management application.

It allows administrators to manage the platform, organizers to manage exhibition details and booth packages, and exhibitors to browse published exhibitions, select booth spots, submit booth applications, and track their application status.

## Features

### Guest

- Browse published exhibitions without logging in
- View exhibition details
- View a read-only booth floor plan
- Receive login/register guidance before making a booth application

### Exhibitor

- Register and log in as an exhibitor
- Browse and search published exhibitions
- View exhibition details and booth packages
- Select booth spots from an interactive matrix floor plan
- View booth availability using color-coded booth statuses
- Submit booth applications with company details, product details, add-ons, and participation dates
- Track application status
- Edit pending or rejected applications where allowed
- Cancel applications where allowed
- Make simulated payment after approval
- Receive in-app notifications for application and payment updates

### Organizer

- Create and manage their own exhibition events
- Edit exhibition details while the exhibition is still unpublished
- Manage booth packages, including size, price, and amenities
- Manage booth spots and floor layout for their own exhibitions
- Open or close booking availability
- View exhibition and application summaries
- Review exhibitor applications
- Approve or reject applications with reasons
- Receive in-app notifications for application updates
- Delete own exhibitions safely with related booth package and booth spot cleanup

Organizers manage their own exhibition information, booth packages, and booth spots. Administrators control platform-level moderation such as publication status, user management, and overall application management.

### Admin

- View and manage all exhibitions
- Publish or unpublish exhibitions
- Manage all users
- Activate or deactivate user accounts
- View and manage all applications
- Edit application details when required
- Monitor overall platform data
- Receive in-app notifications for new user registrations, new exhibitions, and platform activity

## Core Technical Highlights

- Basic search and filter functions
- Role-based routing for Guest, Exhibitor, Organizer, and Admin
- Firebase Authentication for user login and registration
- Cloud Firestore as the main database
- Firebase Storage for exhibition images
- Provider state management
- GoRouter navigation and route guards
- Interactive booth floor plan using a matrix layout
- Firestore transaction-based booth application submission
- Double-booking prevention using Firestore transactions
- Competitor adjacency validation to prevent similar business types from booking adjacent booths
- Participation date selection within the exhibition date range
- Safe exhibition deletion with related booth package and booth spot cleanup
- Published exhibition edit lock to prevent editing public event details directly
- Lifecycle-safe data loading after app restart or Firebase session restore
- Simulated payment flow after application approval
- In-app notification system with read and mark-all-as-read support

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- GoRouter
- Cached Network Image
- Flutter SVG
- Image Picker
- Intl
- Flutter Native Splash
- Flutter Launcher Icons

## Project Structure

```text
lib/
├── app/
│   ├── routes/
│   └── theme/
├── core/
│   ├── constants/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── models/
│   └── services/
├── features/
│   ├── admin/
│   ├── auth/
│   ├── exhibitor/
│   ├── organizer/
│   └── shared/
└── providers/
```

## Main Modules

### Exhibition Management

Organizers can create exhibitions and manage their own event details while the event is still unpublished. Administrators have global access to all exhibitions and control publication status.

Published exhibitions are locked from direct editing. To modify public exhibition details, the administrator must unpublish the event first.

### Booth Package Management

Organizers can create and manage booth packages for their own exhibitions. Booth packages include booth size, price, and included amenities.

Administrators can also manage booth packages at the system level.

### Floor Plan Management

Boothify uses an interactive matrix-based floor plan. Organizers can manage booth spots and floor layout for their own exhibitions, while administrators maintain platform-level access and moderation.

Booth spots are displayed using coordinate labels such as:

```text
A01, A02, B01, B02
```

This digital layout is used for booth selection, booth status display, and competitor adjacency validation.

### Booth Selection

Exhibitors can view the spatial booth layout and select available booth spots.

Booth statuses are color-coded for clarity:

- Available
- Pending
- Booked
- Selected

### Application Management

Exhibitors can submit booth applications. Organizers and admins can review, approve, reject, edit, and manage applications based on their role permissions.

### Competitor Adjacency Rule

The system checks nearby booth spots during application submission. If an exhibitor tries to book a booth beside another active application from the same business type, the submission is blocked.

This helps prevent direct competitors from being placed next to each other.

### Participation Date Management

Exhibitors can select participation start and end dates during application submission. The selected dates must stay within the exhibition duration.

These dates are used for organizer and admin reference only. Booth package pricing remains fixed for the full exhibition package.

### Payment Simulation

After an application is approved, exhibitors can perform a simulated payment. The system stores payment information such as payment method, payment date, and transaction ID.

### Notification Management

Boothify includes an in-app notification system. Users can receive notifications for important activities such as new registrations, exhibition updates, application submissions, approval or rejection results, withdrawn applications, resubmitted applications, and payment completion.

Notifications can be marked as read individually or all at once.

## Database Overview

Boothify uses Firebase Cloud Firestore as the main database.

The logical database can be described as `exhibition_booth_management`, with the following main collections:

- `users`
- `exhibitions`
- `booth_packages`
- `booth_spots`
- `applications`
- `notifications`

These collections act as logical database tables for the application.

## Getting Started

### Prerequisites

Make sure the following tools are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Node.js and npm
- Firebase CLI
- FlutterFire CLI
- A Firebase account

Check Flutter installation:

```bash
flutter doctor
```

Check Node.js and npm installation:

```bash
node --version
npm --version
```

## Installation

Clone the repository:

```bash
git clone https://github.com/mdsykr8894/boothify.git
cd boothify
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

## Firebase Setup

This project uses Firebase Authentication, Cloud Firestore, and Firebase Storage.

Firebase configuration files are not included in this repository for security reasons. You need to connect the project to your own Firebase project before running the app fully.

### Step 1: Create a Firebase Project

1. Open Firebase Console in your browser.
2. Create a new Firebase project.
3. Use a suitable project name, for example:

```text
boothify
```

4. Disable Google Analytics if it is not required.
5. Wait until the Firebase project is created.

### Step 2: Install Firebase CLI

Install Firebase CLI globally using npm:

```bash
npm install -g firebase-tools
```

Check the installation:

```bash
firebase --version
```

### Step 3: Login to Firebase

Login to your Firebase account:

```bash
firebase login
```

A browser window will open. Sign in using the Google account connected to your Firebase project.

To verify that Firebase CLI can access your account, run:

```bash
firebase projects:list
```

You should see your Firebase projects listed in the terminal.

### Step 4: Install FlutterFire CLI

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Make sure the Dart pub global bin path is available in your terminal.

For macOS or Linux, add this to your shell profile if needed:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

For Windows, add this path to your environment variables if needed:

```text
%USERPROFILE%\AppData\Local\Pub\Cache\bin
```

Check FlutterFire CLI:

```bash
flutterfire --version
```

### Step 5: Configure Firebase for Flutter

From the project root folder, run:

```bash
flutterfire configure
```

Select your Firebase project and choose the platforms you want to configure, such as Android, iOS, or Web.

This command generates Firebase configuration files such as:

```text
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

The exact files depend on the selected platforms.

### Step 6: Enable Firebase Authentication

In Firebase Console:

1. Open your Firebase project.
2. Go to Authentication.
3. Open the Sign-in method tab.
4. Enable Email/Password sign-in.
5. Save the changes.

Boothify uses email and password login for Admin, Organizer, and Exhibitor accounts.

### Step 7: Create Cloud Firestore Database

In Firebase Console:

1. Go to Firestore Database.
2. Click Create database.
3. Choose a suitable location.
4. Start in test mode for local development, or configure your own security rules.
5. Create the database.

The app uses Firestore collections such as:

```text
users
exhibitions
booth_packages
booth_spots
applications
notifications
```

### Step 8: Enable Firebase Storage

In Firebase Console:

1. Go to Storage.
2. Click Get started.
3. Choose a suitable location.
4. Configure rules based on your development or production needs.

Firebase Storage is used for exhibition images.

### Step 9: Run the App

After Firebase is configured, run:

```bash
flutter pub get
flutter run
```

## Development Commands

Run static analysis:

```bash
flutter analyze
```

Run the app:

```bash
flutter run
```

Clean build files:

```bash
flutter clean
flutter pub get
```

## Recommended Test Flow

After setup, test the following flow:

1. Register or log in as an Admin.
2. Create organizer and exhibitor accounts.
3. Log in as Organizer and create an exhibition.
4. Add booth packages.
5. Configure booth spots and floor layout.
6. Publish the exhibition as Admin.
7. Log in as Exhibitor.
8. Browse the published exhibition.
9. Select a booth and submit an application.
10. Log in as Organizer and approve or reject the application.
11. Log in as Exhibitor and check the application status.
12. Make payment after approval.
13. Check notification updates for each related role.
14. Log in as Admin and verify users, exhibitions, and applications.

## Notes

- Firebase configuration files are not committed for security reasons.
- You must configure your own Firebase project before running the app fully.
- Some Firebase rules may need to be adjusted depending on your testing environment.
- Boothify currently uses in-app notifications stored in Firestore. Full push notification support can be added as a future enhancement.
- The floor plan uses an interactive matrix layout rather than a static uploaded image map.
- Booth packages are stored in the `booth_packages` collection.
- Booth spots are stored in the `booth_spots` collection and reference booth packages using `boothPackageId`.
- Organizers can manage their own exhibition information, booth packages, and booth spots.
- Administrators control publication status, user management, and platform-level application management.
- Published exhibitions are read-only until they are unpublished by an administrator.

## Purpose

The purpose of Boothify is to provide a mobile platform for managing exhibition booth booking activities through multiple user roles.

Boothify helps administrators manage the platform, organizers manage exhibition operations, and exhibitors submit booth applications through an interactive booth selection flow.

The project demonstrates the use of Flutter, Firebase, state management, routing, role-based access control, Firestore database design, transaction-based validation, notification handling, and interactive UI design in a complete mobile application workflow.
