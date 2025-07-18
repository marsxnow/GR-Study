# Swift App Backend

A Node.js/Express backend API that integrates with Supabase for authentication using Google and Apple Sign-In, designed specifically for Swift iOS applications.

## Features

- 🔐 **OAuth Authentication**: Google and Apple Sign-In integration
- 🛡️ **Supabase Integration**: User management and database operations
- 🔒 **Security**: JWT tokens, rate limiting, CORS protection, helmet middleware
- 👤 **User Management**: Profile management, preferences, session tracking
- 📊 **Database**: PostgreSQL with Row Level Security (RLS)
- 🚀 **Production Ready**: Error handling, logging, environment configuration

## Tech Stack

- **Backend**: Node.js, Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth, Google OAuth, Apple Sign-In
- **Security**: Helmet, CORS, Rate Limiting, JWT
- **Environment**: dotenv for configuration

## Prerequisites

- Node.js 18+ 
- Supabase account and project
- Google OAuth credentials
- Apple Developer account and Sign-In configuration

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Setup

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Update `.env` with your credentials:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# JWT Configuration
JWT_SECRET=your_jwt_secret_key

# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Apple Sign In Configuration
APPLE_CLIENT_ID=your_apple_client_id
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_PRIVATE_KEY_PATH=./keys/apple_private_key.p8

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

### 3. Database Setup

Run the SQL migration in your Supabase SQL editor:

```bash
# Copy the contents of sql/001_initial_schema.sql and run it in Supabase
```

### 4. Apple Private Key

Create a `keys` directory and add your Apple private key:

```bash
mkdir keys
# Add your Apple private key file as apple_private_key.p8
```

### 5. Start the Server

```bash
# Development mode
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:3000`

## API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication

#### OAuth Sign In
```http
POST /api/auth/oauth
Content-Type: application/json

{
  "provider": "google|apple",
  "idToken": "oauth_id_token",
  "nonce": "optional_nonce_for_apple",
  "userInfo": {
    "name": "User Name" // For Apple first sign-in
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Authentication successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "User Name",
      "provider": "google",
      "email_verified": true
    },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "your_refresh_token"
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer your_access_token
```

#### Logout
```http
POST /api/auth/logout
Authorization: Bearer your_access_token
```

### User Management

#### Get Profile
```http
GET /api/user/profile
Authorization: Bearer your_access_token
```

#### Update Profile
```http
PUT /api/user/profile
Authorization: Bearer your_access_token
Content-Type: application/json

{
  "full_name": "Updated Name",
  "avatar_url": "https://example.com/avatar.jpg",
  "bio": "User bio",
  "phone": "+1234567890"
}
```

#### Get Preferences
```http
GET /api/user/preferences
Authorization: Bearer your_access_token
```

#### Update Preferences
```http
PUT /api/user/preferences
Authorization: Bearer your_access_token
Content-Type: application/json

{
  "notifications_enabled": true,
  "theme": "dark",
  "language": "en",
  "privacy_public_profile": false
}
```

## Supabase Configuration

### 1. Create Supabase Project

1. Go to [Supabase](https://supabase.com)
2. Create a new project
3. Note down your project URL and keys

### 2. Configure Authentication

In your Supabase dashboard:

1. Go to **Authentication > Settings**
2. Configure **Google** provider:
   - Enable Google provider
   - Add your Google OAuth client ID and secret
   
3. Configure **Apple** provider:
   - Enable Apple provider
   - Add your Apple configuration

### 3. Run Database Migration

Copy and run the SQL from `sql/001_initial_schema.sql` in your Supabase SQL editor.

## OAuth Setup

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add your domain to authorized origins
6. Copy client ID and secret to your `.env`

### Apple Sign In Setup

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Create an App ID with Sign In with Apple capability
3. Create a Service ID for web authentication
4. Generate a private key for Sign In with Apple
5. Configure your domain and redirect URLs
6. Download the private key and save as `keys/apple_private_key.p8`

## Swift iOS Integration

### Installation

Add the Supabase Swift client to your iOS project:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### Configuration

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "your_supabase_url")!,
    supabaseKey: "your_supabase_anon_key"
)
```

### Google Sign In

```swift
import GoogleSignIn

// Configure Google Sign In
guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else { return }
guard let config = GIDConfiguration(path: path) else { return }
GIDSignIn.sharedInstance.configuration = config

// Sign in
GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
    guard let user = result?.user,
          let idToken = user.idToken?.tokenString else { return }
    
    // Send to your backend
    authenticateWithBackend(provider: "google", idToken: idToken)
}
```

### Apple Sign In

```swift
import AuthenticationServices

class SignInViewController: UIViewController, ASAuthorizationControllerDelegate {
    
    func setupAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let identityToken = appleIDCredential.identityToken,
           let idTokenString = String(data: identityToken, encoding: .utf8) {
            
            // Send to your backend
            authenticateWithBackend(provider: "apple", idToken: idTokenString)
        }
    }
}
```

### Backend Communication

```swift
func authenticateWithBackend(provider: String, idToken: String) {
    let url = URL(string: "http://localhost:3000/api/auth/oauth")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = [
        "provider": provider,
        "idToken": idToken
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response
            if let data = data {
                // Parse authentication response
                // Store access token for future requests
            }
        }.resume()
    } catch {
        print("Error: \(error)")
    }
}
```

## Security Features

- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS Protection**: Configurable allowed origins
- **Helmet Security**: Various security headers
- **JWT Validation**: Secure token verification
- **Input Validation**: Request body validation
- **RLS (Row Level Security)**: Database-level security
- **Environment Isolation**: Secure configuration management

## Error Handling

The API returns consistent error responses:

```json
{
  "status": "error",
  "message": "Error description",
  "details": "Additional details (development only)"
}
```

Common HTTP status codes:
- `200`: Success
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (missing/invalid token)
- `403`: Forbidden (insufficient permissions)
- `429`: Too Many Requests (rate limit exceeded)
- `500`: Internal Server Error

## Development

### Scripts

```bash
npm start          # Start production server
npm run dev        # Start development server with nodemon
npm test          # Run tests (when implemented)
```

### Project Structure

```
backend/
├── config/           # Configuration files
│   └── supabase.js  # Supabase client setup
├── middleware/       # Express middleware
│   └── auth.js      # Authentication middleware
├── routes/          # API routes
│   ├── auth.js      # Authentication routes
│   └── user.js      # User management routes
├── sql/             # Database migrations
│   └── 001_initial_schema.sql
├── utils/           # Utility functions
│   └── oauth.js     # OAuth verification utilities
├── keys/            # Private keys (gitignored)
├── .env.example     # Environment template
├── server.js        # Main application entry point
└── package.json     # Dependencies and scripts
```

## Deployment

### Environment Variables

Ensure all production environment variables are set:

- Set `NODE_ENV=production`
- Use strong `JWT_SECRET`
- Configure proper `ALLOWED_ORIGINS`
- Use production Supabase credentials

### Docker (Optional)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or issues:
1. Check the documentation
2. Search existing issues
3. Create a new issue with detailed information

## Changelog

### v1.0.0
- Initial release
- Google and Apple OAuth integration
- User profile management
- Supabase integration
- Security middleware
- Complete API documentation