//
//  App.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation
import OSLog

enum AccountError: Error {
    case notAuthenticated
    case invalidInstance
    case authenticationFailed(String)
}
