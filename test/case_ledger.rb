covers 'library/ledger'

testcase Library::Ledger do

  method :add do
    test do
      ledger = Library::Ledger.new
      ledger.add(File.dirname(__FILE__) + '/fixture')
      ledger.assert.size == 1
    end
  end

  method :[] do
    test do
      ledger = Library::Ledger.new
      ledger.add(File.dirname(__FILE__) + '/fixture')

      ledger[:foo].assert.is_a? Array
      ledger['foo'].assert.is_a? Array
    end
  end

end
