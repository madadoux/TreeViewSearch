//
//  ViewController.swift
//  LNZTreeViewDemo
//
//  Created by Giuseppe Lanza on 07/11/2017.
//  Copyright © 2017 Giuseppe Lanza. All rights reserved.
//

import UIKit
import LNZTreeView

class CustomUITableViewCell: UITableViewCell
{
    override func layoutSubviews() {
        super.layoutSubviews();
        
        guard var imageFrame = imageView?.frame else { return }
        
        let offset = CGFloat(indentationLevel) * indentationWidth
        imageFrame.origin.x += offset
        imageView?.frame = imageFrame
    }
}


class Node: NSObject, TreeNodeProtocol {
    var identifier: String
    var isExpandable: Bool {
        return children != nil
    }
    
    var children: [Node]?
    
    init(withIdentifier identifier: String, andChildren children: [Node]? = nil) {
        self.identifier = identifier
        self.children = children
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var searchBar : UISearchBar!
    @IBOutlet weak var treeView: LNZTreeView!
    var root = Node(withIdentifier: "root")
    var searchKeyWord :String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        treeView.register(CustomUITableViewCell.self, forCellReuseIdentifier: "cell")

        treeView.tableViewRowAnimation = .right
        
        generateRandomNodes()
        treeView.resetTree()
        
        searchBar.delegate = self
    }
    
    func generateRandomNodes() {
        let depth = 3
        let rootSize = 30
        
        var root: [Node]!
        
        var lastLevelNodes: [Node]?
        for i in 0..<depth {
            guard let lastNodes = lastLevelNodes else {
                root = generateNodes(rootSize, depthLevel: i)
                lastLevelNodes = root
                continue
            }
            
            var thisDepthLevelNodes = [Node]()
            for node in lastNodes {
                guard arc4random()%2 == 1 else { continue }
                let childrenNumber = Int(arc4random()%20 + 1)
                let children = generateNodes(childrenNumber, depthLevel: i)
                node.children = children
                thisDepthLevelNodes += children
            }
            
            lastLevelNodes = thisDepthLevelNodes
        }
        
        self.root.children = root
    }
    
    func generateNodes(_ numberOfNodes: Int, depthLevel: Int) -> [Node] {
        let nodes = Array(0..<numberOfNodes).map { i -> Node in
            return Node(withIdentifier: "\(arc4random()%UInt32.max)")
        }
        
        return nodes
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dfs ( key : String , root : Node? ) -> Bool {
        if let des = root?.identifier , des.lowercased().contains(key.lowercased()) {
            return true
        }
        var isContains = false
        if let childs =  root?.children {
            for node in childs {
                isContains = (isContains || dfs ( key:key , root: node ))
            }
        }
        return isContains
    }
    
    func expandAllTree(root : Node?, expand: Bool = true) {
        if root != nil {
            if expand {
                self.treeView.expand(node: root!, inSection: 0)
            }
            else {
                self.treeView.collapse(node: root!, inSection: 0)
            }
            if let childs =  root?.children {
                for node in childs {
                    expandAllTree(root: node)
                }
            }
        }
    }
}

extension ViewController: LNZTreeViewDataSource {
    func numberOfSections(in treeView: LNZTreeView) -> Int {
        return 1
    }
    
    func treeView(_ treeView: LNZTreeView, numberOfRowsInSection section: Int, forParentNode parentNode: TreeNodeProtocol?) -> Int {
        guard let parent = parentNode as? Node else {
            return root.children!.count
        }
        
        return parent.children?.count ?? 0
    }
    
    func treeView(_ treeView: LNZTreeView, nodeForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> TreeNodeProtocol {
        guard let parent = parentNode as? Node else {
            return root.children![indexPath.row]
        }

        return parent.children![indexPath.row]
    }
    
    func treeView(_ treeView: LNZTreeView, cellForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?, isExpanded: Bool) -> UITableViewCell {
        
        let node: Node
        if let parent = parentNode as? Node {
            node = parent.children![indexPath.row]
        } else {
            node = root.children![indexPath.row]
        }
        
        let cell = treeView.dequeueReusableCell(withIdentifier: "cell", for: node, inSection: indexPath.section)

        if node.isExpandable {
            if isExpanded {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator_open")
            } else {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator")
            }
        } else {
            cell.imageView?.image = nil
        }
        
        cell.textLabel?.text = node.identifier
        
        return cell
    }
    func searchTreeFromNodeWith(searchTxt:String) {
        
        self.searchKeyWord = searchTxt
        self.treeView.resetTree()
        self.expandAllTree(root: self.root)
        
    }
}

extension ViewController: LNZTreeViewDelegate {
    func treeView(_ treeView: LNZTreeView, heightForNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> CGFloat {
        if let sk = self.searchKeyWord {
            
            if let pNodeChildren = (parentNode as? Node)?.children , pNodeChildren.count > indexPath.row {
                
                let currNode = pNodeChildren[indexPath.row]
                if (dfs(key: sk, root: currNode)) {
                    return 60
                }
                else {
                    return 0
                }
            }
        }
        return 60
    }
}

extension ViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print( searchText)
        if searchText.count > 0 {
            self.searchTreeFromNodeWith(searchTxt: searchText)
        }
        else {
            self.searchKeyWord = nil
            self.treeView.resetTree()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
