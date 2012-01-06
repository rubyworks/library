
    ## last ditch attempt, search all $LOAD_PATH
    if suffix
      SUFFIXES.each do |ext|
        $LOAD_PATH.each do |location|
          file = ::File.join(location, path + ext)
          if ::File.file?(file)
            return Library::Script.new(location, '.', path, ext)
            matches << file 
          end
        end
      end
    else
      $LOAD_PATH.each do |location|
        file = ::File.join(location, file)
        if ::File.file?(file)
          return Library::Script.new(location, '.', path, ext) unless select
          matches << file
        end
      end
    end


