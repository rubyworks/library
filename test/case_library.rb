covers 'library'

testcase Library do

  class_method :new do

    test do
      Library.new(File.dirname(__FILE__) + '/fixture')
    end

  end

end
