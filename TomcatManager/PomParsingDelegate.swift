//
//  PomParsingDelegate.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/4/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation


class PomParsingDelegate : NSObject, XMLParserDelegate {

    func parserDidStartDocument(_ parser: XMLParser) {
        print("parsing started")
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        print("parsing ended")
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print("<element: \(elementName)>")
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("characters : \(string)")
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("</element: \(elementName)>")
    }

}

