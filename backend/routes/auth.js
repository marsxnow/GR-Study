const express = require('express');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { verifyOAuthToken, createUserMetadata } = require('../utils/oauth');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/auth/oauth
 * Authenticate user with Google or Apple OAuth
 */
router.post('/oauth', async (req, res) => {
  try {
    const { provider, idToken, nonce, userInfo } = req.body;

    // Validate required fields
    if (!provider || !idToken) {
      return res.status(400).json({
        status: 'error',
        message: 'Provider and idToken are required'
      });
    }

    // Verify the OAuth token
    let oauthUser;
    try {
      oauthUser = await verifyOAuthToken(provider, idToken, nonce);
    } catch (error) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid OAuth token',
        details: error.message
      });
    }

    // For Apple Sign In, if user info is provided on first sign-in
    if (provider === 'apple' && userInfo) {
      oauthUser.name = userInfo.name;
    }

    // Check if user already exists in Supabase
    const { data: existingUser, error: userError } = await supabaseAdmin.auth.admin
      .listUsers();

    if (userError) {
      console.error('Error checking existing users:', userError);
      return res.status(500).json({
        status: 'error',
        message: 'Database error'
      });
    }

    // Find user by email
    const user = existingUser.users.find(u => u.email === oauthUser.email);

    let authResult;

    if (user) {
      // User exists - sign them in
      const { data, error } = await supabase.auth.signInWithPassword({
        email: oauthUser.email,
        password: `oauth_${provider}_${oauthUser.id}` // Use provider-specific password
      });

      if (error) {
        // If password sign-in fails, create a new session
        const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.admin
          .generateLink({
            type: 'magiclink',
            email: oauthUser.email
          });

        if (sessionError) {
          console.error('Session creation error:', sessionError);
          return res.status(500).json({
            status: 'error',
            message: 'Failed to create user session'
          });
        }

        authResult = sessionData;
      } else {
        authResult = data;
      }
    } else {
      // User doesn't exist - create new user
      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email: oauthUser.email,
        password: `oauth_${provider}_${oauthUser.id}`,
        email_confirm: true,
        user_metadata: createUserMetadata(oauthUser)
      });

      if (error) {
        console.error('User creation error:', error);
        return res.status(500).json({
          status: 'error',
          message: 'Failed to create user account',
          details: error.message
        });
      }

      authResult = data;
    }

    // Generate session for the user
    const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.admin
      .generateLink({
        type: 'magiclink',
        email: oauthUser.email
      });

    if (sessionError) {
      console.error('Session generation error:', sessionError);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to generate session'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Authentication successful',
      data: {
        user: {
          id: authResult.user?.id,
          email: oauthUser.email,
          name: oauthUser.name,
          provider: provider,
          email_verified: oauthUser.email_verified
        },
        session: sessionData,
        access_token: sessionData.properties?.access_token,
        refresh_token: sessionData.properties?.refresh_token
      }
    });

  } catch (error) {
    console.error('OAuth authentication error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Authentication failed',
      details: process.env.NODE_ENV !== 'production' ? error.message : undefined
    });
  }
});

/**
 * POST /api/auth/refresh
 * Refresh access token using refresh token
 */
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(400).json({
        status: 'error',
        message: 'Refresh token is required'
      });
    }

    const { data, error } = await supabase.auth.refreshSession({
      refresh_token
    });

    if (error) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid refresh token'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Token refreshed successfully',
      data: {
        access_token: data.session?.access_token,
        refresh_token: data.session?.refresh_token,
        expires_at: data.session?.expires_at,
        user: data.user
      }
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Token refresh failed'
    });
  }
});

/**
 * POST /api/auth/logout
 * Logout user and invalidate session
 */
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const { error } = await supabase.auth.signOut();

    if (error) {
      console.error('Logout error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Logout failed'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Logout failed'
    });
  }
});

/**
 * GET /api/auth/me
 * Get current user information
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    res.status(200).json({
      status: 'success',
      data: {
        user: req.user
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user information'
    });
  }
});

/**
 * DELETE /api/auth/account
 * Delete user account
 */
router.delete('/account', authenticateToken, async (req, res) => {
  try {
    const { error } = await supabaseAdmin.auth.admin.deleteUser(req.user.id);

    if (error) {
      console.error('Account deletion error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to delete account'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Account deleted successfully'
    });

  } catch (error) {
    console.error('Account deletion error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Account deletion failed'
    });
  }
});

module.exports = router;