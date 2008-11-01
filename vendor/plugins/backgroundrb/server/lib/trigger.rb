module BackgrounDRb
  class Trigger

    attr_accessor :start_time, :end_time, :repeat_interval

    def initialize(opts={})
      @start_time = Time.parse(opts[:start]) if opts.has_key?(:start)
      #@end_time = Time.parse(opts[:end])
      @end_time = Time.parse(opts[:end]) if opts.has_key?(:end)
      @repeat_interval = opts[:repeat_interval].to_i if opts.has_key?(:repeat_interval)
    end

    def fire_after_time(time)
      @start_time = time  if not @start_time

      # Support UNIX at-style scheduling, by just specifying a start
      # time.
      if @end_time.nil? and @repeat_interval.nil?
        @end_time = start_time + 1
        @repeat_interval = 1
      end

      case
      when @end_time && time > @end_time
        nil
      when time < @start_time
        @start_time
      when @repeat_interval != nil && @repeat_interval > 0
        time + @repeat_interval - ((time - @start_time) % @repeat_interval)
      end
    end

  end

end
