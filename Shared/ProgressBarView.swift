//import SwiftUI
//
//struct ProgressBarView: View {
//    let totalCards: Int
//    let completedCards: Set<Int>
//    let isIPhone: Bool
//    
//    private var lastCompletedIndex: Int {
//        completedCards.isEmpty ? -1 : completedCards.max() ?? -1
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {  // Use ZStack to center circles on the line
//                // Base line
//                Rectangle()
//                    .fill(Color.black)
//                    .frame(height: 2)
//                    .padding(.horizontal, 30)
//                
//                // Circles
//                HStack(spacing: 0) {
//                    ForEach(0..<totalCards, id: \.self) { index in
//                        Circle()
//                            .fill(completedCards.contains(index) ? Color.green : Color.black)
//                            .frame(width: isIPhone ? 15 : 25, height: isIPhone ? 15 : 25)
//                            .position(
//                                x: calculateCirclePosition(index: index, totalWidth: geometry.size.width),
//                                y: geometry.size.height / 2  // Center vertically
//                            )
//                    }
//                }
//            }
//        }
//        .frame(height: isIPhone ? 20 : 30)
//    }
//    
//    private func calculateCirclePosition(index: Int, totalWidth: CGFloat) -> CGFloat {
//        let availableWidth = totalWidth - 60 // Account for padding
//        let segmentWidth = totalCards > 1 ? availableWidth / CGFloat(totalCards - 1) : availableWidth
//        return 30 + (segmentWidth * CGFloat(index))
//    }
//} 
