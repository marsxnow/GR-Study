# iOS App Setup Instructions

## Required Dependencies

To add the necessary authentication dependencies to your iOS project, follow these steps:

### 1. Add Swift Package Dependencies

In Xcode:

1. **File → Add Package Dependencies**
2. Add the following packages:

#### Google Sign-In
- URL: `https://github.com/google/GoogleSignIn-iOS`
- Version: Latest stable (6.0+)

#### Supabase Swift (Optional)
- URL: `https://github.com/supabase/supabase-swift`
- Version: Latest stable (2.0+)

### 2. Configure Google Sign-In

1. **Download GoogleService-Info.plist**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create/select your project
   - Add iOS app with your bundle identifier
   - Download `GoogleService-Info.plist`
   - Add it to your Xcode project

2. **Configure URL Schemes**:
   - In Xcode, go to your target's Info tab
   - Under URL Types, add a new URL scheme
   - Use the REVERSED_CLIENT_ID from GoogleService-Info.plist

3. **Add Google Sign-In configuration to your App delegate or main App struct**:

```swift
import GoogleSignIn

// In your App struct or AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let config = GIDConfiguration(path: path) else {
        return false
    }
    GIDSignIn.sharedInstance.configuration = config
    return true
}
```

### 3. Configure Apple Sign-In

1. **Enable in Apple Developer Portal**:
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Select your App ID
   - Enable "Sign In with Apple" capability

2. **Add Capability in Xcode**:
   - Select your target
   - Go to "Signing & Capabilities"
   - Click "+" and add "Sign In with Apple"

### 4. Update Info.plist

Add the following to your Info.plist:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to update profile picture</string>

<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take profile pictures</string>
```

### 5. Network Security (for localhost backend)

If testing with localhost backend, add to Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 6. Backend URL Configuration

Update the `baseURL` in `AuthenticationModels.swift` to point to your backend:

```swift
private let baseURL = "https://your-backend-domain.com/api"
// or for local testing:
// private let baseURL = "http://localhost:3000/api"
```

## File Structure

Your project should now include:

- `AuthenticationModels.swift` - Authentication models and manager
- `SignInView.swift` - Sign-in screen
- `ProfileView.swift` - User profile screen
- `ProfileManager.swift` - Profile data management
- `ProfilePictureView.swift` - Reusable profile picture component
- `ContentView.swift` - Updated main view with authentication

## Backend Setup

Make sure your backend is running:

1. Navigate to the `backend` directory
2. Copy `.env.example` to `.env` and configure
3. Install dependencies: `npm install`
4. Start the server: `npm run dev`

## Testing

1. Build and run the app
2. You should see the sign-in screen
3. Test Google and Apple sign-in
4. Check that the profile picture appears in the navigation bar
5. Tap the profile picture to access the profile screen

## Troubleshooting

### Common Issues:

1. **"No bundle URL present" error**: Make sure GoogleService-Info.plist is added to your project
2. **Sign-in fails**: Check that your OAuth credentials are correctly configured
3. **Network errors**: Ensure your backend is running and accessible
4. **Profile picture not loading**: Check image URLs and network permissions

### Debug Steps:

1. Check Xcode console for error messages
2. Verify backend is running on correct port
3. Test API endpoints with Postman/curl
4. Check OAuth provider configurations