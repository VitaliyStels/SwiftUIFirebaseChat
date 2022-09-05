//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by Виталий on 05.09.2022.
//

import SwiftUI
import Firebase



class FirebaseManager: NSObject {
    
    let auth: Auth
//    let storage: Storage
    
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
//        self.storage = Storage.storage()
        
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLogin = false
    @State var email = ""
    @State var password = ""
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    
    
    var body: some View {
        NavigationView {
            
            ScrollView {
                Picker(selection: $isLogin, label: Text("Pick")) {
                    Text("Login")
                        .tag(true)
                    Text("Registration")
                        .tag(false)
                }
                .pickerStyle(.segmented)
                    .padding()
                
                
                if !isLogin {
                    Button {
                        shouldShowImagePicker.toggle()
                    } label: {
                        
                        VStack {
                            if let image = self.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    
                                    .cornerRadius(64)
                            } else {
                                Image(systemName: "person.fill").font(.system(size: 64)).padding().foregroundColor(.black)
                            }
                        }.overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 3))
                        
                    }
                }
                    

                    TextField("Email", text: $email)
                        .padding()
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                        .background(Color.white)
                    
                    
                    SecureField("Password", text: $password).padding()
                        .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Text( isLogin ? "Login" : "Create account")
                                .foregroundColor(Color.white)
                        }
                        .padding().background(Color.blue).cornerRadius(16)
                    }
                
                Text(self.loginStatusMessage)
                    .foregroundColor(.red)
                
                
                
            }.navigationTitle(isLogin ? "Login" : "Create account")
        
        }.navigationViewStyle(StackNavigationViewStyle())
            .fullScreenCover(isPresented: $shouldShowImagePicker) {
                ImagePicker(image: $image)
            }
        
    }
    
    
    private func handleAction() {
        if isLogin {
            print("Login mode")
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to create account", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("User \(result?.user.uid ?? "") created successfully")
            self.persistImageToStorage()
            
        }
    }
    
    private func persistImageToStorage() {
        Storage.storage().reference(withPath: <#T##String#>)
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login account", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            
            print("User \(result?.user.uid ?? "") logged successfully")
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
        }
    }
    
    
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
