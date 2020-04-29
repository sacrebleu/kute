require 'rubygems'
require 'rspec'
require 'colorize'

require_relative '../node_report'

describe 'String Justification' do

  context 'when right justifying strings' do
    it 'pads correctly regardless of whether the string is colorized' do
      c = Nodes::Column.new("test", 40)

      t1 = "test string"
      t2 = t1.red

      expect(t1.length).to_not eql(t2.length)

      v1 = c.rjust(t1)
      v2 = c.rjust(t2)

      expect(v1.length).to eql(v2.uncolorize.length)
    end
  end
end