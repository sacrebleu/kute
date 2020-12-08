require_relative '../ui/util/space'

describe 'Ui::Util::Space' do
  context 'When humanizing byte values' do

    let(:subject) { Ui::Util::Space }

    it 'leaves 1000 bytes alone' do
      expect(subject.humanize(1000)).to eql('1000b')
    end

    it 'translates 1024b to 1kb' do
      expect(subject.humanize(1024)).to eql('1kb')
    end

    it 'leaves 1023kb as 1023kb' do
      expect(subject.humanize(1024*1023)).to eql('1023kb')

    end

    it 'translates 1024kb to 1Mb' do
      expect(subject.humanize(1024*1024)).to eql('1Mb')
    end

  end
end
