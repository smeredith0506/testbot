module Testbot::Server

  class Build < MemoryModel

    def initialize(hash)
      super({ :success => true, :done => false, :results => '' }.merge(hash))
    end

    def self.create_and_build_jobs(hash)
      hash["jruby"] = (hash["jruby"] == "true") ? 1 : 0
      build = create(hash.reject { |k, v| k == 'available_runner_usage' })
      build.create_jobs!(hash['available_runner_usage'])
      build
    end

    def create_jobs!(available_runner_usage)
      groups = Group.build(self.files.split, self.sizes.split.map { |size| size.to_i },
                           Runner.total_instances.to_f * (available_runner_usage.to_i / 100.0), self.type)
      groups.each do |group|
        Job.create(:files => group.join(' '),
                   :root => self.root,
                   :project => self.project,
                   :type => self.type,
                   :build => self,
                   :jruby => self.jruby)
      end
    end

    def destroy
      Job.all.find_all { |j| j.build == self }.each { |job| job.destroy }
      super
    end

  end

end
