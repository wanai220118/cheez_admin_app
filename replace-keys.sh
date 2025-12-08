#!/bin/bash
# Script to replace API keys in firebase_options.dart

if [ -f lib/firebase_options.dart ]; then
    sed -i.bak "s/AIzaSyBJBVtw6tQ0rliQm2ayeWifCr5-RxQ5Jvw/REMOVED_API_KEY_1/g" lib/firebase_options.dart
    sed -i.bak "s/AIzaSyDpBFwuBCEhE3HzVq-59B5Pi36adQ2kNVg/REMOVED_API_KEY_2/g" lib/firebase_options.dart
    rm -f lib/firebase_options.dart.bak
fi

