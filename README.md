# fla_custom
This project will help you quickly customize your own app (lock Url)

## Please note that this project is still in preview testing state, please do not use it in a production environment.

### How to start?
0. Deploy flutter environment: https://flutter.dev/docs/get-started/install
1. clone this project
2. Set your website link in `fla_custom/bin/main.dart:21`  
3. For Android, please set your appID (package name) in `fla_custom/android/app/build.gradle`,Set the package name in `manifest> application> android:label in `fla_custom/android/app/src/main/AndroidManifest.xml`.
4. For ios, please set the package name in the `fla_custom/ios/Runner/Info.plist ``CFBundlePackageType` node and the application name in the `CFBundleName` node.
5. build And run. (For ios, you must compile on macOS.)
6. For customized desktop icons and packaged release applications, please refer to: https://flutter.dev/docs/deployment/android https://flutter.dev/docs/deployment/ios