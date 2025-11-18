////
//  LaunchView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/12/25.
//

import SwiftUI
import CoreText // Required for the animated text path

struct LaunchView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LaunchViewModel()
    @State private var showBee = false
    @State private var showSlogan = false

    var body: some View {
        ZStack {
            // 🟡 Background
            Color.yellow.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Bee Animation
                Image("beeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .offset(x: showBee ? 0 : -300, y: showBee ? 0 : -200)
                    .opacity(showBee ? 1 : 0)
                    .animation(.easeOut(duration: 1.2), value: showBee)

                // Animated "HelloGT"
                HelloGTAnimatedText()
                    .frame(height: 120)
                    .opacity(showSlogan ? 1 : 0)
                    .scaleEffect(showSlogan ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.6).delay(0.5), value: showSlogan)

                // Slogan
                Text("MEET THE BUZZ")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .opacity(showSlogan ? 1 : 0)
                    .animation(.easeIn(duration: 2.0).delay(1.0), value: showSlogan)
                
                Text("The social app for every Yellow Jacket.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .opacity(showSlogan ? 1 : 0)
                    .animation(.easeIn(duration: 2.0).delay(1.3), value: showSlogan)
            }
            .padding()
            .onAppear {
                // Animations
                withAnimation { showBee = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showSlogan = true
                }
                viewModel.startLaunchSequence()
            }
            // When ViewModel says "go," navigate to auth
            .onChange(of: viewModel.shouldNavigate) { newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        appState.completeLaunch()
                    }
                }
            }
        }
    }
}

struct HelloGTAnimatedText: View {
    @State private var drawAmount: CGFloat = 0

    var body: some View {
        HelloGTShape()
            .trim(from: 0, to: drawAmount)
            .stroke(
                LinearGradient(colors: [.yellow, .orange],
                               startPoint: .leading,
                               endPoint: .trailing),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 300, height: 100)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0)) {
                    drawAmount = 1
                }
            }
    }
}

struct HelloGTShape: Shape {
    func path(in rect: CGRect) -> Path {
        let text = "HelloGT"
        let font = UIFont(name: "SnellRoundhand-Bold", size: 70) ?? UIFont.systemFont(ofSize: 70)
        
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributedString)
        let runArray = CTLineGetGlyphRuns(line) as! [CTRun]
        
        let path = CGMutablePath()
        for run in runArray {
            let runFont = CTRunGetAttributes(run) as NSDictionary
            let fontRef = runFont[kCTFontAttributeName as NSAttributedString.Key] as! CTFont
            let glyphCount = CTRunGetGlyphCount(run)
            for index in 0..<glyphCount {
                var glyph = CGGlyph()
                var position = CGPoint()
                CTRunGetGlyphs(run, CFRange(location: index, length: 1), &glyph)
                CTRunGetPositions(run, CFRange(location: index, length: 1), &position)
                if let letter = CTFontCreatePathForGlyph(fontRef, glyph, nil) {
                    let transform = CGAffineTransform(translationX: position.x, y: position.y)
                    path.addPath(letter, transform: transform)
                }
            }
        }
        
        // Scale + center inside rect
        let boundingBox = path.boundingBox
        let scale = min(rect.width / boundingBox.width, rect.height / boundingBox.height)
        var transform = CGAffineTransform(scaleX: scale, y: -scale)
        transform = transform.translatedBy(x: -boundingBox.minX, y: -boundingBox.maxY)
        let scaledPath = path.copy(using: &transform) ?? path
        
        var centered = CGAffineTransform(translationX: rect.midX - scaledPath.boundingBox.midX,
                                         y: rect.midY - scaledPath.boundingBox.midY)
        return Path(scaledPath.copy(using: &centered) ?? scaledPath)
    }
}
