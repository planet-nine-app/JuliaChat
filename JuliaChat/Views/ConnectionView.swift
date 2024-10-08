//
//  JuliaButton.swift
//  JuliaChat
//
//  Created by Zach Babb on 7/21/24.
//

import SwiftUI
import SwiftData

struct ConnectionView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var users: [User]
    @Query private var preferences: [Preferences]
    @State var textfieldOn = false
    @State var enteredText = ""
    @State var handle = ""
    @State var showDisassociateAlert = false
    @State var startPressTime = ""
    let addOrUpdateImage: () -> Void
    var connection = KeyTuple(uuid: "foo", pubKey: "bar")
    let onPress: () -> Void
    var label = ""
    var imageName = ""
    
    struct CircularConnectionStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .green, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 4
                        )
                )
                .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
        }
    }
    
    var body: some View {
        let _ = print("should display image: \(imageName)")
        VStack {
            Button(action: onPress) {
                Image(uiImage: ImageLoader.loadImage(fromPath: imageName))                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if startPressTime == "" {
                                    startPressTime = "".getTime()
                                }
                            }
                            .onEnded { value in
                                let now = "".getTime()
                                print("diff: \((Int(now) ?? 1) - (Int(startPressTime) ?? 1))")
                                if let now = Int(now),
                                   let start = Int(startPressTime),
                                   now - start < 200 {
                                        startPressTime = ""
                                        self.onPress()
                                    } else {
                                        startPressTime = ""
                                        showDisassociateAlert = true
                                    }
                                }
                            )
            }
            .buttonStyle(PlainButtonStyle())
            .modifier(CircularConnectionStyle())
//            .onLongPressGesture {
//                showDisassociateAlert = true
//            }
            .alert(LocalizedStringKey("disassociate"), isPresented: $showDisassociateAlert) {
                Button("Cancel", role: .cancel) {
                    print("Alert canceled")
                    showDisassociateAlert = false
                }
                Button("OK") {
                    print("Alert confirmed")
                    Task {
                        do {
                            await Julia.disassociate(user: users[0], keyToDisassociate: connection) { err, user in
                                if let user = user {
                                    modelContext.insert(user)
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                    showDisassociateAlert = false
                }
            }
            
            if textfieldOn {
                VStack {
                    JuliaTextField(label: handle, enteredText: $enteredText)
                        .onSubmit {
                            print("take care of pref here")
                            print(enteredText)
                            if preferences.count < 1 {
                                var newPreferences = Preferences(appPreferences: ["\(connection.uuid)Handle": enteredText], globalPreferences: [String: String]())
                                
                                Task(priority: .background) {
                                    do {
                                        await Pref.createUser(preferences: newPreferences.appPreferences) { err, prefUser in
                                            if let err = err {
                                                print(err)
                                                return
                                            }
                                            guard let prefUser = prefUser else { return }
                                            newPreferences.prefUUID = prefUser.uuid
                                            modelContext.insert(newPreferences)
                                            try? modelContext.save()
                                        }
                                    }
                                }
                            } else {
                                let preferences = preferences[0]
                                preferences.appPreferences["\(connection.uuid)Handle"] = enteredText
                                modelContext.insert(preferences)
                                try? modelContext.save()
                                
                                Task(priority: .background) {
                                    do {
                                        let prefUser = PrefUser(uuid: preferences.prefUUID, preferences: preferences.appPreferences)
                                        await Pref.savePreferences(prefUser: prefUser, newPreferences: prefUser.preferences) { err, prefUser in
                                            if let err = err {
                                                print("ignore response here")
                                                print(err)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Button() {
                            self.addOrUpdateImage()
                        } label: {
                            Text("Add Image")
                        }
                    }
                
            } else {
                Text(label)
                    .frame(width: 140, height: 24)
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.7), radius: 3, x: 0, y: 2)
                    .onTapGesture {
                        textfieldOn = true
                    }
            }
        }
    }
    
    init(label: String, handle: String, imageName: String, connection: KeyTuple, addOrUpdateImage: @escaping () -> Void, onPress: @escaping () -> Void) {
        self.addOrUpdateImage = addOrUpdateImage
        self.onPress = onPress
        self.label = label
        self.handle = handle
        self.imageName = imageName
        self.connection = connection
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static let tuple = KeyTuple(uuid: "foo", pubKey: "bar")
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ConnectionView(label: "Connect", handle: "foo", imageName: "network", connection: tuple, addOrUpdateImage: {}, onPress: {})
        }
    }
}


