require 'spec_helper'
describe 'role_waarneming' do

  context 'with defaults for all parameters' do
    it { should contain_class('role_waarneming') }
  end
end
