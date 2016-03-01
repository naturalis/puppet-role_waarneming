require 'spec_helper'
describe 'waarneming' do

  context 'with defaults for all parameters' do
    it { should contain_class('waarneming') }
  end
end
