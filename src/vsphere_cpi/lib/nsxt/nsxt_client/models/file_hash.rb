=begin
#NSX API

#VMware NSX REST API

OpenAPI spec version: 1.0.0

Generated by: https://github.com/swagger-api/swagger-codegen.git
Swagger Codegen version: 2.3.1

=end

require 'date'

module NSXT
  # File hash code
  class FileHash
    attr_accessor :_self

    # The server will populate this field when returing the resource. Ignored on PUT and POST.
    attr_accessor :_links

    attr_accessor :_schema

    # File name
    attr_accessor :name

    # Algorithm used to compute the file's hash
    attr_accessor :hash_type

    # Computed hash of file
    attr_accessor :hash_code

    class EnumAttributeValidator
      attr_reader :datatype
      attr_reader :allowable_values

      def initialize(datatype, allowable_values)
        @allowable_values = allowable_values.map do |value|
          case datatype.to_s
          when /Integer/i
            value.to_i
          when /Float/i
            value.to_f
          else
            value
          end
        end
      end

      def valid?(value)
        !value || allowable_values.include?(value)
      end
    end

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        :'_self' => :'_self',
        :'_links' => :'_links',
        :'_schema' => :'_schema',
        :'name' => :'name',
        :'hash_type' => :'hash_type',
        :'hash_code' => :'hash_code'
      }
    end

    # Attribute type mapping.
    def self.swagger_types
      {
        :'_self' => :'SelfResourceLink',
        :'_links' => :'Array<ResourceLink>',
        :'_schema' => :'String',
        :'name' => :'String',
        :'hash_type' => :'String',
        :'hash_code' => :'String'
      }
    end

    # Initializes the object
    # @param [Hash] attributes Model attributes in the form of hash
    def initialize(attributes = {})
      return unless attributes.is_a?(Hash)

      # convert string to symbol for hash key
      attributes = attributes.each_with_object({}){|(k,v), h| h[k.to_sym] = v}

      if attributes.has_key?(:'_self')
        self._self = attributes[:'_self']
      end

      if attributes.has_key?(:'_links')
        if (value = attributes[:'_links']).is_a?(Array)
          self._links = value
        end
      end

      if attributes.has_key?(:'_schema')
        self._schema = attributes[:'_schema']
      end

      if attributes.has_key?(:'name')
        self.name = attributes[:'name']
      end

      if attributes.has_key?(:'hash_type')
        self.hash_type = attributes[:'hash_type']
      end

      if attributes.has_key?(:'hash_code')
        self.hash_code = attributes[:'hash_code']
      end

    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      invalid_properties = Array.new
      if @name.nil?
        invalid_properties.push("invalid value for 'name', name cannot be nil.")
      end

      if @hash_type.nil?
        invalid_properties.push("invalid value for 'hash_type', hash_type cannot be nil.")
      end

      if @hash_code.nil?
        invalid_properties.push("invalid value for 'hash_code', hash_code cannot be nil.")
      end

      return invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      return false if @name.nil?
      return false if @hash_type.nil?
      hash_type_validator = EnumAttributeValidator.new('String', ["SHA1"])
      return false unless hash_type_validator.valid?(@hash_type)
      return false if @hash_code.nil?
      return true
    end

    # Custom attribute writer method checking allowed values (enum).
    # @param [Object] hash_type Object to be assigned
    def hash_type=(hash_type)
      validator = EnumAttributeValidator.new('String', ["SHA1"])
      unless validator.valid?(hash_type)
        fail ArgumentError, "invalid value for 'hash_type', must be one of #{validator.allowable_values}."
      end
      @hash_type = hash_type
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          _self == o._self &&
          _links == o._links &&
          _schema == o._schema &&
          name == o.name &&
          hash_type == o.hash_type &&
          hash_code == o.hash_code
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Fixnum] Hash code
    def hash
      [_self, _links, _schema, name, hash_type, hash_code].hash
    end

    # Builds the object from hash
    # @param [Hash] attributes Model attributes in the form of hash
    # @return [Object] Returns the model itself
    def build_from_hash(attributes)
      return nil unless attributes.is_a?(Hash)
      self.class.swagger_types.each_pair do |key, type|
        if type =~ /\AArray<(.*)>/i
          # check to ensure the input is an array given that the the attribute
          # is documented as an array but the input is not
          if attributes[self.class.attribute_map[key]].is_a?(Array)
            self.send("#{key}=", attributes[self.class.attribute_map[key]].map{ |v| _deserialize($1, v) } )
          end
        elsif !attributes[self.class.attribute_map[key]].nil?
          self.send("#{key}=", _deserialize(type, attributes[self.class.attribute_map[key]]))
        end # or else data not found in attributes(hash), not an issue as the data can be optional
      end

      self
    end

    # Deserializes the data based on type
    # @param string type Data type
    # @param string value Value to be deserialized
    # @return [Object] Deserialized data
    def _deserialize(type, value)
      case type.to_sym
      when :DateTime
        DateTime.parse(value)
      when :Date
        Date.parse(value)
      when :String
        value.to_s
      when :Integer
        value.to_i
      when :Float
        value.to_f
      when :BOOLEAN
        if value.to_s =~ /\A(true|t|yes|y|1)\z/i
          true
        else
          false
        end
      when :Object
        # generic object (usually a Hash), return directly
        value
      when /\AArray<(?<inner_type>.+)>\z/
        inner_type = Regexp.last_match[:inner_type]
        value.map { |v| _deserialize(inner_type, v) }
      when /\AHash<(?<k_type>.+?), (?<v_type>.+)>\z/
        k_type = Regexp.last_match[:k_type]
        v_type = Regexp.last_match[:v_type]
        {}.tap do |hash|
          value.each do |k, v|
            hash[_deserialize(k_type, k)] = _deserialize(v_type, v)
          end
        end
      else # model
        temp_model = NSXT.const_get(type).new
        temp_model.build_from_hash(value)
      end
    end

    # Returns the string representation of the object
    # @return [String] String presentation of the object
    def to_s
      to_hash.to_s
    end

    # to_body is an alias to to_hash (backward compatibility)
    # @return [Hash] Returns the object in the form of hash
    def to_body
      to_hash
    end

    # Returns the object in the form of hash
    # @return [Hash] Returns the object in the form of hash
    def to_hash
      hash = {}
      self.class.attribute_map.each_pair do |attr, param|
        value = self.send(attr)
        next if value.nil?
        hash[param] = _to_hash(value)
      end
      hash
    end

    # Outputs non-array value in the form of hash
    # For object, use to_hash. Otherwise, just return the value
    # @param [Object] value Any valid value
    # @return [Hash] Returns the value in the form of hash
    def _to_hash(value)
      if value.is_a?(Array)
        value.compact.map{ |v| _to_hash(v) }
      elsif value.is_a?(Hash)
        {}.tap do |hash|
          value.each { |k, v| hash[k] = _to_hash(v) }
        end
      elsif value.respond_to? :to_hash
        value.to_hash
      else
        value
      end
    end

  end

end
