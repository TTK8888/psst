//
//  psstWidget.swift
//  psstWidget
//
//  Created by Taraaf Khalidi on 28/12/2025.
//

import WidgetKit
import SwiftUI

struct NoteEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
}

// the provider that fetches data
struct NoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: Date(), image: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        let entry = NoteEntry(date: Date(), image: loadImage())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let entry = NoteEntry(date: Date(), image: loadImage())
        
        // Refresh every 15 mins
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    func loadImage() -> UIImage? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.group
        ) else {
            print("failed to get container")
            return nil
        }
        
        let fileURL = containerURL.appendingPathComponent("note.png")
        print("Looking for file at \(fileURL)")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("Widget: no file found")
            return nil
        }
        
        print("image loaded success")
        return UIImage(data: data)
    }
}

struct PsstNotesEntryView: View {
    var entry: NoteEntry
    
    var body: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Text(Constants.noNotes)
                .foregroundStyle(Color.gray.opacity(0.5))
        }
    }
}

// widget configuration
struct PsstWidget: Widget {
    let kind: String = Constants.widgetName
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoteProvider()) {
            entry in PsstNotesEntryView(entry: entry)
                .containerBackground(Color.white, for: .widget)
        }
        .configurationDisplayName(Constants.displayName)
        .description(Constants.widgetDescriptor)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium){
    PsstWidget()
} timeline: {
    NoteEntry(date: Date(), image: nil)
}
