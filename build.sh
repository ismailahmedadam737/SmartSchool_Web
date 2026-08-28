#!/usr/bin/env bash
# Exit on error
set -o errexit

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor

# Build Flutter Web
flutter build web