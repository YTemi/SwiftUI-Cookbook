//
//  NewNote.swift
//  FirebaseNotesApp
//
//  Created by giordano scalzo on 02/05/2020.
//  Copyright © 2020 giordano scalzo. All rights reserved.
//

import Foundation
import SwiftUI

struct NewNote: View {
    @State
    private var title: String = ""
    @State
    private var bodyText: String = ""

    @Binding
    var isNewNotePresented: Bool

    var repository: NotesRepository

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextField("Title", text: $title)
                    .padding(4)
                    .border(Color.gray)
                TextEditor(text: $bodyText)
                    .border(Color.gray)
            }
            .padding(32)
            .navigationBarTitle("New Note", displayMode: .inline)
            .navigationBarItems(trailing:
                Button {
                    repository.newNote(title: title,
                                            date: Date(),
                                            body: bodyText)
                    isNewNotePresented.toggle()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.headline)
                }
                .disabled(title.isEmpty)
            )
        }
    }
}
