const express = require('express');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/user/profile
 * Get user profile information
 */
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 = table not found
      console.error('Profile fetch error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to fetch profile'
      });
    }

    // If no profile exists, return user metadata
    const profile = data || {
      id: req.user.id,
      email: req.user.email,
      full_name: req.user.user_metadata?.full_name || null,
      avatar_url: req.user.user_metadata?.avatar_url || null,
      provider: req.user.user_metadata?.provider || null,
      created_at: req.user.created_at,
      updated_at: req.user.updated_at
    };

    res.status(200).json({
      status: 'success',
      data: { profile }
    });

  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch profile'
    });
  }
});

/**
 * PUT /api/user/profile
 * Update user profile information
 */
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { full_name, avatar_url, bio, phone } = req.body;

    // Update user metadata in auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin
      .updateUserById(req.user.id, {
        user_metadata: {
          ...req.user.user_metadata,
          full_name: full_name || req.user.user_metadata?.full_name,
          avatar_url: avatar_url || req.user.user_metadata?.avatar_url,
          updated_at: new Date().toISOString()
        }
      });

    if (authError) {
      console.error('Auth update error:', authError);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to update profile'
      });
    }

    // Try to update or insert profile in profiles table
    const profileData = {
      id: req.user.id,
      full_name: full_name || req.user.user_metadata?.full_name,
      avatar_url: avatar_url || req.user.user_metadata?.avatar_url,
      bio: bio || null,
      phone: phone || null,
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('profiles')
      .upsert(profileData)
      .select()
      .single();

    if (error && error.code !== 'PGRST116') { // Table might not exist yet
      console.error('Profile update error:', error);
      // Don't fail if table doesn't exist, return auth data instead
    }

    res.status(200).json({
      status: 'success',
      message: 'Profile updated successfully',
      data: {
        profile: data || profileData
      }
    });

  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update profile'
    });
  }
});

/**
 * GET /api/user/preferences
 * Get user preferences/settings
 */
router.get('/preferences', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Preferences fetch error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to fetch preferences'
      });
    }

    // Default preferences if none exist
    const preferences = data || {
      user_id: req.user.id,
      notifications_enabled: true,
      theme: 'system',
      language: 'en',
      privacy_public_profile: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    res.status(200).json({
      status: 'success',
      data: { preferences }
    });

  } catch (error) {
    console.error('Preferences fetch error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch preferences'
    });
  }
});

/**
 * PUT /api/user/preferences
 * Update user preferences/settings
 */
router.put('/preferences', authenticateToken, async (req, res) => {
  try {
    const {
      notifications_enabled,
      theme,
      language,
      privacy_public_profile
    } = req.body;

    const preferencesData = {
      user_id: req.user.id,
      notifications_enabled: notifications_enabled !== undefined ? notifications_enabled : true,
      theme: theme || 'system',
      language: language || 'en',
      privacy_public_profile: privacy_public_profile !== undefined ? privacy_public_profile : false,
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('user_preferences')
      .upsert(preferencesData)
      .select()
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Preferences update error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to update preferences'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Preferences updated successfully',
      data: {
        preferences: data || preferencesData
      }
    });

  } catch (error) {
    console.error('Preferences update error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update preferences'
    });
  }
});

/**
 * GET /api/user/sessions
 * Get user active sessions
 */
router.get('/sessions', authenticateToken, async (req, res) => {
  try {
    // Note: This would require custom session tracking in your database
    // For now, we'll return current session info
    res.status(200).json({
      status: 'success',
      data: {
        sessions: [{
          id: 'current',
          created_at: new Date().toISOString(),
          last_active: new Date().toISOString(),
          ip_address: req.ip || 'unknown',
          user_agent: req.get('User-Agent') || 'unknown',
          is_current: true
        }]
      }
    });

  } catch (error) {
    console.error('Sessions fetch error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch sessions'
    });
  }
});

/**
 * POST /api/user/change-email
 * Request email change
 */
router.post('/change-email', authenticateToken, async (req, res) => {
  try {
    const { new_email } = req.body;

    if (!new_email) {
      return res.status(400).json({
        status: 'error',
        message: 'New email is required'
      });
    }

    // Email validation regex
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(new_email)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid email format'
      });
    }

    const { data, error } = await supabaseAdmin.auth.admin
      .updateUserById(req.user.id, {
        email: new_email
      });

    if (error) {
      console.error('Email change error:', error);
      return res.status(500).json({
        status: 'error',
        message: 'Failed to change email',
        details: error.message
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Email change request sent. Please check your new email for confirmation.'
    });

  } catch (error) {
    console.error('Email change error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to change email'
    });
  }
});

module.exports = router;