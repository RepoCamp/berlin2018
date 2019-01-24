require 'darlingtonia'

class ModularImporter
  def initialize(csv_file)
    @csv_file = csv_file
    raise "Cannot find expected input file #{csv_file}" unless File.exist?(csv_file)
  end

  def import
    # start_time = Time.zone.now
    # record_importer = ActorRecordImporter.new(error_stream: @error_stream, info_stream: @info_stream)
    Darlingtonia::Importer.new(parser: Darlingtonia::CsvParser.new(file: File.open(@csv_file)), record_importer: Darlingtonia::RecordImporter.new).import
    # end_time = Time.zone.now
    # elapsed_time = end_time - start_time
  end
end
