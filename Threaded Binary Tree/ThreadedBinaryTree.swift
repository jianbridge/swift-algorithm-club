/*
  A Threaded Binary Tree.
  Based on this club's Binary Search Tree implementation.

  Each node stores a value and two children. The left child contains a smaller
  value; the right a larger (or equal) value.
  
  Any nodes that lack either a left or right child instead keep track of their
  in-order predecessor and/or successor.

  This tree allows duplicate elements.

  This tree does not automatically balance itself. To make sure it is balanced,
  you should insert new values in randomized order, not in sorted order.
*/
public class ThreadedBinaryTree<T: Comparable> {
  private(set) public var value: T
  private(set) public var parent: ThreadedBinaryTree?
  private(set) public var left: ThreadedBinaryTree?
  private(set) public var right: ThreadedBinaryTree?

  //THREADED
  private(set) public var leftThread: ThreadedBinaryTree?
  private(set) public var rightThread: ThreadedBinaryTree?

  public init(value: T) {
    self.value = value
  }

  public convenience init(array: [T]) {
    precondition(array.count > 0)
    self.init(value: array.first!)
    for v in array.dropFirst() {
      insert(v, parent: self)
    }
  }

  public var isRoot: Bool {
    return parent == nil
  }

  public var isLeaf: Bool {
    return left == nil && right == nil
  }

  public var isLeftChild: Bool {
    return parent?.left === self
  }

  public var isRightChild: Bool {
    return parent?.right === self
  }

  public var hasLeftChild: Bool {
    return left != nil
  }

  public var hasRightChild: Bool {
    return right != nil
  }

  public var hasAnyChild: Bool {
    return hasLeftChild || hasRightChild
  }

  public var hasBothChildren: Bool {
    return hasLeftChild && hasRightChild
  }

  /* How many nodes are in this subtree. Performance: O(n). */
  public var count: Int {
    return (left?.count ?? 0) + 1 + (right?.count ?? 0)
  }
}

// MARK: - Adding items

extension ThreadedBinaryTree {
  /*
    Inserts a new element into the tree. You should only insert elements
    at the root, to make to sure this remains a valid binary tree!
    Performance: runs in O(h) time, where h is the height of the tree.
  */
  public func insert(value: T) {
    insert(value, parent: self)
  }
  
  private func insert(value: T, parent: ThreadedBinaryTree) {
    if value < self.value {
      if let left = left {
        left.insert(value, parent: left)
      } else {
        left = ThreadedBinaryTree(value: value)
        left?.parent = parent
        //THREADED
        left?.leftThread = leftThread
        left?.rightThread = parent
        leftThread = nil
      }
    } else {
      if let right = right {
        right.insert(value, parent: right)
      } else {
        right = ThreadedBinaryTree(value: value)
        right?.parent = parent
        //THREADED
        right?.rightThread = rightThread
        right?.leftThread = parent
        rightThread = nil
      }
    }
  }
}

// MARK: - Deleting items

extension ThreadedBinaryTree {
  /*
    Deletes the "highest" node with the specified value.

    Returns the node that has replaced this removed one (or nil if this was a
    leaf node). That is primarily useful for when you delete the root node, in
    which case the tree gets a new root.

    Performance: runs in O(h) time, where h is the height of the tree.
  */
  //THREADED
  public func remove(value: T) -> ThreadedBinaryTree? {
    return search(value)?.remove()
  }

  /*
    Deletes "this" node from the tree.
  */
  public func remove() -> ThreadedBinaryTree? {
    let replacement: ThreadedBinaryTree?

    if let left = left {
      if let right = right {
        replacement = removeNodeWithTwoChildren(left, right)
        //THREADED
        replacement?.leftThread = leftThread
        replacement?.rightThread = rightThread
        left.maximum().rightThread = replacement
        right.minimum().leftThread = replacement
      } else {
        // This node only has a left child. The left child replaces the node.
        replacement = left
        //THREADED
        left.maximum().rightThread = rightThread
      }
    } else if let right = right {
      // This node only has a right child. The right child replaces the node.
      replacement = right
      //THREADED
      right.minimum().leftThread = leftThread
    } else {
      // This node has no children. We just disconnect it from its parent.
      replacement = nil
      //THREADED
      if isLeftChild {
        parent?.leftThread = leftThread
      } else {
        parent?.rightThread = rightThread
      }
    }

    reconnectParentToNode(replacement)

    // The current node is no longer part of the tree, so clean it up.
    parent = nil
    left = nil
    right = nil
    //THREADED
    leftThread = nil
    rightThread = nil

    return replacement
  }

