# frozen_string_literal: true

require_relative "../../omnievent/icalendar/version"
require "icalendar"
require "icalendar-recurrence"
require "open-uri"
require "addressable/uri"

module OmniEvent
  module Strategies
    # Strategy for files conforming to https://datatracker.ietf.org/doc/html/rfc5545
    class Icalendar
      class Error < StandardError; end

      include OmniEvent::Strategy

      option :name, "icalendar"
      option :expand_recurrences
      option :uri, ""

      def raw_events
        return [] unless ics_file

        begin
          calendars = ::Icalendar::Calendar.parse(ics_file)
        rescue ArgumentError
          calendars = []
        end

        return [] unless calendars.any?

        result = []
        calendars.each do |calendar|
          result += calendar.events
        end

        result = expand_recurrences(result) if options.expand_recurrences

        result
      end

      def event_hash(raw_event)
        data = {
          start_time: format_time(raw_event.dtstart),
          end_time: format_time(raw_event.dtend),
          name: raw_event.summary.to_s,
          description: raw_event.description.to_s,
          url: raw_event.url.to_s
        }

        OmniEvent::EventHash.new(
          provider: name,
          data: data,
          metadata: retrieve_metadata(raw_event)
        )
      end

      def authorized?
        true
      end

      protected

      def ics_file
        uri = Addressable::URI.parse(options.uri)

        case uri.scheme
        when "http", "https"
          URI.open(uri.to_s).read # rubocop:disable Security/Open we know this is a url so there is no security risk
        when "file"
          File.read(uri.path)
        end
      end

      def retrieve_metadata(event)
        metadata = {
          uid: format_uid(event),
          taxonomies: event.categories.to_s,
          status: convert_status(event.status),
          created_at: format_time(event.created),
          updated_at: format_time(event.last_modified),
          sequence: nil,
          series_id: nil,
          occurrence_id: nil
        }

        metadata[:sequence] = event.sequence.to_s if event.sequence

        if event.recurrence_id
          metadata[:series_id] = event.uid.to_s
          metadata[:occurrence_id] = event.recurrence_id.to_s
        end

        metadata
      end

      def format_uid(event)
        # See https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.4.4
        event_uid = event.uid.to_s
        event_uid += "#{options.uid_delimiter}#{event.recurrence_id}" if event.recurrence_id
        event_uid += "#{options.uid_delimiter}#{event.sequence}" if event.sequence
        event_uid
      end

      def convert_status(raw_status)
        case raw_status
        when "TENTATIVE"
          "draft"
        when "CONFIRMED"
          "published"
        when "CANCELLED"
          "cancelled"
        else
          "published"
        end
      end

      def expand_recurrences(events)
        events.each_with_object([]) do |event, res|
          schedule = ::Icalendar::Recurrence::Schedule.new(event)

          occurrences = if options.from_time && options.to_time
                          schedule.occurrences_between(options.from_time, options.to_time)
                        else
                          schedule.all_occurrences
                        end

          occurrences.each do |occurrence|
            occurrence_event = event.clone
            occurrence_event.recurrence_id = occurrence.start_time
            occurrence_event.dtstart = occurrence.start_time
            occurrence_event.dtend = occurrence.end_time
            res << occurrence_event
          end
        end
      end
    end
  end
end
