
require 'rubygems'

begin
  require 'fastercsv'
rescue LoadError
end

begin
  require 'parseexcel'
  require 'tempfile'
rescue LoadError
end

module ActiveSheet

  def self.available_parsers
    result = []
    ObjectSpace.each_object(Class) { |klass| result << klass if klass < ActiveSheet::AbstractParser }
    result
  end
  
  class AbstractParser
    
    # Load and parse the file, returns an array of arrays
    def load(filename, options = {})
      File.open(filename, "r") do |f|
        return parse(f.read, options)
      end      
    end
    
    # Returns an array of arrays
    def parse(data, options = {})
      raise NotImplementedError
    end
    
  end
  
  class CsvParser < AbstractParser
    
    # Accepts options <tt>:field_separator</tt> and <tt>:row_separator</tt>
    def parse(data, options = {})
      fs = options[:field_separator]
      rs = options[:row_separator]
      CSV.parse(data, fs, rs)
    end
    
  end
  
  if Object.const_defined?("FasterCSV")
  
    class FasterCsvParser < AbstractParser
    
      # Accepts options <tt>:field_separator</tt> and <tt>:row_separator</tt>
      def parse(data, options = {})
        opts = {}
        opts[:col_sep] = options[:field_separator] if options[:field_separator]
        opts[:row_sep] = options[:row_separator]   if options[:row_separator]
        FasterCSV.parse(data, opts)
      end
       
    end
    
  end # FasterCSV
  
  if Object.const_defined?("Spreadsheet") 
  
    class ExcelParser < AbstractParser
    
      def load(filename, options = {})
        sheet_number = options[:worksheet] || 0
        workbook = Spreadsheet::ParseExcel.parse(filename) 
        worksheet = workbook.worksheet(sheet_number) 
        rows = []
        worksheet.each do |row| 
          rows << row.map { |c| c.to_s }
        end
        rows
      end
      
      def parse(data, options = {})
        f = Tempfile.new(options[:tempfile_name] || "activesheet-xls", options[:tempfile_dir] || Dir::tmpdir)
        load(f.path)
      ensure
        f.close
      end
       
    end
  
  end # Spreadsheet
  
  class FixedWidthParser < AbstractParser
    
    # Requires option <tt>:width</tt>, accepting an array of numbers specifying the width (in number of single byte characters) of each column
    def parse(data, options = {})
      raise ArgumentError.new("FixedWidthParser requires the option :widths") unless widths = options[:widths]
      rs = options[:row_separator] || "\n"
      rows = []
      data.split(rs).each do |line|
        offset = 0
        row = []
        widths.each_with_index do |w, i|
          row << ((s = line[offset,w]) ? s.strip : '')
          offset += w
        end
        rows << row
      end
      rows
    end
    
  end
  
end