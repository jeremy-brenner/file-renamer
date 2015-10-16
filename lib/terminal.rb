require 'io/console'

module Terminal
  module Common
    def move_cursor(line,col)
      system('echo', '-en',"\033[#{line};#{col}H")
    end
    def width
      $stdin.winsize[1]
    end
    def height
      $stdin.winsize[0]
    end
  end

  class Screen
    include Terminal::Common
    def initialize
      echo_off
      build_rows
      set_cursor_position(height,width)
    end

    def echo_off
      system("stty raw -echo")
    end

    def echo_on
      system("stty -raw echo")
    end

    def end
      set_cursor_position(height,0)
      echo_on
    end

    def build_rows
      @rows = ( 0..height ).map { |r| Terminal::Row.new(r) }
    end

    def clear_all
      clear_from(0)
    end

    def clear_from(i)
      @rows[i..-i].each { |r| r.clear }
    end

    def get_input
    c = ''
    eoc = false
    begin
      c << $stdin.read_nonblock(1)
    rescue EOFError, Errno::EAGAIN
      if c.length == 0
        sleep 0.01
      else
        eoc = true
      end
    end until eoc
    c
    end

    def update(r,d)
      @rows[r].update(d)
      return_cursor
    end

    def return_cursor
      move_cursor(*@cursor)
    end

    def set_cursor_position(line,col)
      @cursor = [line,col]
      return_cursor
    end


  end

  class Row
    include Terminal::Common
    def initialize(i)
      @i = i
      @data = ''
      clear
    end

    def clear
      update( ' ' * width )
    end

    def value
      @data
    end

    def update(data)
      diff = @data.length - data.length
      pad = ''
      if diff > 0
        pad = ' ' * diff
      end
      if @data != data
        @data = data
        move_cursor(@i,0)
        print @data + pad
      end
    end
  end
end
