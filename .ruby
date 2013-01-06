#!/usr/bin/env ruby

profile :development do

  config 'qed' do
    $LEDGER.isolate_project(File.dirname(__FILE__))
  end

end

