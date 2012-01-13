require_relative '../lib/tar2rpm/build_rpm'
require_relative '../lib/tar2rpm/tar'
require_relative 'FileHelpers.rb'
require 'tmpdir'
include FileUtils
include FileHelpers

describe Tar2Rpm do

  before(:each) do
    @tar = Tar2Rpm::Tar.new("#{TEST_DIR}/simple-3.4.tar.gz")
    @rpm_metadata = build_rpm = {summary: "A simple example", description: "A simple description.", tar: @tar, arch: 'noarch'}
  end


  describe "when working with a Spec file" do

    before(:each) do
      @rpm_metadata[:top_dir] = Dir.mktmpdir
      @build_rpm = Tar2Rpm::BuildRpm.new(@rpm_metadata)
    end

    after(:each) do
      rm_rf(@build_rpm.top_dir)
    end


    it "should create a simple Spec file with the list of files in it" do
      @build_rpm.create_spec_file("#{@build_rpm.top_dir}/test.spec")

      compare_files("#{@build_rpm.top_dir}/test.spec", "#{TEST_DIR}/expected_simple.spec")
    end

  end


  describe "when creating RPM build" do
    
    describe "with missing meta-data" do
      md = {}
      
      before(:each) do
        md = @rpm_metadata
        md[:top_dir] = '/tmp/tar2rpm'
      end

      it "should catch missing top_dir" do
        md.delete(:top_dir)
        ->{Tar2Rpm::BuildRpm.new(md)}.should raise_error(ArgumentError, /top_dir/)
      end
    
      it "should catch missing tar" do
        md.delete(:tar)
        ->{Tar2Rpm::BuildRpm.new(md)}.should raise_error(ArgumentError, /tar/)
      end
    
      it "should catch tar of wrong type" do
        md[:tar] = ''
        ->{Tar2Rpm::BuildRpm.new(md)}.should raise_error(ArgumentError, /Tar2Rpm::Tar/)
      end

      it "should default the name based on the file name" do
        md.delete(:name)
        Tar2Rpm::BuildRpm.new(md).name.should == 'simple'
      end

      it "should default the version based on the file name" do
        md.delete(:version)
        Tar2Rpm::BuildRpm.new(md).version.should == '3.4'
      end

      it "should default the architecture" do
        md.delete(:arch)
        Tar2Rpm::BuildRpm.new(md).arch.should == 'noarch'
      end

      it "should default the prefix" do
        md.delete(:prefix)
        Tar2Rpm::BuildRpm.new(md).prefix.should == '/opt'
      end

      it "should default the summary" do
        md.delete(:summary)
        Tar2Rpm::BuildRpm.new(md).summary.should == 'simple-3.4'
      end

      it "should parse options for verbose" do
        md.delete(:verbose)
        Tar2Rpm::BuildRpm.new(md).verbose.should be_false

        md[:verbose] = true
        Tar2Rpm::BuildRpm.new(md).verbose.should be_true

        md[:verbose] = false
        Tar2Rpm::BuildRpm.new(md).verbose.should be_false
      end
    end
    
    it "should create the Spec and copy the tar" do
      @rpm_metadata[:top_dir] = "/tmp/tar2rpm"
      build_rpm = Tar2Rpm::BuildRpm.new(@rpm_metadata)
      build_rpm.create_build()

      dir_files(@rpm_metadata[:top_dir]).should == ["BUILD", "RPMS", "SOURCES", "SPECS", "SRPMS"]
      File.exist?("#{@rpm_metadata[:top_dir]}/SPECS/simple.spec").should be_true
      File.exist?("#{@rpm_metadata[:top_dir]}/SOURCES/simple-3.4.tar.gz").should be_true
    end

  end

end
