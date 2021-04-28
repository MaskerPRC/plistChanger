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
    return "\033[31m%s\033[0m"%(str)
def Orange(str):
    return "\033[33m%s\033[0m"%(str)
def Purple(str):
    return "\033[35m%s\033[0m"%(str)
def Green(str):
    return "\033[32m%s\033[0m"%(str)

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
