#!/usr/bin/ruby
#encoding: utf-8

require 'fileutils'
require_relative 'trollop'
require 'json'
require 'pathname'


def testFileInit(file, fileName, newFileName, testdir)

    gitname = `git config user.name`.strip
    date = Time.new.strftime("%Y-%m-%d").strip
    className = newFileName.gsub(".m", "")
    testClassName = fileName.gsub(".m", "")
    # ------
    file.puts <<-EOF
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
end

if __FILE__ == $0
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
            puts "跳过#{newFile}"
            exit;
            next;
        end

        if !File.directory?(newFilePath)
            puts "生成目录#{newFilePath}"
            FileUtils.mkdir_p(newFilePath, :mode => 0777)
        end
        
        puts "newFile:#{newFile}"
        newFileHandle = File.new(newFile, "w+")

        testdir = filepath[filepath.index(dir)...]
        testFileInit(newFileHandle, fileName, newFileName, testdir)
        

        newFileHandle.close
        exit;
        # 不存在创建文件

    end

end

