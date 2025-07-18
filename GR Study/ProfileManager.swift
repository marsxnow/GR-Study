//
//  ProfileManager.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI
import Foundation

@MainActor
class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userPreferences: UserPreferences?
    @Published var sessions: [SessionInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000/api"
    private let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    private var accessToken: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }
    
    // MARK: - Profile Operations
    func fetchUserProfile() async {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/user/profile") else { return }
        
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let profileResponse = try JSONDecoder().decode(APIResponse<ProfileResponse>.self, from: data)
                userProfile = profileResponse.data?.profile
            } else {
                let errorResponse = try JSONDecoder().decode(APIResponse<String>.self, from: data)
                errorMessage = errorResponse.message
            }
        } catch {
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateUserProfile(fullName: String?, avatarURL: String?, bio: String?, phone: String?) async -> Bool {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/user/profile") else { return false }
        
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any?] = [
            "full_name": fullName,
            "avatar_url": avatarURL,
            "bio": bio,
            "phone": phone
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let profileResponse = try JSONDecoder().decode(APIResponse<ProfileResponse>.self, from: data)
                userProfile = profileResponse.data?.profile
                isLoading = false
                return true
            } else {
                let errorResponse = try JSONDecoder().decode(APIResponse<String>.self, from: data)
                errorMessage = errorResponse.message
            }
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - Preferences Operations
    func fetchUserPreferences() async {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/user/preferences") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let preferencesResponse = try JSONDecoder().decode(APIResponse<PreferencesResponse>.self, from: data)
                userPreferences = preferencesResponse.data?.preferences
            }
        } catch {
            print("Failed to fetch preferences: \(error)")
        }
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async -> Bool {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/user/preferences") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(preferences)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let preferencesResponse = try JSONDecoder().decode(APIResponse<PreferencesResponse>.self, from: data)
                userPreferences = preferencesResponse.data?.preferences
                return true
            }
        } catch {
            errorMessage = "Failed to update preferences: \(error.localizedDescription)"
        }
        
        return false
    }
    
    // MARK: - Sessions Operations
    func fetchUserSessions() async {
        guard let token = accessToken,
              let url = URL(string: "\(baseURL)/user/sessions") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let sessionsResponse = try JSONDecoder().decode(APIResponse<SessionsResponse>.self, from: data)
                sessions = sessionsResponse.data?.sessions ?? []
            }
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    // MARK: - Image Upload (placeholder for future implementation)
    func uploadProfileImage(_ image: UIImage) async -> String? {
        // This would typically upload to a cloud storage service
        // For now, we'll return a placeholder URL
        // In a real implementation, you'd upload to AWS S3, Cloudinary, etc.
        
        // Placeholder implementation
        await Task.sleep(nanoseconds: 2_000_000_000) // Simulate network delay
        return "https://via.placeholder.com/200x200"
    }
    
    // MARK: - Helper Methods
    func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchUserProfile() }
            group.addTask { await self.fetchUserPreferences() }
            group.addTask { await self.fetchUserSessions() }
        }
    }
}