require 'spec_helper'

describe Git::Bundle do
  it 'has a version number' do
    expect(Git::Bundle::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
