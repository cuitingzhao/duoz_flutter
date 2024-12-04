#!/bin/bash

# Kill any existing Flutter processes
pkill -f flutter
pkill -f dart

# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Run the app with a specific port
flutter run --observatory-port=8888
