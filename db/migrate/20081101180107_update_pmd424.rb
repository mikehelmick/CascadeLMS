class UpdatePmd424 < ActiveRecord::Migration
  def self.up
    execute "update settings set value = 'asm-3.1.jar jakarta-oro-2.0.8.jar jaxen-1.1.1.jar pmd-4.2.4.jar xercesImpl-2.6.2.jar xmlParserAPIs-2.6.2.jar checkStyle.jar asm-3.0.jar backport-util-concurrent.jar' where  name = 'pmd_libs'"
  end

  def self.down
    execute "update settings set value = 'jakarta-oro-2.0.8.jar jaxen-1.1-beta-10.jar pmd-3.9.jar xercesImpl-2.6.2.jar xmlParserAPIs-2.6.2.jar checkStyle.jar asm-3.0.jar backport-util-concurrent.jar' where  name = 'pmd_libs'"
  end
end
