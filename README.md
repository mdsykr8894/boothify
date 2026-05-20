# Boothify

Boothify is a Flutter-based exhibition booth booking and management application.

It allows organizers to create exhibitions, manage booth packages, design floor plan layouts, and review exhibitor applications. Exhibitors can explore published exhibitions, view booth packages, select booth spots from an interactive floor plan, and submit booth applications.

## Features

### Admin / Organizer

- Create, edit, publish, and unpublish exhibitions
- Open or close booking availability
- Manage booth packages
- Create and edit floor plan layouts
- Add, edit, and delete booth spots
- View exhibition and application summaries
- Approve, reject, and manage exhibitor applications

### Exhibitor

- Browse published exhibitions
- View exhibition details and booth packages
- Check booking availability status
- Select booth spots from an interactive matrix floor plan
- Submit booth applications
- Track application status
- Make payment after approval

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Provider state management
- go_router navigation

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

Organizers can create exhibitions, edit event details, publish or unpublish exhibitions, and control booking availability.

### Booth Package Management

Organizers can create and manage booth packages, including booth size, price, and included amenities.

### Floor Plan Management

The floor plan uses a fixed matrix layout based on rows and columns. Booth spots are displayed using coordinate labels such as `A01`, `A02`, `B01`, and `B02`.

### Booth Selection

Exhibitors can view the same spatial booth layout created by the organizer. Booth statuses are color-coded for clarity, such as available, booked, and selected booth spots.

### Application Management

Exhibitors can submit booth applications. Organizers and admins can review, approve, reject, and manage applications.

## Getting Started

### Prerequisites

Make sure you have installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Firebase CLI
- FlutterFire CLI, if your Firebase setup uses it

Check Flutter installation:

```bash
flutter doctor
```

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/boothify.git
cd boothify
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

## Firebase Setup

This project uses Firebase Authentication and Cloud Firestore.

Firebase configuration files are not included in this repository for security reasons. Add your own Firebase configuration based on your local setup.

To configure Firebase using FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then run:

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

## Purpose

This project was developed as part of a Mobile and Ubiquitous Computing assignment. The purpose of Boothify is to provide a mobile platform for managing exhibition booth booking activities through multiple user roles.

Boothify focuses on helping organizers manage exhibitions, booth packages, floor plans, and exhibitor applications. It also allows exhibitors to browse published events, view booth availability, select booth spots from an interactive floor plan, and submit booth applications.

The project demonstrates the use of Flutter, Firebase, state management, routing, role-based access, and interactive UI design in a complete mobile application workflow.
