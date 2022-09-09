//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by Виталий on 05.09.2022.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore



struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    
    @State private var isLogin = false
    @State private var email = "123@gmail.com"
    @State private var password = "123123"
    
    
    @State private var shouldShowImagePicker = false
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
        if image == nil {
            self.loginStatusMessage = "You must select an image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to create account", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("User \(result?.user.uid ?? "") created successfully")
            loginUser()
            persistImageToStorage()
            
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to the storage: \(err)"
                return
            }
            
        }
        
        ref.downloadURL { url, err in
            if let err = err {
                self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                return
                
            }
            
            self.loginStatusMessage = "Successfully stored image with URL: \(url?.absoluteString ?? "")"
            
            guard let url = url else { return }
            self.storeUserInformation(imageProfileUrl: url)
        }
        
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return }
        let userData = ["email" : self.email, "uid" : uid, "profileImageUrl" : imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
            }
                
                print("Success")
                self.didCompleteLoginProcess()
                
            }
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
            self.didCompleteLoginProcess()
        }
    }
    
    
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}
