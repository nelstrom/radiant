require File.dirname(__FILE__) + "/../../../spec_helper"
require 'radiant/extension/script'

describe "Radiant::Extension::Script" do
  it "should determine which subscript to run" do
    Radiant::Extension::Script::Install.should_receive(:new)
    Radiant::Extension::Script.execute ['install']

    Radiant::Extension::Script::Uninstall.should_receive(:new)
    Radiant::Extension::Script.execute ['uninstall']
  end

  it "should pass the command-line args to the subscript" do
    Radiant::Extension::Script::Install.should_receive(:new).with(['page_attachments'])
    Radiant::Extension::Script.execute ['install', 'page_attachments']
  end
end

describe "Radiant::Extension::Script::Util" do
  include Radiant::Extension::Script::Util
  
  it "should determine an extension name from a camelized string" do
    to_extension_name("PageAttachments").should == 'page_attachments'
  end
  
  it "should determine an extension name from a hyphened name" do
    to_extension_name("page-attachments").should == 'page_attachments'
  end
  
  it "should determine an extension name from an underscored name" do
    to_extension_name("page_attachments").should == 'page_attachments'
  end
  
  it "should determine extension paths" do
    # Bad coupling, but will work by default
    extension_paths.should be_kind_of(Array)
    extension_paths.should include("#{RADIANT_ROOT}/vendor/extensions/archive")
  end
  
  it "should determine whether an extension is installed" do
    # Bad coupling, but will work by default
    self.extension_name = 'archive'
    self.should be_installed
  end
  
  it "should load all extensions from the web service" do
    Registry::Extension.should_receive(:find).with(:all).and_return([1,2,3])
    load_extensions.should == [1,2,3]
  end
  
  it "should find an extension of the given name from the web service" do
    @ext_mock = mock("Extension", :name => 'page_attachments')
    should_receive(:load_extensions).and_return([@ext_mock])
    self.extension_name = 'page_attachments'
    find_extension.should == @ext_mock
  end
end

describe "Radiant::Extension::Script::Install" do
  
  before :each do
    @extension = mock('Extension', :install => true, :name => 'page_attachments')
    Registry::Extension.stub!(:find).and_return([@extension])
  end
  
  it "should read the extension name from the command line" do
    @install = Radiant::Extension::Script::Install.new ['page_attachments']
    @install.extension_name.should == 'page_attachments'
  end

  it "should attempt to find the extension and install it" do
    @extension.should_receive(:install).and_return(true)
    @install = Radiant::Extension::Script::Install.new ['page_attachments']    
  end
  
  it "should fail if an extension name is not given" do
    lambda { Radiant::Extension::Script::Install.new []}.should raise_error
  end
end

describe "Radiant::Extension::Script::Uninstall" do
  
  before :each do
    @extension = mock('Extension', :uninstall => true, :name => 'archive')
    Registry::Extension.stub!(:find).and_return([@extension])
  end
  
  it "should read the extension name from the command line" do
    @uninstall = Radiant::Extension::Script::Uninstall.new ['archive']
    @uninstall.extension_name.should == 'archive'
  end
  
  it "should attempt to find the extension and uninstall it" do
    @extension.should_receive(:uninstall).and_return(true)
    @uninstall = Radiant::Extension::Script::Uninstall.new ['archive']
  end
  
  it "should fail if an extension name is not given" do
    lambda { Radiant::Extension::Script::Uninstall.new []}.should raise_error
  end
end