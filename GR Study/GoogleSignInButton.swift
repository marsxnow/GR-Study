//
//  GoogleSignInButton.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI

struct GoogleSignInButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    init(action: @escaping () -> Void, isLoading: Bool = false) {
        self.action = action
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GoogleLogo()
                    .frame(width: 20, height: 20)
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(25)
        }
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .disabled(isLoading)
    }
}

struct GoogleLogo: View {
    var body: some View {
        ZStack {
            // Google "G" recreation using shapes and colors
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 3)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 6, height: 3)
                }
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 6, height: 3)
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 3)
                }
            }
            .clipShape(Circle())
            
            // Simple "G" text overlay
            Text("G")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray.opacity(0.8))
        }
    }
}

// MARK: - Preview
struct GoogleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GoogleSignInButton(action: {})
            
            GoogleSignInButton(action: {}, isLoading: true)
            
            GoogleLogo()
                .frame(width: 40, height: 40)
        }
        .padding()
    }
}