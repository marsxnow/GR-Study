//
//  ProfileView.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    // Edit fields
    @State private var editName = ""
    @State private var editBio = ""
    @State private var editPhone = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Profile Information
                    profileInfoSection
                    
                    // Session Statistics
                    sessionStatsSection
                    
                    // Settings Section
                    settingsSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.05), Color.yellow.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveProfile()
                        } else {
                            startEditing()
                        }
                    }
                    .disabled(profileManager.isLoading)
                }
            }
        }
        .task {
            await profileManager.loadAllData()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { item in
            loadProfileImage(from: item)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Picture
            Button(action: {
                if isEditing {
                    showingImagePicker = true
                }
            }) {
                ZStack {
                    AsyncImage(url: URL(string: profileManager.userProfile?.avatarURL ?? authManager.currentUser?.profilePictureURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.orange, lineWidth: 3)
                    )
                    
                    if isEditing {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .offset(x: -8, y: -8)
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                }
            }
            .disabled(!isEditing)
            
            // User Info
            VStack(spacing: 4) {
                if isEditing {
                    TextField("Full Name", text: $editName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(profileManager.userProfile?.fullName ?? authManager.currentUser?.name ?? "Unknown User")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Verified via \(authManager.currentUser?.provider.capitalized ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // MARK: - Profile Info Section
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                ProfileInfoRow(
                    icon: "text.quote",
                    title: "Bio",
                    value: isEditing ? nil : (profileManager.userProfile?.bio ?? "Add a bio"),
                    editField: isEditing ? AnyView(
                        TextField("Tell us about yourself", text: $editBio, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    ) : nil
                )
                
                ProfileInfoRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: isEditing ? nil : (profileManager.userProfile?.phone ?? "Add phone number"),
                    editField: isEditing ? AnyView(
                        TextField("Phone number", text: $editPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    ) : nil
                )
                
                ProfileInfoRow(
                    icon: "calendar",
                    title: "Member since",
                    value: formatDate(profileManager.userProfile?.createdAt ?? "")
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // MARK: - Session Stats Section
    private var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Statistics")
                .font(.headline)
                .foregroundColor(.orange)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Active Sessions",
                    value: "\(profileManager.sessions.count)",
                    icon: "desktopcomputer",
                    color: .blue
                )
                
                StatCard(
                    title: "Current Session",
                    value: profileManager.sessions.first(where: { $0.isCurrent }) != nil ? "Active" : "None",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            if !profileManager.sessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(profileManager.sessions.prefix(3)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Push notifications",
                    isToggle: true,
                    toggleValue: .constant(profileManager.userPreferences?.notificationsEnabled ?? true)
                )
                
                Divider()
                
                SettingsRow(
                    icon: "moon.fill",
                    title: "Theme",
                    subtitle: profileManager.userPreferences?.theme.capitalized ?? "System",
                    chevron: true
                )
                
                Divider()
                
                SettingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: profileManager.userPreferences?.language.uppercased() ?? "EN",
                    chevron: true
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingSignOutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                showingDeleteAccountAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startEditing() {
        editName = profileManager.userProfile?.fullName ?? authManager.currentUser?.name ?? ""
        editBio = profileManager.userProfile?.bio ?? ""
        editPhone = profileManager.userProfile?.phone ?? ""
        isEditing = true
    }
    
    private func saveProfile() {
        Task {
            let success = await profileManager.updateUserProfile(
                fullName: editName.isEmpty ? nil : editName,
                avatarURL: nil, // Will be updated when image upload is implemented
                bio: editBio.isEmpty ? nil : editBio,
                phone: editPhone.isEmpty ? nil : editPhone
            )
            
            if success {
                isEditing = false
            }
        }
    }
    
    private func loadProfileImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                profileImage = image
                
                // Upload image and update profile
                if let imageURL = await profileManager.uploadProfileImage(image) {
                    await profileManager.updateUserProfile(
                        fullName: nil,
                        avatarURL: imageURL,
                        bio: nil,
                        phone: nil
                    )
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        
        return "Unknown"
    }
}

// MARK: - Supporting Views
struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String?
    let editField: AnyView?
    
    init(icon: String, title: String, value: String?, editField: AnyView? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.editField = editField
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let editField = editField {
                    editField
                } else {
                    Text(value ?? "")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SessionRow: View {
    let session: SessionInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.ipAddress)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    if session.isCurrent {
                        Text("(Current)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Text("Last active: \(formatRelativeDate(session.lastActive))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: session.isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundColor(session.isCurrent ? .green : .gray)
        }
        .padding(.vertical, 4)
    }
    
    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 60 {
                return "Just now"
            } else if timeInterval < 3600 {
                return "\(Int(timeInterval / 60))m ago"
            } else if timeInterval < 86400 {
                return "\(Int(timeInterval / 3600))h ago"
            } else {
                return "\(Int(timeInterval / 86400))d ago"
            }
        }
        
        return "Unknown"
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isToggle: Bool
    let toggleValue: Binding<Bool>?
    let chevron: Bool
    
    init(icon: String, title: String, subtitle: String, isToggle: Bool = false, toggleValue: Binding<Bool>? = nil, chevron: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isToggle = isToggle
        self.toggleValue = toggleValue
        self.chevron = chevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isToggle, let toggleValue = toggleValue {
                Toggle("", isOn: toggleValue)
                    .tint(.orange)
            } else if chevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(
            authManager: AuthenticationManager(),
            profileManager: ProfileManager(authManager: AuthenticationManager())
        )
    }
}