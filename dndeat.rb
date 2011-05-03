#!/usr/bin/ruby

require 'rubygems'
require 'readline'
require 'yaml'
require 'display'
require 'pp'
#
# Create saves directory stucture
#

unless File.directory? "saves"
  Dir.mkdir "saves"
  Dir.mkdir "saves/cha"
  Dir.mkdir "saves/enc"
end

#
# Character Class
#

class Character 
  attr_accessor :under_the_gun, :out_of_combat
  ATTRIBUTE_LIST = 
    [
    ['Name',  Display::ALPHANUMERIC_FIELD, true],
    ['XP',    Display::NUMERIC_FIELD,      true],
    ['HP',    Display::NUMERIC_FIELD,      true],
    ['Notes', Display::ALPHANUMERIC_FIELD, false],
    ['AC',    Display::NUMERIC_FIELD,      false],
    ['Ref',   Display::NUMERIC_FIELD,      false],
    ['Will',  Display::NUMERIC_FIELD,      false],
    ['Fort',  Display::NUMERIC_FIELD,      false],
    ['STR',   Display::NUMERIC_FIELD,      false],
    ['CON',   Display::NUMERIC_FIELD,      false],
    ['DEX',   Display::NUMERIC_FIELD,      false],
    ['INT',   Display::NUMERIC_FIELD,      false],
    ['WIS',   Display::NUMERIC_FIELD,      false],
    ['CHA',   Display::NUMERIC_FIELD,      false],
    ['Init',  Display::NUMERIC_FIELD,      false],
    ]

  def self.create
    config = Display::GetAttribPrompt.new('Character Creation')
    ATTRIBUTE_LIST.each {|a| config.add!(a[0], a[1], a[2])} 
    return Character.new(config.prompt!)
  end

  #
  # @charinfo = [{:id=><string>, :fieldtype=<regex>, :val=><string>}, .. ]
  #

  def initialize(config=[])
    @charinfo = config
  end

  def edit(attrib=nil, value=nil)
    if attrib and value               #Change a single attribute without prompt
      @charinfo.each do |a|
        a[:val] = value if a[:id].eql? attrib
      end
    else                              #Allows user to edit Character attributes.
      curr_cha_name = @charinfo.select{|x| x[:id].eql? 'Name'}[0][:val]
      disp = Display::EditAttribPrompt.new("Editing #{curr_cha_name}")
      @charinfo.each do |a|
        disp.add! a[:id], a[:fieldtype], a[:val] 
      end
      @charinfo = disp.prompt!
    end
  end

  def info(attribute_id_list)
    output = []
    attribute_id_list.each do |a|
      output << @charinfo.select{|x| x[:id].eql? a}[0][:val] rescue output << ''
    end
    return output
  end

  def save
    char_savename = Display::GetAttribPrompt.new('Saving Character Template')
    char_savename.add! "Template Name", Display::ALPHANUMERIC_FIELD, true
    savefile = char_savename.prompt![0][:val]

    File.open("saves/cha/#{savefile}", "w+") do |f|
      f.print YAML::dump(@charinfo)
    end
  end

  def self.loadc
    loadmenu = Display::MenuPrompt.new("Load Character Template", '')
    Dir.entries("saves/cha").select{|x| not ['.', '..'].include? x}.each do |f|
      loadmenu.add! f
    end

    load_filename = loadmenu.prompt!
    if load_filename
      name_prompt = Display::GetAttribPrompt.new("Name of Loaded Character")
      name_prompt.add! 'Name', Display::ALPHANUMERIC_FIELD, true
      new_name = name_prompt.prompt![0][:val]

      loaded_char_data = YAML::load_file("saves/cha/#{load_filename}")
      loaded_char_data.each do |a| 
        a[:val]=new_name if a[:id].eql? 'Name'
      end
      return Character.new(loaded_char_data)
    else
      # If the user selects load but there isn't any files to load, just create a new character
      return Character.create
    end
  end
end

#
# Encounter Class
#

