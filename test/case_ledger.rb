cover 'library/ledger'

test_case Library::Ledger do

  method :add do
    test do
      ledger = Library::Ledger.new
      ledger.add(File.direname(__FILE__) + '/fixture')
      ledger.assert.size == 1
    end
  end

  method :[] do
    test do
      ledger = Library::Ledger.new
      ledger.add(File.direname(__FILE__) + '/fixture')

      ledger[:foo].assert.is_a? Library
      ledger['foo'].assert.is_a? Library
    end
  end

end
