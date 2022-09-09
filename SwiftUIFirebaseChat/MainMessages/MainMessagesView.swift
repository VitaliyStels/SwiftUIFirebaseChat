//
//  NewMessagesView.swift
//  SwiftUIFirebaseChat
//
//  Created by Виталий on 05.09.2022.
//

import SwiftUI
import SDWebImageSwiftUI





class MainMessagesViewModel : ObservableObject {
    @Published var errorMessage = ""
    @Published var chatUser : ChatUser?
    
    init() {
        DispatchQueue.main.async {
            self.isCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else {
            self.errorMessage = "Could not find farebase uid"
            return
        }
        self.errorMessage = "\(uid)"
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch current user: \(error)"
                    print("Failed to fetch current user", error)
                }
                
                
                guard let data = snapshot?.data()
                else {
                    self.errorMessage = "Data not found"
                    print("no Data found")
                    return
                }
                
                
                self.chatUser = .init(data: data)
                
                

                
            }
        
    }
    
    @Published var isCurrentlyLoggedOut = false
    
    func handleSignOut() {
        isCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
    
    
}


struct MainMessagesView: View {
    @State var shouldShowLogOutOption = false
    
    
    @State var shouldNavigateToChatLog = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var customNavBar : some View {
        HStack {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipped()
                .cornerRadius(54)
                .overlay(RoundedRectangle(cornerRadius: 44)
                            .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
            
//            Image(systemName: "person.fill")
//                .font(.system(size: 34, weight: .heavy))
            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                
                Text(email)
                    .font(.system(size: 24, weight: .semibold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.lightGray))
                }
            }
            
            Spacer()
            
            Button {
                shouldShowLogOutOption.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 27, weight: .heavy))
                    .foregroundColor(Color(.label))
            }.actionSheet(isPresented: $shouldShowLogOutOption) {
                .init(title: Text("Settings"), message: Text("Do you want to quit?"), buttons: [
                    .destructive(Text("Sign Out"), action: {
                        print("handle sign out")
                        vm.handleSignOut()
                        
                    }),
                    .cancel()
                    ])
            }
            .fullScreenCover(isPresented: $vm.isCurrentlyLoggedOut) {
                LoginView(didCompleteLoginProcess: {
                    self.vm.isCurrentlyLoggedOut = false
                    self.vm.fetchCurrentUser()
                })
                
            }
            
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                //Optional text for error codes
//                Text("User: \(vm.chatUser?.uid ?? "")") //Change to vm.erromMessage to get error codes in app
                customNavBar
                .padding()
                
                MessagesView
                NavigationLink("", isActive: $shouldNavigateToChatLog) {
                    ChatLogView(chatUser: self.chatUser)
                }
                
            }.navigationBarHidden(true)
        }
    }
    
    private var MessagesView: some View {
        
            ScrollView {
                
                ForEach(0...10, id: \.self) { num in
                    VStack {
                        
                        NavigationLink {
                            Text("destination")
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .overlay(RoundedRectangle(cornerRadius: 44)
                                                .stroke(Color(.label), lineWidth: 1))
                                VStack(alignment: .leading) {
                                    Text("username")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("message text")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(UIColor.lightGray))
                                }
                                
                                Spacer()
                                
                                Text("time").font(.system(size: 14, weight: .semibold))
                            }
                            
                            
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                    }.padding(.horizontal)
                }
                
                
                
                
            }
            .padding(.bottom, 50)
            
            .overlay(NewMessageButton, alignment: .bottom)
            .navigationTitle("Main Messages View")
        
    }

    @State var shouldShowNewMessageScreen = false
    
    private var NewMessageButton : some View {

            Button {
                shouldShowNewMessageScreen.toggle()
            } label: {
                HStack {
                    Spacer()
                    Text("+ New Message")
                    
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    
                    
                }
                .foregroundColor(.white)
                .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
       
            }
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView(didSelectNewUser: { user in
                    print(user.email)
                    self.shouldNavigateToChatLog.toggle()
                    self.chatUser = user
                })
            }
        
    }
    
    @State var chatUser : ChatUser?
    
}




 




struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
//            .preferredColorScheme(.dark)
        
    }
}
