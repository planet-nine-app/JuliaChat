//
//  ContactsView.swift
//  JuliaChat
//
//  Created by Zach Babb on 7/17/24.
//

import SwiftUI
import SwiftData

struct ConnectionsView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var users: [User]
    @State var displayText: String = "noConnections"
    @State var promptsOpen: Bool = false
    @State var enteredText: String = ""
    @State var music: Bool = false
    @State var venue: Bool = false
    @Binding var viewState: Int
    @Binding var receiverUUID: String
    
    let backgroundImage = ImageResource(name: "space", bundle: Bundle.main)

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                PlanetNineView(displayText: $displayText)
                VStack {
                    if promptsOpen {
                        JuliaTextField(enteredText: $enteredText)
                            .transition(.push(from: .trailing))
                        JuliaButton(label: "enterPrompt") {
                            // Enter prompt
                            print("prompt is: \(enteredText)")
                            if enteredText.lowercased() == "music" {
                                music = true
                            }
                            if enteredText.lowercased() == "venue" {
                                venue = true
                            }
                            
//                            Task {
//                                await Network.postPrompt(baseURL: "http://localhost:3000", user: users[0], prompt: enteredText) { err, data in
//                                    if let err = err {
//                                        print(err)
//                                        return
//                                    }
//                                    if let data = data {
//                                        if String(data: data, encoding: .utf8)?.contains("true") == true {
//                                            print("Great success")
//                                            return
//                                        } else {
//                                            print("Terrible failure")
//                                            return
//                                        }
//                                    }
//                                    print("no data")
//                                }
//                            }
                        }
                        .transition(.slide)
                        JuliaButton(label: "getPrompt") {
                            // Call network to get prompt
                            print("get prompt tapped")
                            Task {
                                await Network.getPrompt(baseURL: "http://localhost:3000", user: users[0]) { error, data in
                                    if let error = error {
                                        print(error)
                                        return
                                    }
                                    if let data = data {
                                        print(String(data: data, encoding: .utf8))
                                        do {
                                            let user = try JSONDecoder().decode(User.self, from: data)
                                            print("SUCCESS")
                                            print(user)
                                            print(user.uuid)
                                            modelContext.insert(user)
                                            try? modelContext.save()
                                        } catch {
                                            print("Decoding or saving failed ")
                                            print(error)
                                            return
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .trailing))
                        if !users[0].pendingPrompts.isEmpty {
                           
                            ForEach(users[0].promptsAsArray()) { prompt in
                                if prompt.newPubKey != nil {
                                    let _ = print("boom! add that button")
                                    JuliaButton(label: "Accept \(prompt.prompt)") {
                                        print("Accept the prompt here")
                                        let postPrompt = PostPrompt(timestamp: prompt.timestamp, uuid: prompt.newUUID ?? "", pubKey: prompt.newPubKey ?? "", prompt: prompt.prompt ?? "", signature: prompt.newSignature ?? "")
                                        Task {
                                            await Network.associate(baseURL: "http://localhost:3000", user: users[0], signedPrompt: postPrompt) { error, data in
                                                if let error = error {
                                                    print("ERROROROROR")
                                                    print(error)
                                                    return
                                                }
                                                if let data = data {
                                                    print(String(data: data, encoding: .utf8))
                                                    do {
                                                        let user = try JSONDecoder().decode(User.self, from: data)
                                                        print("SUCCESS")
                                                        print(user)
                                                        print(user.uuid)
                                                        modelContext.insert(user)
                                                        try? modelContext.save()
                                                    } catch {
                                                        print("Decoding or saving failed ")
                                                        print(error)
                                                        return
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    let _ = print("If it's getting here, what heck is \(prompt.toString())")
                                }
                            }
                        }
                    }
                    
                    JuliaButton(label: "handlePrompts") {
                        promptsOpen = !promptsOpen
                        /*Task {
                            await Network.registerPlanetNineUser(baseURL: "http://localhost:3001", handle: enteredText, callback: { err, data in
                                if let err = err {
                                    print("error")
                                    print(err)
                                    return
                                }
                                guard let data = data else { return }
                                print(String(data: data, encoding: .utf8))
                                do {
                                    let pnUser  = try JSONDecoder().decode(PlanetNineUser.self, from: data)
                                    print("SUCCESS")
                                    print(pnUser)
                                    print(pnUser.uuid)
                                    modelContext.insert(pnUser)
                                    try? modelContext.save()
                                    viewState = 1
                                } catch {
                                    print("Decoding or saving failed ")
                                    print(error)
                                    return
                                }
                            })
                        }*/
                    }
                }
                .background(.blue)
                .frame(width: 160, height: 48, alignment: .center)
                .position(x: w / 2, y: h * 0.75)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(users[0].connections(), id: \.uuid) { tuple in
                            ConnectionView(label: tuple.uuid) {
                                print("Tapped a connection")
                                receiverUUID = tuple.uuid
                                viewState = 2
                            }
                            if music {
                                ConnectionView(label: "Concerts, Inc.") {
                                    print("Tapped a connection")
                                    receiverUUID = tuple.uuid
                                    viewState = 2
                                }
                            }
                            if venue {
                                ConnectionView(label: "Crystal Ballrom") {
                                    print("Tapped a connection")
                                    receiverUUID = tuple.uuid
                                    viewState = 4
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                let user = users[0]
                if user.keys.interactingKeys.count == 0 {
                    displayText = "noConnections"
                }
            }
        }
    }
}
