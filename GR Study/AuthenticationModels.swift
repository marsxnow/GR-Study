//
//  AuthenticationModels.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI
import Foundation
import AuthenticationServices
import GoogleSignIn

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let profilePictureURL: String?
    let provider: String
    let emailVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, provider
        case profilePictureURL = "avatar_url"
        case emailVerified = "email_verified"
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let id: String
    let email: String
    var fullName: String?
    var avatarURL: String?
    var bio: String?
    var phone: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, bio, phone
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    let userId: String
    var notificationsEnabled: Bool
    var emailNotifications: Bool
    var pushNotifications: Bool
    var theme: String
    var language: String
    var privacyPublicProfile: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notificationsEnabled = "notifications_enabled"
        case emailNotifications = "email_notifications"
        case pushNotifications = "push_notifications"
        case theme, language
        case privacyPublicProfile = "privacy_public_profile"
    }
}

// MARK: - Session Info
struct SessionInfo: Codable, Identifiable {
    let id: String
    let createdAt: String
    let lastActive: String
    let ipAddress: String
    let userAgent: String
    let isCurrent: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case lastActive = "last_active"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
        case isCurrent = "is_current"
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let status: String
    let message: String
    let data: T?
    let timestamp: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct ProfileResponse: Codable {
    let profile: UserProfile
}

struct PreferencesResponse: Codable {
    let preferences: UserPreferences
}

struct SessionsResponse: Codable {
    let sessions: [SessionInfo]
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000/api"
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "access_token") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "refresh_token") }
    }
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        if let token = accessToken {
            Task {
                await getCurrentUser()
            }
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
                throw AuthError.noViewController
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.noIdToken
            }
            
            await authenticateWithBackend(provider: "google", idToken: idToken)
        } catch {
            errorMessage = "Google sign in failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Apple Sign In
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        do {
            let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
                let delegate = AppleSignInDelegate(continuation: continuation)
                controller.delegate = delegate
                controller.performRequests()
            }
            
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idTokenString = String(data: identityToken, encoding: .utf8) {
                
                await authenticateWithBackend(provider: "apple", idToken: idTokenString, userInfo: appleIDCredential.fullName)
            }
        } catch {
            errorMessage = "Apple sign in failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Backend Authentication
    private func authenticateWithBackend(provider: String, idToken: String, userInfo: PersonNameComponents? = nil) async {
        guard let url = URL(string: "\(baseURL)/auth/oauth") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "provider": provider,
            "idToken": idToken
        ]
        
        if let userInfo = userInfo, let givenName = userInfo.givenName, let familyName = userInfo.familyName {
            body["userInfo"] = [
                "name": "\(givenName) \(familyName)"
            ]
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(APIResponse<AuthResponse>.self, from: data)
                
                if let authData = authResponse.data {
                    self.accessToken = authData.accessToken
                    self.refreshToken = authData.refreshToken
                    self.currentUser = authData.user
                    self.isAuthenticated = true
                }
            } else {
                let errorResponse = try JSONDecoder().decode(APIResponse<String>.self, from: data)
                errorMessage = errorResponse.message
            }
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/auth/me") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let userResponse = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                if let user = userResponse.data {
                    currentUser = user
                    isAuthenticated = true
                }
            } else {
                // Token might be expired, try to refresh
                await refreshAccessToken()
            }
        } catch {
            print("Get current user failed: \(error)")
        }
    }
    
    // MARK: - Refresh Token
    func refreshAccessToken() async {
        guard let refreshToken = refreshToken,
              let url = URL(string: "\(baseURL)/auth/refresh") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(APIResponse<AuthResponse>.self, from: data)
                
                if let authData = authResponse.data {
                    self.accessToken = authData.accessToken
                    self.refreshToken = authData.refreshToken
                    self.currentUser = authData.user
                    self.isAuthenticated = true
                }
            } else {
                signOut()
            }
        } catch {
            signOut()
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
        
        Task {
            await performSignOut()
        }
    }
    
    private func performSignOut() async {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/auth/logout") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            print("Sign out request failed: \(error)")
        }
    }
}

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noViewController
    case noIdToken
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "No view controller available"
        case .noIdToken:
            return "No ID token received"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}