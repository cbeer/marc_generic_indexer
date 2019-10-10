# frozen_string_literal: true

require 'logger'
require 'traject'

settings do
  provide "reader_class_name", "Traject::MarcReader"
end

to_field 'id', extract_marc('001')
to_field 'marcxml_s' do |record, accumulator|
  accumulator << (MARC::FastXMLWriter.single_record_document(record, include_namespace: true) + "\n")
end

each_record do |record, context|
  record.each_with_index do |field, idx|
    context.output_hash["field_#{field.tag}"] ||= []

    field_data = {
      id: "#{context.output_hash['id'].first}_#{field.tag}_#{idx}",
      tag_s: field.tag,
      value_s: field.to_s,
      indicator1_ss: (field.indicator1 if field.respond_to?(:indicator1)),
      indicator2_ss: (field.indicator2 if field.respond_to?(:indicator2))
    }

    subfields_data = field.subfields.each_with_object({}) do |subfield, obj|
      obj["subfield_#{subfield.code}_ss"] ||= []
      obj["subfield_#{subfield.code}_ss"] << subfield.value
    end if field.respond_to? :subfields

    context.output_hash["field_#{field.tag}"] << field_data.merge(subfields_data || {})
  end
end
