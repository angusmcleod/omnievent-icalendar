# frozen_string_literal: true

RSpec.describe OmniEvent::Icalendar do
  let(:calendar) { File.join(File.expand_path("..", __dir__), "fixtures", "calendar.ics") }

  def local_uri(file)
    "file://#{file}"
  end

  before do
    OmniEvent::Builder.new do
      provider :icalendar
    end
  end

  describe "list_events" do
    it "returns an event list" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri(calendar))

      expect(events.size).to eq(2)
      expect(events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri(calendar))

      expect(events.size).to eq(2)
      expect(events).to all(be_valid)
    end

    it "returns events with metadata" do
      events = OmniEvent.list_events(:icalendar, uri: local_uri(calendar))

      expect(events.size).to eq(2)
      expect(events.first.metadata.created_at).to eq("1996-03-29T13:30:00Z")
    end

    context "with remote ics" do
      let(:ext_uri) { "https://icalendar-host.com/calendar.ics" }

      before do
        stub_request(:get, ext_uri)
          .to_return(body: File.read(calendar), headers: { "Content-Type" => "text/calendar" })
      end

      it "returns an event list" do
        events = OmniEvent.list_events(:icalendar, uri: ext_uri)

        expect(events.size).to eq(2)
        expect(events).to all(be_kind_of(OmniEvent::EventHash))
      end
    end

    context "with recurrence" do
      let(:recurring_event) { File.join(File.expand_path("..", __dir__), "fixtures", "calendar_recurring_event.ics") }

      it "expands recurrences" do
        events = OmniEvent.list_events(:icalendar, uri: local_uri(recurring_event), expand_recurrences: true)

        expect(events.size).to eq(5)
        expect(events.last.data.start_time).to eq("1997-07-18T15:00:00+00:00")
        expect(events.last.data.end_time).to eq("1997-07-19T02:00:00+00:00")
      end

      it "handles series_ids, occurrence_ids and sequences correctly" do
        events = OmniEvent.list_events(:icalendar, uri: local_uri(recurring_event), expand_recurrences: true)

        expect(events.map { |e| e.metadata.series_id }.uniq.size).to eq(1)
        expect(events.map { |e| e.metadata.occurrence_id }.uniq.size).to eq(5)
      end
    end
  end
end
