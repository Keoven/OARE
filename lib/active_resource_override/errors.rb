class Oare::Errors < ActiveResource::Errors
  def from_array(messages, save_cache = false)
    clear unless save_cache
    humanized_nested_attributes = @base.nested_attributes_values.map do |model, v|
      v.map do |i, v2|
        v2.keys.map do |k|
          attribute_name = "#{model.gsub('_attributes','')}_#{k}".underscore
          [attribute_name.humanize, attribute_name]
        end
      end
    end.flatten
    humanized_nested_attributes = Hash[*humanized_nested_attributes]

    humanized_attributes = @base.attributes.keys.inject({}) { |h, attr_name| h.update(attr_name.humanize => attr_name) }
    humanized_attributes.merge!(humanized_nested_attributes)
    messages.each do |message|
      attr_message = humanized_attributes.keys.detect do |attr_name|
        if message[0, attr_name.size + 1] == "#{attr_name} "
          add humanized_attributes[attr_name], message[(attr_name.size + 1)..-1]
        end
      end

      self[:base] << message if attr_message.nil?
    end
  end
end
