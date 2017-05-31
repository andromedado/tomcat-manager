//
//  extensions.swift
//  TomcatManager
//
//  Created by Shad Downey on 5/31/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation


extension Dictionary {
    func dictMap<NewKeyType : Hashable, NewValueType>(_ mapper : ((Key, Value) -> (NewKeyType, NewValueType))) -> [NewKeyType : NewValueType] {
        let bits = self.map(mapper)
        let result : [NewKeyType : NewValueType] = bits.reduce([NewKeyType : NewValueType]()) { (memo, bit) -> [NewKeyType : NewValueType] in
            var progress : [NewKeyType : NewValueType] = memo
            progress[bit.0] = bit.1
            return progress
        }
        return result
    }
}

