//
//  MessageThreadController.swift
//  Message Board
//
//  Created by Spencer Curtis on 8/7/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

class MessageThreadController {
    
    func fetchMessageThreads(completion: @escaping () -> Void) {
        
        let requestURL = MessageThreadController.baseURL.appendingPathExtension("json")
        
        // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
        if isUITesting {
            fetchLocalMessageThreads(completion: completion)
            return
        }
        
        networkLoader.loadData(from: requestURL) { (data, error) in
            if let error = error {
                NSLog("Error fetching message threads: \(error)")
                completion()
                return
            }
            
            guard let data = data else { NSLog("No data returned from data task"); completion(); return }
            
            do {
//                self.messageThreads = try JSONDecoder().decode([MessageThread].self, from: data)
                let messageThreadsDictionary = try JSONDecoder().decode([String:MessageThread].self, from: data)
                let messageThreads = messageThreadsDictionary.map { $0.value }
                self.messageThreads = messageThreads
            } catch {
                self.messageThreads = []
                NSLog("Error decoding message threads from JSON data: \(error)")
            }
            
            completion()
        }
    }
    
    func createMessageThread(with title: String, completion: @escaping () -> Void) {
        
        // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
        if isUITesting {
            createLocalMessageThread(with: title, completion: completion)
            return
        }
        
        let thread = MessageThread(title: title)
        
        let requestURL = MessageThreadController.baseURL.appendingPathComponent(thread.identifier).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        do {
            request.httpBody = try JSONEncoder().encode(thread)
        } catch {
            NSLog("Error encoding thread to JSON: \(error)")
        }
        
        //URLSession.shared.dataTask(with: request) { (data, _, error) in
        networkLoader.loadData(from: request) { (data, error) in
            if let error = error {
                NSLog("Error with message thread creation data task: \(error)")
                completion()
                return
            }
            
            self.messageThreads.append(thread)
            completion()
            
        }
    }
    
    func createMessage(in messageThread: MessageThread, withText text: String, sender: String, completion: @escaping () -> Void) {
            
            // This if statement and the code inside it is used for UI Testing. Disregard this when debugging.
            if isUITesting {
                createLocalMessage(in: messageThread, withText: text, sender: sender, completion: completion)
                return
            }
            
            guard let index = messageThreads.index(of: messageThread) else { completion(); return }
            
            let message = MessageThread.Message(text: text, sender: sender)
            messageThreads[index].messages.append(message)
            
            let requestURL = MessageThreadController.baseURL.appendingPathComponent(messageThread.identifier).appendingPathComponent("messages").appendingPathExtension("json")
            var request = URLRequest(url: requestURL)
            request.httpMethod = HTTPMethod.post.rawValue
            
            do {
                request.httpBody = try JSONEncoder().encode(message)
            } catch {
                NSLog("Error encoding message to JSON: \(error)")
            }
            
    //        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            networkLoader.loadData(from: request) { (data, error) in
            
                if let error = error {
                    NSLog("Error with message thread creation data task: \(error)")
                    completion()
                    return
                }
                completion()
            }
        }
    
    static let baseURL = URL(string: "https://lambda-message-board-74ae1.firebaseio.com/")!
    var messageThreads: [MessageThread] = []
    var networkLoader: NetworkDataLoader
    
    init(networkLoader: NetworkDataLoader = URLSession.shared) {
        self.networkLoader = networkLoader
    }
}
