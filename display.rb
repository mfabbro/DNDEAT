module Display
  ALPHANUMERIC_FIELD = Regexp.new(/^[0-9a-zA-Z]*/)
  NUMERIC_FIELD      = Regexp.new(/^[0-9]*$/)
  SCREEN_WIDTH       = 85

  class Pause
    def initialize
      STDIN.getc
    end
  end

  class Table
    @cols = []
    @sort = ''
    def initialize(cols, sortby)
      @cols     = cols
      @sortby   = sortby
      @rows     = []
    end
    def row!(values)
      @rows << values 
    end
    def display!
      if @rows.any?
        col_widths = []
        @cols.each do |c|
          col_widths << c.length
        end
       # Determine table column widths 
        @rows.each do |r|
          @cols.length.times do |c|
            if col_widths[c] < r[c].length
              col_widths[c] = r[c].length
            end
          end
        end

        # Make Table Header
        output = ""
        @cols.length.times do |c|
          col_widths[c] = col_widths[c]+3
          output << @cols[c].center(col_widths[c]).chomp 
          output << "|"
        end
        output << "\n"

        # Sort Rows
        @sortby.each do |id, type|
          sortindex = @cols.index(id)
          @rows.each do |r|
            if r[sortindex].nil? and type.eql? NUMERIC_FIELD
              r[sortindex] = 0
            elsif r[sortindex].nil? and type.eql? ALPHANUMERIC_FIELD
              r[sortindex] = ''
            end
          end
        end
        @rows.sort! do |x,y|
          a = []
          b = []
          @sortby.each do |id, type|
            sortindex = @cols.index(id)
            case type
            when :numeric
              a << y[sortindex].to_i 
              b << x[sortindex].to_i
            when :alphanumeric
              a << y[sortindex]
              b << x[sortindex]
            end
          end
          a <=> b
        end

        # Make Table Rows
        @rows.each do |r|
          @cols.length.times do |c|
            output << r[c].center(col_widths[c]).chomp     
            output << "|"
          end
          output << "\n"
        end
        system('clear')
        print output
        return output
      else
        return ''
      end
    end
  end
  #
  # Menu Select Prompt
  #
  class MenuPrompt
    def initialize(title, screencap='')  
      @screencapture = screencap
      @promptdata    = []
      @title         = title
    end
    def add!(id)
      @promptdata << {:id=>id}
    end
    def prompt!
      output = []
      #Prompt user and check each type as it is returned
      begin
      system('clear')
        screencapture = @screencapture.dup
        unless @title.empty?
          screencapture << "-"*SCREEN_WIDTH << "\n" unless @screencapture.empty?
          screencapture << "  #{@title}\n"
          screencapture << '-'*(@title.length + 4) + "\n"
        end
        @promptdata.each_with_index do |r, i|
          screencapture << "#{i.to_s.rjust(2, ' ')}. #{r[:id]}\n"
        end
        print screencapture
        select = Readline.readline('Select Menu Item: ', false)
        if select.empty?
        elsif select.to_i < @promptdata.length
          return @promptdata[select.to_i][:id]
        end
      end while select.to_i >= @promptdata.length and  @promptdata.length != 0
    end
   end

  #
  # Get Attributes Prompt
  #
  class GetAttribPrompt
    def initialize(title, sep=':')  
      @sep = sep
      @promptdata = []
      @title = title
    end
    def add!(id, type, required)
      @promptdata << {:id=>id, :fieldtype=>type, :needed=>required}
    end
    def prompt!
      # Find widest prompt string
      strwidth = 0
      colwidth = @promptdata.each do |r|
        strwidth = r[:id].length unless strwidth > r[:id].length
      end
      # Right-justify all strings so they align
      @promptdata.each {|r| r[:id] = r[:id].rjust(strwidth+1, ' ')}

			screencapture = ''
      unless @title.empty?
        #screencapture << "-"*SCREEN_WIDTH << "\n"
        screencapture << "  #{@title}\n"
        screencapture << '-'*(@title.length + 4) + "\n"
      end
      output = []
      #Prompt user and check each type as it is returned
      @promptdata.each do |r|
        val = ''
        begin
          system('clear')
          print screencapture
          val = Readline.readline("#{r[:id]}#{@sep} ",false)   
        end while (not r[:fieldtype].match(val)) or (/^$/.match(val) and r[:needed])  
        output << {:id=>r[:id].strip,:val=>val,:fieldtype=>r[:fieldtype]} 
        screencapture << "#{r[:id]}#{@sep} #{val}\n"
      end
      return output
    end
  end

  #
  # Edit Attributes Prompt
  #
  class EditAttribPrompt
    def initialize(title, sep=':')  
      @sep = sep
      @promptdata = []
      @title = title
    end
    def add!(id, type, val='') 
      @promptdata << {:id=>id, :fieldtype=>type, :val=>val.to_s}
    end
    def prompt!
      # Find widest prompt string
      strwidth = 0
      colwidth = @promptdata.each do |r|
        strwidth = r[:id].length unless strwidth > r[:id].length
      end
      # Right-justify all strings so they align
      @promptdata.each {|r| r[:id] = r[:id].rjust(strwidth+1, ' ')}

      output = []
      #Prompt user and check each type as it is returned
      begin
        system('clear')
        screencapture = ''
        unless @title.empty?
          #screencapture << "-"*SCREEN_WIDTH << "\n"
          screencapture << "  #{@title}\n"
          screencapture << '-'*(@title.length + 4) + "\n"
        end
        @promptdata.each_with_index do |r, i|
          screencapture << "#{i.to_s}. #{r[:id]}#{@sep} #{r[:val]}\n"
        end
        print screencapture
        select = Readline.readline('Select Attribute: ', false)
        if select.empty?
          select = @promptdata.length + 1
        elsif select.to_i < @promptdata.length
          val = ''
          begin
            Readline::HISTORY.push @promptdata[select.to_i][:val]
            val = Readline.readline("#{@promptdata[select.to_i][:id].strip}#{@sep} ", true)
          end while (not @promptdata[select.to_i][:fieldtype].match(val)) or (/^$/.match(val))
          @promptdata[select.to_i][:val] = val
        end
      end while select.to_i < @promptdata.length and @promptdata.length != 0
      @promptdata.each {|r| r[:id] = r[:id].gsub(/^\s*/, '')}
      return @promptdata
    end
  end
end
