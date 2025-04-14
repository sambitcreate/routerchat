import SwiftUI

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    let bgColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundStyle(.white)
                .padding()
                .background {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .padding(20)
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                        .padding(20)
                }
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor)
    }
}