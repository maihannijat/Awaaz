//
//  CustomError.swift
//  Awaaz
//
//  Created by Maihan Nijat on 2018-05-19.
//  Copyright © 2018 Sunzala Technology. All rights reserved.
//

class CustomError: Decodable {
    
    // Properties
    var errors: [String: [String]]?
    var message: String?
    
    // Static method to return errors as string
    static func getErrors(errors: [String : [String]]) -> String {
        // Make a string out of errors
        var errorString = ""
        for (_, messages) in errors {
            for message in messages {
                errorString = "\(errorString) \(message)"
            }
        }
        
        return errorString
    }
}