  private func removeNodeWithTwoChildren(left: ThreadedBinaryTree, _ right: ThreadedBinaryTree) -> ThreadedBinaryTree {
    // This node has two children. It must be replaced by the smallest
    // child that is larger than this node's value, which is the leftmost
    // descendent of the right child.
    let successor = right.minimum()

    // If this in-order successor has a right child of its own (it cannot
    // have a left child by definition), then that must take its place.
    successor.remove()

    // Connect our left child with the new node.
    successor.left = left
    left.parent = successor

    // Connect our right child with the new node. If the right child does
    // not have any left children of its own, then the in-order successor
    // *is* the right child.
    if right !== successor {
      successor.right = right
      right.parent = successor
    } else {
      successor.right = nil
    }

    // And finally, connect the successor node to our parent.
    return successor
  }

  private func reconnectParentToNode(node: ThreadedBinaryTree?) {
    if let parent = parent {
      if isLeftChild {
        parent.left = node
      } else {
        parent.right = node
      }
    }
    node?.parent = parent
  }
}

// MARK: - Searching

extension ThreadedBinaryTree {
  /*
    Finds the "highest" node with the specified value.
    Performance: runs in O(h) time, where h is the height of the tree.
  */
  public func search(value: T) -> ThreadedBinaryTree? {
    var node: ThreadedBinaryTree? = self
    while case let n? = node {
      if value < n.value {
        node = n.left
      } else if value > n.value {
        node = n.right
      } else {
        return node
      }
    }
    return nil
  }

  /*
  // Recursive version of search
  // Educational but undesirable due to the overhead cost of recursion
  public func search(value: T) -> ThreadedBinaryTree? {
    if value < self.value {
      return left?.search(value)
    } else if value > self.value {
      return right?.search(value)
    } else {
      return self
    }
  }
  */
  
  public func contains(value: T) -> Bool {
    return search(value) != nil
  }

  /*
    Returns the leftmost descendent. O(h) time.
  */
  public func minimum() -> ThreadedBinaryTree {
    var node = self
    while case let next? = node.left {
      node = next
    }
    return node
  }
  
  /*
    Returns the rightmost descendent. O(h) time.
  */
  public func maximum() -> ThreadedBinaryTree {
    var node = self
    while case let next? = node.right {
      node = next
    }
    return node
  }
  
  /*
    Calculates the depth of this node, i.e. the distance to the root.
    Takes O(h) time.
  */
  public func depth() -> Int {
    var node = self
    var edges = 0
    while case let parent? = node.parent {
      node = parent
      edges += 1
    }
    return edges
  }
  
  /*
    Calculates the height of this node, i.e. the distance to the lowest leaf.
    Since this looks at all children of this node, performance is O(n).
  */
  public func height() -> Int {
    if isLeaf {
      return 0
    } else {
      return 1 + max(left?.height() ?? 0, right?.height() ?? 0)
    }
  }

  /*
    Finds the node whose value precedes our value in sorted order.
  */
  public func predecessor() -> ThreadedBinaryTree<T>? {
    if let left = left {
      return left.maximum()
    } else {
      //THREADED
      return leftThread
    }
  }

  /*
    Finds the node whose value succeeds our value in sorted order.
  */
  public func successor() -> ThreadedBinaryTree<T>? {
    if let right = right {
      return right.minimum()
    } else {
      //THREADED
      return rightThread
    }
  }
}

// MARK: - Traversal

extension ThreadedBinaryTree {
  //THREADED
  public func traverseInOrderForward(@noescape visit: T -> Void) {
    var n: ThreadedBinaryTree
    n = minimum()
    while true {
      visit(n.value)
      if let successor = n.successor() {
        n = successor
      } else {
        break
      }
    }
  }

  //THREADED
  public func traverseInOrderBackward(@noescape visit: T -> Void) {
    var n: ThreadedBinaryTree
    n = maximum()
    while true {
      visit(n.value)
      if let predecessor = n.predecessor() {
        n = predecessor
      } else {
        break
      }
    }
  }
  
  public func traversePreOrder(@noescape visit: T -> Void) {
    visit(value)
    left?.traversePreOrder(visit)
    right?.traversePreOrder(visit)
  }
  
  public func traversePostOrder(@noescape visit: T -> Void) {
    left?.traversePostOrder(visit)
    right?.traversePostOrder(visit)
    visit(value)
  }

