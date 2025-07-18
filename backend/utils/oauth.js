const { OAuth2Client } = require('google-auth-library');
const appleSignin = require('apple-signin-auth');

// Initialize Google OAuth client
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * Verify Google ID token
 * @param {string} idToken - Google ID token from client
 * @returns {Object} - User information from Google
 */
const verifyGoogleToken = async (idToken) => {
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    
    return {
      id: payload.sub,
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
      email_verified: payload.email_verified,
      provider: 'google'
    };
  } catch (error) {
    console.error('Google token verification failed:', error);
    throw new Error('Invalid Google token');
  }
};

/**
 * Verify Apple ID token
 * @param {string} idToken - Apple ID token from client
 * @param {string} nonce - Nonce used in the request (optional)
 * @returns {Object} - User information from Apple
 */
const verifyAppleToken = async (idToken, nonce = null) => {
  try {
    const appleResponse = await appleSignin.verifyIdToken(idToken, {
      audience: process.env.APPLE_CLIENT_ID,
      nonce: nonce,
      ignoreExpiration: false,
    });

    return {
      id: appleResponse.sub,
      email: appleResponse.email,
      name: appleResponse.name || null,
      email_verified: appleResponse.email_verified === 'true',
      provider: 'apple'
    };
  } catch (error) {
    console.error('Apple token verification failed:', error);
    throw new Error('Invalid Apple token');
  }
};

/**
 * Extract provider and user info from OAuth token
 * @param {string} provider - OAuth provider ('google' or 'apple')
 * @param {string} idToken - ID token from the provider
 * @param {string} nonce - Nonce for Apple (optional)
 * @returns {Object} - Standardized user information
 */
const verifyOAuthToken = async (provider, idToken, nonce = null) => {
  switch (provider.toLowerCase()) {
    case 'google':
      return await verifyGoogleToken(idToken);
    case 'apple':
      return await verifyAppleToken(idToken, nonce);
    default:
      throw new Error(`Unsupported OAuth provider: ${provider}`);
  }
};

/**
 * Create user metadata for Supabase from OAuth provider data
 * @param {Object} oauthUser - User data from OAuth provider
 * @returns {Object} - Formatted user metadata
 */
const createUserMetadata = (oauthUser) => {
  return {
    provider: oauthUser.provider,
    provider_id: oauthUser.id,
    full_name: oauthUser.name,
    avatar_url: oauthUser.picture || null,
    email_verified: oauthUser.email_verified,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };
};

module.exports = {
  verifyGoogleToken,
  verifyAppleToken,
  verifyOAuthToken,
  createUserMetadata
};