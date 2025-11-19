//
//  Event.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import Foundation
import SwiftUI

struct Event: Identifiable, Hashable, Codable {
    let id: String // Change from UUID to String for Firebase compatibility
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String
    let description: String
    let iconSystemName: String?
    
    // Custom initializer to generate consistent IDs
    init(id: String? = nil, title: String, startDate: Date, endDate: Date, location: String, description: String, iconSystemName: String?) {
        if let id = id {
            self.id = id
        } else {
            // Create a clean Firebase-compatible ID from the title
            let cleanTitle = title.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                .prefix(50) // Limit length
            self.id = String(cleanTitle)
        }
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.description = description
        self.iconSystemName = iconSystemName
    }
    
    // MARK: - Date Formatting
    
    private static let nyTimeZone: TimeZone = TimeZone(identifier: "America/New_York") ?? .current
    
    // List page single-line: "Wednesday, November 12 2025 at 1:00 PM EST"
    static func listDateString(for date: Date, locale: Locale = .current) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.timeZone = nyTimeZone
        df.dateFormat = "EEEE, MMMM d yyyy 'at' h:mm a zzz"
        return df.string(from: date)
    }
    
    // Detail page range: "Wed, Nov 12, 2025 • 1:00 PM–1:45 PM ET"
    static func detailRangeString(start: Date, end: Date, locale: Locale = .current) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = locale
        dayFormatter.timeZone = nyTimeZone
        dayFormatter.dateFormat = "E, MMM d, yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = nyTimeZone
        timeFormatter.dateFormat = "h:mm a"
        
        let day = dayFormatter.string(from: start)
        let startTime = timeFormatter.string(from: start)
        let endTime = timeFormatter.string(from: end)
        let tzShort = "ET" // cleaner display
        
        return "\(day) • \(startTime)–\(endTime) \(tzShort)"
    }
}

// MARK: - Hard-coded Events
extension Event {
    static var sampleEvents: [Event] {
        func nyDate(hour: Int, minute: Int) -> Date {
            var comps = DateComponents()
            comps.year = 2025
            comps.month = 11
            comps.day = 12
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "America/New_York") ?? .current
            return cal.date(from: comps) ?? Date()
        }
        
        let salsa = Event(
            title: "Salsa Dance Workshop",
            startDate: nyDate(hour: 13, minute: 0),
            endDate: nyDate(hour: 13, minute: 45),
            location:
"""
Arts Plaza
353 Ferst Dr NW, Atlanta , GA
""",
            description:
"""
Celebrate culture and creativity at the ImagiNATION Festival with a vibrant Salsa Dance Workshop hosted by the GT Salsa Club! Join us on Wednesday, November 12 from 1:00–1:45 PM in the Arts Plaza for an exciting and beginner-friendly session!
""",
            iconSystemName: "figure.socialdance"
        )
        
        let paintSip = Event(
            title: "Paint & Sip: GT Arts x Center for Mental Health Care and Resources",
            startDate: nyDate(hour: 14, minute: 0),
            endDate: nyDate(hour: 15, minute: 0),
            location:
"""
Ferst Center for the Arts & Arts Plaza
349 Ferst Dr NW , Atlanta, GA
""",
            description:
"""
Paint & Sip Workshop | ImagiNATION Festival
November 12 | 2:00–3:00 PM | Arts Plaza

Take a break, unwind, and express yourself creatively at our Paint & Sip Workshop, co-hosted by GT Arts and the Center for Mental Health Care and Resources. As part of the ImagiNATION Festival, this event brings together art, mental health, and community in a relaxing outdoor setting.

All supplies and drinks are free, just bring your creativity!

Participants will explore reflective themes like “What does self-care look like to you?” or “Visualizing mental health and well-being,” guided by facilitators who will help you express your imagination and find calm through art.

This event is open to all students, faculty, and staff, with space for up to 50 participants (First come first serve)! Come paint, sip, and celebrate the connection between art and mental wellness!

All participants will receive a free shirt!
""",
            iconSystemName: "paintpalette"
        )
        
        let cramJam = Event(
            title: "Cram and Jam",
            startDate: nyDate(hour: 17, minute: 30),
            endDate: nyDate(hour: 18, minute: 30),
            location: "IC 205",
            description: "This is our final week before finals where we hold a study session for all our members.",
            iconSystemName: "books.vertical"
        )
        
        let nar = Event(
            title: "North Avenue Review - Weekly Meeting!",
            startDate: nyDate(hour: 18, minute: 0),
            endDate: nyDate(hour: 19, minute: 0),
            location:
"""
Student Media Office

2nd Floor Student Center
""",
            description:
"""
North Avenue Review is Georgia Tech's Open-Forum Magazine! We publish semesterly issues and online content monthly at northavereview.com. Anyone is able to join our staff as part of the content, layout, and/or marketing team – no experience needed! All you need to do is come to meetings Wednesdays at 6pm in the Student Media Center (2nd floor of the Student Center, next to Dancing Goats). Feel free to join at any part of the semester! If you don't want to be part of staff but still want to submit, email your submissions to editor@northavereview.com
 (we accept any type of content from creative fiction and poetry to op-eds and essays).

We also host events where we collage, watch movies, and craft so look out on our insta (@northavereview) or Engage page for those!
""",
            iconSystemName: "newspaper"
        )
        
        return [salsa, paintSip, cramJam, nar]
    }
}

