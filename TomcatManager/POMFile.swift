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
    fileprivate(set) var artifactId : String?
    fileprivate(set) var dependencies : [PomDependency] = []

    init(path : String) {
        self.path = path
    }

    func read() throws {
        let xmlString = try String(contentsOfFile: path)

        let doc = try XMLDocument(xmlString: xmlString, options: 0)

        packaging = try doc.nodes(forXPath: "/project/packaging").first?.stringValue ?? ""
        version = try doc.nodes(forXPath: "/project/version").first?.stringValue
        finalName = try doc.nodes(forXPath: "/project/build/finalName").first?.stringValue
        artifactId = try doc.nodes(forXPath: "/project/artifactId").first?.stringValue

        let properties : [String : String] = try doc.nodes(forXPath: "/project/properties/*").asDictionary

        dependencies = try doc.nodes(forXPath: "/project/dependencies/dependency").flatMap({ (dependencyNode) -> PomDependency? in
            guard let rawDependencyInfo = dependencyNode.children?.asDictionary else { return nil }

            let dependencyInfo = rawDependencyInfo.dictMap({ (key, value) -> (String, String) in
                var useValue = value
                properties.forEach({ (propertyName, propertyValue) in
                    useValue = useValue.replacingOccurrences(of: "${\(propertyName)}", with: propertyValue)
                })
                return (key, useValue)
            })

            return PomDependency(dependencyInfo)
        })
    }

}

struct PomDependency {
    let groupId : String
    let artifactId : String
    let version : String

    init(groupId : String, artifactId : String, version : String) {
        self.groupId = groupId
        self.artifactId = artifactId
        self.version = version
    }

    init?(_ dictionary : [String : String]?) {
        guard let groupId = dictionary?["groupId"],
            let artifactId = dictionary?["artifactId"],
            let version = dictionary?["version"] else {
                return nil
        }
        self.init(groupId: groupId, artifactId: artifactId, version: version)
    }
}

extension Array where Element == XMLNode {
    var asDictionary : [String : String] {
        return self.reduce([String:String](), { (memo, node) -> [String : String] in
            var progress : [String : String] = memo
            guard let name = node.name,
                let value = node.stringValue else { return progress }
            progress[name] = value
            return progress
        })
    }
}

