#!/usr/bin/ruby
#encoding: utf-8

require 'fileutils'
require_relative 'trollop'
require 'json'
require 'pathname'
require 'xcodeproj'

## 查询正则项第一个所在行
def findGrepStringLine(filePath, grepString) 
    result = `cat #{filePath} | grep -n -e "#{grepString}"`
    return result.split(":").first.to_i
end

# 替换文件中的关键字
def replaceContent(file, afterContent, replaceContent) 
    findImplementation = findGrepStringLine(file, afterContent)
    if findImplementation == 0 then return; end

    oldfileHandle = File.new(file, 'r')
    tmpFile = file + ".tmp"
    oldfileReplaceHandle = File.new(tmpFile, 'w')
    puts findImplementation
    lineNum = 0
    oldfileHandle.each do |line|
        lineNum += 1
        oldfileReplaceHandle.puts line
        if lineNum == findImplementation
            puts "行数:#{lineNum}, #{line}"
            oldfileReplaceHandle.puts replaceContent
        end
    end
    oldfileHandle.close
    oldfileReplaceHandle.close
    `mv #{tmpFile} #{file}`
end

def testFileInit(newFile, oldfile, newFileName, testdir)
    newFileHandle = File.new(newFile, "w+")
    oldFileName = oldfile.split("/").last
    gitname = `git config user.name`.strip
    date = Time.new.strftime("%Y-%m-%d").strip
    className = newFileName.gsub(".m", "")
    testClassName = oldFileName.gsub(".m", "")

    #--- 检查是否有init函数
    findInitFunc = findGrepStringLine(oldfile, "-[ ]*(instancetype)[ ]*init[ ]*{")
    findImplementation = findGrepStringLine(oldfile, "@implementation[ ]*#{testClassName}")

    if findInitFunc == 0 && findImplementation > 0
        # 如果没有找到, 插入init函数
        # File.open(oldfile, 'w') {|file| file.puts replace}
        replaceContent = <<-EOF
\n//-- autobuild init --//
- (instancetype)init {
    self = [super init];
    return self;
}
//-- autobuild init end --//
                EOF

        replaceContent(oldfile, "@implementation[ ]*#{testClassName}", replaceContent)
#         oldfileHandle = File.new(oldfile, 'r+')
#         tmpFile = oldfile + ".tmp"
#         oldfileReplaceHandle = File.new(tmpFile, 'w')
#         lineNum = 0
#         oldfileHandle.each do |line|
#             lineNum += 1
#             oldfileReplaceHandle.puts line
#             if lineNum == findImplementation
#                 puts "行数:#{lineNum}, #{line}"

#                 oldfileReplaceHandle.puts <<-EOF
# \n//-- autobuild init --//
# - (instancetype)init {
#     self = [super init];
#     return self;
# }
# //-- autobuild init end --//
#                 EOF
#             end
            
#         end
#         oldfileHandle.close
#         oldfileReplaceHandle.close
#         `mv #{tmpFile} #{oldfile}`
    end

    # ------
    newFileHandle.puts <<-EOF
//
//  #{newFileName}
//  live4iphoneTests
//
//  Created by #{gitname} on #{date}.
//  Copyright © #{date} Tencent Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCHamcrest/OCHamcrest.h>
#import "#{testClassName}.h"

@interface #{className} : XCTestCase

@end

@implementation #{className}

- (void)testInit {
    /*
    CaseAdditionInfo start
    {
    "FT = 终端-开发1组",
    "模块 = #{testdir}",
    "功能 = 测试类的初始化",
    "测试分类 = 功能",
    "测试阶段 = 全用例",
    "管理者 = #{gitname}",
    "用例等级 = P0",
    "用例类型 = 5",
    "被测函数 = init",
    "用例描述 =  测试初始化函数",
    "版本 = 815"
    }
    CaseAdditionInfo end
    **/
    #{testClassName} *objc = [[#{testClassName} alloc] init];
    XCTAssertNotNil(objc, @"#{testClassName} 初始化不该为空");
    assertThat(@([objc isEqual:[[#{testClassName}  alloc] init]]), equalTo(@(NO)));
    assertThat(@([objc isEqual:objc]), equalTo(@(YES)));
}

//--- TODO:autotest待补充 ---//
//--- end ---//
@end
    EOF
    newFileHandle.close
end

def addFilesToGroup(project_path)
    # project = Xcodeproj::Project.open(project_path)
    # target = project.targets.first
    # filePath = "./qqlive4iphone/VBHttpNetworkRequestConfig-Imp/QLHttpRequestNacHelper.m"

    # group_path = File.join("CommonProject", "SVGKit", "usr", "asc", "xx")
    # puts "group_path:#{group_path}"
    # fatherGroup = project.main_group.find_subpath(group_path, true)
    # fatherGroup.set_source_tree('<group>')
    # fatherGroup.set_path("xxx2")

    # puts "fatherGroup:#{fatherGroup}"
    # 过滤目录和.DS_Store文件
    # if !File.directory?(filePath) && entry != ".DS_Store" then
        # 特殊逻辑

        # 向group中增加文件引用
        # fileReference = fatherGroup.new_reference(filePath)
        # # 如果不是头文件则继续增加到Build Phase中，PB文件需要加编译标志
        # if filePath.to_s.end_with?("pbobjc.m", "pbobjc.mm") then
        #     target.add_file_references([fileReference], '-fno-objc-arc')
           
        # elsif filePath.to_s.end_with?(".m", ".mm", ".cpp") then
        #     target.source_build_phase.add_file_reference(fileReference, true)
        #     puts "m"
        # elsif filePath.to_s.end_with?(".plist") then
        #     target.resources_build_phase.add_file_reference(fileReference, true)
        # end
        # exit;
end

if __FILE__ == $0
    # addFilesToGroup("./qqlive4iphone/live4iphone.xcodeproj")
    opts = Trollop::options do
        opt :dir, 'Path for xcresult file', :type => :string
        opt :aim_dir, 'Path for xcresult file', :type => :string
    end

    dir = if opts[:dir].nil? then "qqlive4iphone/Classes" else opts[:dir] end
    aim_dir = if opts[:aim_dir].nil? then "qqlive4iphone/live4iphoneTests/Classes" else opts[:aim_dir] end


    all_file = Dir.glob(File.join(dir, "**/*.[m|mm]"))
    all_file.each do |file|
        
        pathname =  Pathname.new(File.dirname(file))
        filepath = pathname.realdirpath.to_s
        fileName = file.split("/").last

        puts pathname
        if fileName.to_s().end_with?('.h')
            next;
        end

        newFile = file.gsub(dir, aim_dir).gsub(".m", "Tests.m")
        newFilePath = filepath.gsub(dir, aim_dir)
        newFileName = fileName.to_s().gsub(dir, aim_dir).gsub(".m", "Tests.m")
        puts "\n\n--- #{file} to #{newFile} ---"

        # 文件是否已经存在
        fileHasCreate = FileTest::exists?(newFile)
        if fileHasCreate
            # 存在就跳过
            puts "跳过已存在文件#{newFile}"
            exit;
            next;
        end

        if newFile.include?("+")
            # 文件包含+号，是扩展
            puts "跳过扩展#{newFile}"
            next;
        end

        if !File.directory?(newFilePath)
            puts "生成目录#{newFilePath}"
            FileUtils.mkdir_p(newFilePath, :mode => 0777)
        end
        
        puts "newFile:#{newFile}"
        

        testdir = filepath[filepath.index(dir)...]
        testFileInit(newFile, file, newFileName, testdir)
        exit;
        # 不存在创建文件

    end

end

