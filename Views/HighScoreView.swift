import SwiftUI

struct HighScoreView: View {
    let userLanguage: WelcomeView.Language
    @ObservedObject var highScoreManager: HighScoreManager
    @Binding var isPresented: Bool
    
    private var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Spacer()
                        Text("שיאים")
                            .font(.system(size: isIPhone ? 30 : 40, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                        
                        Button(action: { 
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: isIPhone ? 24 : 32))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Table
                    VStack(spacing: 15) {
                        // Headers
                        HStack(spacing: isIPhone ? 30 : 70) {
                            Text("#")
                                .frame(width: isIPhone ? 20 : 60)
                            Text("שם")
                                .frame(width: isIPhone ? 120 : 180)
                            Text("נקודות")
                                .frame(width: isIPhone ? 85 : 120)
                            Text("פספוסים")
                                .frame(width: isIPhone ? 85 : 120)
                            Text("זמן")
                                .frame(width: isIPhone ? 85 : 120)
                        }
                        .padding(.horizontal, 30)
                        .font(.system(size: isIPhone ? 18 : 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .background(Color.yellow.opacity(0.4))
                        
                        // Rows
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(0..<10) { index in
                                    if index < highScoreManager.highScores.count {
                                        let record = highScoreManager.highScores[index]
                                        HStack(spacing: isIPhone ? 30 : 70) {
                                            Text("\(index + 1)")
                                                .frame(width: isIPhone ? 20 : 60)
                                            Text(record.name)
                                                .frame(width: isIPhone ? 120 : 180)
                                            Text("\(record.score)")
                                                .frame(width: isIPhone ? 80 : 120)
                                            Text("\(record.mistakes)")
                                                .frame(width: isIPhone ? 80 : 120)
                                            if let timeTaken = record.timeTaken {
                                                let minutes = timeTaken / 60
                                                let seconds = timeTaken % 60
                                                Text(String(format: "%02d:%02d", minutes, seconds))
                                                    .frame(width: isIPhone ? 80 : 120)
                                            } else {
                                                Text("-")
                                                    .frame(width: isIPhone ? 80 : 120)
                                            }
                                        }
                                        .font(.system(size: isIPhone ? 16 : 24))
                                        
                                        if index < 9 {  // Don't add divider after last row
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.horizontal)
                                        }
                                    } else {
                                        // Empty row
                                        HStack(spacing: isIPhone ? 30 : 70) {
                                            Text("\(index + 1)")
                                                .frame(width: isIPhone ? 20 : 60)
                                            Text("-")
                                                .frame(width: isIPhone ? 120 : 180)
                                            Text("-")
                                                .frame(width: isIPhone ? 80 : 120)
                                            Text("-")
                                                .frame(width: isIPhone ? 80 : 120)
                                            Text("-")
                                                .frame(width: isIPhone ? 80 : 120)
                                        }
                                        .font(.system(size: isIPhone ? 16 : 24))
                                        .foregroundColor(.gray)
                                        
                                        if index < 9 {  // Don't add divider after last row
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(30)
                .frame(
                    width: geometry.size.width * 0.9,
                    height: isIPhone ? geometry.size.height * 0.9 : geometry.size.height * 0.8
                )
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 5)
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
        }
    }
} 
