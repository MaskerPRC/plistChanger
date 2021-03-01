//
//  ViewController.swift
//  plistChanger
//
//  Created by 宋佳恒 on 2021/2/25.
//

import Cocoa
import Foundation

struct ImageItem {
    var image: NSImage
    var name: String
}
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
    func processImage(_ imageUrl: URL)
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

//        let pasteBoard = sender.draggingPasteboard
//        guard let image = NSImage(pasteboard: pasteBoard) else {
//            return false
//        }
        if let board = sender.draggingPasteboard.propertyList(forType:NSPasteboard.PasteboardType(rawValue:"NSFilenamesPboardType")) as? [String] {
            for path in board {
                let url = URL(fileURLWithPath: path)
                let fileExtension = url.pathExtension.lowercased()
                if fileExtension == "png" || fileExtension == "jpeg" {
                    delegate?.processImage(url)
                    return true
                }
            }
        }
        return false
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
    @IBOutlet weak var myTextView: NSTextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, XMLParserDelegate {

    
    @IBOutlet weak var imgDrag: DestinationView!
    @IBOutlet weak var drop1: DestinationPlistView!
    @IBOutlet weak var table_view: NSTableView!
    @IBOutlet weak var iimg_list: NSTableView!
    @IBOutlet weak var imgShow: NSImageView!
    
    var dataPlist: [String] = []
    var nowImg: NSImage = NSImage()
    var nowImgs: [NSImage] = []
    var dataList: [ImageItem] = []
    var plistData: NSDictionary = [:]
    var imageData: NSImage?
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView.tag == 2 {
            //根据当前选中的plist文件，获取图片个数
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
            cell?.myTextView?.stringValue = dataList[row].name
            return cell;
        }
        else {
            let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
            let content = getData()[row];
            let pos = content.positionOf(sub: "/Resources/")
            cell?.textField?.stringValue = (content as NSString).substring(from: pos+11);
            return cell;
        }
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        let view: NSTableView = notification.object as! NSTableView;
        if view.tag == 2  {
            let index = view.selectedRow
            let item = self.dataList[index];
            imgShow.image = item.image
            return
        }
        let index = view.selectedRow
        if index > -1 {
            let fileUrl = self.dataPlist[index];
            let pos = fileUrl.positionOf(sub: ".plist")
            var imgFilePath = (fileUrl as NSString).substring(to: pos);
            imgFilePath += ".png";
            
            parseImage(url: URL(string: imgFilePath)!)
            parsePlist(url: URL(string: fileUrl)!)
            nowImgs = []
            plitImage()
            
            
            iimg_list.reloadData()
        }
        else {
            nowImgs = []
            iimg_list.reloadData()
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
    
    func parseImage(url: URL) {
            imageData = NSImage(contentsOf: url)
        }
        
    
    func parsePlist(url: URL) {
           if let data = NSDictionary(contentsOf: url) {
               plistData = data
           }
       }
       
    
    func plitImage() {
            if let data = imageData {
                //MARK: 解析cocoa2d-x类型的plist
                if let frames = plistData["frames"] as? NSDictionary {
                    dataList.removeAll()
                    for key in frames.allKeys {
                        if let frame = frames[key] as? NSDictionary {
                            if let textureRect = (frame["frame"] != nil ? frame["frame"] : frame["textureRect"]) as? String {
                                let list = textureRect.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(separator: ",")
                                if list.count >= 4, let name = key as? String {
                                    let x = CGFloat(NSString(string: String(list[0])).floatValue)
                                    let y = CGFloat(NSString(string: String(list[1])).floatValue)
                                    let width = CGFloat(NSString(string: String(list[2])).floatValue)
                                    let height = CGFloat(NSString(string: String(list[3])).floatValue)
                                    let newImage: NSImage = NSImage(size: NSSize(width: width, height: height))
                                    let clipRect = NSRect(x: 0, y: 0, width: width, height: height)
                                    let rect = CGRect(x: -x, y: y-data.size.height+height, width: data.size.width, height: data.size.height)
                                    newImage.lockFocus()
                                    data.draw(in: rect)
                                    let path = NSBezierPath(rect: clipRect)
                                    path.addClip()
                                    newImage.unlockFocus()
                                    if let textureRotated = frame["textureRotated"] as? Bool, textureRotated {
                                        // 图片方向调换
                                        let rotateImage: NSImage = NSImage(size: NSSize(width: height, height: width))
                                        rotateImage.lockFocus()
                                        let rorate = NSAffineTransform()
                                        rorate.rotate(byDegrees: 90)
                                        rorate.concat()
                                        newImage.draw(in: CGRect(x: 0, y: -height, width: width, height: height))
                                        rotateImage.unlockFocus()
                                    
                                        nowImgs.append(rotateImage)
                                        dataList.append(ImageItem(image: rotateImage, name: name))
                                    } else {
                                        
                                            nowImgs.append(newImage)
                                        dataList.append(ImageItem(image: newImage, name: name))
                                    }
                                }
                            }
                        }
                    }
                    //MARK: 解析SpriteKit类型的plist
                } else if let images = plistData["images"] as? NSArray {
                    for image in images {
                        if let imageDict = image as? NSDictionary {
                            if let subimages = imageDict["subimages"] as? NSArray {
                                dataList.removeAll()
                                for subimage in subimages {
                                    if let subDict = subimage as? NSDictionary {
                                        if let textureRect = subDict["textureRect"] as? String {
                                            let list = textureRect.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(separator: ",")
                                            if list.count >= 4, let name = subDict["name"] as? String {
                                                let x = CGFloat(NSString(string: String(list[0])).floatValue)
                                                let y = CGFloat(NSString(string: String(list[1])).floatValue)
                                                let width = CGFloat(NSString(string: String(list[2])).floatValue)
                                                let height = CGFloat(NSString(string: String(list[3])).floatValue)
                                                let newImage: NSImage = NSImage(size: NSSize(width: width, height: height))
                                                let clipRect = NSRect(x: 0, y: 0, width: width, height: height)
                                                let rect = CGRect(x: -x, y: y-data.size.height+height, width: data.size.width, height: data.size.height)
                                                newImage.lockFocus()
                                                data.draw(in: rect)
                                                let path = NSBezierPath(rect: clipRect)
                                                path.addClip()
                                                newImage.unlockFocus()
                                                if let textureRotated = subDict["textureRotated"] as? Bool, textureRotated {
                                                    // 图片方向调换
                                                    let rotateImage: NSImage = NSImage(size: NSSize(width: height, height: width))
                                                    rotateImage.lockFocus()
                                                    let rorate = NSAffineTransform()
                                                    rorate.rotate(byDegrees: 90)
                                                    rorate.concat()
                                                    newImage.draw(in: CGRect(x: 0, y: -height, width: width, height: height))
                                                    rotateImage.unlockFocus()
                                                    
                                                    
                                                        nowImgs.append(rotateImage)
                                                    dataList.append(ImageItem(image: rotateImage, name: name))
                                                } else {
                                                    
                                                        nowImgs.append(newImage)
                                                    dataList.append(ImageItem(image: newImage, name: name))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
//
//    private func getAllImagePlist() -> [NSImage] {
//        let imgs: [NSImage] = []
//        if let path = Bundle.main.path(forResource: "apps", ofType: "plist"),
//               let root = (NSArray(contentsOfFile: path))
//           {
//               let url = NSURL(string: path)
//               let data = NSData(contentsOf: url! as URL)
//               if let imageData = crop
//           }
//        }
//    }
}


@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

extension ViewController: DestinationViewDelegate {
    
    func processImage(_ imageUrl: URL) {
        // tipsTextField.stringValue = String("\(Int(image.size.width))x\(Int(image.size.height))")
//        destinationImageView.image = image
        // 只要有拖动，就将拖动行为记录，放入堆栈中，异步去将堆栈行为执行
        
//        let subImg = image.trim(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        //找到当前选中的plist图片，替换掉
        
        let indexPlist = table_view.selectedRow
        //获取plist路径
        let indexImage = iimg_list.selectedRow
        //被替换的png路径
        //替换png的路径
//        var curPlistImage =
        //解包->文件传递到解包目录替换->打包->删除原目录
        if indexPlist != -1 && indexImage != -1 {
            var plistPath = URL(string: dataPlist[indexPlist])?.path
//            var plistFolderPath = URL(string: dataPlist[indexPlist])?.path
            shell("python "+NSHomeDirectory()+"/py/plistUnpack.py "+plistPath!)
            shell("ls")
            //重新加载当前plist到tableview，并刷新imglistview，取消当前选中的图片。
            
            //开始下一步的替换
            
            table_view.reloadData()
            table_view.selectRowIndexes(IndexSet(integer: indexPlist), byExtendingSelection: false)
//            nowImgs = []
//            iimg_list.reloadData()
            imgShow.image = NSImage()
        }
        
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
            dataPlist.append(articleString as String)
        }
        table_view.reloadData()
//        for item in files {
//            let articleString = item.absoluteString
//
//        }
    }
}



extension NSImage {
    // 截取部分图片
//    func imageAtRect(rect: NSRect) -> NSImage{
//        let newSize = NSSize(width: rect.width, height: rect.height)
//        let newImage = NSImage(size: newSize, flipped: true, drawingHandler: { (rect) -> Bool in
//            self.draw(in: rect)
//            return true
//        })
//
//        return newImage
//    }
//
        // The height of the image.
       var height: CGFloat {
           return size.height
       }
       
       // The width of the image.
       var width: CGFloat {
           return size.width
       }
       
    
//    func resize(withSize targetSize: NSSize, x: CGFloat, y: CGFloat) -> NSImage? {
//        let frame = NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
//          guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
//              return nil
//          }
//          let image = NSImage(size: targetSize, flipped: false, drawingHandler: { Bool in
//              return representation.draw(in: frame)
//          })
//
//          return image
//      }
//    func resizeMaintainingAspectRatio(withSize targetSize: NSSize, x: CGFloat, y: CGFloat) -> NSImage? {
//            let newSize: NSSize
//            let widthRatio  = targetSize.width / self.width
//            let heightRatio = targetSize.height / self.height
//
//            if widthRatio > heightRatio {
//                newSize = NSSize(width: floor(self.width * widthRatio),
//                                 height: floor(self.height * widthRatio))
//            } else {
//                newSize = NSSize(width: floor(self.width * heightRatio),
//                                 height: floor(self.height * heightRatio))
//            }
//            return self.resize(withSize: newSize, x: 0, y: 0)
//        }
    
    func trim(rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()

        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)

        result.unlockFocus()
        return result
    }
    
//    func crop(toSize targetSize: NSSize, x: CGFloat, y: CGFloat) -> NSImage? {
//           guard let resizedImage = self.resizeMaintainingAspectRatio(withSize: targetSize, x: x, y: y) else {
//               return NSImage()
//           }
//           let frame = NSRect(x: -50, y: -50, width: 100, height: 100)
//
//           guard let representation = resizedImage.bestRepresentation(for: frame, context: nil, hints: nil) else {
//               return nil
//           }
//////
//        let image = NSImage(size: NSSize(width: 200, height: 200), flipped: false, drawingHandler: { (destinationRect: NSRect) -> Bool in
//                return representation.draw(in: destinationRect)
//           })
////
//           return image
//       }
}
