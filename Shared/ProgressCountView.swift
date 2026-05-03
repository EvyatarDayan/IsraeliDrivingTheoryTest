import SwiftUI

struct ProgressCountView: View {
    let completedCount: Int
    let totalCount: Int
    let isIPhone: Bool
    
    var body: some View {
        Text("\(completedCount + 1)/\(totalCount)")
            .font(.system(size: isIPhone ? 15 : 25, weight: .bold))
            .foregroundColor(.white)
            .frame(
                width: isIPhone ? 80 : 150,
                height: isIPhone ? 30 : 50
            )
            .overlay(
                RoundedRectangle(cornerRadius: isIPhone ? 8 : 12)
                    .stroke(Color.white.opacity(0.8), lineWidth: isIPhone ? 7 : 10)
            )
            .background(Color.blue.opacity(0.7))
            .cornerRadius(isIPhone ? 8 : 12)
    }
} 
