class ModularImporter
  def initialize(csv_file)
    @csv_file = csv_file
    raise "Cannot find expected input file #{csv_file}" unless File.exist?(csv_file)
  end

  def import
    start_time = Time.zone.now
    # record_importer = ActorRecordImporter.new(error_stream: @error_stream, info_stream: @info_stream)
    # Darlingtonia::Importer.new(parser: parser, record_importer: record_importer).import if parser.validate
    end_time = Time.zone.now
    elapsed_time = end_time - start_time
  end
end
