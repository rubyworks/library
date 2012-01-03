covers 'library/version'

testcase Library::Version do

  concern "Ensure functionality of Roll's Version class."

  method :to_s do
    test do
      v = Library::Version.new('1.2.3')
      v.to_s.assert == '1.2.3'
    end
  end

  method :to_str do
    test do
      v = Library::Version.new('1.2.3')
      v.to_str.assert == '1.2.3'
    end
  end

  method :inspect do
    test do
      v = Library::Version.new('1.2.3')
      v.inspect.assert == '1.2.3'
    end
  end

  method :[] do
    test do
      v = Library::Version.new('1.2.3')
      v[0].assert == 1
      v[1].assert == 2
      v[2].assert == 3
    end
  end

  method :<=> do
    test do
      v1 = Library::Version.new('1.2.3')
      v2 = Library::Version.new('1.2.4')
      (v2 <=> v1).assert == 1
    end
  end

  # TODO
  #   def =~( other )
  #     #other = other.to_t
  #     upver = other.dup
  #     upver[0] += 1
  #     @self >= other and @self < upver
  #   end

  method :=~ do
    test "pessimistic constraint" do
      v1 = Library::Version.new('1.2.4')
      v2 = Library::Version.new('1.2')
      assert(v1 =~ v2)
    end
  end

  method :major do
    test do
      v = Library::Version.new('1.2.3')
      v.major.assert == 1
    end
  end

  method :minor do
    test do
      v = Library::Version.new('1.2.3')
      v.minor.assert == 2
    end
  end

  method :patch do
    test do
      v = Library::Version.new('1.2.3')
      v.patch.assert == 3
    end
  end

  class_method :parse_constraint do
    test do
      constraint = Library::Version.parse_constraint("~> 1.0.0")
      constraint.assert == ["=~", Library::Version['1.0.0']]
    end
  end

end
