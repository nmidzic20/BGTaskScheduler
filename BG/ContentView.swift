//
//  ContentView.swift
//  BG
//
//  Created by FOI on 27.11.2022..
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var mockServer = MockServer.mockServer
    
    var body: some View {
        VStack {
            
            Text(mockServer.data)
            
        }
        .padding()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
