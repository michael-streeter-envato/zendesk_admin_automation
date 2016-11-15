#!/usr/bin/env ruby

##
# Original author: M.Streeter
# Creation date: 20161109
# Purpose: copy hosted field from envatomarketplaces1453179616 to envatomarketplaces
# Example call: ruby ~/Development/cp_ticket_fields.rb

require 'json'
require 'dotenv'

class ZendeskTable
    # Initialise by reading in a json file, exported from Zendesk
    def initialize(file)
        @zendesk_table = JSON.parse(File.read(file))
    end
    
=begin
            {
            "id": 24586663,
            "type": "tagger",
            "title": "Outcome (Hosted)",
            "description": "",
            "active": true,
            "required": true,
            "collapsed_for_agents": false,
            "regexp_for_validation": null,
            "title_in_portal": "Outcome (Hosted)",
            "visible_in_portal": false,
            "editable_in_portal": false,
            "required_in_portal": false,
            "removable": true,
            "custom_field_options": [
                {
                    "name": "Cancelled",
                    "value": "hosted_outcome_cancelled",
                    "default": false
                }...
            ]
        },
=end

    def ticket_field(id)
        @zendesk_table["ticket_fields"].find {|g|g["id"]==id}
    end
    
    # Id function, when given "name" as a parameter, searches the array and returns the id (or raises an unhandled exception).
    def group_id(name)
        @zendesk_table["groups"].find {|g|g["name"]==name}["id"]
    end
    
end

#general setup
Dotenv.load
mp_sandbox                = ENV["MP_SANDBOX"] # "envatomarketplaces1473407787"
mp_sandbox_credentials    = ENV["MP_SANDBOX_CREDENTIALS"] # "-u michael.streeter@envato.com/token:..."
mp_production             = ENV["MP_PRODUCTION"] # "envatomarketplaces"
mp_production_credentials = ENV["MP_PRODUCTION_CREDENTIALS"] # "-u michael.streeter@envato.com/token:..."

#setup for this run
destination = mp_sandbox
credentials = mp_sandbox_credentials
#source = "/Users/michaelstreeter/Development/envatomarketplaces/ticket_fields/envatomarketplaces1473407787.ticket_fields.20161111.json"
source = "/Users/michaelstreeter/Development/envatomarketplaces/ticket_fields/envatomarketplaces.ticket_fields..20161109.json"
safety = true # true = don't make changes only print messages, false = make changes

#output configuration
puts "source: " + source
puts "destination: " + destination

from = ZendeskTable.new(source)

# some examples from previous versions
#[productionGroup.ticket_field(24634066), productionGroup.ticket_field(24634086), productionGroup.ticket_field(24586703), productionGroup.ticket_field(24586663), productionGroup.ticket_field(24634106), productionGroup.ticket_field(24586683)].each {| f |
#[from.ticket_field(24404686), from.ticket_field(24363483), from.ticket_field(24369856)].each {| f |  #Root cause|Outcome|Common problem
[from.ticket_field(21350889), from.ticket_field(22823450)].each {| f |  # Full name|Incident final impact
    
    # print "f = \'"
    # print f
    # puts "\'"
    # puts " "
    
    if( f )
        field_input = "{\"ticket_field\": {\"type\": \"" + f["type"] + "\",\"title\": \"" + f["title"] + "\",\"active\": " + (f["active"]? "true" : "false") + ",\"required\": " + (f["required"]? "true" : "false") + ",\"collapsed_for_agents\": " + (f["collapsed_for_agents"]? "true" : "false") + ",\"title_in_portal\": \"" + f["title_in_portal"] + "\",\"visible_in_portal\": " + (f["visible_in_portal"]? "true" : "false") + ",\"editable_in_portal\": " + (f["editable_in_portal"]? "true" : "false") + ",\"required_in_portal\": " + (f["required_in_portal"]? "true" : "false") + ",\"removable\": " + (f["removable"]? "true" : "false") 
        custom_field_options = ""

        if (f["type"]=="tagger")
            cfo = ""
            f["custom_field_options"].each do |h|
            cfo += "{\"name\": \"" + h["name"] + "\", \"value\": \"" + h["value"] + "\", \"default\": " + (h["default"]? "true" : "false") + "}, "
            end
            #remove the trailing ", ", then close off the array, and terminate the JSON object
            custom_field_options = ",\"custom_field_options\": [" + cfo[0..-3] += "]}"
        end

        field_input += custom_field_options + "}"
        field_input = field_input.gsub(/'/, %q/'"'"'/) # Field may contain text like "Let's get specific" see http://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings

        command = "curl -g https://#{destination}.zendesk.com/api/v2/ticket_fields.json -d \'#{field_input}\' -H 'Content-Type: application/json' -X POST -v #{credentials}"

        if(safety)
            puts "safety is on. command = " + command
        else
            response = `curl -g https://#{destination}.zendesk.com/api/v2/ticket_fields.json -d \'#{field_input}\' -H 'Content-Type: application/json' -X POST -v #{credentials}`
            puts response
        end
    
        puts `sleep 5`
        
    end        
}
