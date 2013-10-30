class TestLab

  # Labfile Error Class
  class LabfileError < TestLabError; end

  # Labfile Class
  #
  # @author Zachary Patten <zachary AT jovelabs DOT com>
  class Labfile < ZTK::DSL::Base
    has_many   :dependencies,  :class_name => 'TestLab::Dependency'
    has_many   :sources,       :class_name => 'TestLab::Source'
    has_many   :nodes,         :class_name => 'TestLab::Node'

    attribute  :testlab
    attribute  :config,        :default => Hash.new
    attribute  :version

    def initialize(*args)
      @ui = TestLab.ui

      @ui.logger.debug { "Loading Labfile" }
      super(*args)
      @ui.logger.debug { "Labfile '#{self.id}' Loaded" }

      if version.nil?
        raise LabfileError, 'You must version the Labfile!'
      else
        @ui.logger.debug { "Labfile Version: #{version}" }
        version_arguments = version.split
        @ui.logger.debug { "version_arguments=#{version_arguments.inspect}" }

        if version_arguments.count == 1
          compare_versions(TestLab::VERSION, version_arguments.first)
        elsif version_arguments.count == 2
          compare_versions(TestLab::VERSION, version_arguments.last, version_arguments.first)
        else
          raise LabfileError, 'Invalid Labfile version attribute!'
        end
      end
    end

    def compare_versions(version_one, version_two, comparison_operator=nil)
      v1_splat = version_one.split('.')
      v2_splat = version_two.split('.')

      max_length = [v1_splat.map(&:length).max, v2_splat.map(&:length).max].max

      v1 = v1_splat.collect{ |element| "%0#{max_length}d" % element.to_i }.join('.')
      v2 = v2_splat.collect{ |element| "%0#{max_length}d" % element.to_i }.join('.')

      @ui.logger.debug { "v1=#{v1.inspect}" }
      @ui.logger.debug { "v2=#{v2.inspect}" }
      @ui.logger.debug { "max_length=#{max_length.inspect}" }

      if comparison_operator.nil?
        invalid_version if v1 != v2
      else
        invalid_version if !v1.send(comparison_operator.to_sym, v2)
      end
    end

    def invalid_version
      raise LabfileError, "This Labfile is not compatible with this version of TestLab! (#{self.version})"
    end

    def config_dir
      self.testlab.config_dir
    end

    def repo_dir
      self.testlab.repo_dir
    end

  end

end
