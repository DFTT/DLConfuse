//
//  ImagesAst.swift
//  DLConfuse
//
//  Created by 大大东 on 2021/8/2.
//  Copyright © 2021 大大东. All rights reserved.
//

import Foundation

class Test {}

class Test2: NSObject {
    func aaa() {
        let a = "普通字符串"
        let b = "包含一个\"转义字符"
        let v = "包含两个\"转义\"字符" + "" + "拼接字符串"
        
        print(a)
        print(b)
        print(v)
    }
}
