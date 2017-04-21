//
//  POMFile.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/21/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation

class POMFile {

    let path : String

    fileprivate(set) var packaging : String?
    fileprivate(set) var version : String?
    fileprivate(set) var finalName : String?

    init(path : String) {
        self.path = path
    }

    func read() throws {
        let xmlString = try String(contentsOfFile: path)

        let doc = try XMLDocument(xmlString: xmlString, options: 0)

        packaging = try doc.nodes(forXPath: "//packaging").first?.stringValue ?? ""
        version = try doc.nodes(forXPath: "//version").first?.stringValue
        finalName = try doc.nodes(forXPath: "//finalName").first?.stringValue
    }

}

