//
//  SignInView.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var showingError = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    // Logo and Title Section
                    VStack(spacing: 24) {
                        // App Icon
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 12) {
                            Text("Golden Ratio Study")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Sign in to sync your study sessions\nand track your progress")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Benefits Section
                    VStack(spacing: 16) {
                        benefitRow(icon: "cloud.fill", text: "Sync across all devices")
                        benefitRow(icon: "chart.bar.fill", text: "Track your study progress")
                        benefitRow(icon: "lock.shield.fill", text: "Secure and private")
                        benefitRow(icon: "person.2.fill", text: "Personalized experience")
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign In Buttons
                    VStack(spacing: 16) {
                        // Apple Sign In Button
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await authManager.signInWithApple()
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        
                        // Google Sign In Button
                        GoogleSignInButton(
                            action: {
                                Task {
                                    await authManager.signInWithGoogle()
                                }
                            },
                            isLoading: authManager.isLoading
                        )
                        
                        // Guest Mode Button (Optional)
                        Button("Continue as Guest") {
                            // Handle guest mode if needed
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    // Loading State
                    if authManager.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.orange)
                            
                            Text("Signing you in...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By signing in, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // Handle terms
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            
                            Text("and")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Privacy Policy") {
                                // Handle privacy
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.05),
                    Color.yellow.opacity(0.05),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(authManager.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: authManager.errorMessage) { error in
            if error != nil {
                showingError = true
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(authManager: AuthenticationManager())
    }
}