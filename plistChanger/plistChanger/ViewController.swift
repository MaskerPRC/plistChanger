//
//  ViewController.swift
//  plistChanger
//
//  Created by 宋佳恒 on 2021/2/25.
//

import Cocoa

extension String {
    //返回第一次出现的指定子字符串在此字符串中的索引
    //（如果backwards参数设置为true，则返回最后出现的位置）
    func positionOf(sub:String, backwards:Bool = false)->Int {
        var pos = -1
        if let range = range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
}

protocol DestinationViewDelegate {
    func processImage(_ image: NSImage)
}

class DestinationView: NSView {
    
    var delegate: DestinationViewDelegate?
    
    override func awakeFromNib() {
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
       
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        let pasteBoard = sender.draggingPasteboard
        guard let image = NSImage(pasteboard: pasteBoard) else {
            return false
        }
        delegate?.processImage(image)
        return true
    }
}

protocol DestinationPlistViewDelegate {
    func processPlist(_ files: [URL])
}

class DestinationPlistView: NSView {
    
    let acceptTypes = ["plist"]
    var delegate: DestinationPlistViewDelegate?
    
    override func awakeFromNib() {
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var files: [URL] = []
        if let board = sender.draggingPasteboard.propertyList(forType:NSPasteboard.PasteboardType(rawValue:"NSFilenamesPboardType")) as? [String] {
            for path in board {
                let url = URL(fileURLWithPath: path)
                let fileExtension = url.pathExtension.lowercased()
                if acceptTypes.contains(fileExtension){
                    files.append(url)
                }
            }
        }
        delegate?.processPlist(files)
        return true
    }
}

class CustomCellTableViewCell: NSTableCellView {


    @IBOutlet weak var myImageView: NSImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    
    @IBOutlet weak var imgDrag: DestinationView!
    @IBOutlet weak var drop1: DestinationPlistView!
    @IBOutlet weak var table_view: NSTableView!
    @IBOutlet weak var iimg_list: NSTableView!
    
    var dataPlist: [String] = []
    var nowImgs: [NSImage] = []
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView.tag == 2 {
            return nowImgs.count;
        }
        return getData().count;
    }

    func getData() -> Array <String> {
        return dataPlist
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        configDestinationView()
        table_view.reloadData()
        iimg_list.reloadData()
    }
    
    internal func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView.tag == 2 {
            let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? CustomCellTableViewCell
            cell?.myImageView?.image = nowImgs[row]
            return cell;
        }
        else {
            let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
            let content = getData()[row];
            cell?.textField?.stringValue = content;
            return cell;
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear();
        self.view.window!.title = "Plist换皮助手";
    }
    
    private func configDestinationView() {
        drop1.delegate = self
        imgDrag.delegate = self
    }
}




extension ViewController: DestinationViewDelegate {
    
    func processImage(_ image: NSImage) {
        // tipsTextField.stringValue = String("\(Int(image.size.width))x\(Int(image.size.height))")
//        destinationImageView.image = image
        // 只要有拖动，就将拖动行为记录，放入堆栈中，异步去将堆栈行为执行
        nowImgs.append(image)
        iimg_list.reloadData()
    }
}

extension ViewController: DestinationPlistViewDelegate {
    func processPlist(_ files: [URL]) {
        // tipsTextField.stringValue = String("\(Int(image.size.width))x\(Int(image.size.height))")
        // 使用file信息，去建立可选择的左侧列表
        // 保存file的全部信息
        dataPlist = []
        for item in files {
            let articleString = item.absoluteString
            let pos = articleString.positionOf(sub: "/Resources/")
            dataPlist.append((articleString as NSString).substring(from: pos+11))
        }
        table_view.reloadData()
//        for item in files {
//            let articleString = item.absoluteString
//
//        }
    }
}
