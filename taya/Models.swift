//
//  Models.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import Foundation
import SwiftUI

struct User: Identifiable, Hashable, Codable {
    var id = UUID()
    var username: String
    var bio: String
    var avatarName: String // System image name for simplicity in mock
}

struct Post: Identifiable, Hashable, Codable {
    var id = UUID()
    let user: User
    let imageName: String // System image name or asset name
    let description: String
    let likes: Int
    let date: Date
    var categoryName: String? // Optional for backwards compatibility, but we'll use it for filtering
    var videoName: String? // Name of local video file (e.g. "1.mp4")
}

struct Message: Identifiable, Hashable, Codable {
    var id = UUID()
    let content: String
    let isCurrentUser: Bool
    let timestamp: Date
}

struct Conversation: Identifiable, Hashable, Codable {
    var id = UUID()
    let user: User
    var lastMessage: String
    var unreadCount: Int
    var time: String
    var messages: [Message] = []
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
}

class MockData {
    static let currentUser = User(username: "Stargazer99", bio: "Exploring the cosmos one star at a time. ✨🔭", avatarName: "person.circle.fill")
    
    static let categories = [
        Category(name: "Planets", iconName: "circle.grid.hex"),
        Category(name: "Galaxies", iconName: "sparkles"),
        Category(name: "Stars", iconName: "star.fill"),
        Category(name: "Nebulas", iconName: "cloud.fill"),
        Category(name: "Events", iconName: "calendar"),
        Category(name: "Equipment", iconName: "camera.fill")
    ]
    
    static let posts = [
        // Video Posts (Top Priority)
        // Note: Using "sky" and "star" as per actual files found in directory
        Post(user: User(username: "NatureLover", bio: "Capturing the wild", avatarName: "leaf.fill"), imageName: "sky", description: "Amazing nature scene! 🌿📹", likes: 1024, date: Date(), categoryName: "Events", videoName: "sky"),
        Post(user: User(username: "CityVibes", bio: "Urban explorer", avatarName: "building.2.fill"), imageName: "star", description: "City lights at night. 🌃✨", likes: 856, date: Date().addingTimeInterval(-100), categoryName: "Events", videoName: "star"),

        // Planets
        Post(user: currentUser, imageName: "moon.fill", description: "Beautiful full moon tonight! Captured with my 8-inch Dobsonian.", likes: 124, date: Date().addingTimeInterval(-3600), categoryName: "Planets"),
        Post(user: User(username: "MarsRover", bio: "Red Planet Fan", avatarName: "circle.fill"), imageName: "circle.fill", description: "Mars is visible near the horizon. Look at that red hue!", likes: 55, date: Date().addingTimeInterval(-10000), categoryName: "Planets"),
        
        // Stars
        Post(user: User(username: "CosmicRay", bio: "Astro photographer", avatarName: "person.fill"), imageName: "star.fill", description: "Betelgeuse is looking particularly bright lately.", likes: 89, date: Date().addingTimeInterval(-7200), categoryName: "Stars"),
        Post(user: User(username: "StarWalker", bio: "Night sky lover", avatarName: "star"), imageName: "star", description: "The North Star is my guide.", likes: 12, date: Date().addingTimeInterval(-20000), categoryName: "Stars"),

        // Nebulas
        Post(user: User(username: "LunaLove", bio: "Moon walker", avatarName: "moon.stars.fill"), imageName: "sparkles", description: "Orion Nebula looking crisp in this clear winter sky. The colors are amazing.", likes: 256, date: Date().addingTimeInterval(-86400), categoryName: "Nebulas"),
        Post(user: User(username: "DeepSpace", bio: "Deep sky objects", avatarName: "cloud.fill"), imageName: "cloud.fill", description: "Captured the Veil Nebula last night. 4 hours of integration.", likes: 340, date: Date().addingTimeInterval(-90000), categoryName: "Nebulas"),

        // Galaxies
        Post(user: User(username: "AndromedaFan", bio: "Galaxies are cool", avatarName: "tornado"), imageName: "tornado", description: "Andromeda Galaxy M31. Our neighbor!", likes: 112, date: Date().addingTimeInterval(-150000), categoryName: "Galaxies"),
        
        // Solar/Events
        Post(user: currentUser, imageName: "sun.max.fill", description: "Solar flare activity is high today. Always wear protection when viewing the sun!", likes: 45, date: Date().addingTimeInterval(-172800), categoryName: "Events"),
        
        // Equipment
        Post(user: User(username: "GearHead", bio: "Telescope addict", avatarName: "camera"), imageName: "camera.fill", description: "Just got my new ZWO camera. Can't wait for clear skies!", likes: 78, date: Date().addingTimeInterval(-5000), categoryName: "Equipment"),
        
        // More Mock Data to fill the feed
        Post(user: User(username: "AuroraHunter", bio: "Chasing lights", avatarName: "wind.snow"), imageName: "thermometer.sun.fill", description: "The northern lights were spectacular yesterday! 💚", likes: 2100, date: Date().addingTimeInterval(-12000), categoryName: "Events"),
        
        Post(user: User(username: "SkyWatcher", bio: "Look up", avatarName: "eye.fill"), imageName: "cloud.moon.fill", description: "Cloudy night, but the moon is still shining through. ☁️🌙", likes: 45, date: Date().addingTimeInterval(-30000), categoryName: "Planets"),
        
        Post(user: User(username: "AstroDad", bio: "Teaching kids astronomy", avatarName: "person.2.fill"), imageName: "telescope", description: "Setting up the telescope for the neighborhood watch party.", likes: 156, date: Date().addingTimeInterval(-60000), categoryName: "Events"),
        
        Post(user: User(username: "CometChaser", bio: "Speedy rocks", avatarName: "hare.fill"), imageName: "location.north.fill", description: "Tracking the new comet path. It's moving fast!", likes: 332, date: Date().addingTimeInterval(-180000), categoryName: "Stars"),
        
        Post(user: User(username: "GalaxyGirl", bio: "Spiral arms", avatarName: "hurricane"), imageName: "hurricane", description: "Processing data from last week's session on M51.", likes: 890, date: Date().addingTimeInterval(-240000), categoryName: "Galaxies")
    ]
}
