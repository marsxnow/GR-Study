# Quick Setup Guide

This guide will help you get your Swift app backend up and running quickly.

## 🚀 Quick Start

### 1. Environment Setup (Required)

```bash
# Copy the example environment file
cp .env.example .env
```

Edit `.env` with your actual credentials:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Supabase Configuration (REQUIRED)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_min_32_chars

# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Apple Sign In Configuration
APPLE_CLIENT_ID=your.app.bundle.id
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_PRIVATE_KEY_PATH=./keys/apple_private_key.p8

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

### 2. Supabase Setup

1. **Create Project**: Go to [supabase.com](https://supabase.com) and create a new project
2. **Get Credentials**: Go to Settings > API to find your URL and keys
3. **Run SQL Migration**: Copy and paste the contents of `sql/001_initial_schema.sql` into your Supabase SQL editor and run it
4. **Configure Auth Providers**:
   - Go to Authentication > Settings
   - Enable Google and Apple providers
   - Add your OAuth credentials

### 3. Apple Private Key (Optional)

If using Apple Sign In:

```bash
# Create keys directory
mkdir keys

# Add your Apple private key file as apple_private_key.p8
# Download this from Apple Developer Portal
```

### 4. Start the Server

```bash
# Install dependencies (if not already done)
npm install

# Start development server
npm run dev
```

### 5. Test the API

Visit: `http://localhost:3000/health`

You should see:
```json
{
  "status": "success",
  "message": "Server is running",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "environment": "development"
}
```

## 🔧 Configuration Details

### Minimum Required Environment Variables

These are required for the server to start:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` 
- `SUPABASE_SERVICE_ROLE_KEY`

### OAuth Provider Setup

#### Google OAuth
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create/select project
3. Enable Google+ API or Google Sign-In API
4. Create OAuth 2.0 credentials
5. Add authorized origins and redirect URIs

#### Apple Sign In
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Create App ID with Sign In with Apple capability
3. Create Service ID
4. Generate private key
5. Configure domain and redirect URLs

## 📡 API Endpoints

Once running, your API will be available at:

### Authentication
- `POST /api/auth/oauth` - Google/Apple sign in
- `POST /api/auth/refresh` - Refresh tokens
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update profile
- `GET /api/user/preferences` - Get preferences
- `PUT /api/user/preferences` - Update preferences

### System
- `GET /health` - Health check

## 🔍 Troubleshooting

### Common Issues

1. **"Missing required environment variables"**
   - Make sure you've copied `.env.example` to `.env`
   - Fill in all required Supabase credentials

2. **"Supabase connection failed"**
   - Check your Supabase URL and keys
   - Ensure your Supabase project is active

3. **OAuth errors**
   - Verify your Google/Apple credentials
   - Check redirect URLs match your configuration

4. **Database errors**
   - Make sure you've run the SQL migration in Supabase
   - Check if RLS policies are properly set up

### Getting Help

1. Check the main [README.md](./README.md) for detailed documentation
2. Verify all environment variables are set correctly
3. Check Supabase dashboard for any configuration issues
4. Review the API documentation for correct request format

## ✅ Success Checklist

- [ ] Environment file created and configured
- [ ] Supabase project created and configured
- [ ] SQL migration run successfully
- [ ] Dependencies installed (`npm install`)
- [ ] Server starts without errors (`npm run dev`)
- [ ] Health check endpoint responds correctly
- [ ] OAuth providers configured (if using)

Once all items are checked, your backend is ready for your Swift app integration!