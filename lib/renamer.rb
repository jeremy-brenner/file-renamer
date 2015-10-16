require 'io/console'
require 'terminal'

class Renamer
  def initialize(dir)
    @dir = dir
    @run = true
    @current = :find
    @data = {
      find: {
        string: '',
        offset: 0
      },
      replace: {
        string: '',
        offset: 0
      }
    }
    @term = Terminal::Screen.new
    main_loop
  end

  def current
    @data[@current]
  end

  def main_loop
    Dir.chdir(@dir) do
      while @run
        @l=0
        header
        list_dir
        @term.clear_from(@l+1)
        set_cursor_position
        interact
      end
    end
    @term.end
  end

  def set_cursor_position
    left = ( @current == :find ? find_header.length : replace_header.length + middle ) - current[:offset]
    @term.set_cursor_position(0,left)
  end


  def interact
    c = @term.get_input
    case
    when is_esc?(c)
      @run = false
    when c.ord == 13
      ask_commit
    when is_leftarrow?(c)
      moveleft
    when is_rightarrow?(c)
      moveright
    when c.ord == 9
      @current = @current == :find ? :replace : :find
    when c.ord == 127
      del(true)
    when is_del?(c)
      del
    when is_home?(c)
      moveleft(true)
    when is_end?(c)
      moveright(true)
    when is_escape_code?(c)
      #ignore
    else
      add_char c
    end
  end

  def is_esc?(c)
    is_escape_code?(c) && c.length == 1
  end

  def is_del?(c)
    is_escape_code?(c) && c.length == 4 && c[2..3] == '3~'
  end

  def is_home?(c)
    is_escape_code?(c) && c.length == 4 && c[2..3] == '1~'
  end

  def is_end?(c)
    is_escape_code?(c) && c.length == 4 && c[2..3] == '4~'
  end

  def is_rightarrow?(c)
    is_escape_code?(c) && c.length == 3 && c[2] == 'C'
  end

  def is_leftarrow?(c)
    is_escape_code?(c) && c.length == 3 && c[2] == 'D'
  end

  def is_escape_code?(c)
    c.ord == 27
  end

  def moveright(complete=false)
    current[:offset] = current[:offset] == 0 || complete ? 0 : current[:offset] - 1
  end

  def moveleft(complete=false)
    current[:offset] = current[:offset] == current[:string].length || complete ? current[:string].length : current[:offset] + 1
  end

  def ask_commit
    @l+=1
    @term.update(@l+=1, "Are you sure you want to commit these changes? [y/N]?" )
    case @term.get_input
    when 'y', 'Y'
      commit
    end
  end

  def commit
    Dir.glob( '*' ).each do |f|
      if f =~ /#{@data[:find][:string]}/
        file = f
        dest = f.gsub(/#{@data[:find][:string]}/,@data[:replace][:string])
        if dest != file
          File.rename(file,dest) if dest != file
          @term.update(@l+=1,"Renamed #{file} => #{dest}")
        end
      end
    end

    @run = false
  end

  def add_char(c)
    current[:string].insert(current[:string].length-current[:offset],c)
  end

  def del(backspace=false)
    return if current[:offset] == current[:string].length && backspace
    return if current[:offset] == 0 && !backspace
    current[:offset]-=1 if !backspace

    first = current[:string][0...current[:string].length-current[:offset]-1]
    second = current[:string][current[:string].length-current[:offset]..current[:string].length-1]
    current[:string] = first + second
  end

  def middle
    ( @term.width / 2 ).floor
  end

  def find_header
    t = @current == :find ? '[Find]' : 'Find'
    "#{t}: /#{@data[:find][:string]}/"
  end

  def middle_spacing(s)
    " " * ( middle - s.length )
  end

  def replace_header
    t = @current == :replace ? '[Replace]' : 'Replace'
    "#{t}: '#{@data[:replace][:string]}'"
  end

  def divider
    '=' * @term.width
  end

  def header
    @term.update(@l+=1, find_header + middle_spacing(find_header) + replace_header )
    @term.update(@l+=1, divider)
  end

  def list_dir
    Dir.glob( '*' ).each do |f|
      begin
        if f =~ /#{@data[:find][:string]}/
          @term.update(@l+=1, f + middle_spacing(f) + f.gsub(/#{@data[:find][:string]}/,@data[:replace][:string]))
        end
      rescue
        @term.update(@l+=1, f + middle_spacing(f) + "Invalid Regex")
      end
    end
  end

end
