module TogoMapper
  module D2rq
    class TurtleGeneratorJob
      @queue = :d2rq_turtle_generator_r5

      class << self
        def perform(work_id, data_dir, tmp_dir, generation_id = nil)
          generator = TogoMapper::D2rq::TurtleGenerator.new(work_id, data_dir, tmp_dir, generation_id)
          generator.generate
        end
      end

    end
  end
end
