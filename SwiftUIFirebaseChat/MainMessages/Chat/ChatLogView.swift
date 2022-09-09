//
//  ChatLogView.swift
//  SwiftUIFirebaseChat
//
//  Created by Виталий on 07.09.2022.
//

import SwiftUI
import Firebase

struct FirebaseContants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
}

struct ChatMessage : Identifiable {
    var id : String { documentId }
    
    let documentId : String
    let toId, fromId, text : String
    
    init(documentId : String, data : [String : Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseContants.fromId] as? String ?? ""
        self.toId = data[FirebaseContants.toId] as? String ?? ""
        self.text = data[FirebaseContants.text] as? String ?? ""
    }
}


class ChatLogViewModel : ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser : ChatUser?
    
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Failed to listen for messages \(error)")
                    self.errorMessage = "Failed to listen for messages \(error)"
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
            }
    }
    
    
    func handleSend() {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        let messageData = [FirebaseContants.fromId : fromId, FirebaseContants.toId : toId, FirebaseContants.text : self.chatText, "timestamp" : Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message to Firestore: \(error)"
                return
            }
            print("Successfully saved current user sending message")
            self.chatText = ""
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message to Firestore: \(error)"
                return
            }
            print("Recipient saved message successfully")
        }
        
    }
}


struct ChatLogView : View {
    
    let chatUser : ChatUser?
    
    init(chatUser : ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    
    @ObservedObject var vm : ChatLogViewModel
    
    var body: some View {
        ZStack {
            
            messagesView
            Text(vm.errorMessage)
            VStack {
                Spacer()
                chatBottomBar
                    .background(Color.white)
            }
            
            
        }
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messagesView : some View {
        ScrollView {
            
            ForEach(vm.chatMessages) { message in
                VStack {
                    if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                        HStack {
                            
                            Spacer()
                            
                            HStack {
                                Text(message.text)
                                    .foregroundColor(.white)
                            }
                            .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                            
                            
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    else {
                        HStack {
                            HStack {
                                Text(message.text)
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .background(.white)
                        .cornerRadius(8)
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            
            
                
            }
            
            HStack { Spacer() }
            
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .padding(.bottom, 65)
        .padding(.top, 0)
    }
    
    private var chatBottomBar : some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
//                TextEditor(text: $chatText)
            
//            ZStack {
//                DescriptionPlaceholder()
//                TextEditor(text: $chatText)
//                    .opacity(chatText.isEmpty ? 0.5 : 1)
//            }
            TextField("Description", text: $vm.chatText)
            
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(4)

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            ChatLogView(chatUser: .init(data: ["uid" : "YcUAQuGQuJeomQiPFGWWSNtGxqZ2", "email" : "123@gmail.com"]))
//        }
        MainMessagesView()
    }
}
