//
//  MockServer.swift
//  BG
//
//  Created by FOI on 27.11.2022..
//

import Foundation
import CoreData

@MainActor class MockServer : ObservableObject
{
    static let mockServer = MockServer()
        
    @Published var data = "podatak: \(Date())"
    var lastCleaned = Date()
        
    func generateNewDataOperation() -> Operation
    {
        return BlockOperation
        {
            print("Importing..")
            let delay : TimeInterval = 2
            let random = Int.random(in: 5..<10)
            for _ in 0..<random
            {
                self.data += "\npodatak: \(Date())"
                if delay > 0 {
                    Thread.sleep(forTimeInterval: delay)
                    print("delay")
                }
            }
            print(self.data)
            
        }
        
    }
    
    func cleanDatabaseOperation() -> Operation
    {
        return BlockOperation
        {
            print("Deleting..")
            self.data = ""
        }
    }

}

