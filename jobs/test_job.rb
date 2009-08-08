
class TestJob
  
  def initialize( arg )
    @arg = arg
  end
  
  def execute()
    puts "Starting job with #{@arg}"
    sleep(1)
    puts "Donw with job #{@arg}"
  end
  
end

job = TestJob.new(ARGV[0].to_i)
job.execute()
return 0