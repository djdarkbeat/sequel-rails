require 'active_support/core_ext/module/attr_internal'

module SequelRails
  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

      protected

      attr_internal :db_runtime

      def process_action(action, *)
        # We also need to reset the runtime before each action
        # because of queries in middleware or in cases we are streaming
        # and it won't be cleaned up by the method below.
        ::SequelRails::Railties::LogSubscriber.reset_runtime
        super
      end

      def cleanup_view_runtime
        db_rt_before_render = ::SequelRails::Railties::LogSubscriber.reset_runtime
        self.db_runtime = (db_runtime || 0) + db_rt_before_render
        runtime = super
        db_rt_after_render = ::SequelRails::Railties::LogSubscriber.reset_runtime
        self.db_runtime += db_rt_after_render
        runtime - db_rt_after_render
      end

      def append_info_to_payload(payload)
        super
        payload[:db_runtime] = (db_runtime || 0) + ::SequelRails::Railties::LogSubscriber.reset_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, db_runtime = super, payload[:db_runtime]
          messages << sprintf('Models: %.1fms', db_runtime.to_f) if db_runtime
          messages
        end
      end
    end
  end
end
