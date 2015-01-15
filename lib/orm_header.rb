require 'rubygems'    
require 'active_record'    
ActiveRecord::Base.establish_connection(    
    :adapter => "mysql2",    
    :host => "10.30.10.46",    
    :database => "cms",
    :username => "tableau",
    :password => "tableau"    
)


class Vendor < ActiveRecord::Base
    self.table_name = "device_manufacturer"

    has_many :devices, foreign_key: "manufacturer_id"
end
 
class LeadName < ActiveRecord::Base 
    self.table_name = "device_lead_name"

    has_many :devices,        foreign_key: "device_lead_name_id"
    has_many :device_players, foreign_key: "device_lead_name_id"

    has_and_belongs_to_many :players,   join_table: "device_to_player" , 
        foreign_key: "device_lead_name_id" ,
        association_foreign_key: "mobile_content_player_id"
    has_and_belongs_to_many :platforms, join_table: "device_to_player" , 
        foreign_key: "device_lead_name_id",
        association_foreign_key: "device_os_id"
end

class Device < ActiveRecord::Base
    self.table_name = "device_model"

    belongs_to :lead_name, foreign_key: "device_lead_name_id"
    belongs_to :vendor,    foreign_key: "manufacturer_id"
end

class Player < ActiveRecord::Base
    self.table_name = "mobile_content_player"
    
    has_and_belongs_to_many :platforms,  join_table: "device_to_player" , 
        association_foreign_key: "device_os_id" ,
        foreign_key: "mobile_content_player_id"
    has_and_belongs_to_many :lead_names, join_table: "device_to_player" , 
        association_foreign_key: "device_lead_name_id", 
        foreign_key: "mobile_content_player_id"
end

class Platform < ActiveRecord::Base
    self.table_name = "device_os"
    
    has_and_belongs_to_many :players,    join_table: "device_to_player" , 
        association_foreign_key: "mobile_content_player_id" ,
        foreign_key: "device_os_id"
    has_and_belongs_to_many :lead_names, join_table: "device_to_player" , 
        association_foreign_key: "device_lead_name_id", 
        foreign_key: "device_os_id"
end
