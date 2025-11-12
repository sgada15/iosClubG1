//
//  EventDetailView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    Text(Event.detailRangeString(start: event.startDate, end: event.endDate))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.accentColor)
                        Text("Location")
                            .font(.headline)
                    }
                    Text(event.location)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.justify.left")
                            .foregroundColor(.accentColor)
                        Text("Description")
                            .font(.headline)
                    }
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "tag")
                            .foregroundColor(.accentColor)
                        Text("Categories")
                            .font(.headline)
                    }
                    
                    if event.categories.isEmpty {
                        CategoryPill(text: "No category")
                    } else {
                        WrapHStack(spacing: 8, lineSpacing: 8) {
                            ForEach(event.categories, id: \.self) { cat in
                                CategoryPill(text: cat)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CategoryPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.systemGray6))
            )
            .overlay(
                Capsule().stroke(Color(.separator), lineWidth: 0.5)
            )
    }
}

private struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }
    
    var body: some View {
        FlowLayout(spacing: spacing, lineSpacing: lineSpacing, content: content)
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                content()
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height + lineSpacing
                        }
                        let result = width
                        if d.width <= geometry.size.width {
                            width -= d.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        height
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EventDetailView(event: Event.sampleEvents[0])
        }
    }
}

