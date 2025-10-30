#!/bin/bash

# 安装Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /opt/flutter
export PATH="/opt/flutter/bin:$PATH"

# 禁用 analytics
flutter config --no-analytics

# 获取依赖
flutter pub get

# 构建Web版本
flutter build web --release --base-href="/zhiyuanhui/"

# 复制构建产物到Vercel的输出目录
cp -r build/web/* /vercel/output/static/