//
//  ProfilePictureView.swift
//  GR Study
//
//  Created by Assistant on Date
//

import SwiftUI

struct ProfilePictureView: View {
    let imageURL: String?
    let size: CGFloat
    let borderWidth: CGFloat
    
    init(imageURL: String?, size: CGFloat = 32, borderWidth: CGFloat = 2) {
        self.imageURL = imageURL
        self.size = size
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_), .empty:
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.orange)
            @unknown default:
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.orange, lineWidth: borderWidth)
        )
    }
}

// MARK: - Preview
struct ProfilePictureView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProfilePictureView(imageURL: nil, size: 32)
            ProfilePictureView(imageURL: nil, size: 50)
            ProfilePictureView(imageURL: nil, size: 100, borderWidth: 3)
        }
        .padding()
    }
}