class Encounter
  NEW_ENCOUNTER     = "New  Encounter"
  LOAD_ENCOUNTER    = "Load Encounter"
  RESUME_ENCOUNTER  = "Resume Playing Encounter"
  SAVE_ENCOUNTER    = "Save Encounter As Template"
  MERGE_ENCOUNTERS  = "Merge Encounter Templates"
  ADD_NEW_CHARACTER = "Add New Character"
  ENCOUNTER_XP      = "Encounter Experience Total"
  LOAD_CHARACTER    = "Load Character Template"
  SAVE_CHARACTER    = "Save Character Template"
  EDIT_CHARACTER    = "Edit Character"
  DELETE_CHARACTER  = "Delete Character from Encounter"
  CUSTOMISE_DISPLAY = "Customise Display"
  COMBAT_BEGIN      = "Engage Combat!"
  COMBAT_NEXT       = "Next Character's Turn"
  COMBAT_PREV       = "Preview Character's Turn"
  COMBAT_DAMAGE     = "Damage Character"
  COMBAT_HEAL       = "Heal  Character"
  COMBAT_DEATH      = "Remove Current Character From Combat"
  EXIT_PROGRAMME    = "Exit Programme"
  EXIT_ENCOUNTER    = "Exit Encounter"

  def initialize(loadfile=[])
    # Can modify the Table views here by changing the attributes shown.
    # Eventually will add the feature were the user can modify these arrays.
    @createview = ['Name', 'AC', 'Ref', 'Will','Fort', 'Notes']
    @combatview = ['Init', 'Name', 'HP', 'AC', 'Notes']
    @characters = loadfile
    edit
    return true
  end

  def edit
    loop do
      table = Display::Table.new(@createview, [['Name', Display::ALPHANUMERIC_FIELD]])
      @characters.each {|c| table.row! c.info(@createview)}
      currentscreen = table.display!

      menu = Display::MenuPrompt.new('Encounter Menu', currentscreen)
      menu.add! ADD_NEW_CHARACTER
      menu.add! LOAD_CHARACTER
      menu.add! DELETE_CHARACTER
      menu.add! EDIT_CHARACTER
      menu.add! SAVE_CHARACTER
      menu.add! ENCOUNTER_XP
      menu.add! SAVE_ENCOUNTER
      menu.add! LOAD_ENCOUNTER
      menu.add! MERGE_ENCOUNTERS
      menu.add! COMBAT_BEGIN
      menu.add! RESUME_ENCOUNTER
      menu.add! EXIT_PROGRAMME
      selection = menu.prompt!

      case selection
      when ADD_NEW_CHARACTER then @characters << Character.create
      when LOAD_CHARACTER    then @characters << Character.loadc
      when EDIT_CHARACTER
        prompt_character_selection("Edit Character",   'Name'){|c,i| c.edit}
      when DELETE_CHARACTER
        prompt_character_selection("Delete Character", 'Name'){|c,i| @characters.delete_at(i)}
      when SAVE_CHARACTER
        prompt_character_selection("Save Character",   'Name'){|c,i| c.save}
      when ENCOUNTER_XP
        xpdisp  = Display::Table.new(['Total XP'], [['Total XP', Display::NUMERIC_FIELD]])
        xpcount = 0
        @characters.each {|c| xpcount += c.info('XP')[0].to_i}
        xpdisp.row! [xpcount.to_s]
        xpdisp.display!
        Display::Pause.new
      when SAVE_ENCOUNTER   then save
      when LOAD_ENCOUNTER   then Encounter.loade
      when MERGE_ENCOUNTERS then @characters += Encounter.loade(:merge)
      when COMBAT_BEGIN     then combat!
      when RESUME_ENCOUNTER then combat!(:resume)
      when EXIT_PROGRAMME   then exit 0
      end
    end
  end

  def prompt_character_selection(title, attribute_id)
    menu = Display::MenuPrompt.new(title)
    @characters.each {|c| menu.add! c.info(attribute_id)}
    selected_char = menu.prompt!
    if selected_char
      index=0
      @characters.each do |c| 
        yield(c,index) if c.info(attribute_id).eql? selected_char
        index+=1
      end
    end
  end

  def save
    enc_savename = Display::GetAttribPrompt.new('Saving Encounter Template')
    enc_savename.add! "Template Name", Display::ALPHANUMERIC_FIELD, true
    savefile = enc_savename.prompt![0][:val]
    File.open("saves/enc/#{savefile}", "w+"){|f| f.print YAML::dump(@characters)}
  end

  def self.loade(merge=nil)
    loadlist = Display::MenuPrompt.new("Load Encounter Template", '')
    Dir.entries("saves/enc").select{|x| not ['.', '..'].include? x}.each do |f|
      loadlist.add! f
    end
    loadfile = loadlist.prompt!
    enc_load = YAML::load_file("saves/enc/#{loadfile}") rescue []

    case
    when merge           then return enc_load
    when enc_load.empty? then return Encounter.new()
    else return Encounter.new(enc_load) 
    end
  end

  def combat!(resume=false)
    unless resume
      initiative = Display::GetAttribPrompt.new('Roll Initiative')
      @characters.each do |c|
        c.under_the_gun = false
        c.out_of_combat = false
        initiative.add! c.info('Name')[0], Display::NUMERIC_FIELD, true
      end
      rolls = initiative.prompt!.reverse!
      @characters.each{|c| c.edit('Init', rolls.pop[:val])}
    else
      @characters.each do |c|
        if c.info('Init')[0].empty?
          initiative ||= Display::GetAttribPrompt.new('Roll Initiative')
          initiative.add! c.info('Name')[0], Display::NUMERIC_FIELD, true
        end
      end
      rolls = initiative.prompt!.reverse! rescue []
      @characters.each do |c|
        if c.info('Init')[0].empty?
          c.under_the_gun = false
          c.edit('Init', rolls.pop[:val])
        end
      end
     end

    # Sort Characters from highest to lowest, first by Initiative then by Dexterity
    @characters.sort!{|x,y|
      [y.info('Init')[0].to_i, y.info('DEX')[0].to_i] <=> [x.info('Init')[0].to_i, x.info('DEX')[0].to_i]
    }
    @characters[0].under_the_gun=true unless resume

    loop do 
      playtable = Display::Table.new(["Turn", @combatview].flatten, [['Init', Display::NUMERIC_FIELD]])
      @characters.each do |c|
        playtable.row! [(c.under_the_gun ? '+' : ''), c.info(@combatview)].flatten
      end
      currentscreen = playtable.display!

      playoptions = Display::MenuPrompt.new("DM Combat Options", currentscreen)
      playoptions.add! COMBAT_NEXT
      playoptions.add! COMBAT_PREV
      playoptions.add! COMBAT_DAMAGE
      playoptions.add! COMBAT_HEAL
      playoptions.add! COMBAT_DEATH
      playoptions.add! EDIT_CHARACTER
      playoptions.add! SAVE_ENCOUNTER
      playoptions.add! EXIT_ENCOUNTER
      combatdecision = playoptions.prompt!
      
      case combatdecision
      when COMBAT_NEXT
        @characters.each_with_index do |c,i|
          if c.under_the_gun
            c.under_the_gun = false
            (1..@characters.length).each do |d|
              index = (i+d) % (@characters.length)
              @characters[index].under_the_gun=true and break unless @characters[index].out_of_combat
            end
            break
          end
        end
      when COMBAT_PREV
        @characters.each_with_index do |c,i|
          if c.under_the_gun
            c.under_the_gun = false
            (1..@characters.length).each do |d|
              index = (i-d) % (@characters.length)
              @characters[index].under_the_gun=true and break unless @characters[index].out_of_combat
            end
            break
          end
        end
      when COMBAT_DAMAGE
       prompt_character_selection("Who Receives Damage",'Name') do |c,i| 
         damage = Display::GetAttribPrompt.new("How much?")
         damage.add! 'Amount', Display::NUMERIC_FIELD, true
         damage_value = damage.prompt![0][:val].to_i
         damage_value = c.info('HP')[0].to_i - damage_value
         c.edit('HP', damage_value.to_s)
       end
      when COMBAT_HEAL
       prompt_character_selection("Who Receives Healing",'Name') do |c,i| 
         heal = Display::GetAttribPrompt.new("How much?")
         heal.add! 'Amount', Display::NUMERIC_FIELD, true
         heal_value = heal.prompt![0][:val].to_i
         heal_value = c.info('HP')[0].to_i + heal_value
         c.edit('HP', heal_value.to_s)
       end
      when COMBAT_DEATH   then current_characters_turn{|c| c.out_of_combat=true}
      when EDIT_CHARACTER then prompt_character_selection("Edit Character", 'Name'){|c,i| c.edit}
      when SAVE_ENCOUNTER then save
      when EXIT_ENCOUNTER then break
      end
    end
  end
  def current_characters_turn
    @characters.each{|c| c.under_the_gun ? yield(c) : c}
  end
end

if (__FILE__ == $0) 
  loop do
    Encounter.new
  end
end
