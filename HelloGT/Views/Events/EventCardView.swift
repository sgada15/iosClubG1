//
//  EventCardView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct EventCardView: View {
    let event: Event
    
    private var salsaIconName: String? {
        guard let name = event.iconSystemName else { return nil }
        if UIImage(systemName: name) != nil {
            return name
        } else {
            return "music.note.list"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = salsaIconName {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 34, height: 34, alignment: .topLeading)
                    .padding(.top, 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(Event.listDateString(for: event.startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .padding(.horizontal)
    }
}

struct EventCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EventCardView(event: Event.sampleEvents[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.light)
            EventCardView(event: Event.sampleEvents[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}

