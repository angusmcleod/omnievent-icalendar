# frozen_string_literal: true

RSpec.describe OmniEvent::Icalendar do
  let(:ical_file) { File.join(File.expand_path("..", __dir__), "fixtures", "calendar.ics") }

  before do
    OmniEvent::Builder.new do
      provider :icalendar
    end
  end

  describe "list_events" do
    before do
      @events = OmniEvent.list_events(:icalendar, uri: "file://#{ical_file}")
    end

    it "returns an event list" do
      expect(@events.size).to eq(1)
      expect(@events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      expect(@events.size).to eq(1)
      expect(@events).to all(be_valid)
    end

    it "returns events with metadata" do
      expect(@events.size).to eq(1)
      expect(@events.first.metadata.created_at).to eq("1996-03-29T13:30:00+00:00")
    end
  end
end
