module CableReady
  module Updatable
    class CollectionsRegistry
      def initialize
        @registered_collections = []
      end

      def register(collection)
        @registered_collections << collection
      end

      def broadcast_for!(model, operation)
        @registered_collections.select { |c| c[:options][:on].include?(operation) }
          .each do |collection|
          resource = find_resource_for_update(collection, model)
          next if resource.nil?

          collection[:klass].cable_ready_update_collection(resource, collection[:name], model) if collection[:options][:if].call(resource)
        end
      end

      private

      def find_resource_for_update(collection, model)
        inverse_association = collection[:inverse_association]

        # Sometimes this isn't coming through even when we've defined the `inverse_of` on both sides of the association.
        unless inverse_association
          # For now, we'll just force the issue.
          inverse_association = collection[:klass].reflect_on_association(collection[:name]).inverse_of.name.to_s
        end

        raise ArgumentError, "Could not find inverse_of for #{collection[:name]}" unless inverse_association

        resource = model
        resource = resource.send(collection[:through_association].underscore) if collection[:through_association]
        resource.send(inverse_association.underscore)
      end
    end
  end
end
