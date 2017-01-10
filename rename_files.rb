class Directory

  def initialize(chars_to_change, new_chars, target_directory, home_directory)
    require 'find'
    @chars_to_change = chars_to_change.gsub(/\./, '\.')
    @new_chars = new_chars
    @target_directory = target_directory
    @home_directory = home_directory || ""
  end

  def find_target_directory
    return nil if @home_directory.empty?

    counter = 0
    back_one_directory_level = ""
    directory = Dir.pwd

    until directory =~ /Users\/#{@home_directory}$/ || counter == 100
      directory = File.expand_path('../' + back_one_directory_level)
      back_one_directory_level += "../"
      counter += 1
    end

    Find.find(directory) { |path|
      Find.prune if path =~ /(\/\.)|(Application(s)?\/)|(Cloud|cloud)|(Library\/)|(Trash\/)/

      if path =~ /#{@target_directory}$/
        return path
      end
      next
    }
  end

  def find_directory_files
    paths = Dir[(find_target_directory or "/#{@target_directory}") + "/*"]
    raise "ERROR: Directory Not Found!" if paths.empty?
    paths
  end

  def confirm_file(path)
    matched_path = ( !path.nil? && File.file?(path[0]) && !path[2].match("/") ).to_s
    return matched_path if matched_path.respond_to? :successful?
    matched_path.class.class_eval {
      define_method :successful? do
        eql? "true"
      end
    }
    matched_path
  end

  def confirm_file_rename(answer, full_path, combined_path)
    answer = ""

    puts "Confirm Changes (Y/N/ALL): \n"
    answer = $stdin.gets.chomp.upcase

    case answer
    when /Y(ES)?/
      File.rename(full_path, combined_path)
      puts "Changes Successful!"
    when /N(O)?/
      puts "No changes made."
    when /ALL/
      return answer
    else
      confirm_file_rename(answer, full_path, combined_path)
    end
    answer
  end

  def rename_files
    files = find_directory_files
    @collecton_of_paths = []
    puts "Filenames:"

    files.each do |path|
      matched_path = path.match(/(.*\/)(.*#{@chars_to_change}.*)/)

      if confirm_file(matched_path).successful?
        @path_without_file = matched_path[1]
        @file = matched_path[2].gsub(/#{@chars_to_change}/, "#{@new_chars}")

        puts "\tOld: " + path
        puts "\tNew: " + @path_without_file + @file
        print "\n"

        @answer ||= ""

        unless @answer =~ /ALL/
          @answer = confirm_file_rename(@answer, path, @path_without_file + @file)
          if @answer =~ /ALL/
            @collecton_of_paths << path 
            @collecton_of_paths << @path_without_file + @file
          end
        else
          @collecton_of_paths << path
          @collecton_of_paths << @path_without_file + @file
        end

      end
    end

    if @collecton_of_paths.any?
      paths = @collecton_of_paths

      for i in 0...paths.length
        if i.even?
          File.rename(paths[i], paths[i+1])
        end
      end
      puts "Changes Successful!"
    end

    puts "NO MATCHING FILES!" if @file.nil? || @file.empty?
  end

end

if ARGV.length < 3
  puts "File characters to change: \n"
  ARGV[0] = $stdin.gets.chomp
  puts "New characters to insert: \n"
  ARGV[1] = $stdin.gets.chomp
  puts "Target directory or path: \n"
  ARGV[2] = $stdin.gets.chomp
  puts "Home directory (optional): \n"
  ARGV[3] = $stdin.gets.chomp
end

dir = Directory.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
dir.rename_files