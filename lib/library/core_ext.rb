class File

  #
  RE_PATH_SEPERATOR = Regexp.new('[' + Regexp.escape(File::Separator) + %q{\\\/} + ']')

  #
  def self.split_root(path)
    path.split(RE_PATH_SEPERATOR, 2)
  end

end

class Hash

  #
  # Transform keys of hash returning a new hash.
  #
  def rekey #:yield:
    if block_given?
      inject({}){|h,(k,v)| h[yield(k)]=v; h}
    else
      inject({}){|h,(k,v)| h[k.to_sym]=v; h}
    end
  end

  #
  # In-place rekey.
  #
  def rekey! #:yield:
    replace(rekey{|k| yield(k) })
  end

end