  /*
    Performs an in-order traversal and collects the results in an array.
  */
  public func map(@noescape formula: T -> T) -> [T] {
    var a = [T]()
    //THREADED
    var n: ThreadedBinaryTree
    n = minimum()
    while true {
      a.append(formula(n.value))
      if let successor = n.successor() {
        n = successor
      } else {
        break
      }
    }
    return a
  }
}

// MARK: - Verification

extension ThreadedBinaryTree {
  /*
    Is this threaded binary tree a valid binary search tree?
  */
  public func isBST(minValue minValue: T, maxValue: T) -> Bool {
    if value < minValue || value > maxValue { return false }
    let leftBST = left?.isBST(minValue: minValue, maxValue: value) ?? true
    let rightBST = right?.isBST(minValue: value, maxValue: maxValue) ?? true
    return leftBST && rightBST
  }

  /*
    Is this binary tree properly threaded?
    Either left or leftThread (but not both) must be nil (likewise for right).
    The first and last nodes in the in-order traversal are exempt from this,
    as the first has leftThread = nil, and the last has rightThread = nil.
  */
  //THREADED
  public func isThreaded() -> Bool {
    if self === minimum() {
      if left != nil && leftThread != nil {
        return false
      }
    } else if (left == nil && leftThread == nil) || (left != nil && leftThread != nil) {
      return false
    }
    if self === maximum() {
      if right != nil && rightThread != nil {
        return false
      }
    } else if (right == nil && rightThread == nil) || (right != nil && rightThread != nil) {
      return false
    }
    let leftThreaded = left?.isThreaded() ?? true
    let rightThreaded = right?.isThreaded() ?? true
    return leftThreaded && rightThreaded
  }
}

// MARK: - Debugging

extension ThreadedBinaryTree: CustomStringConvertible {
  public var description: String {
    var s = ""
    if let left = left {
      s += "(\(left.description)) <- "
    }
    s += "\(value)"
    if let right = right {
      s += " -> (\(right.description))"
    }
    return s
  }
}

extension ThreadedBinaryTree: CustomDebugStringConvertible {
  public var debugDescription: String {
    var s = "value: \(value)"
    if let parent = parent {
      s += ", parent: \(parent.value)"
    }
    if let left = left {
      s += ", left = [" + left.debugDescription + "]"
    }
    if let right = right {
      s += ", right = [" + right.debugDescription + "]"
    }
    //THREADED
    if let leftThread = leftThread {
      s += ", leftThread: \(leftThread.value)"
    }
    if let rightThread = rightThread {
      s += ", rightThread: \(rightThread.value)"
    }
    return s
  }

  public func toArray() -> [T] {
    return map { $0 }
  }
}

/*
  TESTS
  I don't have an Apple computer, so I can't make a Playground or any of that
  fancy stuff.  Here's a simple demonstration of the ThreadedBinaryTree class.
  It follows the examples in the README.
*/

// Simple little debug function to make testing output pretty
private func check(tree: ThreadedBinaryTree<Int>?) {
  if let tree = tree {
    print("\(tree.count) Total Nodes:");
    print(tree)
    print("Debug Info:")
    print(tree.debugDescription)
    print("In-Order Traversal:")
    let myArray = tree.toArray()
    for node in myArray {
      print(node)
    }
    if tree.isThreaded() {
      print("This threaded binary tree is VALID.")
    } else {
      print("This threaded binary tree is INVALID.")
    }
  } else {
    print("This tree is nil.")
  }
}


print("\nTree with Single Node")
let emptyTree = ThreadedBinaryTree<Int>(value: 1)
check(emptyTree)

print("\nFull Balanced Binary Tree with 7 Nodes")
let fullTree = ThreadedBinaryTree<Int>(value: 4)
fullTree.insert(2)
fullTree.insert(6)
fullTree.insert(1)
fullTree.insert(3)
fullTree.insert(5)
fullTree.insert(7)
check(fullTree)


print("\n\nUnbalanced Binary Tree with 5 Nodes")
let tree = ThreadedBinaryTree<Int>(array: [9, 5, 12, 2, 7])
check(tree)

print("\nInsert 10")
tree.insert(10)
check(tree)

print("\nInsert 4")
tree.insert(4)
check(tree)

print("\nInsert 15")
tree.insert(15)
check(tree)

print("\nRemove 13 (Not in the Tree)")
tree.remove(13)
check(tree)

print("\nRemove 7")
tree.remove(7)
check(tree)

print("\nRemove 5")
tree.remove(5)
check(tree)

print("\nRemove 9 (root)")
let newRoot = tree.remove(9)
check(newRoot)

print("\nRemove 12")
newRoot?.remove(12)
check(newRoot)

print("\n\nDone with Tests!\n")
