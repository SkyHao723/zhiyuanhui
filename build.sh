#!/bin/bash

echo "Starting Flutter build process..."

# 安装Flutter SDK
echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /opt/flutter
export PATH="/opt/flutter/bin:$PATH"

# 禁用 analytics
flutter config --no-analytics

# 获取依赖
echo "Getting dependencies..."
flutter pub get

# 构建Web版本，使用根路径作为base href
echo "Building web release..."
flutter build web --release --base-href="/"

echo "Build completed successfully!"