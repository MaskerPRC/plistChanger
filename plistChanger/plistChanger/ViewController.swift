//
//  ViewController.swift
//  plistChanger
//
//  Created by 宋佳恒 on 2021/2/25.
//

import Cocoa
import Foundation
import PythonKit

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
    var curSelectImgIndex = -1
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
        PythonLibrary.useVersion(2,7)
        super.viewDidLoad();
        configDestinationView()
        table_view.reloadData()
        iimg_list.reloadData()
        buildPyFile()
    }
    
    func runPythonCode(dirPath: String, plistPath:String){
            let sys = Python.import("sys")
            sys.path.append(dirPath)
            let os = Python.import("os")
            let pkgutil = Python.import("pkgutil")
        let PIL1 = Python.import("PIL")
        
        let etree = Python.import("xml.etree")
            let plistUnpack = Python.import("plistUnpack")
        let response = plistUnpack.doIt(plistPath, os, pkgutil, PIL1, etree)
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
    func setChange() {
        
        if table_view.tag == 2  {
            let index = table_view.selectedRow
            
            curSelectImgIndex = -1
            if index >= 0 {
                let item = self.dataList[index];
                imgShow.image = item.image
                return
            }
        }
        let index = table_view.selectedRow
        
        curSelectImgIndex = -1
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
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        let view: NSTableView = notification.object as! NSTableView;
        if view.tag == 2  {
            let index = view.selectedRow
            
            curSelectImgIndex = index
            if index >= 0 {
                let item = self.dataList[index];
                imgShow.image = item.image
                return
            }
        }
        let index = view.selectedRow
        
        curSelectImgIndex = -1
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
    
    override func keyDown(with theEvent: NSEvent) {
        if isDeleteKeyDownEvent(theEvent: theEvent) {
            //删除当前项
            tihuan(NSURL() as URL, true)
        }
    }
    private func isDeleteKeyDownEvent(theEvent: NSEvent) -> Bool {
        let char = theEvent.keyCode
        if char == 51 {
            return true
        }
        return false
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
                                   
                                    
                                    
                                    var newImage = NSImage()
                                        
                                    var rect = CGRect()
                                    var clipRect = NSRect()
                                    
                                    if let textureRotated = frame["rotated"] as? Bool, textureRotated {
                                        rect = CGRect(x: -x, y: y-data.size.height+width, width: data.size.width, height: data.size.height)
                                        newImage = NSImage(size: NSSize(width: height, height: width))
                                        clipRect = NSRect(x: 0, y: 0, width: height, height: width)
                                    } else {
                                        rect = CGRect(x: -x, y: y-data.size.height+height, width: data.size.width, height: data.size.height)
                                        newImage = NSImage(size: NSSize(width: width, height: height))
                                        clipRect = NSRect(x: 0, y: 0, width: width, height: height)
                                    }
//
                                    newImage.lockFocus()
                                    data.draw(in: rect)
                                    let path = NSBezierPath(rect: clipRect)
                                    path.addClip()
                                    newImage.unlockFocus()
                                    if let textureRotated = frame["rotated"] as? Bool, textureRotated {
                                        // 图片方向调换
                                        let rotateImage: NSImage = NSImage(size: NSSize(width: width, height: height))
                                        rotateImage.lockFocus()
                                        let rorate = NSAffineTransform()
                                        rorate.rotate(byDegrees: 90)
                                        rorate.concat()
                                        newImage.draw(in: CGRect(x: 0, y: -width, width: height, height: width))
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
        tihuan(imageUrl)
    }
    func tihuan(_ imageUrl: URL, _ isDelet: Bool = false) {
        // tipsTextField.stringValue = String("\(Int(image.size.width))x\(Int(image.size.height))")
//        destinationImageView.image = image
        // 只要有拖动，就将拖动行为记录，放入堆栈中，异步去将堆栈行为执行
        
//        let subImg = image.trim(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        //找到当前选中的plist图片，替换掉
        
        let indexPlist = table_view.selectedRow
        //获取plist路径
        let indexImage = curSelectImgIndex
        //被替换的png路径
        //替换png的路径
        
        
        
//        var curPlistImage =
        //解包->文件传递到解包目录替换->打包->删除原目录
        let tmpDir2 = NSHomeDirectory() + "/"
        let cwd = tmpDir2
        print("script run from:\n" + cwd)
        
        
        let sys = Python.import("sys")
          sys.path.append(cwd)
        let shutil = Python.import("shutil")
        let pkgutil = Python.import("pkgutil")
        let os = Python.import("os")
        let Image = Python.import("PIL.Image")
        let etree = Python.import("xml.etree.ElementTree")
        let plistPack = Python.import("plistPack")
        let plistUnpack = Python.import("plistUnpack")
       
        print(Python.version)
        
        
        if indexPlist != -1 {
            let plistPath = URL(string: dataPlist[indexPlist])?.path
            plistUnpack.doIt(plistPath, sys, shutil, pkgutil, os, Image, etree)
            let pos = plistPath!.positionOf(sub: ".plist")
            var UnpackPath = (plistPath as! NSString).substring(to: pos);
            let pos1 = UnpackPath.positionOf(sub: "/", backwards: true)
            var UnpackPrefixName = (UnpackPath as! NSString).substring(from: pos1+1);
            
            let fileManager = FileManager.default
            let homeDirectory = NSHomeDirectory()
           
            
            if isDelet {
                if (indexImage != -1) {
                    let toUrl = UnpackPath+"/"+dataList[indexImage].name
                    //未选中，表示要覆盖，忽略拖动文件名
                    if fileManager.fileExists(atPath: toUrl) {
                        try! fileManager.removeItem(atPath: toUrl)
                    }
                }
            }
            else {
                var file_name = NSURL(fileURLWithPath: imageUrl.path).lastPathComponent!
                let srcUrl = imageUrl.path
                if (indexImage == -1) {
                    //未选中，表示要添加
                    let toUrl = UnpackPath+"/"+UnpackPrefixName+"_"+file_name
                    if fileManager.fileExists(atPath: toUrl) {
                        try! fileManager.removeItem(atPath: toUrl)
                        try! fileManager.copyItem(atPath: srcUrl, toPath: toUrl)
                    }
                    else {
                        try! fileManager.copyItem(atPath: srcUrl, toPath: toUrl)
                    }
                } else {
                    let toUrl = UnpackPath+"/"+dataList[indexImage].name
                    //未选中，表示要覆盖，忽略拖动文件名
                    if fileManager.fileExists(atPath: toUrl) {
                        try! fileManager.removeItem(atPath: toUrl)
                        try! fileManager.copyItem(atPath: srcUrl, toPath: toUrl)
                    }
                    else {
                        try! fileManager.copyItem(atPath: srcUrl, toPath: toUrl)
                    }
                }
            }
            
            
            plistPack.doIt(UnpackPath, sys, shutil, pkgutil, os, Image, etree)
//            shell("python "+NSHomeDirectory()+"/py/plistPack.py "+plistPath!)
            //重新加载当前plist到tableview，并刷新imglistview，取消当前选中的图片。
           
            //开始下一步的替换
            
            table_view.selectRowIndexes(IndexSet(integer: indexPlist), byExtendingSelection: false)
            setChange()
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


extension ViewController {
    public func buildPyFile() {
        let msg = """
#!/usr/bin/env python
# coding: utf-8
# title: Plist打包
# filters: subfolder
# options: clear global
# order: 210
# icon: Icons/unpack.png
# submenu: remove 打包并删除文件夹
# submenu: keep 打包并保留文件夹

sys = None
shutil = None
pkgutil = None
os = None
Image = None
ElementTree = None
def Red(str):
    return "\\033[31m%s\\033[0m"%(str)
def Orange(str):
    return "\\033[33m%s\\033[0m"%(str)
def Purple(str):
    return "\\033[35m%s\\033[0m"%(str)
def Green(str):
    return "\\033[32m%s\\033[0m"%(str)

TexturePackerPath = "/Applications/TexturePacker.app/Contents/MacOS/TexturePacker"
def CheckTexturePacker():
    if not os.path.exists(TexturePackerPath):
        print Red("打包失败，没有找到TexturePacker，请将TexturePacker软件拖到”应用程序“（Applications）目录下！")
        exit(-1)

def TexturePackerPack(fullpath, outputPlist, maxSize):
    if not outputPlist:
        outputPlist = "/dev/null"
        outputPng = "/dev/null"
        redirPipe = "1>/dev/null 2>&1"
    else:
        outputPng = outputPlist.replace(".plist", ".png")
        redirPipe = ""
    cmd = (TexturePackerPath + " --smart-update " + \\
        "--texture-format png " + \\
        "--format cocos2d " + \\
        "--data \\"%s\\" " + \\
        "--sheet \\"%s\\" " + \\
        "--algorithm MaxRects " + \\
        "--maxrects-heuristics best " + \\
        "--enable-rotation " + \\
        "--scale 1 " + \\
        "--shape-padding 2 " + \\
        "--border-padding 2 " + \\
        "--max-size %d " + \\
        "--opt RGBA8888 " + \\
        "--trim " + \\
        "--size-constraints AnySize " + \\
        "\\"%s\\"/*.png %s") \\
        %(outputPlist, outputPng, maxSize, fullpath, redirPipe)
    ret = os.system(cmd)
    return ret >> 8

def GetMaxSizeOfTexture(fullpath):
    sizeArray = [256, 512, 1024, 2048]
    for size in sizeArray:
        ret = TexturePackerPack(fullpath, None, size)
        if ret == 0:
            return size

def PackTextureToPlist(fullpath):
    size = GetMaxSizeOfTexture(fullpath)
    if not size:
        print Red("打包失败，图片资源过大，无法装进2048x2048的图集里，请重新整理图集后再试")
        exit(-1)
    parentPath, dirName = os.path.split(fullpath)
    outputPlist = os.path.join(parentPath, dirName + ".plist")
    ret = TexturePackerPack(fullpath, outputPlist, size)
    return ret

def CheckFolder(fullpath):
    for name in os.listdir(fullpath):
        path = os.path.join(fullpath, name)
        if os.path.isdir(path):
            if name.startswith("."): continue
            print Red("打包失败，文件夹下含有其他文件夹，打包要求文件夹下只能含有png文件")
            exit(-1)
        else:
            if name.startswith("."):
                os.remove(path) #删除隐藏临时文件
            elif not name.endswith(".png"):
                print Red("打包失败，文件夹下含有其他类型的文件，打包要求文件夹下只能含有png类型的文件")
                exit(-1)
            elif " " in name:
                print Red("打包失败，文件名中包含空格")
                exit(-1)

def doIt(fullpath, sys1, shutil1, pkgutil1, os1, Image1, etree1):
    global Image
    global sys
    global ElementTree
    global shutil
    global pkgutil
    global os
    
    sys = sys1
    shutil = shutil1
    pkgutil = pkgutil1
    os = os1
    Image = Image1
    ElementTree = etree1
    isKeep = 1
    CheckTexturePacker()
    CheckFolder(fullpath)
    print Orange("正在打包，请稍后...")
    ret = PackTextureToPlist(fullpath)
    if ret == 0 and not False:
        shutil.rmtree(fullpath)
        print Green("打包完成，原文件夹已删除，请右键点击“Refresh”刷新目录列表！")
    else:
        print Green("打包完成，请右键点击“Refresh”刷新目录列表！")
"""
        
        let fileName = "学习笔记.text"
        let tmpDir2 = NSHomeDirectory()+"/"

        let cwd = tmpDir2
        
        let msg2 = """
#!/usr/bin/env python
# coding: utf-8
# title: Plist解包
# filters: plist
# options: clear global
# order: 210
# icon: Icons/unpack.png


sys = None
shutil = None
pkgutil = None
os = None
Image = None
ElementTree = None
def Red(str):
    return "\\033[31m%s\\033[0m"%(str)
def Orange(str):
    return "\\033[33m%s\\033[0m"%(str)
def Purple(str):
    return "\\033[35m%s\\033[0m"%(str)
def Green(str):
    return "\\033[32m%s\\033[0m"%(str)

def tree_to_dict(tree):
    d = {}
    for index, item in enumerate(tree):
        if item.tag == 'key':
            if tree[index+1].tag == 'string':
                d[item.text] = tree[index + 1].text
            elif tree[index + 1].tag == 'true':
                d[item.text] = True
            elif tree[index + 1].tag == 'false':
                d[item.text] = False
            elif tree[index+1].tag == 'dict':
                d[item.text] = tree_to_dict(tree[index+1])
    return d

def genPngFromPlist(plist_filename):
    
    file_path = plist_filename.replace('.plist', '')
    big_image = Image.open(plist_filename.replace('.plist', '.png'))
    root = ElementTree.fromstring(open(plist_filename, 'r').read())
    plist_dict = tree_to_dict(root[0])
    to_list = lambda x: x.replace('{','').replace('}','').split(',')
    for k,v in plist_dict['frames'].items():
        rectlist = to_list(v['frame'])
        width = int( rectlist[3] if v['rotated'] else rectlist[2] )
        height = int( rectlist[2] if v['rotated'] else rectlist[3] )
        box=(
            int(rectlist[0]),
            int(rectlist[1]),
            int(rectlist[0]) + width,
            int(rectlist[1]) + height,
            )
        sizelist = [ int(x) for x in to_list(v['sourceSize'])]
        rect_on_big = big_image.crop(box)
        if v['rotated']:
            rect_on_big = rect_on_big.rotate(90, 0, True)
 
        result_image = Image.new('RGBA', sizelist, (0,0,0,0))
        sourceColorRect = [ int(x) for x in to_list(v['sourceColorRect'])]
 
        sourceColorRect[2] += sourceColorRect[0]
        sourceColorRect[3] += sourceColorRect[1]
        result_image.paste(rect_on_big, sourceColorRect, mask=0)

        if not os.path.isdir(file_path):
            os.mkdir(file_path)
        outfile = (file_path+'/' + k)
        result_image.save(outfile)
    return file_path

def doIt(fullpath, sys1, shutil1, pkgutil1, os1, Image1, etree1):
    global Image
    global sys
    global ElementTree
    global shutil
    global pkgutil
    global os
    
    sys = sys1
    shutil = shutil1
    pkgutil = pkgutil1
    os = os1
    Image = Image1
    ElementTree = etree1

    if not pkgutil.find_loader("PIL"):
        print Orange("请输入Mac登录密码安装插件需要的依赖库:")
        if not os.path.exists("/usr/local/bin/pip"):
            os.system("sudo easy_install pip")
        os.system("sudo pip install Pillow")

    file_path = genPngFromPlist(fullpath)
    print Green("解包完成，已创建同名文件夹，请右键点击“Refresh”刷新目录列表！")
"""
        
        let fileManager = FileManager.default
        let path = cwd + "plistPack.py"
        let path2 = cwd + "plistUnpack.py"
        if fileManager.fileExists(atPath: cwd) {
            
        } else {
            fileManager.createFile(atPath: cwd, contents:nil, attributes:nil)
        }
        
        if fileManager.fileExists(atPath: path) {
            
        } else {
            fileManager.createFile(atPath: path, contents:nil, attributes:nil)
            try! msg.write(toFile: path, atomically: true, encoding: .utf8)
        }
        
        if fileManager.fileExists(atPath: path2) {
            
        } else {
            fileManager.createFile(atPath: path2, contents:nil, attributes:nil)
            try! msg2.write(toFile: path2, atomically: true, encoding: .utf8)
        }
    }
}
