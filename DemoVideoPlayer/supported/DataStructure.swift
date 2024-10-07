//
//  DataStructure.swift
//  DemoVideoPlayer
//
//  Created by TaHoangMinh on 7/10/24.
//

import Foundation

class LinkedList<T> {
    var head: Node<T>?
    var tail: Node<T>?
    
    var count: Int = 0
    
    func append(_ value: T) {
        let newNode = Node(value: value)
        if let tailNode = tail {
            tailNode.next = newNode
        } else {
            head = newNode
        }
        tail = newNode
        count += 1
    }
    
    func removeFirst() -> T? {
        guard let headNode = head else { return nil }
        head = headNode.next
        if head == nil {
            tail = nil
        }
        count -= 1
        return headNode.value
    }
}

class Node<T> {
    let value: T
    var next: Node<T>?
    
    init(value: T) {
        self.value = value
    }
}

