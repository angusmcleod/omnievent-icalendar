# frozen_string_literal: true

RSpec.describe OmniEvent::Icalendar do
  let(:ical_file) { File.join(File.expand_path("..", __dir__), "fixtures", "calendar.ics") }

  before do
    OmniEvent::Builder.new do
      provider :icalendar
    end
  end

  describe "list_events" do
    let(:local_uri) { "file://#{ical_file}" }

    it "returns an event list" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri)

      expect(events.size).to eq(1)
      expect(events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri)

      expect(events.size).to eq(1)
      expect(events).to all(be_valid)
    end

    it "returns events with metadata" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri)

      expect(events.size).to eq(1)
      expect(events.first.metadata.created_at).to eq("1996-03-29T13:30:00+00:00")
    end

    context "with remote ics" do
      let(:ext_uri) { "https://icalendar-host.com/calendar.ics" }

      before do
        stub_request(:get, ext_uri)
          .to_return(body: File.read(ical_file), headers: { "Content-Type" => "text/calendar" })
      end

      it "returns an event list" do
        events = OmniEvent.list_events(:icalendar, uri: ext_uri)

        expect(events.size).to eq(1)
        expect(events).to all(be_kind_of(OmniEvent::EventHash))
      end
    end
  end
end
