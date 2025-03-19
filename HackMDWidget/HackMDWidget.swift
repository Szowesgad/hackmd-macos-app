//
//  HackMDWidget.swift
//  HackMDWidget
//
//  Created on 2025-03-19.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Model

struct NoteEntry: TimelineEntry {
    let date: Date
    let notes: [NoteItem]
    let configuration: ConfigurationAppIntent
}

struct NoteItem: Identifiable, Hashable {
    let id: String
    let title: String
    let lastEdited: Date
    let previewText: String
    let collaborators: Int
    
    static var placeholder: NoteItem {
        NoteItem(
            id: "placeholder",
            title: "Notatka przykładowa",
            lastEdited: Date(),
            previewText: "To jest przykładowy tekst notatki, który zostanie wyświetlony w widgecie...",
            collaborators: 2
        )
    }
    
    static var placeholders: [NoteItem] {
        [
            NoteItem(
                id: "note1",
                title: "Spotkanie projektowe",
                lastEdited: Date().addingTimeInterval(-3600),
                previewText: "Agenda spotkania: 1. Przegląd postępów, 2. Planowanie sprintu, 3. Pytania",
                collaborators: 3
            ),
            NoteItem(
                id: "note2",
                title: "Notatki z wykładu",
                lastEdited: Date().addingTimeInterval(-86400),
                previewText: "Główne punkty wykładu: - Architektura aplikacji, - Wzorce projektowe, - Przykłady implementacji",
                collaborators: 1
            ),
            NoteItem(
                id: "note3",
                title: "Lista zadań",
                lastEdited: Date().addingTimeInterval(-172800),
                previewText: "- Zaimplementować widgety, - Dodać eksport PDF, - Poprawić obsługę powiadomień",
                collaborators: 0
            )
        ]
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "HackMD Widget"
    static var description: IntentDescription = .init("Wyświetla ostatnie notatki z HackMD")

    @Parameter(title: "Liczba notatek")
    var noteCount: Int = 3
    
    @Parameter(title: "Pokaż współpracowników")
    var showCollaborators: Bool = true
}

// MARK: - Widget Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(
            date: Date(),
            notes: [NoteItem.placeholder],
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> NoteEntry {
        // W rzeczywistej aplikacji dane byłyby pobierane z HackMD API
        // lub lokalnej bazy danych
        NoteEntry(
            date: Date(),
            notes: Array(NoteItem.placeholders.prefix(configuration.noteCount)),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<NoteEntry> {
        // W rzeczywistej aplikacji dane byłyby pobierane z HackMD API
        // lub lokalnej bazy danych
        let currentDate = Date()
        let entry = NoteEntry(
            date: currentDate,
            notes: Array(NoteItem.placeholders.prefix(configuration.noteCount)),
            configuration: configuration
        )
        
        // Odświeżanie widgetu co godzinę
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
}

// MARK: - Widget Views

struct HackMDWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Image("WidgetIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.bottom, 4)
            
            if let note = entry.notes.first {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(note.previewText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                HStack {
                    Text(timeAgo(date: note.lastEdited))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if entry.configuration.showCollaborators && note.collaborators > 0 {
                        Spacer()
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(note.collaborators)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Brak ostatnich notatek")
                    .font(.headline)
            }
        }
        .padding()
        .widgetURL(URL(string: "hackmd://widget/open"))
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("WidgetIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text("Ostatnie notatki")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if !entry.notes.isEmpty {
                ForEach(entry.notes.prefix(2)) { note in
                    Link(destination: URL(string: "hackmd://note/\(note.id)")!) {
                        NoteRowView(note: note, showCollaborators: entry.configuration.showCollaborators)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Brak ostatnich notatek")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "hackmd://widget/open"))
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("WidgetIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text("Ostatnie notatki")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if !entry.notes.isEmpty {
                ForEach(entry.notes) { note in
                    Link(destination: URL(string: "hackmd://note/\(note.id)")!) {
                        NoteRowView(note: note, showCollaborators: entry.configuration.showCollaborators)
                    }
                    .buttonStyle(.plain)
                    
                    if note.id != entry.notes.last?.id {
                        Divider()
                    }
                }
            } else {
                Text("Brak ostatnich notatek")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "hackmd://widget/open"))
    }
}

struct NoteRowView: View {
    let note: NoteItem
    let showCollaborators: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(note.previewText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text(timeAgo(date: note.lastEdited))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if showCollaborators && note.collaborators > 0 {
                    Spacer()
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(note.collaborators)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Helper Functions

func timeAgo(date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Widget Definition

struct HackMDWidget: Widget {
    let kind: String = "HackMDWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            HackMDWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("HackMD Notatki")
        .description("Wyświetla Twoje ostatnie notatki z HackMD.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HackMDWidget()
} timeline: {
    NoteEntry(
        date: Date(),
        notes: [NoteItem.placeholder],
        configuration: ConfigurationAppIntent()
    )
}

#Preview(as: .systemMedium) {
    HackMDWidget()
} timeline: {
    NoteEntry(
        date: Date(),
        notes: NoteItem.placeholders,
        configuration: ConfigurationAppIntent()
    )
}

#Preview(as: .systemLarge) {
    HackMDWidget()
} timeline: {
    NoteEntry(
        date: Date(),
        notes: NoteItem.placeholders,
        configuration: ConfigurationAppIntent()
    )
}