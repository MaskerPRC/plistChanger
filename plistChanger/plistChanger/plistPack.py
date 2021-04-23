#!/usr/bin/env python
# coding: utf-8
# title: Plist打包
# filters: subfolder
# options: clear global
# order: 210
# icon: Icons/unpack.png
# submenu: remove 打包并删除文件夹
# submenu: keep 打包并保留文件夹


def Red(str):
    return "\033[31m%s\033[0m"%(str)
def Orange(str):
    return "\033[33m%s\033[0m"%(str)
def Purple(str):
    return "\033[35m%s\033[0m"%(str)
def Green(str):
    return "\033[32m%s\033[0m"%(str)

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
    cmd = (TexturePackerPath + " --smart-update " + \
        "--texture-format png " + \
        "--format cocos2d " + \
        "--data \"%s\" " + \
        "--sheet \"%s\" " + \
        "--algorithm MaxRects " + \
        "--maxrects-heuristics best " + \
        "--enable-rotation " + \
        "--scale 1 " + \
        "--shape-padding 2 " + \
        "--border-padding 2 " + \
        "--max-size %d " + \
        "--opt RGBA8888 " + \
        "--trim " + \
        "--size-constraints AnySize " + \
        "\"%s\"/*.png %s") \
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

def mmain():
    fullpath = sys.argv[1]
    isKeep = len(sys.argv) > 4 and sys.argv[4] == "keep"
    CheckTexturePacker()
    CheckFolder(fullpath)
    print Orange("正在打包，请稍后...")
    ret = PackTextureToPlist(fullpath)
    if ret == 0 and not isKeep:
        shutil.rmtree(fullpath)
        print Green("打包完成，原文件夹已删除，请右键点击“Refresh”刷新目录列表！")
    else:
        print Green("打包完成，请右键点击“Refresh”刷新目录列表！")
