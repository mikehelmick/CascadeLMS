
module ActionView
  module Helpers
    module ActiveRecordHelper
  
      ## Helper method for deciding if an error class should be emitted
      ## for a particular field of an active record.
      def error_class_for(object, field)
        return '' if object.nil?
        return '' if object.errors.nil? rescue return ''
        # has an errors field
        return 'error' unless object.errors[field].nil? rescue ''
        ''
      end

      def tab_active(tabObj, tabName)
        return false if tabObj.nil?
        return tabName.eql?(tabObj)
      end
    end
  end
end