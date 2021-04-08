# require "spec_helper"
require_relative '../ui/pane'

describe 'Ui::Layout::Pane' do
  let(:data) { generate_data(20) }
  let(:partial_data)   { generate_data(15) } # test partial
  let(:page_plus_one)  { generate_data(21) } # test boundary condition postitive
  let(:page_minus_one) { generate_data(19) } # test boundary condition negative

  let(:subject) do
    s = Ui::Pane.new(data, 10)
    allow(s.color).to receive(:cyan).with(anything) { |arg| arg }
    s
  end

  context 'when unfiltered' do
    it 'reports the list of items' do
      expect(subject.items).to eql(20)
    end

    it 'reports the number of items per page' do
      expect(subject.items_per_page).to eql(10)
    end

    it 'reports the number of pages' do
      expect(subject.pages).to eql(2)
    end

    it 'reports the length of the filtered subset of data' do
      expect(subject.filtered_items).to eql(20)
    end

    it 'reports the view as being the correct length and containing the correct items' do
      expect(subject.view.length).to eql(10)
      expect(subject.view[0].name).to eql('row 1')
      expect(subject.view[9].name).to eql('row 10')
    end

    it 'will permit pagination to the next page when legal' do
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      subject.next!
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 11')
      subject.next!
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 11')
    end

    it 'will permit pagination to the previous page when legal' do
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      subject.next!
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 11')
      subject.previous!
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      subject.previous!
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
    end

    it 'permits scrolling to a legal page' do
      subject.goto!(2)
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 11')
      subject.goto!(3) # should cause no change
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 11')
      subject.goto!(1)
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      subject.goto!(0)
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      subject.goto!(nil) # should have no effect
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
    end

    it 'will jump to the last page' do
      expect(subject.display_page).to eql('1/2')
      subject.last!
      expect(subject.display_page).to eql('2/2')
    end

    it 'will jump to the first page' do
      subject.last!
      expect(subject.display_page).to eql('2/2')
      subject.first!
      expect(subject.display_page).to eql('1/2')
    end

    it 'permits selecting the first row' do
      subject.first_row!
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
    end

    it 'permits selecting the last row' do
      subject.last_row!
      expect(subject.view[0].selected).to be_falsey
      expect(subject.view[1].selected).to be_falsey
      expect(subject.view[9].selected).to be_truthy
    end

    it 'moves the selected index one row forward if legal' do
      subject.first_row!
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
      subject.next_row!
      expect(subject.view[0].selected).to be_falsey
      expect(subject.view[1].selected).to be_truthy
      subject.goto_row!(10)
      expect(subject.view[0].selected).to be_falsey
      expect(subject.view[1].selected).to be_falsey
      expect(subject.view[9].selected).to be_truthy
    end

    it 'moves the selected index one row back if legal' do
      subject.goto_row!(1)
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
      subject.goto_row!(2)
      expect(subject.view[0].selected).to be_falsey
      expect(subject.view[1].selected).to be_truthy
      subject.previous_row!
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
      subject.previous_row! # should be noop
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
    end

    it 'does not permit going to an illegal row' do
      subject.goto_row!(1)
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey

      subject.goto_row!(-1)
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey

      subject.goto_row!(200)
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[1].selected).to be_falsey
    end

    it 'will move to the correct page when goto is issued to something beyond the current view' do
      subject.goto_row!(15)
      expect(subject.view[3].selected).to be_falsey
      expect(subject.view[4].selected).to be_truthy
      expect(subject.view[5].selected).to be_falsey
      expect(subject.display_page).to eql('2/2')
    end

    it 'will move to the next page when next_row! is called from the last row of the current view' do
      subject.goto_row!(10)
      expect(subject.view[9].selected).to be_truthy
      expect(subject.display_page).to eql('1/2')

      subject.next_row!
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[9].selected).to be_falsey
      expect(subject.display_page).to eql('2/2')
    end

    it 'will move to the previous page when previous_row! is called from the first row of the current view' do
      subject.goto_row!(11)
      expect(subject.view[0].selected).to be_truthy
      expect(subject.view[9].selected).to be_falsey
      expect(subject.display_page).to eql('2/2')

      subject.previous_row!
      expect(subject.view[9].selected).to be_truthy
      expect(subject.view[0].selected).to be_falsey
      expect(subject.display_page).to eql('1/2')
    end
  end

  context 'when filtering' do
    it 'reports the list of items' do
      expect(subject.items).to eql(20)
    end

    it 'reports the length of the filtered subset of data' do
      subject.filter! { |f| /1/.match(f.name) }
      expect(subject.filtered_items).to eql(11)
      expect(subject.pages).to eql(2)
    end

    it 'correctly paginates on the filtered items' do
      subject.filter! { |f| /1/.match(f.name) }

      subject.goto_row!(11)
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 19')
      expect(subject.view.length).to eql(1)

      subject.previous_row!
      expect(subject.display_page).to eql('1/2')
      expect(subject.view[0].name).to eql('row 1')
      expect(subject.view[9].name).to eql('row 18')
      expect(subject.view.length).to eql(10)

      subject.next!
      expect(subject.display_page).to eql('2/2')
      expect(subject.view[0].name).to eql('row 19')
      expect(subject.view.length).to eql(1)

      subject.filter! { |f| /11/.match(f.name) }

      subject.goto_row!(11)
      expect(subject.display_page).to eql('1/1')
      expect(subject.view[0].name).to eql('row 11')
      expect(subject.view.length).to eql(1)

      subject.previous_row!
      expect(subject.display_page).to eql('1/1')
      expect(subject.view[0].name).to eql('row 11')
      expect(subject.view.length).to eql(1)

      subject.next!
      expect(subject.display_page).to eql('1/1')
      expect(subject.view[0].name).to eql('row 11')
      expect(subject.view.length).to eql(1)
    end
  end

  def generate_data(n)
    (1..n).collect do |i|
      MockRow.new(i)
    end
  end

  class MockRow < Ui::Pane::SelectableRow
    attr_reader :selected, :index, :name

    def initialize(idx)
      @index = idx
      @name = "row #{idx}"
    end
  end
end
