//
//  EventsView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct EventsView: View {
    private let events = Event.sampleEvents
    @StateObject private var attendanceManager = EventAttendanceManager()
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(events) { event in
                        NavigationLink(value: event) {
                            EventCardView(event: event)
                                .environmentObject(attendanceManager)
                                .environmentObject(authManager)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Events")
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
                    .environmentObject(attendanceManager)
                    .environmentObject(authManager)
            }
            .onAppear {
                attendanceManager.startListeningToAttendance()
                
                // Load attendance for current events
                let eventIds = events.map { $0.id }
                Task {
                    await attendanceManager.loadAttendanceForEvents(eventIds)
                }
            }
            .onDisappear {
                attendanceManager.stopListeningToAttendance()
            }
        }
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
    }
}

