# GYM PRO — GitHub/Codemagic Ready

This repository contains a complete SwiftUI Xcode project structure.

## Upload to GitHub
1. Create a new GitHub repository named `GymPro`.
2. Upload **all contents of this folder**, including `GymPro.xcodeproj`.
3. In Codemagic, choose GitHub and select the repository.
4. Select the `GymPro.xcodeproj` project and the `GymPro` scheme.
5. Configure your Apple Developer signing credentials in Codemagic.
6. Start the iOS build.

## Important
The bundle identifier is currently `com.example.GymPro`. Change it to a unique reverse-domain identifier in your Apple Developer account/Codemagic signing configuration.

The app targets iOS 17+ and uses SwiftData.
